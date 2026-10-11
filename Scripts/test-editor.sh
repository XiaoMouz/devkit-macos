#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build
swift build > build/editor-core-build.log 2>&1
editor_bin_dir="$(swift build --show-bin-path)"
# Compile the actual editor in the same file context, so the regression can
# exercise private AppKit types without exposing them in the production API.
cat DevKit/Shared/CodeEditor.swift Scripts/editor-tests.swift > build/editor-regression.swift
if [[ -f "$editor_bin_dir/DevKitCore.o" ]]; then
  editor_core_objects=("$editor_bin_dir/DevKitCore.o")
else
  editor_core_objects=("$editor_bin_dir/DevKitCore.build/"*.o)
fi
xcrun swiftc -swift-version 6 -parse-as-library \
  -I "$editor_bin_dir" -I "$editor_bin_dir/Modules" \
  build/editor-regression.swift DevKit/Shared/WorkspaceStyle.swift DevKit/Shared/WorkspaceBridge.swift \
  DevKit/Shared/Clipboard.swift \
  "${editor_core_objects[@]}" -o "$editor_bin_dir/editor-regression"
# The executable stays next to SwiftPM's resource bundle. The hidden host window
# and unique pasteboard keep the user's app session and clipboard untouched.
"$editor_bin_dir/editor-regression"
