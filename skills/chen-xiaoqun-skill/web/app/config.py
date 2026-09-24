import os

from dotenv import load_dotenv

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(BASE_DIR, ".env"))

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")
DEEPSEEK_BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")

TTS_PROVIDER = os.getenv("TTS_PROVIDER", "edge")
TTS_VOICE = os.getenv("TTS_VOICE", "zh-CN-YunjianNeural")
TTS_RATE = os.getenv("TTS_RATE", "+10%")

# MiniMax 音色克隆（TTS_PROVIDER=minimax 时启用）
MINIMAX_API_KEY = os.getenv("MINIMAX_API_KEY", "")
MINIMAX_GROUP_ID = os.getenv("MINIMAX_GROUP_ID", "")
MINIMAX_VOICE_ID = os.getenv("MINIMAX_VOICE_ID", "")
MINIMAX_TTS_MODEL = os.getenv("MINIMAX_TTS_MODEL", "speech-01-turbo")
MINIMAX_SPEED = float(os.getenv("MINIMAX_SPEED", "1.0"))
MINIMAX_BASE_URL = os.getenv("MINIMAX_BASE_URL", "https://api.minimaxi.com")

MAX_HISTORY_TURNS = int(os.getenv("MAX_HISTORY_TURNS", "8"))

HOST = os.getenv("HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8000"))
