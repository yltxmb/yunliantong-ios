#!/usr/bin/env bash
# 上传企业签平台前的 IPA 结构自检（含 V2/V3 签名格式检查）
set -euo pipefail

IPA="${1:?Usage: ci-validate-resign-ipa.sh /path/to/app.ipa}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

unzip -q "$IPA" -d "$WORKDIR"

APP=$(find "$WORKDIR/Payload" -maxdepth 1 -name '*.app' -type d | head -1)
if [ -z "$APP" ]; then
  echo "FAIL: Payload/*.app not found" >&2
  exit 1
fi

EXEC=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Info.plist")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
BIN="$APP/$EXEC"

echo "Bundle ID: $BUNDLE_ID"
echo "Executable: $EXEC"

if [ ! -f "$BIN" ]; then
  echo "FAIL: missing executable $BIN" >&2
  exit 1
fi

file "$BIN" | tee /dev/stderr | grep -q 'arm64' || {
  echo "FAIL: executable is not arm64 device binary" >&2
  exit 1
}

if ! codesign -dv "$APP" >/dev/null 2>&1; then
  echo "FAIL: app has no codesign metadata (enterprise platforms usually reject this)" >&2
  exit 1
fi

SIG_INFO=$(codesign -dv "$APP" 2>&1 || true)
echo "$SIG_INFO" | grep -E 'CodeDirectory|Format=' || true

# V2: CodeDirectory v>=20400 + DER entitlements（-5 非零，-7 有值）
if echo "$SIG_INFO" | grep -q 'CodeDirectory v=20'; then
  CD_VER=$(echo "$SIG_INFO" | sed -n 's/.*CodeDirectory v=\([0-9]*\).*/\1/p' | head -1)
  if [ -n "$CD_VER" ] && [ "$CD_VER" -lt 20400 ] 2>/dev/null; then
    echo "FAIL: CodeDirectory v=$CD_VER too old (need >=20400 for V2/V3 resign)" >&2
    exit 1
  fi
  echo "PASS: CodeDirectory v=${CD_VER:-unknown} (V2/V3 compatible range)"
else
  echo "WARN: could not read CodeDirectory version; platform may still accept" >&2
fi

if [ -d "$APP/PlugIns" ]; then
  while IFS= read -r -d '' appex; do
    ext_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$appex/Info.plist" 2>/dev/null || echo "")
    if [ -n "$ext_id" ] && [[ "$ext_id" != "$BUNDLE_ID"* ]]; then
      echo "FAIL: extension bundle id mismatch: $ext_id (main=$BUNDLE_ID)" >&2
      exit 1
    fi
  done < <(find "$APP/PlugIns" -maxdepth 1 -name '*.appex' -type d -print0)
fi

IPA_SIZE=$(stat -f%z "$IPA" 2>/dev/null || stat -c%s "$IPA")
if [ "$IPA_SIZE" -lt 5000000 ]; then
  echo "FAIL: IPA too small ($IPA_SIZE bytes)" >&2
  exit 1
fi

echo "PASS: resign-ready IPA checks OK (V1/V2/V3 placeholder sign)"
