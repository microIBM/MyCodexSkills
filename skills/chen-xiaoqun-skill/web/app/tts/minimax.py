import logging

import httpx

from app.tts.base import TTSProvider

logger = logging.getLogger("xiaoqun")


class MiniMaxTTSProvider(TTSProvider):
    """MiniMax T2A v2 合成，使用克隆得到的 voice_id。"""

    def __init__(self, api_key: str, group_id: str, voice_id: str, model: str, speed: float, base_url: str):
        if not (api_key and group_id and voice_id):
            raise ValueError("MiniMax 需要配置 MINIMAX_API_KEY / MINIMAX_GROUP_ID / MINIMAX_VOICE_ID")
        self.api_key = api_key
        self.voice_id = voice_id
        self.model = model
        self.speed = speed
        self.url = f"{base_url}/v1/t2a_v2"
        self.params = {"GroupId": group_id}
        self._client = httpx.AsyncClient(timeout=30)

    async def synthesize(self, text: str) -> bytes:
        payload = {
            "model": self.model,
            "text": text,
            "stream": False,
            "voice_setting": {"voice_id": self.voice_id, "speed": self.speed, "vol": 1.0, "pitch": 0},
            "audio_setting": {"format": "mp3", "sample_rate": 24000, "channel": 1},
        }
        headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
        r = await self._client.post(self.url, params=self.params, json=payload, headers=headers)
        r.raise_for_status()
        data = r.json()
        audio_hex = (data.get("data") or {}).get("audio")
        if not audio_hex:
            raise RuntimeError(f"MiniMax 无音频返回: {data.get('base_resp')}")
        return bytes.fromhex(audio_hex)
