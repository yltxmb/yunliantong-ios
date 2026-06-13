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

# 清空所有 target 的签名
perl -i -pe '
  s/DEVELOPMENT_TEAM = [^;]+;/DEVELOPMENT_TEAM = "";/g;
  s/"DEVELOPMENT_TEAM\[sdk=iphoneos\*\]" = [^;]+;/"DEVELOPMENT_TEAM[sdk=iphoneos*]" = "";/g;
  s/PROVISIONING_PROFILE_SPECIFIER = [^;]+;/PROVISIONING_PROFILE_SPECIFIER = "";/g;
  s/"PROVISIONING_PROFILE_SPECIFIER\[sdk=iphoneos\*\]" = [^;]+;/"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]" = "";/g;
  s/PROVISIONING_PROFILE = [^;]+;/PROVISIONING_PROFILE = "";/g;
  s/CODE_SIGN_IDENTITY = "[^"]*";/CODE_SIGN_IDENTITY = "";/g;
  s/CODE_SIGN_STYLE = Manual;/CODE_SIGN_STYLE = Automatic;/g;
  s/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/TUIKitDemo\.entitlements;/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/ci-empty.entitlements;/g;
' "$PBX"

# 真机构建时 pushservice 扩展常因描述文件失败；CI 未签名包先不嵌扩展（主 App 仍可重签安装）
# 注意：perl -pe 按行处理，不能用 \n 跨行匹配；用 sed 删整行
sed -i '' \
  '/48DF2C49253FE1B800BC522F \/\* PBXTargetDependency \*\//d' \
  '/48DF2C4F253FE1B800BC522F \/\* Embed App Extensions \*\//d' \
  '/48DF2C4A253FE1B800BC522F \/\* pushservice\.appex in Embed App Extensions \*\//d' \
  "$PBX"

if grep -Fq '48DF2C49253FE1B800BC522F /* PBXTargetDependency */' "$PBX"; then
  echo "::error::CI prep failed: pushservice dependency still present in project.pbxproj"
  exit 1
fi
if grep -Fq '48DF2C4F253FE1B800BC522F /* Embed App Extensions */' "$PBX"; then
  echo "::error::CI prep failed: Embed App Extensions phase still linked to TUIKitDemo"
  exit 1
fi

echo "Prepared project for unsigned CI export"
echo "--- TUIKitDemo Release signing (after prep) ---"
awk '/CF01449A216E1A4B00C12E35 \/\* Release \*\//,/^[\t ]*\};$/' "$PBX" \
  | grep -E 'CODE_SIGN|DEVELOPMENT_TEAM|PROVISIONING_PROFILE' || true
