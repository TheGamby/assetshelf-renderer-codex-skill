# assetshelf-render Reference

Release 1.2 (Build 10) reports:

```text
assetshelf-render 1.2 (10)
```

The signed installer is `AssetShelf3DRenderCLI-1.2-10.pkg`. It installs the
renderer at `/usr/local/bin/assetshelf-render`.

## Commands and outputs

```sh
assetshelf-render <model> --output <render.png> [options]
assetshelf-render <model> --output-directory <new-directory> [options]
assetshelf-render <model> --list-parts
assetshelf-render --version
```

Supported render inputs are FBX, OBJ, DAE, SCN, USD, USDA, USDC, USDZ, glTF,
GLB, STL and PLY. Version-1 logical-node inventory and rotation require a
hierarchy-preserving rigid FBX or GLB.

Actual rendering needs SceneKit/Metal host GPU access. `--list-parts`, `--help`
and `--version` do not render. Do not use `sudo` to solve a GPU sandbox error.

## Part inventory must come first

Before any subobject rotation, run:

```sh
assetshelf-render model.fbx --list-parts > model.parts.json
```

This writes one JSON document to stdout with schema
`de.thegamby.assetshelf-render.parts`, version 1. Diagnostics remain on stderr.
Top-level fields are:

- `model_sha256`: exact SHA-256 of the model file;
- `format`: `fbx` or `glb`;
- `parts`: flat logical-node inventory.

Each part includes:

- `original_name`;
- `source_id`, such as `fbx:73` or `gltf:4`;
- preferred canonical `selector`, such as `path:fbx:70/fbx:73`;
- optional canonical `parent`;
- `has_geometry` and `has_children`;
- `local_transform` with a column-major 4×4 matrix and, when safe,
  translation, quaternion rotation and signed scale;
- `rotatable` and, when false, `rotation_block_reason`.

The authoritative matrix is serialized by columns. If it contains non-finite
values, `column_major_matrix` is `null`; the renderer never invents zeros or an
identity transform. Safe TRS convenience fields are omitted for unsafe
transforms.

Rigid-pose validation is all-or-nothing. Defined block reasons are:

```text
model-has-animation-or-deformation
authored-hierarchy-unavailable:<canonical-path>
unsafe-local-transform:<canonical-path>
```

Synthetic render primitives, cameras and lights are not selectable parts.

## Selectors

Use the exact canonical `path:` selector returned by inventory for automation:

```text
path:fbx:70/fbx:73
path:gltf:0/gltf:4
```

The renderer also accepts `id:fbx:73`, `id:gltf:4`, `name:OriginalName`, or a
bare original name when it resolves globally and uniquely. An ambiguous name or
ID fails and reports candidate canonical paths. A caller must not guess among
them.

## One explicit command-line pose

```sh
assetshelf-render model.fbx \
  --output turned.png \
  --rotate-part "path:fbx:70/fbx:73" "y=90"
```

Repeat `--rotate-part` to rotate more than one explicitly named node in that
same pose:

```sh
--rotate-part "path:fbx:70/fbx:73" "x=10,y=90" \
--rotate-part "path:fbx:70/fbx:81" "z=-15"
```

Local axis values must be finite. Missing axes are zero. The delta is applied
in local X, then Y, then Z order around the authored node origin and relative to
the imported transform. Angles normalize modulo 360; exact full turns preserve
the authored matrix. Every pose begins at the imported state and never
accumulates from a previous pose.

The same resolved node may occur only once in a pose. A parent and child may
both be present when both were explicitly requested. `--rotate-part` and
`--pose-file` cannot be combined.

## Ordered explicit pose input

Schema version 1:

