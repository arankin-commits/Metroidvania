# Required animation, VFX and impact bindings

Read with AI_AND_TEST_SCENE.md. The individual PNGs are animation KEY POSES and static FX keys. They are not complete interpolated frame-by-frame clips. Use timed holds and author missing in-betweens where practical. A loaded file is not evidence its animation plays. Manifest metadata gives ACTUAL delivered sizes, crop rectangles and estimated root; do not assume prompt dimensions were honored.

## Body state bindings

| State | Required pose keys | Playback requirements |
|---|---|---|
| Ceiling idle |ceiling_idle_01, ceiling_idle_02|Slow0.9s loop; feet contact real ceiling|
| Ceiling crawl |ceiling_crawl_01..04|0.8s loop while supported and abs(vx)>8px/s; visible0.15s turn, not idle sliding|
| Single swing |swing_prepare, swing_hang, swing_rake, swing_rise, swing_recovery|Full tell before rake; active window at real low crossing; exposed LOW recovery|
| Double swing |Same five swing keys, two passes|Distinct intermediate harmless lift, two event IDs, final recovery longer|
| Grapple zip |zip_aim, zip_release, zip_compress, zip_travel, zip_arrival, zip_recovery|Hook shot at release, travel only after cable taut, arrival on actual body support|
| Reattach |zip_aim/release/compress/travel, reattach_catch, zip_recovery|Harmless return; grounded takeoff then actual underside catch, no damaging zip flag|
| Trap placement |trap_prepare, trap_release, trap_recovery|Seed spawns once; boss recovery separate from trap arming|
| Committed drop |drop_gather, drop_airborne, drop_impact, floor_idle|Drop impact on true ground contact, harmless landing dust; full floor recovery|
| Floor idle |floor_idle|Damageable stable foot support|
| Fang bite |bite_tell, bite_active, floor_idle|Tell and actual fang reach match; recovery cannot immediately restart bite|
| Hurt |hurt|Visible0.12–0.15s override in idle/crawl/recovery; restore CURRENT state|
| Phase change |phase_change|Harmless0.85s plus fraying FX; one transition|
| Defeat |defeat|Harmless collapse/hold, eyes dim; animated fall if killed overhead|

Body poses include camera-facing/front-facing variation; inspect orientations rather than blindly rotating a floor frame for ceiling attachment. Adjust individual visual offsets/support anchors without shifting the authoritative physics trajectory. Dynamic rope rendering needs measured spinneret socket coordinates per pose; a rectangle-center anchor is not adequate. Expose sockets for spinneret, front fangs, ceiling foot contacts and floor contact in debug overlay.

When boss damage is accepted during idle/crawl/recovery, show hurt.png briefly while preserving logical cooldowns/attack clocks. During committed tell/active, keep critical tell/contact pose and show a hit spark/flash; queue hurt key for the first safe recovery without restarting its timeline. Attack commitment is not immunity. Lethal damage supersedes hurt/phase queues and removes danger. Report actual hurt playback and accepted damage in both support states.

## Every original effect has a separate implementation

| Behavior | Supplied FX key(s) | Required trigger / presentation |
|---|---|---|
| Hook flight |hook_head|Release event; orient to target; visible projectile stops on first valid anchor; harmless|
| Destination/attachment cue |anchor_rosette|Visible pulse during aim and after connection; anchor fixed to physical surface|
| Tether/cable |cable_segment + dynamic thin silk line|Draw current spinneret-to-anchor every physics/render update; swing length consistent; zip straight segment; harmless|
| Swing attack streak |swing_streak|Short-lived trail along actual active sweep; no full-screen hoop; harmless beyond contact area|
| Snare seed |trap_seed|Visible descent to locked valid floor target; no player damage/slow in flight|
| Snare deployment |trap_unfold|0.35s reveal; no slow until armed, keep floor edge visible|
| Armed floor patch |trap_active|Shallow side-view mesh on real floor, world width100px; exact slow Area derived from visible bounds|
| Triggered snare |trap_trigger|Short wisps when grounded status is accepted/refreshed; do not pin/cover character|
| Drop/takeoff landing dust |landing_dust|Floor contact/takeoff anchors; short spread/alpha cycle; harmless|
| Fang bite streak |bite_streak|Only during active fang sweep; align to fangs and facing; do not add range|
| Hurt / silk phase |hit_fray|Accepted-hit spark and harmless phase fraying, with distinct scale/density|
| Cable break / trap expiry / death drift |web_dissolve|Short nondamaging dissolve from actual former geometry; owned effects cleaned immediately on reset|

