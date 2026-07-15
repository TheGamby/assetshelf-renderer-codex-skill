# assetshelf-render Reference

`assetshelf-render` is installed at `/usr/local/bin/assetshelf-render`.

Actual rendering requires host Metal/GPU access and cannot run in a restricted sandbox. Run render commands outside the sandbox from the first attempt; in Codex shell tools, request `sandbox_permissions: require_escalated`. This is not administrator access and does not require `sudo`. Inspection commands such as `assetshelf-render --help` may run inside the sandbox.

If rendering reports `Metal device unavailable` or `SceneKit offscreen rendering requires GPU access`, repeat the exact command once outside the sandbox. Do not change model, camera, material, texture, or render options for this error. If it remains with host GPU access, report a local Metal/SceneKit availability failure.

Usage:

```sh
assetshelf-render <model> --output <render.png> [options]
assetshelf-render --version
```

Release 1.1 (Build 7) reports `assetshelf-render 1.1 (7)` for `--version`.

Supported formats: `FBX, OBJ, DAE, SCN, USD, USDA, USDC, USDZ, glTF, GLB, STL, PLY`.

Output must be PNG. The renderer creates missing output directories automatically.

FBX BaseColor, Normal, Roughness, Metallic, Emission, Opacity, Ambient Occlusion, and Specular textures can be loaded from external files or packed image data. Packed textures do not require a neighboring `.fbm` directory. The fallback also preserves vertex colors, tangents, multiple UV sets, texture UV selection, wrap modes, and UV transforms.

glTF and GLB use GLTFKit2 0.5.15 for core PBR materials, embedded data, external buffers/images, sparse accessors, samplers, alpha modes, double-sided materials, and multiple UV channels. Required Draco and KTX2/BasisU resources are rejected clearly in 1.1.

USD, USDA, and USDC imports preserve relative layer, payload, reference, texture, and material trees. Explicit `--asset-dir` values provide additional resource roots. Symlinks are not followed.

Recoverable issues are written to standard error as `assetshelf-render: warning [CODE]: ...`; successful renders with warnings still exit `0`.

Single-view renders can reproduce a camera exported from AssetShelf 3D:

```sh
assetshelf-render model.fbx --output render.png --camera-preset Product-Hero.camera.json
```

Camera presets use the `assetshelf-camera-preset` schema version 1. They cannot be combined with `--camera`, `--camera-position`, `--camera-target`, `--fov`, or a contact-sheet layout. Numeric camera vectors and field-of-view values must be finite; field of view must be greater than 0 and less than 180 degrees.

`--show-pivot` renders the axis overlay at the imported model wrapper's actual transform origin. This is intentionally distinct from the center of the geometry bounds when a model's geometry is offset from its origin.

Contact sheets are supported with:

```text
--layout single|contact-4|contact-6
--contact-arrangement grid|strip
```

`contact-4` renders front, back, left, and right views. `contact-6` also includes top and bottom views. The output is still one PNG.

Contact-sheet output is limited to 16,777,216 pixels total and 8192 pixels per dimension. Invalid, non-finite, overflowing, or out-of-range numeric values fail before rendering.

Release package for AssetShelf Renderer CLI 1.1 (Build 7):

```text
AssetShelf3DRenderCLI-1.1-7.pkg
```

Download the current signed and notarized installer from `https://thegamby.de/assetshelf-renderer/`.

The package installs the CLI, GLTFKit2 framework, and third-party notices at:

```text
/usr/local/bin/assetshelf-render
/usr/local/lib/assetshelf-render/GLTFKit2.framework
/usr/local/share/doc/assetshelf-render/THIRD-PARTY-NOTICES.txt
```

For a smoke test, use an owned local FBX or GLB fixture and write output to a temporary or project-specific path. Do not assume machine-specific model locations.
