import sys

for _s in (sys.stdout, sys.stderr):
    if _s and hasattr(_s, "reconfigure"):
        _s.reconfigure(encoding="utf-8")

import uvicorn

from app import config


def main():
    if not config.DEEPSEEK_API_KEY or config.DEEPSEEK_API_KEY.startswith("sk-xxxx"):
        print("[错误] 未配置 DEEPSEEK_API_KEY。")
        print("请复制 web/.env.example 为 web/.env，并填入你的 DeepSeek API Key。")
        print("获取地址: https://platform.deepseek.com")
        sys.exit(1)
    print(f"陈小群语音对话已启动 → http://{config.HOST}:{config.PORT}  (请用 Chrome/Edge 打开)")
    uvicorn.run("app.main:app", host=config.HOST, port=config.PORT, log_level="warning")


if __name__ == "__main__":
    main()
