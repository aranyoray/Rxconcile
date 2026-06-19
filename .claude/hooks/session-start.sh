#!/bin/bash
# Rxconcile SessionStart hook.
#
# This is an iOS / Swift app, so the Xcode build & XCTest suite can only run on
# macOS — not in a Linux web session. What *is* runnable here is the Python data
# pipeline that generates the bundled datasets (controlled substances, state
# rules) and the app icon. This hook prepares that tooling and validates the data.
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

echo "[Rxconcile hook] Installing Python tooling for the dataset/icon pipeline…"
python3 -m pip install --quiet --upgrade pip >/dev/null 2>&1 || true
python3 -m pip install --quiet Pillow >/dev/null 2>&1 || true

echo "[Rxconcile hook] Validating bundled datasets…"
python3 scripts/build_controlled_substances.py --check
python3 - <<'PY'
import json, pathlib
root = pathlib.Path("Sources/Rxconcile/Resources/Data")
states = json.loads((root / "state_rules.json").read_text())["states"]
assert states, "state_rules.json has no states"
print(f"OK: {len(states)} state rules")
PY

echo "[Rxconcile hook] Done. (Swift build/tests require macOS + Xcode: 'xcodegen generate && xcodebuild test')"