```json
{
  "schema": "de.thegamby.assetshelf-render.poses",
  "version": 1,
  "model_sha256": "optional lowercase 64-character SHA-256",
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

- `model_sha256` is optional; when present it must match exactly.
- `poses` is required, non-empty and rendered in array order.
- Pose IDs are non-blank and globally unique. Labels are optional.
- An empty rotations array explicitly requests the bind/rest pose.
- Each `local_degrees` object contains one or more of finite `x`, `y`, `z`.

There is no range or sweep syntax. The renderer never derives intermediate
angles, axes, joints, combinations, or poses. Render only entries explicitly
requested by the user or upstream automation project.

## Single PNG and paginated series

`--layout single` produces one view per pose. `contact-4` produces front, back,
left and right. `contact-6` adds top and bottom. Only listed poses are rendered.

Small plans may be written to one PNG:

```sh
assetshelf-render model.fbx \
  --output poses.png \
  --pose-file poses.json \
  --layout contact-4 \
  --width 2048 \
  --height 2048
```

Every cell must be at least 128×128 pixels and the complete plan must fit one
image. For larger plans, the output directory must not already exist:

```sh
assetshelf-render model.fbx \
  --output-directory pose-pages \
  --pose-file poses.json \
  --layout contact-6 \
  --contact-arrangement grid \
  --tile-width 512 \
  --tile-height 512
```

The renderer stages the complete directory and publishes it atomically. It
contains `page-0001.png`, subsequent numbered pages, and `contact-sheet.json`.
No partial directory is published on failure.

The index uses schema `de.thegamby.assetshelf-render.contact-sheet`, version 1.
It records the model filename and SHA-256, layout, arrangement, tile size, an
ordered top-level pose table, and numbered pages with cells. Each cell contains
`pose_index`, `pose_id`, `view_index`, `view`, and an integer pixel `frame`.
Resolved rotations are stored once in the pose table with canonical selectors,
requested degrees, and normalized degrees. A pose block is never split across
pages.

## Limits

- Pose file: 16 MiB maximum.
- 4,096 explicit poses maximum.
- 256 node rotations per pose.
- 4,096 total pose/view cells.
- 256 output pages.
- 8,192 pixels maximum per page dimension.
- 16,777,216 pixels maximum per page.
- Default pose-series tile: 512×512.

All poses use shared union bounds for stable automatic framing. A manual camera
or schema-v1 camera preset remains fixed instead.

## Existing rendering options

```text
--width <pixels>
--height <pixels>
--layout single|contact-4|contact-6
--contact-arrangement grid|strip
--surface textured|untextured|transparent|mesh
--background transparent|#RRGGBB
--camera auto
--camera-position x,y,z
--camera-target x,y,z
--fov <degrees>
--camera-preset <schema-v1 JSON>
--asset-dir <path>                 repeatable
--show-pivot
--show-rigging
```

`--show-pivot` marks the imported model wrapper transform origin, not the center
of its bounds and not a selected part pivot.

## Materials and resources

- FBX supports packed or external BaseColor, Normal, Roughness, Metallic,
  Emission, Opacity, Ambient Occlusion and Specular inputs plus vertex colors,
  tangents, UV sets, wrapping and UV transforms.
- A missing optional neighboring `<model>.fbm` directory is completely silent,
  is not created and is not required. Missing resources that are actually
  referenced may produce a warning.
- A materialless FBX receives an opaque neutral PBR fallback; an FBX with vertex
  colors receives opaque white so the colors remain visible. One
  `fbx.material-fallback` warning may be emitted. Authored opacity is preserved.
- glTF/GLB use pinned source-built GLTFKit2 0.5.15. KTX2/BasisU, Draco and
  Zstandard codecs are excluded.
- USD resource trees and repeated `--asset-dir` roots remain supported. Symlinks
  are not followed.
- Input models, sidecars and resources are never modified.

Recoverable diagnostics use
`assetshelf-render: warning [CODE]: ...` on stderr while a valid render may
still exit 0.

## Package contents

```text
/usr/local/bin/assetshelf-render
/usr/local/lib/assetshelf-render/GLTFKit2.framework
/usr/local/share/doc/assetshelf-render/THIRD-PARTY-NOTICES.txt
/usr/local/share/doc/assetshelf-render/THIRD-PARTY-SBOM.spdx.json
```

Download the current signed and notarized installer from
<https://thegamby.de/assetshelf-renderer/>.
