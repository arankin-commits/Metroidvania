# Ironback — Cyborg Gorilla sprite and animation specification

Animation design proposal, 2026-10-01. Follows the supplied archive's readable anticipation/active/recovery philosophy. Timings and sizes below are initial authoring targets, not implemented or playtested balance.

## Sprite construction

Side-view boss, default facing right. Charcoal organic silverback, short powerful legs, exaggerated long arms, weathered slate steel forearms, exposed hydraulics and restrained amber reactor/vent accents. Distinguish him from the cave goblin through blunt mechanical fists, broad silverback shoulder mass and upright two-handed smash silhouette. No handheld weapon.

Suggested native frame canvas: 256x256 pixels; idle visible body approximately150x140. Bottom-center ground pivot(128,240). Overhead fists remain within the canvas. Larger traveling effects are separate sprites, never baked into the body atlas. Suggested uniform integer scale2; confirm against the actual gameplay viewport before import. Keep all body frames the same canvas and origin; foot-contact baseline stable. Airborne motion comes from the actor, not shifting canvas registration. Preserve the same armor joints, reactor and face across clips. A draft sheet is a visual reference; frames need registered cleanup before engine use.

## Clips and timing

Frame counts mean individually authored sprite drawings; holds supply phase duration. Movement and damage events use explicit animation phases, independent of playback speed.

| Clip | Drawings | Initial duration | Required visual keys / events |
|---|---:|---:|---|
| idle |6|0.9s loop|Slow breathing, shoulder/knuckle weight shift; stable feet; restrained reactor pulse|
| knuckle_walk |8|0.8s loop|Alternating hand support and short leg steps; grounded weight; match speed to contacts|
| seismic_smash |12|1.75s|Anticipation0.65s, downward drive0.15s, impact0.10s, exposed recovery0.85s|
| faultline_barrage |18|3.30s|Initial tell0.65s; impacts at0.80/1.50/2.20s; distinct overhead reset between; final recovery1.00s|
| bounding_impact |10|variable|Crouch0.45s; leap/flight tied to physics; landing impact0.10s; recovery0.70s|
| hydraulic_backhand |8|1.15s|Cross-chest tell0.35s, sweep0.15s, recovery0.65s|
| piston_rush |10|variable|Shoulder-low tell0.45s; charge tied to travel; brake0.20s; recovery0.60s|
| hurt |3|0.15s|Small recoil and brief contrast flash; no silhouette disappearance|
| phase_change |6|0.80s|Reactor casing cracks, asymmetric sparks; posture returns to familiar attack shapes|
| defeat |10|1.60s then hold|Arms buckle, shoulders drop, body settles, reactor dims; permanent inert final pose|

## Seismic Smash frame direction

1-2: wide planted feet, knees compress, knuckles gather beneath chest.
3-4: torso rises; elbows lift; fists join above brow.
5-6: full upright overhead silhouette. Hold key6 to complete0.65s anticipation. Pistons lock visibly; amber cue confined to forearms.
7-8: accelerate fists vertically down beneath torso. No forward punch or tracking turn.
9: compressed impact, both fists touching supporting ground. Trigger local impact hit and exactly one wave in each direction ONCE at this event.
10: impact settles, shoulders low; sparse debris behind character.
11: hands embedded, exposed reactor/back and exhausted silhouette.
12: pull fists free and return to hunched idle. Recovery must remain readable and vulnerable.

The local impact damage window is0.10s. Decorative lifting/settling frames are harmless. Ground waves remain separate damage entities after the local impact ends. Do not attach active melee hitboxes to the entire overhead arm arc.

## Secondary attack silhouettes

Bounding Impact uses a deep crouch and airborne body arc, unlike the upright stationary smash. Commit landing destination at takeoff; actual floor contact owns impact and wave spawn. Flight pose must support short or long airtime without sliding or inventing landing frames in midair.

Backhand pulls only one arm across chest while the other stays braced. Active damage follows the visible forearm sweep; torso/idle arm do not extend attack reach. Return the striking arm slowly enough to show recovery.

Rush lowers one shoulder and extends the body horizontally, rather than raising fists. Charge feet cycle while collision moves the actor; braking sparks trail behind, not in front of the damaging shoulder. End charge damage at the braking event.

Barrage reuses familiar overhead/impact silhouettes. Each impact emits one wave pair. Use visible intermediate resets and slower, heavier final recovery; do not disguise a damaging follow-up as the final recovery. Existing waves must clear before the next barrage begins.

Hurt is a separate reaction only where the state machine permits interruption. For uninterruptible attack phases, use a brief damage flash without resetting pose, damaging phases or impact events. Uninterruptible animation is not invulnerability. Charge glow is anticipation, not protection.

## Separate effects

- impact_core:6 drawings/0.30s, anchored to supporting floor under fists. Bright at contact, then quickly dim; avoid covering the player.
- shockwave_travel:6 drawings/0.45s looping visual cycle; proposed crest native64x48, clear bright leading edge and subdued wake. Actual travel speed and crest height require real-controller jump tests. Both directions share consistent art/collision; mirror this isolated directional FX sprite if appropriate, never environmental artwork.
- shockwave_end:4 drawings/0.20s, extinguish collision as dissipation starts. No invisible lingering damage.
- piston_vent:4 drawings/0.20s, localized steam behind arms.
- reactor_spark:4 drawings/0.25s, sparse phase-change accent, not ambient loot-like glints.

Shockwave collision tracks the visible moving crest, not the broad dust trail. Supporting ground determines placement; waves stop at actual solid arena boundaries. Defeat/reset/deactivation removes owned effects immediately. At phase two, emphasize cracked casing and intermittent vents; keep original tells and wave speeds legible.

## Implementation and acceptance

Export cleaned clips as transparent PNG frames or a registered atlas with uniform cells, nearest-neighbor filtering and no mipmaps. Separate body and effects sheets. Generate left-facing clips by whole-body mirroring only if the design and actual attachment/hitbox anchors allow it; otherwise author matching left-facing frames.

Check at gameplay zoom against cave and forest backgrounds: idle silhouette, overhead tell, fist impact, active crest and exhausted recovery. Test full sequence in motion with normal jumps/basic dodge before granting dash. Verify events cannot fire twice on looping/held frames, attack cancellation cleans hitboxes, leap lands on actual collision, hurt does not restart wave spawns, and defeat removes all active danger. Gameplay controller/hitboxes remain authoritative; the art must match them. Concept art and proposed timings are not runtime verification.
