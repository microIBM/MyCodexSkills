_TERMINATORS = set("。！？；!?;\n")
_MIN_LEN = 6


class SentenceSplitter:
    def __init__(self):
        self._buf = ""
        self._scanned = 0

    def feed(self, delta: str) -> list[str]:
        self._buf += delta
        sentences = []
        start = 0
        for i in range(self._scanned, len(self._buf)):
            if self._buf[i] in _TERMINATORS:
                candidate = self._buf[start : i + 1].strip()
                if len(candidate) >= _MIN_LEN:
                    sentences.append(candidate)
                    start = i + 1
                # 太短的碎句不切，留给下一句合并
        self._buf = self._buf[start:]
        self._scanned = len(self._buf)
        return sentences

    def flush(self) -> list[str]:
        rest = self._buf.strip()
        self._buf = ""
        self._scanned = 0
        return [rest] if rest else []
