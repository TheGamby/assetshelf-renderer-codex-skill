---
name: assetshelf-render
description: Render 3D model files to PNG images with the local AssetShelf 3D command-line renderer. Use when Codex needs to call assetshelf-render, create thumbnails/previews, run render smoke tests, validate installed CLI behavior, render FBX/glTF/GLB/USD/OBJ/STL/PLY assets, batch-render model folders, or diagnose assetshelf-render command failures.
---

# assetshelf-render

## Overview

Use the installed `/usr/local/bin/assetshelf-render` CLI to render supported 3D model files to PNG outputs, including single-view renders and contact sheets with multiple model views in one image. FBX PBR images may be external or packed inside the FBX. glTF and GLB use GLTFKit2 for core PBR materials and external or embedded resources. Prefer the bundled wrapper script for repeatable calls because it validates the CLI, input, output extension, and PNG signature.

## Quick Workflow

1. Confirm the CLI exists:

```sh
command -v assetshelf-render
assetshelf-render --help
```

2. Locate a model file if the user did not provide one:

```sh
find /Users/jurgenreichardt-kron/Downloads /Users/jurgenreichardt-kron/Documents -type f \( -iname '*.fbx' -o -iname '*.obj' -o -iname '*.gltf' -o -iname '*.glb' -o -iname '*.usdz' -o -iname '*.usd' -o -iname '*.stl' -o -iname '*.ply' \) -print
```

3. Render via the wrapper:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/render.png" \
  --width 1024 \
  --height 1024 \
  --surface textured \
  --background transparent
```

4. Report the output path and any validation result. If the user asked to inspect the image, use `view_image` on the PNG.

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
--asset-dir <path>           Extra texture/material directory. Repeatable.
--show-pivot                 Render pivot axis overlay.
--show-rigging               Render rigging overlay.
```

Manual `--camera-position` and `--camera-target` are only valid with `--layout single`. `--fov` also applies to contact sheets.

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
mkdir -p "/Users/jurgenreichardt-kron/Downloads/renders"
for file in "/Users/jurgenreichardt-kron/Downloads/GH_V07_MODEL_"*/*.fbx; do
  name="$(basename "${file%.*}")"
  ~/.codex/skills/assetshelf-render/scripts/render_model.sh \
    "$file" \
    "/Users/jurgenreichardt-kron/Downloads/renders/${name}.png" \
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
- If rendering fails with Metal/GPU errors, note that SceneKit offscreen rendering needs local macOS GPU access.
- If contact-sheet views are needed, use `--layout contact-4` for front/back/left/right or `--layout contact-6` to add top/bottom.
- If the user asks for details, read `references/user-guide-summary.md`.

## Repo Context

The source project is typically:

```text
/Users/jurgenreichardt-kron/Documents/FbxViewer
```

The CLI packaging script in that repo is:

```text
scripts/package_render_cli.sh
```
