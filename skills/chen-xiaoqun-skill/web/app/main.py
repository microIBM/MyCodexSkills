import asyncio
import base64
import logging
import os
import re

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles

from app import config, llm
from app.sentence import SentenceSplitter
from app.session import Session
from app.tts import get_tts_provider

logger = logging.getLogger("xiaoqun")
app = FastAPI()
tts = get_tts_provider()

STATIC_DIR = os.path.join(config.BASE_DIR, "static")

# LLM 偶尔违规输出 markdown/舞台注释，兜底清洗保证朗读干净
_MD_CHARS = str.maketrans("", "", "*#`")
_PAREN_NOTE = re.compile(r"[（(][^）)]{1,12}[）)]")


def _clean_delta(text: str) -> str:
    return text.translate(_MD_CHARS)


def _clean_sentence(text: str) -> str:
    return _PAREN_NOTE.sub("", text).strip()


async def _synth_and_send(ws: WebSocket, gen_id: int, seq: int, sentence: str):
    try:
        audio = await tts.synthesize(sentence)
    except Exception as e:
        logger.warning("TTS failed for %r: %s", sentence, e)
        await ws.send_json({"type": "tts_error", "gen_id": gen_id, "sentence": sentence})
        return
    await ws.send_json(
        {
            "type": "audio",
            "gen_id": gen_id,
            "seq": seq,
            "sentence": sentence,
            "data": base64.b64encode(audio).decode(),
        }
    )


async def _pipeline(ws: WebSocket, session: Session, user_text: str, gen_id: int):
    messages = session.build_messages(user_text)
    splitter = SentenceSplitter()
    full_reply: list[str] = []
    # TTS 在独立 task 中逐句消费，避免每句合成阻塞 LLM 流（字幕卡顿、总时长串行叠加）
    queue: asyncio.Queue = asyncio.Queue()

    async def tts_consumer():
        seq = 0
        while True:
            sentence = await queue.get()
            if sentence is None:
                return
            sentence = _clean_sentence(sentence)
            if not sentence:
                continue
            await _synth_and_send(ws, gen_id, seq, sentence)
            seq += 1

    consumer = asyncio.create_task(tts_consumer())
    try:
        async for delta in llm.stream_chat(messages):
            delta = _clean_delta(delta)
            full_reply.append(delta)
            await ws.send_json({"type": "llm_delta", "gen_id": gen_id, "text": delta})
            for sentence in splitter.feed(delta):
                queue.put_nowait(sentence)
        for sentence in splitter.flush():
            queue.put_nowait(sentence)
        queue.put_nowait(None)
        await consumer
        session.append_turn(user_text, "".join(full_reply))
        await ws.send_json({"type": "done", "gen_id": gen_id})
    except asyncio.CancelledError:
        if full_reply:
            session.append_turn(user_text, "".join(full_reply) + "（被打断）")
        raise
    except Exception as e:
        logger.exception("pipeline error")
        if full_reply:
            session.append_turn(user_text, "".join(full_reply))
        try:
            await ws.send_json({"type": "error", "gen_id": gen_id, "message": str(e)})
        except Exception:
            pass
    finally:
        if not consumer.done():
            consumer.cancel()
            await asyncio.gather(consumer, return_exceptions=True)


@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    await ws.accept()
    session = Session()
    try:
        while True:
            msg = await ws.receive_json()
            mtype = msg.get("type")
            if mtype == "user_text":
                text = (msg.get("text") or "").strip()
                if not text:
                    continue
                await session.interrupt()
                gen_id = session.next_gen_id()
                await ws.send_json({"type": "gen_start", "gen_id": gen_id, "user_text": text})
                session.current_task = asyncio.create_task(_pipeline(ws, session, text, gen_id))
            elif mtype == "set_mode":
                m = msg.get("mode")
                if m in ("base", "full"):
                    session.mode = m
                    await ws.send_json({"type": "mode_set", "mode": m})
            elif mtype == "interrupt":
                await session.interrupt()
    except WebSocketDisconnect:
        pass
    finally:
        await session.interrupt()


app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
