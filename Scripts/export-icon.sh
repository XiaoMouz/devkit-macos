#!/bin/bash
set -euo pipefail

# Export previews from the same editable source that Xcode builds into the app.
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="${1:-$project_dir/build/icon-previews}"
developer_dir="$(xcode-select -p)"
renderer="${developer_dir%/Developer}/Applications/Icon Composer.app/Contents/Executables/ictool"
icon_path="$project_dir/DevKit/Resources/AppIcon.icon"

if [[ ! -x "$renderer" ]]; then
  echo "Icon Composer was not found in the selected Xcode installation." >&2
  exit 1
fi

mkdir -p "$output_dir"

render() {
  local output="$1" rendition="$2" size="$3"
  shift 3
  "$renderer" "$icon_path" --export-image \
    --output-file "$output_dir/$output.png" --platform macOS \
    --rendition "$rendition" --width "$size" --height "$size" --scale 1 "$@"
}

render default Default 1024
render dark Dark 1024
render mono TintedLight 1024 --tint-strength 0
render preview Default 512
render size-32 Default 32
render size-64 Default 64
render macOS26 Default 1024 --design-generation 26
echo "Exported icon previews: $output_dir"
