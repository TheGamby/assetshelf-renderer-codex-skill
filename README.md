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

The renderer is distributed separately from this repository as a signed and
notarized installer package.

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
