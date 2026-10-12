#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build
swift build > build/menu-core-build.log 2>&1
menu_bin_dir="$(swift build --show-bin-path)"
if [[ -f "$menu_bin_dir/DevKitCore.o" ]]; then
  menu_core_objects=("$menu_bin_dir/DevKitCore.o")
else
  menu_core_objects=("$menu_bin_dir/DevKitCore.build/"*.o)
fi
# A separate test process exercises NSMenu without installing or launching DevKit.
xcrun swiftc -swift-version 6 -warnings-as-errors -parse-as-library \
  -I "$menu_bin_dir" -I "$menu_bin_dir/Modules" \
  DevKit/App/NativeMenuLocalization.swift Scripts/menu-localization-tests.swift \
  "${menu_core_objects[@]}" -o "$menu_bin_dir/menu-localization-regression"
"$menu_bin_dir/menu-localization-regression"