12 static effect keys are supplied so no VFX category is silently omitted. Turn each into short node/particle animations or additional drawn frames. Cable must be code-native geometry following endpoints; do not stretch the decorative diagonal sprite into a fake tether. Use real transparency and nearest-neighbor settings; supplied alpha/edge colors need visual QA on the actual arena background. Keep dust/trails recessed enough to see the player and bright silk edges. On expiry/death disable statuses and hitboxes FIRST, then optionally play harmless dissolve. On scene exit free immediately.

FX are owned by boss/attack/trap instance, with unique IDs. Holds/hurt overlays never resubmit spawn events. All normal and double-swing attacks need complete effect coverage. A checkerboard contact sheet is preview-only, never a game sprite. No scene backgrounds, labels or panels from the original sheet may be imported as actor art.

## Attack-specific player knockback

Keep baseline movement/controller intact. Use existing accepted-hit damage path with a source-specific profile, scoped to this boss/test scene. Extend hit data if needed; never double-apply the controller's existing recoil or apply an impulse every overlap frame. Traps, silk seeds, hook head, cables, crawl, reattach and cosmetic FX cause NO knockback or stun.

Initial world-space velocity targets px/s, Godot upward y-negative:

| Source |Horizontal magnitude|Upward magnitude|Maximum input lock|Tier |
|---|---:|---:|---:|---|
| Fang bite |150|90|0.10s|Light, quick|
| Pendulum rake |220|150|0.15s|Medium sweeping|
| Double swing first rake |220|150|0.15s|Medium|
| Double swing final rake |250|180|0.17s|Heavy sweeping|
| Grapple zip moving front |260|120|0.17s|Heavy horizontal|
| Drop landing footprint |210|240|0.19s|Heavy upward|

Damage stays1 basic-hit equivalent; physical impact differs independently. Swing/zip pushes in committed horizontal travel direction; bite in locked facing; drop away from impact center. Centered ties use stable last relative side, never random zero/sign. Compute once on accepted contact. No hurt/knockback on a dodge, duplicate or invulnerability-rejected hit. Use distinct event IDs for two swing passes. Existing immunity must prevent overlapping geometry from double-hitting; do not shorten immunity to manufacture difficulty.

Airborne recipient: y=min(current_y,-profile_up) so a weak hit does not erase stronger upward motion. Apply horizontal combat launch once; cap this boss's combat channel320px/s sideways/300px/s upward, without clamping ordinary jump/dash outside hit handling. Grounded launches release floor adhesion for that tick. Input may not erase recoil next frame; let the existing controller's combat impulse channel/input lock and normal gravity/collision resolve it. Locks stay shorter than existing immunity; no stacking/refresh beyond one accepted event. Knockback and death supersede trap-ground-speed modifier appropriately; never multiply the launch/dodge/jump velocity by the snare's0.70 walk multiplier. Respect real walls; no teleport/depenetration through art.

Test every profile on grounded/airborne targets, both sides, held input, arena wall, trapped ground and rejected hits. Log requested and actual velocities plus lock/return-to-control. Different displacement at a wall is expected; compare requested profile magnitudes separately. Ensure slow expires/clears and normal movement resumes after hit recovery. No guaranteed follow-up or chain-lock from double swing/drop while slowed. Cosmetic hitstop/shake, if used, is nonstacking, optional, and cannot change collision/event timing.

## Playback acceptance

Instrument clip/key and time changes. Force idle, four-key crawl both directions, each attack, floor idle, hurt in idle/crawl/recovery and after a committed hit, phase and defeat. Provide a table listing every body/FX key's resource/node path and witnessed playback. Explain any replaced pose with the replacement artifact. Actual movement and damaged state must select these animations, not just AI intentions. Scheduler None means harmless hold/crawl as appropriate, not always freeze on idle. No unreported unused supplied sprites.
