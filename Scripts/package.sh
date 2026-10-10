#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
Scripts/build.sh Release
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent build/Build/Products/Release/DevKit.app dist/DevKit-0.1.0-macos.zip
print "Local ad-hoc build: $PWD/dist/DevKit-0.1.0-macos.zip"
print 'Public distribution still requires your Developer ID signing and notarization.'
