---
name: assetshelf-render
description: Render supported 3D models to PNG with the local AssetShelf renderer, inspect rigid FBX/GLB part hierarchies, apply only explicitly requested local part rotations, and create indexed paginated pose contact sheets.
---

# assetshelf-render

## Overview

Use the installed `/usr/local/bin/assetshelf-render` CLI to render supported 3D
models to PNG. Release 1.2 (Build 10) adds read-only FBX/GLB part inventory,
explicit local part rotations, ordered pose files, and paginated pose contact
sheets.

The renderer never derives a joint, axis, angle, pose, sweep, or axis
combination. Without `--rotate-part` or `--pose-file`, rendering stays on the
unchanged bind/rest-pose path.

Prefer `scripts/render_model.sh`: it validates the renderer, input and output.

## Non-Negotiable Pose Workflow

When the user requests a subobject rotation:

1. Run `--list-parts` first.
2. Read `rotatable` and `rotation_block_reason` from the inventory.
3. Prefer the returned canonical `path:` selector.
4. Never guess an ambiguous name or substitute a similar-looking node. Ask the
   user which reported path they mean when intent is not unambiguous.
5. Apply only axes and angles the user explicitly requested.
6. Never invent angle ranges, regular sweeps, intermediate poses, or Cartesian
   combinations. A pose file contains only the explicitly requested poses in
   the requested order.

Version 1 part rotation supports hierarchy-preserving rigid FBX and GLB nodes.
It does not control animation, skinning, morphing, deformation, translation,
scale, or world-space rotation.

## Execution Requirements

`--version`, `--help`, and `--list-parts` do not initialize Metal and may run in
a restricted sandbox. Actual rendering uses SceneKit and Metal. Run render
commands outside the sandbox from the first attempt with host GPU access. For
Codex shell tools, request `sandbox_permissions: require_escalated`; do not use
`sudo`.

If a render reports `Metal device unavailable` or
`SceneKit offscreen rendering requires GPU access`, retry the exact command once
outside the sandbox. Do not alter the model or options in response.

## Quick Workflow

Confirm the release:

```sh
command -v assetshelf-render
assetshelf-render --version
assetshelf-render --help
```

Build 10 reports `assetshelf-render 1.2 (10)`.

Render an unchanged model:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/render.png" \
  --width 1024 \
  --height 1024 \
  --surface textured \
  --background transparent
```

Inspect a rigid FBX or GLB hierarchy without rendering:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  --list-parts > "/path/to/model.parts.json"
```

After choosing an exact selector from that JSON, render one explicitly requested
pose:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/turned.png" \
  --rotate-part "path:fbx:70/fbx:73" "y=90"
```

Repeated `--rotate-part` entries form one pose:

```sh
... --rotate-part "path:fbx:70/fbx:73" "x=10,y=90" \
    --rotate-part "path:fbx:70/fbx:81" "z=-15"
```

## Explicit Pose Files

Use a schema-v1 pose file when the user explicitly requests multiple poses:

```json
{
  "schema": "de.thegamby.assetshelf-render.poses",
  "version": 1,
  "model_sha256": "optional exact lowercase SHA-256",
  "poses": [
    {
      "id": "bind",
      "label": "Bind pose",
      "rotations": []
    },
    {
      "id": "turntable-90",
      "label": "Turntable 90 degrees",
      "rotations": [
        {
          "selector": "path:fbx:70/fbx:73",
          "local_degrees": { "y": 90 }
        }
      ]
    }
  ]
}
```

`model_sha256` is optional but, when present, must match exactly. Pose IDs are
unique and array order is render order. An empty rotation list explicitly means
the bind/rest pose. `--pose-file` and `--rotate-part` are mutually exclusive.

For a small result that fits one PNG:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/poses.png" \
  --pose-file "/path/to/poses.json" \
  --layout contact-4 \
  --width 2048 \
  --height 2048
```

For larger explicitly requested jobs, use a destination that does not yet
exist:

```sh
~/.codex/skills/assetshelf-render/scripts/render_model.sh \
  "/path/to/model.fbx" \
  --output-directory "/path/to/new-pose-pages" \
  --pose-file "/path/to/poses.json" \
  --layout contact-6 \
  --contact-arrangement grid \
  --tile-width 512 \
  --tile-height 512
```

