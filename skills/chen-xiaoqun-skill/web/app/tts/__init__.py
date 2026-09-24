import logging

from app import config
from app.tts.base import TTSProvider
from app.tts.edge import EdgeTTSProvider

logger = logging.getLogger("xiaoqun")


class FallbackTTS(TTSProvider):
    """主 provider 失败（如余额不足/限流）时自动降级到备用 provider。"""

    def __init__(self, primary: TTSProvider, backup: TTSProvider):
        self.primary = primary
        self.backup = backup

    async def synthesize(self, text: str) -> bytes:
        try:
            return await self.primary.synthesize(text)
        except Exception as e:
            logger.warning("主 TTS 失败(%s)，降级到 edge-tts", e)
            return await self.backup.synthesize(text)


def get_tts_provider() -> TTSProvider:
    edge = EdgeTTSProvider(voice=config.TTS_VOICE, rate=config.TTS_RATE)
    if config.TTS_PROVIDER == "edge":
        return edge
    if config.TTS_PROVIDER == "minimax":
        from app.tts.minimax import MiniMaxTTSProvider

        minimax = MiniMaxTTSProvider(
            api_key=config.MINIMAX_API_KEY,
            group_id=config.MINIMAX_GROUP_ID,
            voice_id=config.MINIMAX_VOICE_ID,
            model=config.MINIMAX_TTS_MODEL,
            speed=config.MINIMAX_SPEED,
            base_url=config.MINIMAX_BASE_URL,
        )
        return FallbackTTS(minimax, edge)
    raise ValueError(f"未知的 TTS_PROVIDER: {config.TTS_PROVIDER}")
