# Cave Room 1 opening

Fresh slots start at (-640,577) in Room 1. Eight blood-stained poses play for 0.5 seconds each, totaling four seconds. Movement, attacks and incoming damage are suppressed during the opening. Completion is persisted; loading an activated hand, returning from another biome, or reloading a completed opening restores normal control without replaying it.

The supplied room was cleaned of baked UI and its standing player. Floor y780 in the 1651px-wide painting maps to the physical floor y600 at room width1200. Existing solid roof and traversal platforms retain matching drawn terrain and collision. Blood on the floor remains in the environment; clothing blood moves with each pose. Existing enemy prefabs remain test-only.

## Image generation provenance

Mode: edit, built-in imagegen skill/tool. Inputs: `design/references/cave-room1/room-reference.png`, `design/references/cave-room1/wake-reference.png`.

Room prompt:

> Use case: precise-object-edit. Edit target: supplied Cave Room 1 screenshot. Prepare the same room as a clean Godot game environment plate: remove ONLY the top-left HUD and bottom-left ability icons, the central standing blue player, and the thin outside image border, restoring matching stone/background beneath them. Preserve the huge circular sealed door, corpses, fallen weapons, hanging body, red cloth, crows, candles, cave architecture and ALL BLOOD on floor and stone. Keep the continuous flat floor boundary, ceiling silhouette, original composition and pixel art. Empty player space near horizontal center for a waking-up player. No new characters, enemies, UI, labels or text. Full opaque environment, no transparency.

Wake prompt:

> Use case: background-extraction. Edit target: supplied eight-pose hooded teal player waking-up reference. Create a genuine TRANSPARENT ALPHA sheet preserving EXACTLY all EIGHT supplied poses, in left-to-right order, same proportions and cloak/armor identity. Remove dark background, title, numbers and horizontal guide lines ONLY. Keep all fingers, cloak tips and boots complete with clear transparent margins. Add small dark-crimson BLOOD stains to the visible chest/forearm, hands and knees in every pose, consistent with the bloodied traveller in the cave-room reference; the first pose lies face-down, then slowly pushes up, kneels and stands. Preserve the eight poses and their pixel-art look, no extra poses, no rearranging. Keep the original wide layout and ground baseline. No floor, pool, text, border or checkerboard.

Outputs: `assets/cave_room1_opening.png`, `design/references/cave-room1/wake-blood-cutouts.png`. The native Godot atlas builder thresholds low-alpha background residue, packs eight complete cuts into 192px cells, and registers each body's pivot and floor baseline. Runtime atlas: `assets/characters/hooded_player_wake.png`.

## Verification

`cave_opening_smoke.gd`: passed exact 240-tick duration, input/damage lock, all eight poses containing blood, clear atlas margins and shared floor, fresh start/death in Room 1, completion reload, saved hand preservation, and playable biome return.

`cave_opening_visual.gd`: passed native rendered capture of all eight poses and the transition to normal standing. Screenshots: `cave-opening-pose-0.png` through `cave-opening-pose-7.png`, and `cave-opening-standing.png`.

`save_slots_smoke.gd` and `player_complete_animation_smoke.gd`: passed.

`start_game_smoke.gd` and `gallery_gates_smoke.gd`: passed, including menu slot loading, both neighboring room transitions, ability gate persistence and biome travel. Fixtures now explicitly enter the gallery and expect the new Room 1 pre-hand checkpoint. The start-game fixture grants the bow-boss flag required by the existing dash unlock rule.

The broader `cave_rooms_smoke.gd` passes fresh start, menus, both room transitions and short dodge checks, then fails its legacy first-aerial-hit assertion. It expects sword damage after two physics ticks, while the current sword implementation has a 0.15s active-frame windup. This unrelated combat assertion was left unchanged; the full route suite is not claimed as passing.

Local Web build refreshed: 171 runtime resources, 337 packed entries, 71,457,796 bytes. Pack verification passed retained media checks and excluded design/test resources; the new reference enemy scenes and models remain outside the production dependency graph.
