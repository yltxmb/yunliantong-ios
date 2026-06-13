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
  s/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/TUIKitDemo\.entitlements;/CODE_SIGN_ENTITLEMENTS = "";/g;
  s/CODE_SIGN_ENTITLEMENTS = TUIKitDemo\/ci-empty\.entitlements;/CODE_SIGN_ENTITLEMENTS = "";/g;
' "$PBX"

# 真机构建时 pushservice 扩展常因描述文件失败；CI 未签名包先不嵌扩展（主 App 仍可重签安装）
python3 - "$PBX" <<'PY'
from pathlib import Path
import sys

pbx_path = Path(sys.argv[1])
text = pbx_path.read_text(encoding="utf-8")
replacements = [
    "\t\t\t\t48DF2C49253FE1B800BC522F /* PBXTargetDependency */,\n",
    "\t\t\t\t48DF2C4F253FE1B800BC522F /* Embed App Extensions */,\n",
    "\t\t\t\t48DF2C4A253FE1B800BC522F /* pushservice.appex in Embed App Extensions */,\n",
]
for needle in replacements:
    if needle not in text:
        print(f"::warning::CI prep: line not found (may already removed): {needle.strip()}")
    text = text.replace(needle, "")
if "\t\t\t\t48DF2C49253FE1B800BC522F /* PBXTargetDependency */," in text:
    print("::error::CI prep failed: TUIKitDemo still depends on pushservice")
    sys.exit(1)
if "\t\t\t\t48DF2C4F253FE1B800BC522F /* Embed App Extensions */," in text:
    print("::error::CI prep failed: TUIKitDemo still embeds App Extensions")
    sys.exit(1)
pbx_path.write_text(text, encoding="utf-8")
print("Removed pushservice dependency/embed from TUIKitDemo target")
PY

# 注意：不要关 buildImplicitDependencies，否则 CocoaPods 依赖不会参与编译（TUILogin.h / ImSDK_Plus 找不到）

if [ -x "$ROOT/scripts/patch-tuicallkit-swift-xcode16.sh" ]; then
  bash "$ROOT/scripts/patch-tuicallkit-swift-xcode16.sh"
fi

echo "Prepared project for unsigned CI export"
echo "--- TUIKitDemo Release signing (after prep) ---"
awk '/CF01449A216E1A4B00C12E35 \/\* Release \*\//,/^[\t ]*\};$/' "$PBX" \
  | grep -E 'CODE_SIGN|DEVELOPMENT_TEAM|PROVISIONING_PROFILE' || true
