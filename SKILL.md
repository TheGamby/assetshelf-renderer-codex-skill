---
name: assetshelf-render
description: Render 3D model files to PNG images with the local AssetShelf 3D command-line renderer. Use when Codex needs to call assetshelf-render, create thumbnails/previews, run render smoke tests, validate installed CLI behavior, render FBX/glTF/GLB/USD/OBJ/STL/PLY assets, batch-render model folders, or diagnose assetshelf-render command failures.
---

# assetshelf-render

## Overview

Use the installed `/usr/local/bin/assetshelf-render` CLI to render supported 3D model files to PNG outputs, including single-view renders and contact sheets with multiple model views in one image. FBX PBR images may be external or packed inside the FBX. glTF and GLB use GLTFKit2 for core PBR materials and external or embedded resources. Prefer the bundled wrapper script for repeatable calls because it validates the CLI, input, output extension, and PNG signature.

## Execution Requirements

Actual rendering uses SceneKit and Metal and cannot run in a restricted sandbox without host GPU access. Run render commands outside the sandbox from the first attempt. When using Codex shell tools, request `sandbox_permissions: require_escalated` with a concise Metal/GPU justification. This permission is not administrator access: do not use `sudo`.

Commands that only inspect the CLI, such as `assetshelf-render --help`, may run inside the sandbox. If a render reports `Metal device unavailable` or `SceneKit offscreen rendering requires GPU access`, retry the exact command once outside the sandbox. Do not change the model, textures, camera, or render options in response to this error. If the same error remains with host GPU access, report it as a local Metal/SceneKit availability failure.

## Quick Workflow

1. Confirm the CLI exists:

```sh
command -v assetshelf-render
assetshelf-render --version
assetshelf-render --help
```

2. Locate a model file if the user did not provide one:

```sh
find "${HOME}/Downloads" "${HOME}/Documents" -type f \( -iname '*.fbx' -o -iname '*.obj' -o -iname '*.gltf' -o -iname '*.glb' -o -iname '*.usdz' -o -iname '*.usd' -o -iname '*.stl' -o -iname '*.ply' \) -print
```

3. Request execution outside the sandbox with host Metal/GPU access. Do not use `sudo`.

4. Render via the wrapper:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/render.png" \
  --width 1024 \
  --height 1024 \
  --surface textured \
  --background transparent
```

5. Report the output path and any validation result. If the user asked to inspect the image, use `view_image` on the PNG.

## CLI Contract

Syntax:

```sh
assetshelf-render <model> --output <render.png> [options]
```

Supported input extensions:

```text
fbx, obj, dae, scn, usd, usda, usdc, usdz, gltf, glb, stl, ply
```

Output must be `.png`.

Common options:

```text
--version                    Print the renderer version and exit.
--width <pixels>             Positive integer. Default: 1024.
--height <pixels>            Positive integer. Default: 1024.
--layout <mode>              single, contact-4, or contact-6. Default: single.
--contact-arrangement <mode> grid or strip. Default: grid.
--surface <mode>             textured, untextured, transparent, or mesh.
--background <value>         transparent or #RRGGBB.
--camera auto                Automatic framing.
--camera-position x,y,z      Manual camera position.
--camera-target x,y,z        Manual camera target.
--fov <degrees>              Field of view, > 0 and < 180.
--camera-preset <path>       AssetShelf camera-preset JSON, schema v1.
--asset-dir <path>           Extra texture/material directory. Repeatable.
--show-pivot                 Render axes at the actual model transform origin.
--show-rigging               Render rigging overlay.
```

Manual `--camera-position`, `--camera-target`, and `--camera-preset` are only valid with `--layout single`. A camera preset cannot be combined with `--camera`, manual camera values, or `--fov`; `--fov` by itself also applies to contact sheets. Camera vectors and field-of-view values must be finite. Contact sheets are limited to 16,777,216 output pixels and 8192 pixels per dimension.

`--show-pivot` marks the imported model wrapper's transform origin. It does not substitute the center of the model's geometry bounds.

## Good Defaults

For general previews:

```sh
--width 1024 --height 1024 --surface textured --background transparent
```

For quick smoke tests:

```sh
--width 512 --height 512 --surface textured --background transparent
```

For QA/geometry checks:

```sh
--surface mesh --show-pivot
```

For product-like screenshots:

```sh
--width 1600 --height 1200 --background "#FFFFFF"
```

For a four-view contact sheet:

```sh
--layout contact-4 --contact-arrangement grid --width 1600 --height 1200
```

For a six-view strip:

```sh
--layout contact-6 --contact-arrangement strip --width 2200 --height 500
```

## Batch Rendering

For folders of FBX files, generate stable output names and quote every path:

```sh
mkdir -p "${HOME}/Downloads/renders"
for file in "${HOME}/Downloads/models/"*.fbx; do
  name="$(basename "${file%.*}")"
  ~/.codex/skills/assetshelf-render/scripts/render_model.sh \
    "$file" \
    "${HOME}/Downloads/renders/${name}.png" \
    --width 1024 \
    --height 1024 \
    --background transparent
done
```

## Troubleshooting

- If `assetshelf-render` is missing, tell the user the CLI package needs to be installed. Expected path: `/usr/local/bin/assetshelf-render`.
- If the output is not PNG, change the output path to end in `.png`.
- If the model path has spaces, quote it.
- If textures are missing, add one or more `--asset-dir` paths for texture/material folders.
- Packed FBX textures do not require `--asset-dir` or an external `.fbm` folder. A warning on standard error identifies referenced textures that could not be resolved or decoded.
- FBX supports BaseColor, Normal, Roughness, Metallic, Emission, Opacity, Ambient Occlusion, and Specular maps plus UV selection, wrapping, UV transforms, tangents, and vertex colors.
- `.gltf` resolves relative BIN and image URIs. Add repeated `--asset-dir` roots when resources are outside the model directory. Remote, absolute, and escaping resource paths are rejected.
- Required Draco or KTX2/BasisU glTF content fails clearly because those codecs are not bundled in 1.1.
- USD, USDA, and USDC imports preserve relative layers, payloads, references, materials, and textures. Symlinks are skipped and reported.
- Recoverable loader notices are written as `assetshelf-render: warning [CODE]: ...` on standard error while the render exits `0`.
- If rendering reports `Metal device unavailable` or `SceneKit offscreen rendering requires GPU access`, retry the exact command once outside the sandbox with host GPU access. For Codex shell tools, request `sandbox_permissions: require_escalated`.
- Do not use `sudo` for Metal access and do not diagnose this sandbox error as a broken model, camera, material, or texture. If the same error remains outside the sandbox, report a local Metal/SceneKit availability failure.
- If contact-sheet views are needed, use `--layout contact-4` for front/back/left/right or `--layout contact-6` to add top/bottom.
- Keep contact-sheet output at or below 16,777,216 pixels total and 8192 pixels on either dimension.
- If an automated render needs to match an app camera exactly, export a schema-v1 camera preset and pass it with `--camera-preset` on a single-view render.
- If the user asks for details, read `references/user-guide-summary.md`.
