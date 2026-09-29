# Temple Guardian mini boss — 2026-09-29

The supplied Temple Guardian now replaces the procedural stone placeholder in the
existing room 10 encounter, reached through the temple hand room's left arch.
Its arena bounds remain 22900..23900, home position (23390,553), floor y=600,
and health remains six. Defeat awards the saved Stone Gauntlet through the existing
progression flow; room entry preserves the last activated hand checkpoint.

## Assets and registration

The original reference is `../references/temple-boss/temple-guardian-design-sheet.png`.
Built-in imagegen extracted genuine transparent cutouts into
`../references/temple-boss/temple-guardian-cutouts.png`, then isolated the small
action sprites in `../references/temple-boss/temple-guardian-actions.png`.
The first extraction moved the sprites relative to the storyboard; source crops
were measured from the delivered image. A targeted second edit separated the
charging pose from the oversized portrait. Both extraction files and the original
reference remain available.

`tools/build_temple_guardian_atlas.gd` packs all thirteen supplied action/idle poses
into `assets/characters/temple_guardian.png`, with 384px cells, foot pivot
(160,272), and a common 144/148 scale. The standing idle is 144px tall; local feet
y=47 meet the floor at the encounter's y=553 home position. Torso damage bounds
are 124x144. Frame crops, centers and source foot rows are recorded in
`../references/temple-boss/temple-guardian-frames.json`. Facing reflection retains
the supplied sprites; no separately authored opposite facing is claimed.

Detached reference effects are `assets/effects/temple_rocket_fist.png` and
`assets/effects/temple_charged_shot.png`. The fist's radius15 and the shot's
radius21 swept contact cores retain their existing gameplay size and speeds.
The cyan projectile diamond registers to the contact center; the trailing wake
is decorative. The fist returns after 0.55 seconds and renders linked chain
segments to its owner's launch wrist.
Launch and return positions follow the actual rendered wrists: chain punch at
local (facing*32,-32), returning hand at (facing*62,-32), shot at (facing*58,-38).
The generic projectile return-position hook retains its original default for all
other projectiles; the temple fist supplies the animated wrist destination.

## Combat

Rocket punch uses windup, launch, extension, retraction and return-to-idle poses.
Charged firing uses both supplied braced charging poses, launch and recovery.
A first attack selection at half health introduces a protected 0.45-second
phase transition before charging; chest/rune pixels stay brighter below half health.
Charging lasts 1.05 seconds and remains protected, then launch immediately restores
vulnerability. Phase two chooses rocket punch or charged shot at range, and three
punches or slam nearby. The first two punches reach x=125 and the third reaches
x=150, matching the shorter opening poses and longer finishing wake. Slam retains
its 260x67 damaging footprint and supplied raised-arm/impact art.

## Verification

`tests/temple_guardian_smoke.gd` checks all thirteen poses are reachable, both
facings, phase gates, transition/charge protection and launch vulnerability,
three distinct melee contacts, slam, reference projectile selection and reset.
`tests/temple_guardian_visual.gd` captures all thirteen poses in both facings
and the four real attacks in the existing temple arena without an active save slot.
The live-rendered idle, braced charge, rocket fist, punches and slam were reviewed.
`tests/boss_combat_smoke.gd` passes the existing combat/reward regressions.
The final-concourse route test verifies real-input defeat and persistence separately.
It passes cave travel, death, reload and fast travel after both real-input encounter
defeats. The rebuilt Web pack passes its resource audit and opens every forest room;
all 170 runtime resources load, and the 61 original live media resources stay unchanged.

## Image generation prompts

Mode: built-in imagegen; transparent background enabled. No CLI fallback.

### Extraction

Use case: background-extraction. Edit target: the attached Temple Guardian design sheet. Make a production game sprite extraction sheet on GENUINE TRANSPARENT ALPHA. Preserve EXACTLY the original 1672x941 canvas, all original character poses, stone/moss/cyan pixel detail, silhouettes, pixel positions, sizes, and all attack glow effects. Remove ONLY all background scenery, floor strips, UI panel frames, text, labels, diagram arrows and decorative framing. Keep the giant standing guardian on the left; keep windup, launching guardian with stump where fist launches, extended chain and flying fist, retracting guardian and fist, and idle guardian across top; keep three charging/firing guardians, detached cyan projectile and recovery guardian across middle; keep three different punching guardians, raised-arm guardian and slamming guardian with impact burst across bottom. Keep every original sprite/effect in precisely its source position so measured crops remain valid. Do not redraw, rearrange, add a grid or checkerboard, omit sprites, change weapon hands, or add text. Transparent outside the silhouettes; opaque stone interiors and softly alpha-edged cyan energy.

### Separate overlapping portrait

Use case: precise-object-edit. Image 1 is the transparent sprite sheet edit target; Image 2 is the original Temple Guardian reference for reconstructing any occluded stone pixels. Remove ONLY the giant standing portrait on the LEFT of Image 1 (the large guardian from x0..570,y140..813). Leave that entire portrait area truly transparent. Keep all the thirteen small attack/idle guardian cutouts and the detached fist/chain and cyan diamond projectile effects in EXACTLY their current Image 1 positions, sizes, pixel style and colors. In particular the first charging guardian at approximately x555..720,y435..605 must remain COMPLETE, with both legs, chest, two braced hands; repair its left edge using Image 2 where the giant portrait overlapped it. Do not remove the top windup guardian at x545..720,y185..343 or the bottom punching guardian at x510..706,y707..849. Do not shift, rearrange, resize, redraw or omit any other small sprite or effect. Preserve genuine transparent alpha and opaque stone interiors. No checkerboard, no background, text or UI.
