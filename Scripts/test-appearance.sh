#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build
xcrun swiftc -swift-version 6 DevKit/App/AppAppearance.swift DevKit/App/GlassPreferences.swift DevKit/App/WorkspaceChrome.swift \
  Scripts/appearance-tests.swift -o build/appearance-regression
build/appearance-regression
