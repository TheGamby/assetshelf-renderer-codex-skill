# AssetShelf Renderer Codex Skill

Codex skill for rendering 3D model files to PNG images with the macOS
`assetshelf-render` command-line tool.

The skill provides repeatable commands for single-view renders, four- and
six-view contact sheets, transparent backgrounds, custom camera settings, and
additional texture or material directories.

## Requirements

- macOS
- The AssetShelf 3D renderer installed at `/usr/local/bin/assetshelf-render`
- Codex with local skill support
- Host Metal/GPU access for actual rendering

The renderer is distributed separately from this repository as a signed and
notarized installer package.

## Renderer CLI and Download

The skill and the AssetShelf Renderer CLI are maintained as one public toolset.
The product page always provides the current signed and notarized macOS
installer, feature overview, and rendered examples:

- [AssetShelf Renderer CLI product page](https://thegamby.de/assetshelf-renderer/)
- [Download the current macOS installer](https://thegamby.de/assetshelf-renderer/downloads/AssetShelf3DRenderCLI-1.1-8.pkg)

Current renderer release: **1.1 (Build 8)**.

SceneKit rendering cannot run in a restricted sandbox without GPU access. Run
actual render commands outside the sandbox from the first attempt. In Codex,
request `sandbox_permissions: require_escalated` for the render command. This
does not require administrator access or `sudo`. Commands such as
`assetshelf-render --help` may still run inside the sandbox.

## Installation

Clone the repository into the Codex skills directory:

```sh
git clone https://github.com/TheGamby/assetshelf-renderer-codex-skill.git \
  ~/.codex/skills/assetshelf-render
```

Restart Codex after installing or updating the skill.

## Supported Formats

`fbx`, `obj`, `dae`, `scn`, `usd`, `usda`, `usdc`, `usdz`, `gltf`, `glb`,
`stl`, and `ply`.

PNG is the supported output format.

## Usage

Confirm the installed release:

```sh
assetshelf-render --version
# assetshelf-render 1.1 (8)
```

Ask Codex to render a supported model, or run the included wrapper directly:

```sh
./scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/render.png" \
  --width 1024 \
  --height 1024 \
  --surface textured \
  --background transparent
```

If the renderer reports `Metal device unavailable`, repeat the exact command
once outside the sandbox. Do not change the model, camera, materials, textures,
or render options for this error. If it remains outside the sandbox, the host's
Metal/SceneKit environment is unavailable.

Create a four-view contact sheet:

```sh
./scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/contact-sheet.png" \
  --layout contact-4 \
  --contact-arrangement grid \
  --width 1600 \
  --height 1200
```

Contact sheets are limited to 16,777,216 output pixels and 8192 pixels per dimension. Camera vectors and field-of-view values must be finite.

Apply an AssetShelf camera preset to a single-view render:

```sh
./scripts/render_model.sh \
  "/path/to/model.fbx" \
  "/path/to/render.png" \
  --camera-preset "/path/to/Product-Hero.camera.json"
```

Use `--show-pivot` to draw axes at the imported model wrapper's actual transform origin. The renderer intentionally does not replace that origin with the center of the model's geometry bounds.

An optional neighboring `<model>.fbm` folder is not required. If it is absent,
Build 8 stays completely silent; warnings are reserved for genuine problems
with resources that the model actually references.

See [SKILL.md](SKILL.md) for the complete workflow and CLI contract. Additional
usage notes are available in
[references/user-guide-summary.md](references/user-guide-summary.md).

## Repository Layout

```text
SKILL.md                         Codex skill instructions
agents/openai.yaml               Skill metadata
references/user-guide-summary.md Renderer reference
scripts/render_model.sh          Validating render wrapper
```
