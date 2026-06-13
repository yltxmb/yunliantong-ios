#!/usr/bin/env bash
# 对企业签平台：给 .app 内所有 Mach-O / framework / appex 做 ad-hoc 占位签名（codesign -s -）
# 多数第三方重签工具无法处理「完全无 _CodeSignature」的包
set -euo pipefail

APP="${1:?Usage: ci-adhoc-sign-app.sh /path/to/App.app}"

if [ ! -d "$APP" ]; then
  echo "App bundle not found: $APP" >&2
  exit 1
fi

sign_path() {
  local target="$1"
  if [ ! -e "$target" ]; then
    return 0
  fi
  codesign --force --sign - --timestamp=none --generate-entitlement-der "$target" 2>/dev/null \
    || codesign --force --sign - "$target"
}

echo "Ad-hoc signing (inside-out): $APP"

while IFS= read -r -d '' item; do
  sign_path "$item"
done < <(find "$APP" -depth \( -type d \( -name '*.framework' -o -name '*.appex' \) -o -type f -name '*.dylib' \) -print0)

sign_path "$APP"

if ! codesign --verify --deep --strict "$APP" 2>/dev/null; then
  echo "Warning: strict verify failed, retrying with --deep only" >&2
  codesign --verify --deep "$APP"
fi

echo "Ad-hoc sign OK: $APP"
codesign -dv "$APP" 2>&1 | head -5 || true
