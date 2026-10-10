#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
configuration="${1:-Release}"
if ! command -v xcodegen >/dev/null; then
  print -u2 'Install XcodeGen first: brew install xcodegen'
  exit 1
fi
python3 Scripts/update-registry.py
xcodegen generate
xcodebuild -project DevKit.xcodeproj -scheme DevKit -configuration "$configuration" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
app_path="build/Build/Products/$configuration/DevKit.app"
codesign --force --sign - "$app_path/Contents/Helpers/DevKitWorker"
codesign --force --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
print "Built: $PWD/$app_path"
