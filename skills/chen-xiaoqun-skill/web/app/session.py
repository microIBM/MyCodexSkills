import asyncio
from collections import deque

from app import config
from app.persona import get_system_prompt


class Session:
    def __init__(self):
        self.history: deque = deque(maxlen=2 * config.MAX_HISTORY_TURNS)
        self.current_task: asyncio.Task | None = None
        self._gen_id = 0
        self.mode = "base"  # base=蒸馏版人设 / full=完整 SKILL.md

    def next_gen_id(self) -> int:
        self._gen_id += 1
        return self._gen_id

    def build_messages(self, user_text: str) -> list[dict]:
        return [
            {"role": "system", "content": get_system_prompt(self.mode)},
            *self.history,
            {"role": "user", "content": user_text},
        ]

    def append_turn(self, user_text: str, assistant_text: str):
        self.history.append({"role": "user", "content": user_text})
        self.history.append({"role": "assistant", "content": assistant_text})

    async def interrupt(self):
        if self.current_task and not self.current_task.done():
            self.current_task.cancel()
            # gather 只吞子任务的取消，interrupt 自身被取消时仍会向上抛
            await asyncio.gather(self.current_task, return_exceptions=True)
        self.current_task = None
