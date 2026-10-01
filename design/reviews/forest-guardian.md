# Forest Guardian implementation — 2026-09-29

The supplied hooded kobold reference now replaces the Forest Bow Hunter's procedural
body. The encounter keeps its existing arena, routes, defeat rewards and save behavior.
The HUD and entrance announcement identify it as FOREST GUARDIAN.

## Frame catalog and preparation

Both independent facing atlases contain every supplied Guardian pose. Source rectangles,
centers, foot anchors and neighboring-silhouette masks are recorded in
[the atlas builder](../../tools/build_forest_guardian_atlas.gd). Cells are320×320 in a
4×5 atlas, with the foot pivot at160,240. The standing silhouette is99px tall, matching
the existing combat body; floor contact is local y47 at arena floor600.

| Atlas index | Sequence | Supplied character poses |
|---|---|---:|
|0|Standing portrait / idle|1|
|1–2|Summon channel and emergence|2|
|3–5|Aim, full charge, release|3|
|6–10|Rapid shots1–5|5|
|11–13|Arrow pull, slash, stab|3|
|14–16|Retreat leap, dash, landing|3|
|17–19|Volley overhead dash, airborne aim, recovery|3|
|Total per facing||20|

The summoning appearance panel supplies three additional woodland allies. The volley
impact panel supplies arrow and impact effects rather than another character pose.
All three allies and12 root/arrow/impact assets are preserved separately. No supplied
character pose was removed. Two slashes followed by a stab produce three knife hits.
Five separate shooting poses produce the rapid volley.

Generated with the built-in image generation tool from the preserved
[reference](../references/forest-boss/forest-boss-design-sheet.png). The extraction
brief was to retain every character pose, ally and combat effect on a flat magenta
matte while removing captions, scenery, arrows between panels and blue player diagrams.
The opposite-facing brief requested independently authored left-facing counterparts,
preserving the same panel positions, moss/leather/quiver details and luminous blue eye;
bow in anatomical left hand and arrow knife in right. The delivered matte sheets are
saved as `forest-guardian-matte.png` and `forest-guardian-left-matte.png` in that reference
directory. The builder removes the matte, isolates neighboring silhouettes and packs
actual transparent runtime assets with nearest-neighbor scaling.

Runtime outputs: `assets/characters/forest_guardian_right.png`,
`forest_guardian_left.png`, `forest_guardian_allies.png`, and
`assets/effects/forest_*.png`. Source matte sheets are excluded from the web pack.

## Combat and presentation

Charged arrows deal twice ordinary arrow damage and use a larger bright cyan crest.
The rapid volley uses five separate arrow textures. Air dashes leave fading sprite
afterimages and kick up dust on landing. Root emergence marks the three summons;
their feet align with the floor. Their118.8px height is20% larger than the99px boss,
with corresponding collision and damage bounds; scout AI remains intact.
Room melee handlers use these same bounds; the old34×40 scout target rectangles
are removed for summons. Normal/heavy sword and projectile hits agree across the
enlarged upper and lower body, and miss empty space outside it.
The allies are rebuilt from full reference cutouts at119px in256px atlas cells,
avoiding loss of detail from enlarging the earlier38px runtime sprites.
Arrow impacts use extracted cyan effects. Decorative trails do not gain collision.
Collision effects render only the bottom impact burst from the reference panel;
its descending arrows are not replayed above a target after an ordinary hit.
The active boss hurts on body contact; invulnerability still governs repeated hits.
Summoning is skipped while any previous summon remains alive. Hostile rapid-fire
and volley arrows use0.1s hit immunity without launch knockback; every other attack
keeps normal recovery. A stationary player can take all five rapid shots or all
three volley hits. Existing normal hit immunity is still respected.

Below half health, Flipping Volley creates three arrows during the overhead dash.
Each hovers harmlessly for one second, then continuously tracks the player with
positive downward velocity. Targeting never sends it upwards. The earned Bow ability
shares the same behavior and arrow appearance. Reset/death clears summons, arrows,
afterimages and dust.

## Verification

- `forest_guardian_smoke.gd`: PASS,20 poses per facing, alpha/gutters, all phase poses
  reachable,5 shots,3 advancing knife strikes, phase gate,3 distinct grounded allies,
  summon cap and FX reset.
- `boss_combat_smoke.gd`: PASS, existing attacks, rewards, progression and persistence.
- `flipping_volley_smoke.gd`: PASS, one-second harmless stationary hover, continuous
  downward tracking, target loss, encounter cleanup, release damage and earned ability.
- Live arena review captured each attack pose in both directions under
  `forest-guardian-{direction}-{attack}-pose-{index}.png`, plus summons and release views.
  The review used slot0 and restored the main menu without writing a player save.
- `forest_arrow_recovery_smoke.gd`: PASS, all five rapid shots and three volley
  arrows damage a stationary player; charged/normal recovery remains unchanged,
  and special arrows respect existing normal immunity.
- `forest_summon_hitbox_smoke.gd`: PASS, all three variants accept normal/heavy
  melee and projectile hits across their enlarged bodies; outside hits miss and
  physics bounds match combat bounds.
- Web pack rebuilt:70,333,528 bytes (70.33MB),323 entries,163 runtime resources.
  All61 baseline live media resources remain byte-identical; design/tests/docs excluded.
- `web_pack_smoke.gd`: PASS, all163 audited resources load from the exported pack,
  menu/cave/forest instantiate and every forest room opens.
