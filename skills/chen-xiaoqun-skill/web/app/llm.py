from typing import AsyncIterator

from openai import AsyncOpenAI

from app import config

_client = AsyncOpenAI(base_url=config.DEEPSEEK_BASE_URL, api_key=config.DEEPSEEK_API_KEY)


async def stream_chat(messages: list[dict]) -> AsyncIterator[str]:
    stream = await _client.chat.completions.create(
        model=config.DEEPSEEK_MODEL,
        messages=messages,
        stream=True,
        max_tokens=400,
        temperature=1.1,
    )
    try:
        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content
    finally:
        # 被打断（task cancel）时立即释放底层 HTTP 连接
        await stream.close()
