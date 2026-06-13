#!/usr/bin/env bash
# 官方 TIMSDK Demo：仅去掉签名/扩展嵌套，不改 Bundle ID（用于对照排查）
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
pbx_path.write_text(text, encoding="utf-8")
print("Removed pushservice dependency/embed from TUIKitDemo target (official baseline)")
PY

echo "Prepared official TIMSDK Demo for unsigned CI export"
