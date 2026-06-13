#!/usr/bin/env bash
# 企业签平台常见要求：占位签名需兼容 V1/V2/V3 重签
# V2: --generate-entitlement-der（iOS 15+ 必需）
# V3: --generate-pre-encrypt-hashes（iOS 17+ / 新 CodeDirectory）
set -euo pipefail

APP="${1:?Usage: ci-adhoc-sign-app.sh /path/to/App.app}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENT="$ROOT/TUIKitDemo/ci-resign-placeholder.entitlements"

if [ ! -d "$APP" ]; then
  echo "App bundle not found: $APP" >&2
  exit 1
fi

cat > "$ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict></dict></plist>
EOF

supports_v3=false
if codesign --help 2>&1 | grep -q 'generate-pre-encrypt-hashes'; then
  supports_v3=true
fi

sign_nested() {
  local target="$1"
  local -a args=(--force --sign - --timestamp=none)
  if [ "$supports_v3" = true ]; then
    args+=(--generate-entitlement-der --generate-pre-encrypt-hashes)
  else
    args+=(--generate-entitlement-der)
  fi
  codesign "${args[@]}" "$target"
}

sign_app() {
  local target="$1"
  local -a args=(--force --sign - --timestamp=none --entitlements "$ENT")
  if [ "$supports_v3" = true ]; then
    args+=(--generate-entitlement-der --generate-pre-encrypt-hashes)
  else
    args+=(--generate-entitlement-der)
  fi
  args+=(--preserve-metadata=identifier,entitlements,flags)
  codesign "${args[@]}" "$target"
}

echo "Ad-hoc signing (V2/V3 compatible): $APP"
echo "V3 pre-encrypt hashes: $supports_v3"

while IFS= read -r -d '' item; do
  sign_nested "$item"
done < <(find "$APP" -depth \( -type d \( -name '*.framework' -o -name '*.appex' \) -o -type f -name '*.dylib' \) -print0)

sign_app "$APP"

if ! codesign --verify --deep --strict "$APP" 2>/dev/null; then
  echo "Warning: strict verify failed, retrying with --deep only" >&2
  codesign --verify --deep "$APP"
fi

echo "Ad-hoc sign OK: $APP"
codesign -dv "$APP" 2>&1 | grep -E 'Identifier=|CodeDirectory|TeamIdentifier|Format=' || codesign -dv "$APP" 2>&1 | head -8 || true
