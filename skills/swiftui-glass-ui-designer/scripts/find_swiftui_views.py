#!/usr/bin/env python3
"""List likely SwiftUI view files in the current repository.

This helper is optional. It does not modify files. It helps an agent quickly
inventory Swift files that define SwiftUI Views before a design-system pass.
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path.cwd()
EXCLUDE_DIRS = {".git", ".build", "DerivedData", "Pods", "Carthage", ".swiftpm"}
VIEW_RE = re.compile(r"\bstruct\s+\w+\s*:\s*View\b|\bvar\s+body\s*:\s*some\s+View\b")


def should_skip(path: pathlib.Path) -> bool:
    return any(part in EXCLUDE_DIRS for part in path.parts)


def main() -> int:
    files = []
    for path in ROOT.rglob("*.swift"):
        if should_skip(path):
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if "import SwiftUI" in text and VIEW_RE.search(text):
            rel = path.relative_to(ROOT)
            files.append(str(rel))

    if not files:
        print("No likely SwiftUI view files found.")
        return 0

    print("Likely SwiftUI view files:")
    for item in sorted(files):
        print(f"- {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
