# Enemy models and animation review

Prepared from all seven supplied reference sheets. Goblin combo belongs to the basic Goblin, giving six enemy types. Assets are **unplaced**: only the isolated test scene instantiates them. Normal gameplay dependency audit remains at 170 resources with zero new enemy dependencies; no production room script or normal encounter was changed for this work.

## Test entry

Open `tests/scenes/enemy_animation_lab.tscn` in the root Godot project and press F6.

- 1–6: select Goblin, Dog, Sentinel, Archer, Clubber, Summoner.
- Tab: cycle complete reference animations; nonlooping sequences hold their last pose for inspection.
- V: flip facing. G: toggle demonstration AI. R: reset actor/player.
- Real player: A/D movement, Space jump, J attack, H heavy charge. Player hits trigger posture break.

The lab uses its own matching visible floor/collision, the existing forest backdrop and production player controller. It does not load/save progress, grant rewards or connect to room transitions. Attack cues are animation events for testing, not a completed production combat/balance implementation. Archer cues launch a temporary arrow; Summoner's supplied column and spectral creature appear in its cast frames without placing a persistent enemy.

## Delivered models

| Enemy | Body frames | Sequences | Standing body height |
| --- | ---: | ---: | ---: |
| Goblin | 59 | 9 | 58 px |
| Goblin Dog | 42 | 6 | 40 px |
| Goblin Sentinel | 33 | 6 | 72 px |
| Kobold Archer | 26 | 5 | 68 px |
| Kobold Clubber | 31 | 6 | 86 px |
| Kobold Summoner | 26 | 5 | 74 px |

Idle, walk, run and posture break exist for all six. Goblin adds sleep/wake and three slash/slam sequences; Dog adds leap/bite; Sentinel adds thrust/two-hit combo; Archer adds shooting; Clubber adds slam/two-hit combo; Summoner adds casting. Supplied windup/active/recovery poses remain in order.

- Prefabs: `scenes/enemies/*.tscn`.
- Shared animation/controller: `scripts/enemies/reference_enemy.gd` (no global class registration).
- External atlases and SpriteFrames: `assets/characters/enemies/*.png` and `*.tres`.
- Source cutouts: `design/references/enemies/extracted/`; originals in `cave/` and `forest/` remain unchanged.
- Measured source metadata: `enemy-source-crops.json`; delivered sequence/frame indices: `enemy-frames.json`.
- Rebuild: `python tools/enemy_crop_catalog.py`, then Godot `--headless --path . --script tools/build_enemy_atlases.gd`; reimport textures before playing.

Atlases use 320 px cells, a common (128,224) foot pivot, nearest-neighbor sampling and external textures. Collision bodies cover the torso, excluding capes, weapons and spell wakes. The original last Sentinel run spear was clipped; that pose was extracted separately with a restored complete tip. The Clubber's eleven overlapping movement poses were reconstructed as separate complete sprites. Other poses retain their supplied design. Airborne Dog frames exclude detached ground dust, so the physics leap does not carry floor debris through the air.

## Verification

Final result: smoke checks PASS, rendered review PASS, placement dependency audit
PASS. All six prefabs include editor-visible sprites, animation resources and
collision shapes. The Dog launches after its crouch frames and returns to the
floor for its landing poses. Normal gameplay still has 170 runtime resources and
zero dependencies on these new enemies.

`tests/enemy_animation_smoke.gd` checks all six prefabs, all 217 frames in both facings, nonempty cells with transparent gutters, real physics grounding, looping/final poses, active cues, walking translation, recoil recovery, the Dog's physical leap and lab AI cue delivery.

`tests/enemy_animation_visual.gd` renders full contact sheets for both facings and six actors plus all attacks in the player lab. Review images are `design/reviews/enemies-*.png`; logs are `enemy-smoke.log`, `enemy-visual.log`, `enemy-build.log`. Godot's editor MCP port conflict and restricted certificate-store warnings are environment messages; game tests are evaluated separately.

## Image generation provenance

Mode: edit / transparent background extraction using the imagegen skill and built-in image tool. Original references were viewed first; delivered alpha/poses were inspected before native atlas assembly. Exact prompts below.

