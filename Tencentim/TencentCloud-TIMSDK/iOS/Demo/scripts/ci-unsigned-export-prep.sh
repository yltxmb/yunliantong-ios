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

# 仅影响 TUIKitDemo Release 里写死的生产描述文件 / 团队
sed -i '' \
  -e 's/PROVISIONING_PROFILE_SPECIFIER = com.imchat.imchat_Production_SignProvision;/PROVISIONING_PROFILE_SPECIFIER = "";/g' \
  -e 's/DEVELOPMENT_TEAM = FN2V63AD2J;/DEVELOPMENT_TEAM = "";/g' \
  -e 's/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/TUIKitDemo.entitlements;/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/ci-empty.entitlements;/g' \
  "$PBX"

# TUIKitDemo Release 块里的 Distribution 身份（pushservice 等同字符串，CI 只编 TUIKitDemo scheme）
sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Distribution";/CODE_SIGN_IDENTITY = "";/g' "$PBX"

echo "Prepared project for unsigned CI export"
