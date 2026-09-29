# Web pack size audit — 2026-09-28

`docs/index.pck` is now **70,333,528 bytes:70.33MB /67.08MiB**, below both
decimal100MB and binary100MiB limits. Previously it was226,603,352 bytes
(226.60MB /216.11MiB). The reduction is156,269,824 bytes, approximately69.0%.
The later Cave Boss sprite revision adds one live atlas (about0.38MB packed) to
the initial67.52MB optimized build.

## What made the old pack large

The Web preset exported every project resource, including development images and
superseded asset versions. Its795 entries contained:

| Payload category | Decimal MB |
|---|---:|
| Imported images |225.390|
| Imported audio |0.352|
| Scripts, scenes and other resources |0.780|

By original source folder, design references and review screenshots accounted for
113.181MB; assets accounted for111.483MB. Images were the cause, not audio.
The largest individual images were approximately2.1–2.5MB each, with many older
Room2 panoramas/foundations exported alongside their current replacements.

## Change and preservation

The Web preset now explicitly selects the142 resources reachable from the main
scene, three runtime scenes and configured autoload. The dependency audit follows
res:// paths, relative load/preload paths, and named GDScript classes. An initial
scene-only selection was insufficient; the explicit audited closure is required.

No source asset was deleted, downscaled, recompressed or converted. Design references,
review screenshots, tests and old artwork remain available in the workspace. They
are excluded from this runtime package. All61 live media resources—40 textures and
21 audio resources—retain the same payload hashes as the original pack. The pack
inspector also verifies each stored media hash against its actual bytes.

The final273-entry pack includes gameplay scripts, shaders, scenes, live media,
import/remap records and required autoload support scripts. Native engine validation
ran from an empty directory with only this pack mounted, preventing source-project
fallback. All142 resources loaded; every packed script could instantiate; menu,
cave and forest scenes started; transitions through forest rooms6/8/7/9/10 passed.
Slot0 prevented writes to player saves. This validates packaged resources using the
native Godot engine; it is not a browser/WASM gameplay test.

The matching Web files in docs were regenerated. index.html declares the new pack
size. The separate39.51MB index.wasm is the engine binary and is not part of the PCK
size; the100MB requirement here applies to index.pck. No deployment was performed.

## Future export checks

1. Run `python tools/web_pack_audit.py --refresh-export` after adding runtime resources.
2. Export the Web release through Godot using `export_presets.cfg`.
3. Run `python tools/web_pack_audit.py --verify` to check size, media integrity and exclusions.
4. Run `tests/web_pack_smoke.gd` with `--main-pack docs/index.pck` from an empty
   directory, passing the absolute runtime-manifest path after `--`.

The hash comparison uses this export's baseline; deliberately replacing live media
requires reviewing and updating that baseline. The current audit follows literal
paths and named classes. Any future computed resource path needs an explicit audited
entry rather than assuming the exporter will discover it.

Evidence: [original inventory](index-pck-inventory.json),
[final inventory](index-pck-runtime-inventory.json),
[runtime resource manifest](web-runtime-resources.json).
