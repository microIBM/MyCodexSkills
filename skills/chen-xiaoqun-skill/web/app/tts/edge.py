import asyncio
import logging

import edge_tts

from app.tts.base import TTSProvider

logger = logging.getLogger("xiaoqun")


class EdgeTTSProvider(TTSProvider):
    def __init__(self, voice: str, rate: str):
        self.voice = voice
        self.rate = rate

    async def synthesize(self, text: str) -> bytes:
        try:
            return await self._synth(text)
        except Exception as e:
            logger.warning("edge-tts first attempt failed for %r: %s, retrying", text, e)
            await asyncio.sleep(0.5)
            return await self._synth(text)

    async def _synth(self, text: str) -> bytes:
        communicate = edge_tts.Communicate(text, self.voice, rate=self.rate)
        chunks = []
        async for c in communicate.stream():
            if c["type"] == "audio":
                chunks.append(c["data"])
        if not chunks:
            raise RuntimeError("edge-tts returned no audio")
        return b"".join(chunks)