### goblin

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapons, capes and effects of EVERY supplied animation pose. Required contents: 6 sleeping-idle poses; 7 wake-up poses; 6 awake-idle poses; 6 walk poses and 6 run poses; 8 posture-break recoil poses. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all sword wakes, dust, surprise/sleep/recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep sprites distinct and avoid fusing neighboring capes/wakes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### goblin_combo

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapons, capes and effects of EVERY supplied animation pose. Required contents: 7 horizontal-slash poses in row 1; 7 upward-slash poses in row 2; 6 downward-slam poses in row 3. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all sword wakes, dust, surprise/sleep/recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep sprites distinct and avoid fusing neighboring capes/wakes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### goblin_dog

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapon length, capes and effects of EVERY supplied animation pose. Required contents: 6 idle, 6 walk, 7 run, 8 jump-attack, 8 bite and 7 posture-break recoil poses. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all weapon wakes, dust and recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep every frame distinct; do not join neighboring silhouettes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### goblin_sentinel

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapon length, capes and effects of EVERY supplied animation pose. Required contents: 4 idle, 5 walk, 4 run, 6 thrust-attack, 8 two-hit-combo and 6 posture-break recoil poses. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all weapon wakes, dust and recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep every frame distinct; do not join neighboring silhouettes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### kobold_archer

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapon length, capes and effects of EVERY supplied animation pose. Required contents: 4 idle, 5 walk, 4 run, 7 shooting-body poses PLUS the separate flying arrow panel (keep that arrow as an effect, not an actor), and 6 posture-break recoil poses. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all weapon wakes, dust and recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep every frame distinct; do not join neighboring silhouettes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### kobold_clubber

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapon length, capes and effects of EVERY supplied animation pose. Required contents: 4 idle, 4 walk, 3 run, 6 slam, 7 two-hit-combo and 7 posture-break recoil poses. Preserve its larger elite build and the complete studded club and impact debris.. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all weapon wakes, dust, magic and recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep every frame distinct; do not join neighboring silhouettes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### kobold_summoner

```
Use case: background-extraction. Edit target: attached enemy animation reference. Produce a genuine TRANSPARENT ALPHA extraction sheet for a Godot pixel-art game. Preserve the original 1448x1086 canvas and EXACT pixel positions, sizes, order, silhouette, colors, weapon length, capes and effects of EVERY supplied animation pose. Required contents: 4 idle, 4 walk, 3 run, 8 summon-cast and 7 posture-break recoil poses. Preserve the complete staff, magical coils, ground summoning column and summoned spectral creature as separate readable effects within their supplied panels.. Remove ONLY dark background, headings, labels, horizontal separator lines and cyan ground guide lines beneath feet. Keep complete bodies, all weapon wakes, dust, magic and recoil marks. Do not redraw, resize, rearrange, invent poses or omit repeated-looking transition frames. Keep every frame distinct; do not join neighboring silhouettes. Opaque body interiors; transparent empty space; soft alpha only on existing glow edges. No checkerboard, grid, background, text or watermark.
```

### sentinel_repair

```
Edit this transparent enemy extraction sheet. Preserve every pose and transparent background. Repair ONLY the spear tip of the rightmost RUN pose in the upper row: it is clipped at the right canvas edge. Keep that body's position unchanged; angle the complete spear slightly toward vertical so its tip has at least 16 pixels of transparent space before the right edge, preserving weapon length and pixel art. Preserve all other poses and canvas layout exactly. Output transparent alpha, no text or background.
```

### clubber_movement

```
Create a clean transparent sprite animation extraction of ONLY the ELEVEN top-row movement poses of this exact Kobold Clubber enemy. Exclude all attack and recoil rows. Preserve the large teal reptile, bone skull shoulder armor, striped fur skirt, tail and long heavy spiked club, and the exact pose progression in the reference. Arrange cleanly in a 4-column by 3-row grid on a 1536x1152 TRANSPARENT canvas (384x384 cells). Row 1 exactly FOUR idle poses (complete body and club); row 2 exactly FOUR walk poses; row 3 exactly THREE run poses and one empty last cell. Never merge or overlap neighboring sprites. Every cell has its own complete character AND COMPLETE CLUB, no duplicated body parts, no clipped tips. Draw each standing torso from head to boots about 180 pixels tall, with full weapon extending above it. Keep each cell's boot baseline 320 pixels below that row's top. Horizontal body pivot 160 pixels from each cell's left. Pixel-art transparent alpha, generous clear margins, no lines, no text, no labels, no shadow/backdrop. Restore obscured portions of individual poses where reference neighbors overlap.
```

### clubber_single_weapon

```
Edit this transparent eleven-pose Kobold Clubber animation grid. Preserve canvas layout, all eleven poses, size, feet positions, teal skin and bone skull armor. Every pose must carry EXACTLY ONE heavy spiked club. In the FIRST TWO IDLE sprites in the TOP ROW there is an accidental second club over the LEFT/back shoulder, with a shaft extending to the left hand. REMOVE that extra left/back club and its shaft completely and restore the normal skull shoulder armor and relaxed left arm, matching the other idle poses. Keep the SINGLE complete upright club held on the RIGHT side of each sprite. Do not remove skull shoulder armor or tail. Preserve every other sprite and transparent alpha. No background, text or guide lines.
```

### sentinel_run

```
From this enemy reference extraction, produce ONLY ONE complete transparent pixel-art sprite: the rightmost running goblin sentinel in the TOP ROW. Remove all other poses. Preserve that exact running stance, teal skin, black armor, cape, and spear. Restore its missing spear tip and show the entire long spear diagonally upward to the right. Center the full silhouette with generous transparent margins on all four edges, no clipped pixels. No ground, labels or background. Match original pixel-art rendering and body proportions.
```
