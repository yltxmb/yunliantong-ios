#!/usr/bin/env bash
# CI 专用：去掉 Release 手动签名，便于打出未签名真机包供第三方企业签平台重签
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBX="$ROOT/TUIKitDemo.xcodeproj/project.pbxproj"
ENT="$ROOT/TUIKitDemo/ci-empty.entitlements"

cp "$PBX" "$PBX.ci.bak"

cat > "$ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict></dict></plist>
EOF

# 清空所有 target 的签名（CI 只编 TUIKitDemo，但 Pods/扩展 target 也可能触发签名检查）
perl -i -pe '
  s/DEVELOPMENT_TEAM = [^;]+;/DEVELOPMENT_TEAM = "";/g;
  s/"DEVELOPMENT_TEAM\[sdk=iphoneos\*\]" = [^;]+;/"DEVELOPMENT_TEAM[sdk=iphoneos*]" = "";/g;
  s/PROVISIONING_PROFILE_SPECIFIER = [^;]+;/PROVISIONING_PROFILE_SPECIFIER = "";/g;
  s/"PROVISIONING_PROFILE_SPECIFIER\[sdk=iphoneos\*\]" = [^;]+;/"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]" = "";/g;
  s/CODE_SIGN_IDENTITY = "[^"]*";/CODE_SIGN_IDENTITY = "";/g;
  s/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/TUIKitDemo\.entitlements;/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/ci-empty.entitlements;/g;
' "$PBX"

echo "Prepared project for unsigned CI export"
echo "--- TUIKitDemo Release signing (after prep) ---"
awk '/CF01449A216E1A4B00C12E35 \/\* Release \*\//,/^[\t ]*\};$/' "$PBX" \
  | grep -E 'CODE_SIGN|DEVELOPMENT_TEAM|PROVISIONING_PROFILE' || true
