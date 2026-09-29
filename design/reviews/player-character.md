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
ledge grip, meditation, death and the earned thrust ability, which
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

The Web pack is 70,421,704 bytes (70.42 MB), with 164 audited runtime resources;
menu, cave and forest scenes instantiate and all forest rooms open. All 61 original
live media resources remain byte-identical. References and reviews stay outside
export.

## Heavy attack — 2026-09-29

`heavy-attack-reference.png` supplies nine additional poses. The measured crops
from `heavy-attack-matte.png` are preserved in `heavy-attack-frames.json`;
`tools/build_player_heavy_atlas.gd` creates `hooded_player_heavy.png`.
All five charge poses play over the existing 0.8-second charge, with the last
held while H remains down. All four release/recovery poses play over the existing
0.25-second attack. The supplied blade energy and crescent replace the detached
charge ring and reused normal downward slash. Sound/contact still occur on release;
damage remains one 96-by-80 volume and the cooldown remains 0.65 seconds.

The standing endpoints retain 58-pixel height. Every resized pose registers its
measured last opaque boot row to local y=23, avoiding fractional scaling drift.
Movement reset clears charge/release state during room travel, death and chair use.
The existing facing reflection is retained; the reference supplies one facing.

`player_heavy_animation_smoke.gd` passes real H presses in both facings, all nine
ordered frames, alpha/gutters/feet, the earned-ability gate, harmless partial
charges, exactly one contact, unchanged reach and movement reset. Its rendered
run saves each pose as `player-heavy-{direction}-frame-{index}.png`; charge and
active-release views were inspected. Player art, complete-animation and ordinary
combo and boss-combat regressions pass alongside it. The local Web export includes
the heavy atlas and passes the pack audit; publication is separate.

Heavy-charge feedback now blinks the textured character white at full power
for 0.12 seconds every 0.24 seconds, clearing on release/reset. Normal horizontal
movement while charging is capped immediately at half speed (127.5 px/s).
Grounded movement combines the supplied charge upper body with all five supplied
unsheathed walking-leg frames below local y=2; stationary charge and release retain
their full supplied poses. Real-input tests verify both directions, half-speed
movement, restored release speed, leg playback and repeating readiness feedback.
Rendered normal/white frames in both facings were inspected.

The charging torso, hands and sword now follow the walking cycle's hip rise and
sway, including its raised passing pose. The fourth leg crop is recentered at the
hips, and the moving waist seam overlaps by two pixels so the body stays connected.
`player_charge_walk_visual.gd` captures all five walking and charge-walking poses
side by side in both facings for rendered review.
