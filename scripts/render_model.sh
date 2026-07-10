#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: render_model.sh <input-model> <output.png> [assetshelf-render options]

Wrapper around /usr/local/bin/assetshelf-render that validates the input path,
PNG output path, CLI availability, and generated PNG signature.

All assetshelf-render options are passed through, including:
  --layout single|contact-4|contact-6
  --contact-arrangement grid|strip
  --asset-dir PATH (repeatable)

Packed FBX and GLB resources are loaded automatically. Use --asset-dir for
additional external glTF, USD, texture, or material resource roots.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 2
fi

input_model="$1"
output_png="$2"
shift 2

renderer="${ASSETSHELF_RENDER_BIN:-/usr/local/bin/assetshelf-render}"

if [[ ! -x "$renderer" ]]; then
  echo "assetshelf-render not found or not executable: $renderer" >&2
  exit 127
fi

if [[ ! -f "$input_model" ]]; then
  echo "Input model not found: $input_model" >&2
  exit 2
fi

case "${output_png##*.}" in
  png|PNG) ;;
  *)
    echo "Output must end in .png: $output_png" >&2
    exit 2
    ;;
esac

renderer_stderr="$(mktemp "${TMPDIR:-/tmp}/assetshelf-render-stderr.XXXXXX")"
cleanup() {
  rm -f "$renderer_stderr"
}
trap cleanup EXIT

set +e
"$renderer" "$input_model" --output "$output_png" "$@" 2>"$renderer_stderr"
renderer_status=$?
set -e

cat "$renderer_stderr" >&2

if [[ $renderer_status -ne 0 ]]; then
  if grep -Eq 'Metal device unavailable|SceneKit offscreen rendering requires GPU access' "$renderer_stderr"; then
    cat >&2 <<'METAL_GUIDANCE'
assetshelf-render wrapper: rendering requires host Metal/GPU access and cannot run in the current sandbox.
Retry this exact command once outside the sandbox with GPU access. For Codex shell tools, request sandbox_permissions: require_escalated.
Do not use sudo; this is a sandbox permission issue, not a model, camera, material, or texture error.
METAL_GUIDANCE
  fi
  exit "$renderer_status"
fi

if [[ ! -s "$output_png" ]]; then
  echo "Render output is missing or empty: $output_png" >&2
  exit 1
fi

signature="$(/usr/bin/xxd -p -l 8 "$output_png")"
if [[ "$signature" != "89504e470d0a1a0a" ]]; then
  echo "Render output is not a PNG: $output_png" >&2
  exit 1
fi

if ! /usr/bin/swift -e '
import AppKit
import Darwin
import Foundation

guard CommandLine.arguments.count == 2,
      let bitmap = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))) else {
    exit(2)
}
for y in 0..<bitmap.pixelsHigh {
    for x in 0..<bitmap.pixelsWide where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.01 {
        exit(0)
    }
}
exit(1)
' "$output_png"; then
  echo "Render output contains no visible pixels: $output_png" >&2
  exit 1
fi

echo "Render OK: $output_png"
