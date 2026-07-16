#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  render_model.sh <input-model> <output.png> [assetshelf-render options]
  render_model.sh <input-model> --output-directory <new-directory> [options]
  render_model.sh <input-model> --list-parts

Validating wrapper around assetshelf-render. It supports ordinary PNG renders,
JSON FBX/GLB part inventory, and atomic indexed pose-series directories.

For any requested subobject rotation, run --list-parts first and use a returned
canonical path selector. Never guess an ambiguous name, infer angles, or create
unrequested sweeps.

All renderer options are passed through, including repeatable --rotate-part,
--pose-file, --layout, --contact-arrangement, --tile-width, --tile-height, and
repeatable --asset-dir.

Packed FBX and GLB resources load automatically. A missing optional
<model>.fbm folder is normal, silent, and is not created.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 2
fi

input_model="$1"
operation="$2"
renderer="${ASSETSHELF_RENDER_BIN:-/usr/local/bin/assetshelf-render}"

if [[ ! -x "$renderer" ]]; then
  echo "assetshelf-render not found or not executable: $renderer" >&2
  exit 127
fi

if [[ ! -f "$input_model" ]]; then
  echo "Input model not found: $input_model" >&2
  exit 2
fi

renderer_stderr="$(mktemp "${TMPDIR:-/tmp}/assetshelf-render-stderr.XXXXXX")"
inventory_json=""
cleanup() {
  rm -f "$renderer_stderr"
  if [[ -n "$inventory_json" ]]; then
    rm -f "$inventory_json"
  fi
}
trap cleanup EXIT

report_renderer_failure() {
  local status="$1"
  cat "$renderer_stderr" >&2
  if [[ $status -ne 0 ]] && grep -Eq 'Metal device unavailable|SceneKit offscreen rendering requires GPU access' "$renderer_stderr"; then
    cat >&2 <<'METAL_GUIDANCE'
assetshelf-render wrapper: rendering requires host Metal/GPU access and cannot run in the current sandbox.
Retry this exact command once outside the sandbox with GPU access. For Codex shell tools, request sandbox_permissions: require_escalated.
Do not use sudo; this is a sandbox permission issue, not a model, camera, material, or texture error.
METAL_GUIDANCE
  fi
  return "$status"
}

json_field() {
  local file="$1"
  local field="$2"
  /usr/bin/plutil -extract "$field" raw -o - "$file" 2>/dev/null
}

validate_pngs() {
  local png
  for png in "$@"; do
    if [[ ! -s "$png" ]]; then
      echo "Render output is missing or empty: $png" >&2
      return 1
    fi
    if [[ "$(/usr/bin/xxd -p -l 8 "$png")" != "89504e470d0a1a0a" ]]; then
      echo "Render output is not a PNG: $png" >&2
      return 1
    fi
  done

  if ! /usr/bin/swift -e '
import AppKit
import Darwin
import Foundation

guard CommandLine.arguments.count > 1 else { exit(2) }
for path in CommandLine.arguments.dropFirst() {
    guard let bitmap = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: path))) else {
        exit(2)
    }
    var visible = false
    for y in 0..<bitmap.pixelsHigh {
        for x in 0..<bitmap.pixelsWide where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.01 {
            visible = true
            break
        }
        if visible { break }
    }
    if !visible { exit(1) }
}
' "$@"; then
    echo "One or more render outputs contain no visible pixels." >&2
    return 1
  fi
}

case "$operation" in
  --list-parts)
    shift 2
    inventory_json="$(mktemp "${TMPDIR:-/tmp}/assetshelf-render-parts.XXXXXX.json")"

    set +e
    "$renderer" "$input_model" --list-parts "$@" >"$inventory_json" 2>"$renderer_stderr"
    renderer_status=$?
    set -e

    if ! report_renderer_failure "$renderer_status"; then
      exit "$renderer_status"
    fi
    if [[ "$(json_field "$inventory_json" schema)" != "de.thegamby.assetshelf-render.parts" ]] ||
       [[ "$(json_field "$inventory_json" version)" != "1" ]]; then
      echo "Part inventory has an unexpected schema or version." >&2
      exit 1
    fi
    cat "$inventory_json"
    ;;

  --output-directory)
    if [[ $# -lt 3 ]]; then
      echo "--output-directory requires a destination path." >&2
      exit 2
    fi
    output_directory="$3"
    shift 3

    if [[ -e "$output_directory" ]]; then
      echo "Output directory must not already exist: $output_directory" >&2
      exit 2
    fi

    set +e
    "$renderer" "$input_model" --output-directory "$output_directory" "$@" 2>"$renderer_stderr"
    renderer_status=$?
    set -e

    if ! report_renderer_failure "$renderer_status"; then
      exit "$renderer_status"
    fi
    index_json="$output_directory/contact-sheet.json"
    if [[ ! -f "$index_json" ]] ||
       [[ "$(json_field "$index_json" schema)" != "de.thegamby.assetshelf-render.contact-sheet" ]] ||
       [[ "$(json_field "$index_json" version)" != "1" ]]; then
      echo "Pose-series contact-sheet.json is missing or invalid: $index_json" >&2
      exit 1
    fi
    pages=("$output_directory"/page-*.png)
    if [[ ! -e "${pages[0]}" ]]; then
      echo "Pose-series contains no numbered PNG pages: $output_directory" >&2
      exit 1
    fi
    validate_pngs "${pages[@]}"
    echo "Render OK: $output_directory"
    ;;

  *)
    output_png="$operation"
    shift 2

    case "${output_png##*.}" in
      png|PNG) ;;
      *)
        echo "Output must end in .png: $output_png" >&2
        exit 2
        ;;
    esac

    set +e
    "$renderer" "$input_model" --output "$output_png" "$@" 2>"$renderer_stderr"
    renderer_status=$?
    set -e

    if ! report_renderer_failure "$renderer_status"; then
      exit "$renderer_status"
    fi
    validate_pngs "$output_png"
    echo "Render OK: $output_png"
    ;;
esac
