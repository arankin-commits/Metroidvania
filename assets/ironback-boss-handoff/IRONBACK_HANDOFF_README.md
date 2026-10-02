# Ironback boss handoff

## Included files
- ironback-sprite-animation-design.png: character model and animation key-pose reference.
- IRONBACK_ANIMATION_DESIGN.md: proposed clip frame counts, timings, FX separation, damage events, registration and verification requirements.
- ironback-generation-prompt.txt: exact built-in imagegen prompt.

## Integration status
These are design artifacts, not an engine-ready atlas or implemented animations. The PNG contains labels, a background, and nonuniform pose panels. Author clean transparent, consistently registered frames before importing as sprites; do not import the whole sheet as a gameplay sprite.

## Boss behavior
Main attack: visibly raise both fists overhead, smash ground directly beneath the body, emit one large traveling ground shockwave in each direction, then remain vulnerable during an exhausted recovery. Separate local fist-impact damage from traveling wave entities. Dust trails are harmless.
Secondary attacks: bounding landing impact, close hydraulic backhand, medium-range piston rush, and a three-smash barrage below half health. Use distance-aware selection and cooldowns; seismic smash is the central move. Do not begin another barrage while prior shockwaves remain. Commit leap destination at takeoff.

## Project fit
Follow existing project instructions and design memories. Preserve the real player controller, progression, checkpoints and save behavior. The encounter should be beatable with normal jumps/basic dodge; do not require earned air dash. No new traversal ability or reward is approved by this package. Boss placement, arena changes, final balance and reward remain integration decisions requiring the project owner's direction as applicable.

All stated sizes/timings are proposed starting values, not measured runtime balance. Validate real-controller wave jumping, visible damage bounds, recovery opportunities, both-facing poses, animation-event duplication prevention, and cleanup on defeat/reset/room deactivation. Store defeat state separately from checkpoint activation. Integration tests using invulnerability do not establish difficulty balance.
