#!/usr/bin/env bash
# TUICallKit_Swift + RTCRoomEngine on Xcode 16: missing .onSuggestSwitchToCellular in switch(event)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PODS="$ROOT/Pods/TUICallKit_Swift/TUICallKit_Swift"

python3 - "$PODS" <<'PY'
from pathlib import Path
import sys

pods_root = Path(sys.argv[1])
files = [
    pods_root / "Feature" / "CallingBellFeature.swift",
    pods_root / "TUICallKitImpl.swift",
]
marker = ".onSuggestSwitchToCellular"
insert = "        case .onSuggestSwitchToCellular:\n            break\n"


def patch_switch_event(text: str) -> tuple[str, int]:
    needle = "switch event {"
    patched = 0
    start = 0
    while True:
        idx = text.find(needle, start)
        if idx == -1:
            break
        brace = text.find("{", idx)
        depth = 0
        end = None
        for i in range(brace, len(text)):
            ch = text[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i
                    break
        if end is None:
            break
        block = text[brace : end + 1]
        if marker not in block and "@unknown default" not in block:
            text = text[:end] + insert + text[end:]
            patched += 1
            start = end + len(insert) + 1
        else:
            start = end + 1
    return text, patched


for path in files:
    if not path.is_file():
        print(f"::warning::TUICallKit patch skipped (missing): {path}")
        continue
    original = path.read_text(encoding="utf-8")
    updated, count = patch_switch_event(original)
    if count:
        path.write_text(updated, encoding="utf-8")
        print(f"Patched {count} switch(event) in {path.name}")
    else:
        print(f"No patch needed for {path.name}")
PY
