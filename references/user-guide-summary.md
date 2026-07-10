# assetshelf-render Reference

`assetshelf-render` is installed at `/usr/local/bin/assetshelf-render`.

Actual rendering requires host Metal/GPU access and cannot run in a restricted sandbox. Run render commands outside the sandbox from the first attempt; in Codex shell tools, request `sandbox_permissions: require_escalated`. This is not administrator access and does not require `sudo`. Inspection commands such as `assetshelf-render --help` may run inside the sandbox.

If rendering reports `Metal device unavailable` or `SceneKit offscreen rendering requires GPU access`, repeat the exact command once outside the sandbox. Do not change model, camera, material, texture, or render options for this error. If it remains with host GPU access, report a local Metal/SceneKit availability failure.

Usage:

```sh
assetshelf-render <model> --output <render.png> [options]
```

Supported formats: `FBX, OBJ, DAE, SCN, USD, USDA, USDC, USDZ, glTF, GLB, STL, PLY`.

Output must be PNG. The renderer creates missing output directories automatically.

FBX BaseColor, Normal, Roughness, Metallic, Emission, Opacity, Ambient Occlusion, and Specular textures can be loaded from external files or packed image data. Packed textures do not require a neighboring `.fbm` directory. The fallback also preserves vertex colors, tangents, multiple UV sets, texture UV selection, wrap modes, and UV transforms.

glTF and GLB use GLTFKit2 0.5.15 for core PBR materials, embedded data, external buffers/images, sparse accessors, samplers, alpha modes, double-sided materials, and multiple UV channels. Required Draco and KTX2/BasisU resources are rejected clearly in 1.1.

USD, USDA, and USDC imports preserve relative layer, payload, reference, texture, and material trees. Explicit `--asset-dir` values provide additional resource roots. Symlinks are not followed.

Recoverable issues are written to standard error as `assetshelf-render: warning [CODE]: ...`; successful renders with warnings still exit `0`.

Contact sheets are supported with:

```text
--layout single|contact-4|contact-6
--contact-arrangement grid|strip
```

`contact-4` renders front, back, left, and right views. `contact-6` also includes top and bottom views. The output is still one PNG.

Release package created during AssetShelf 3D 1.1 (6):

```text
/Users/jurgenreichardt-kron/Downloads/AssetShelf3DRenderCLI-1.1-6.pkg
```

User guide PDF:

```text
/Users/jurgenreichardt-kron/Downloads/assetshelf-render-Benutzeranleitung-2026-07-09.pdf
```

The package installs the CLI, GLTFKit2 framework, and third-party notices at:

```text
/usr/local/bin/assetshelf-render
/usr/local/lib/assetshelf-render/GLTFKit2.framework
/usr/local/share/doc/assetshelf-render/THIRD-PARTY-NOTICES.txt
```

Known good packed-PBR FBX test model:

```text
/Users/jurgenreichardt-kron/Downloads/SmokeImagePawn.fbx
```
