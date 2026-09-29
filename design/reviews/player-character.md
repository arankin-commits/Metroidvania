# Complete hooded traveller animations ? 2026-09-28

The supplied `design/references/player/character-animation-reference.png` owns the
character and frame sequences. `complete-player-matte.png` separates sprites from
labels and scenery without reducing the supplied sequences. The measured source
coordinates and ordered frame catalog are in `complete-player-frames.json`.
`tools/build_complete_player_atlas.gd` builds the runtime alpha atlas.

| Sequence | Sheathed frames | Unsheathed frames |
| --- | --- | --- |
| Idle | 5 | 5 |
| Walk | 5 | 5 |
| Run | 5 | 5 |
| Dash | 4 | 4 |
| Jump up | 4 | 4 |
| Fall | 5 | 5 |

The sword combo preserves all 11 character frames: three for the horizontal
slash, four for the upward slash and four for the downward slash. The extended
horizontal blade wake stays with its active frame. Together these are 67 frames
in 15 ordered runtime sequences. The prior supplemental atlas is retained for
ledge grip, meditation, death, charge stance and the earned thrust ability, which
are not separate supplied sequences.

Every standing idle frame is calibrated to the previous 58-pixel hood-to-boot
height. Boots share the controller's floor contact at local y=23. The body stays
28 ? 46; speed, jump, pre-boss dodge, unlock gates and melee sizes are unchanged.
State clocks restart at transitions, movement loops in supplied order, and dash,
jump and fall play through their full sequences. Airborne sequences hold their
final frame rather than looping back to takeoff.

Normal sword animations run for the existing 0.3-second attack cooldown. One
contact event occurs on the active reference frame after preparation: horizontal
and downward at 0.15 seconds, upward at 0.075 seconds. Each uses the existing
72 ? 56 melee volume. Damage, other attacks, weapon changes, a 0.8-second pause
and movement resets clear the chain and cancel any pending contact.

`player_complete_animation_smoke.gd` verifies all 67 catalog entries, sequence
counts and order, real alpha, transparent gutters, foot registration, standing
height and reachability of every frame through runtime state selection.
`player_combo_smoke.gd` verifies real presses in both facings, harmless preparation,
one active hit, chain wrap/reset and unchanged melee volumes. The original player
art checks and full boss-combat regression pass.

`player_art_visual.gd` reviews live movement and captures every preparation,
active and recovery frame of all three slashes; it asserts that no supplied slash
frame is skipped. Review captures use a non-saving game session.

The Web pack is 68,989,696 bytes (68.99 MB). All 145 audited runtime resources load;
menu, cave and forest scenes instantiate and all forest rooms open. All 61 original
live media resources remain byte-identical. References and reviews stay outside
export.