The directory contains `page-0001.png`, additional numbered pages as needed,
and `contact-sheet.json`. That index maps each explicit pose and rotation to its
page, view, and pixel frame. A pose block is never split across pages.

## CLI Contract

```sh
assetshelf-render <model> (--output <render.png> | --output-directory <path> | --list-parts) [options]
```

Supported inputs: `fbx`, `obj`, `dae`, `scn`, `usd`, `usda`, `usdc`, `usdz`,
`gltf`, `glb`, `stl`, and `ply`. Part inventory and rotation are limited to
rigid FBX and GLB in schema version 1.

Important options:

```text
--list-parts                 JSON hierarchy inventory on stdout; no rendering.
--rotate-part S A            Explicit selector S and local axis spec A; repeatable.
--pose-file PATH             Ordered explicit pose JSON, schema version 1.
--output PATH                One PNG.
--output-directory PATH      New atomic paginated output directory.
--tile-width PIXELS          Pose-series tile width. Default: 512.
--tile-height PIXELS         Pose-series tile height. Default: 512.
--width PIXELS               Single-PNG width. Default: 1024.
--height PIXELS              Single-PNG height. Default: 1024.
--layout MODE                single, contact-4, or contact-6.
--contact-arrangement MODE   grid or strip.
--surface MODE               textured, untextured, transparent, or mesh.
--background VALUE           transparent or #RRGGBB.
--camera auto                Automatic framing.
--camera-position x,y,z      Manual camera position.
--camera-target x,y,z        Manual camera target.
--fov DEGREES                Finite field of view greater than 0 and less than 180.
--camera-preset PATH         AssetShelf camera-preset JSON, schema version 1.
--asset-dir PATH             Additional texture/material root; repeatable.
--show-pivot                 Show the model wrapper origin, not a part pivot.
--show-rigging               Render the rigging overlay.
```

### Selectors and local rotations

- Prefer `path:fbx:70/fbx:73` or `path:gltf:0/gltf:4` from `--list-parts`.
- `id:fbx:73`, `id:gltf:4`, `name:OriginalName`, and a bare original name are
  accepted only when they resolve uniquely.
- Ambiguous names fail and report candidate canonical paths. Do not choose one
  automatically.
- Axis specs contain finite `x=`, `y=`, and/or `z=` degrees, for example
  `x=10,y=90`. Omitted axes are zero.
- Deltas are applied in local X, then Y, then Z order around the authored node
  origin and relative to its imported transform.
- Every pose starts from the imported transform; poses never accumulate.
- Angles normalize modulo 360. Full turns preserve the authored matrix.
- The same resolved node may occur only once per pose. Explicit parent and child
  rotations may coexist.
- A non-finite, non-affine, sheared, degenerate, animated, deformed, or otherwise
  unsafe hierarchy blocks the complete pose request before output.

### Limits

- Pose JSON: 16 MiB maximum.
- 4,096 explicit poses maximum.
- 256 explicit node rotations per pose.
- 4,096 total pose/view cells and 256 pages maximum.
- 8,192 pixels per page dimension and 16,777,216 pixels per page.
- With `--output`, every cell must be at least 128×128 and all cells must fit the
  one PNG. Use `--output-directory` otherwise.
- All poses share union bounds for automatic framing. Manual or preset cameras
  stay exact.

## Rendering Notes

- `contact-4` renders front, back, left, right; `contact-6` adds top and bottom.
- `--show-pivot` always marks only the imported model wrapper origin.
- FBX images may be external or packed. A missing optional `<model>.fbm` folder
  is normal, is not created, and stays silent.
- Materialless FBXs receive an opaque neutral PBR fallback (or opaque white for
  vertex colors) and may emit one `fbx.material-fallback` warning. Genuine
  material opacity is preserved.
- glTF/GLB use source-built GLTFKit2 0.5.15. KTX2/BasisU, Draco and Zstandard
  codecs are not bundled.
- Recoverable loader notices use
  `assetshelf-render: warning [CODE]: ...` on standard error and may still exit
  with status 0.
- The renderer never modifies the input model, sidecars, or resource tree.

See `references/user-guide-summary.md` for JSON field details and examples.
