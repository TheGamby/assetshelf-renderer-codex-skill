# AssetShelf Renderer Codex Skill

Codex skill for rendering supported 3D models with the macOS
`assetshelf-render` CLI. It supports ordinary PNG previews and contact sheets,
read-only rigid FBX/GLB part inventory, explicitly requested local part
rotations, ordered pose files, and indexed paginated pose contact sheets.

Current renderer release: **1.2 (Build 10)**.

## Safety and intent

The skill never infers a joint, axis, angle, range, sweep, intermediate pose, or
combination. For any requested subobject rotation it first runs `--list-parts`,
uses a canonical selector from the inventory, and renders only the poses the
user explicitly requested. Ambiguous names are reported rather than guessed.

Without `--rotate-part` or `--pose-file`, the renderer follows its unchanged
bind/rest-pose rendering path.

## Requirements

- macOS
- `assetshelf-render` installed at `/usr/local/bin/assetshelf-render`
- Codex with local skill support
- Host Metal/GPU access for actual rendering

The free renderer is distributed separately as a signed and notarized package:

- [AssetShelf Renderer CLI product page](https://thegamby.de/assetshelf-renderer/)
- [Download AssetShelf3DRenderCLI-1.2-10.pkg](https://thegamby.de/assetshelf-renderer/downloads/AssetShelf3DRenderCLI-1.2-10.pkg)

## Install the skill

```sh
git clone https://github.com/TheGamby/assetshelf-renderer-codex-skill.git \
  ~/.codex/skills/assetshelf-render
```

Restart Codex after installing or updating the skill.

## Supported formats

Rendering supports `fbx`, `obj`, `dae`, `scn`, `usd`, `usda`, `usdc`, `usdz`,
`gltf`, `glb`, `stl`, and `ply`. Version-1 logical part rotation is intentionally
limited to hierarchy-preserving rigid FBX and GLB nodes. PNG is the render
output format.

## Basic use

```sh
assetshelf-render --version
# assetshelf-render 1.2 (10)

./scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/render.png" \
  --width 1024 \
  --height 1024 \
  --surface textured \
  --background transparent
```

Actual rendering uses SceneKit/Metal and should run with host GPU access. This
does not require `sudo`. `--list-parts`, `--help` and `--version` do not render.

## Explicit rigid-part pose

Inventory always comes first:

```sh
./scripts/render_model.sh "/path/to/model.fbx" --list-parts > model.parts.json
```

Choose an exact `path:` selector returned by the JSON, then apply only the
requested local angles:

```sh
./scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/turned.png" \
  --rotate-part "path:fbx:70/fbx:73" "y=90"
```

Repeated `--rotate-part` entries form one explicit pose. Local X, then Y, then Z
are applied as deltas from the imported transform around the authored node
origin. Each pose starts from the imported state.

For an explicit ordered pose JSON, use `--pose-file`. There is no range or sweep
syntax. Large jobs can publish a new paginated directory:

```sh
./scripts/render_model.sh \
  "/path/to/model.fbx" \
  --output-directory "/path/to/new-pose-pages" \
  --pose-file "/path/to/poses.json" \
  --layout contact-6 \
  --tile-width 512 \
  --tile-height 512
```

The result contains numbered PNG pages and `contact-sheet.json`, which maps
each explicit pose, view and pixel frame. A pose block is never split across
pages, and the destination must not already exist.

## Rendering notes

- `--show-pivot` marks the imported model wrapper's true origin, not bounds or
  a selected part pivot.
- An optional neighboring `<model>.fbm` directory is not required. If missing,
  it remains silent and is never created.
- Materialless FBXs render with an opaque neutral PBR fallback and may report
  one `fbx.material-fallback` warning. Authored opacity remains intact.
- GLTFKit2 0.5.15 is built from pinned source without KTX2/BasisU, Draco or
  Zstandard codecs.
- Contact sheets remain limited to 16,777,216 pixels and 8192 pixels per page
  dimension; explicit pose plans are additionally limited to 4096 cells and
  256 pages.

See [SKILL.md](SKILL.md) for the operational workflow and
[references/user-guide-summary.md](references/user-guide-summary.md) for the
JSON contracts, selector rules and limits.

## Repository layout

```text
SKILL.md                         Codex skill instructions
agents/openai.yaml               Skill metadata
references/user-guide-summary.md Renderer reference
scripts/render_model.sh          Validating renderer wrapper
```

No renderer binary, installer, model, signing material or generated render is
stored in this repository.
