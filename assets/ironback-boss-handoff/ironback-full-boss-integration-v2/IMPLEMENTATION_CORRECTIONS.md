# Required corrections: VFX, sprite use and player impact

Revision 2. This document supersedes conflicting statements in all earlier handoff notes. Apply these requirements to the test scene. The supplied body poses intentionally separate body artwork from effects, but the previous package did not supply every VFX sequence visible in the original sheet. A body-only attack with omitted effects is incomplete. The PNG set is unchanged in this revision; the agent must create the missing effect assets/layers below.

## Restore the complete visual attack, using separate effects

Inspect reference/ironback-sprite-animation-design.png alongside the individual body PNGs. Preserve the visual meaning of each original effect. Do not paste labeled sheet panels into the scene or bake moving shockwaves into the boss body. Use genuine transparent animated effect sprites, or code-native pixel particles/geometry matching the sheet. Preserve crisp pixels and restrained alpha; no background matte/checkerboard. If generating bitmaps, inspect transparency, frame registration and gameplay-scale results.

| Move/state | Required separate VFX | Exact trigger and placement |
|---|---|---|
| Smash anticipation |Hydraulic steam/amber vent pulse|Forearm vent anchors during the last0.25s of the overhead tell; no damage/glow shield|
| Seismic impact |Amber impact burst, outward ground-pressure arc, stone chips and settling dust|Once at fist-floor contact; floor anchor beneath both fists; body stays readable|
| Seismic travel |TWO large traveling shockwave crests with restrained debris wakes|Same guarded impact event; directions-1/+1; crest visuals follow damaging entities; trailing dust harmless|
| Bounding leap |Brief takeoff dust and restrained airborne motion trail|Takeoff at rear foot; trail behind airborne body, never an extra hitbox|
| Bounding landing |Smaller impact burst, two small waves, outward landing dust|Actual grounded landing, not predicted timer; no premature midair floor burst|
| Backhand |Short amber forearm arc/sweep trail|Only during visible0.15s sweep; attached to striking hand; trail does not extend damaging reach|
| Rush |Trailing foot dust and short motion streaks|Active movement only; behind shoulder/body; no forward projectile|
| Rush brake |Skid dust/brief steel sparks|At actual deceleration/contact, ending with recovery; harmless|
| Barrage |Per-impact burst/chips/dust and exactly3 pairs of waves|Three unique guarded contact events; intermediate reset poses are not impacts|
| Hurt |Brief local hit spark plus readable damage flash|Accepted damage only; no FX for dodge/invulnerability-rejected hit|
| Phase change |Cracked-reactor amber sparks/steam|One harmless transition; keep silhouette/tell readable|
| Defeat |Reactor shutdown smoke/last sparse sparks|Lethal event; every existing damaging effect immediately disabled/removed|

impact_fx.png and shockwave_fx.png are single static keys: create short impact/dissipation sequences or animate their separate nodes transparently. They do not replace vents, backhand trails, leap dust, rush dust or reactor smoke. Split large/small wave scale and collision intentionally; never scale a trail into damage geometry. Owner-tag every FX instance so reset/death/unload removes it. Render dust/trails behind actor where possible, bright crest visible above terrain. Optional subtle impact shake is cosmetic and must not change camera coverage or cause a seam reset; provide disable toggle.

Deliver an FX coverage table with asset/node paths, triggers and captured evidence for every row. Missing VFX is a remaining task, not an acceptable silent omission.

## Bind and actually exercise all supplied body poses

Create explicit animation resources/state bindings. Preloading a PNG is not evidence it plays. Do not replace walk/hurt with idle, tint alone or procedural body drawings when their supplied frames apply.

| State/clip | Required PNG keys in playback order |
|---|---|
| Idle |idle_01, idle_02 (loop)|
| Walking |walk_01, walk_02, walk_03, walk_04 (loop, initial cycle0.8s)|
| Smash |smash_crouch, smash_rise, smash_overhead, smash_downstroke, smash_impact, smash_recovery|
| Leap |leap_crouch, leap_takeoff, leap_airborne, leap_descend, leap_impact, leap_recovery|
| Backhand |backhand_tell, backhand_active, backhand_recovery|
| Rush |rush_tell, rush_active, rush_brake|
| Hurt reaction |hurt, then restore the appropriate locomotion/recovery pose|
| Phase2 entrance |phase_change|
| Defeat |defeat_kneel, defeat_final (hold final)|
| Barrage |Repeat the smash sequence with3 explicit impact events and a genuine final recovery|

Walking animation is selected from ACTUAL supported horizontal motion, not merely an AI intent: abs(velocity.x)>8px/s while grounded and outside committed attacks. If blocked or stationary, return to idle. The scheduler's None result is no attack intent, not 'always idle': implement the specified safe90px/s repositioning when waves are absent. Add a walk-only debug exercise that physically moves the boss across a safe span in each direction and asserts every walk key becomes active. Do not introduce unwanted combat movement just to make a test pass.

On accepted nonlethal boss damage in idle/walk/recovery, display hurt.png for0.12–0.15s using a temporary visual override. Preserve logical state, recovery clock and cooldowns; locomotion physics may continue. Restore the current state/pose after the override, not a stale idle state. During committed anticipation/active frames, maintain the necessary tell/contact pose, use a damage flash/spark and queue a short hurt-sprite override at the first safe recovery opportunity. This is attack superarmor, not damage immunity. A queued hurt override does not delay recovery or reset its timeline. Multiple hits refresh one visual override, never replay impact/spawn events. Lethal damage cancels queued hurt and immediately enters defeat.

Instrument actual frame changes with clip/key and timestamp. Force each state, and obtain an actual accepted hit during idle, walking, recovery and an active attack. Verify hurt key playback in eligible states and queued recovery playback after a surviving active hit. Confirm damage still registers during superarmor, effects spawn once, and death supersedes hurt. Report every supplied key used, including separate FX keys; explain/refine any deliberately replaced key. No unreported unused sprites.

## Vary player knockback by attack

Inspect the player's existing damage, knockback, gravity, input lock, invulnerability and collision handling FIRST. Reuse one accepted-hit pathway. Extend hit data with per-attack knockback values only where needed; keep baseline speed/jump/dodge and all unrelated enemies unchanged. Scope the new tuning to Ironback/test-scene hit profiles. Do not set global knockback to one fixed vector.

Initial world-space velocity targets (px/s), y upward-negative in Godot. These are initial tuning values, not forces applied each frame. Damage remains1 basic-hit equivalent for baseline moderate testing; physical impact strength differs independently of damage.

| Hit source |Horizontal launch magnitude|Upward launch magnitude|Input lock/hitstun ceiling|Impact tier |
|---|---:|---:|---:|---|
| Small landing wave |130|100|0.10s|Light|
| Large smash/barrage wave crest |190|150|0.14s|Medium|
| Hydraulic backhand |240|130|0.16s|Heavy sideways|
| Piston rush shoulder |280|120|0.18s|Heavy sideways|
| Bounding landing footprint |220|230|0.18s|Heavy upward|
| Single seismic fist footprint |260|260|0.20s|Very heavy|
| Barrage first/second fist footprint |240|240|0.18s|Heavy|
| Barrage final fist footprint |310|280|0.22s|Strongest|

Direction: waves push in THEIR travel direction; backhand/rush push in committed facing; local slam/landing footprints push outward from impact center toward the player at accepted contact. If exactly centered, use stable last relative side or committed facing, never a random sign or zero vector. Compute direction once at hit acceptance, not continuously while the source moves.

Apply ONCE after the damage receiver confirms an accepted hit. A rejected/dodged/invulnerable/duplicate impact causes NO damage, knockback, lock, hitstop or hit spark. Preserve once-per-impact deduplication across local footprint and both waves; do not let a player receive a small wave profile immediately after the same footprint. Route the profile from the actual source that was accepted. Overlapping source processing must have deterministic order (local footprint first on contact frame), not whichever signal happens to arrive first.

If the current controller already applies knockback, pass the profile through it or replace its per-hit vector in the same path; never add a second impulse outside it. Do not accumulate launch velocity every tick. Separate launch velocity from walk input so held directional input does not erase it on the next physics frame. Let the existing controller's gravity/collision recovery handle landing. If a combat knockback channel is absent, add a narrowly scoped accepted-hit override that uses normal body collision and restores ordinary input on its timer/landing; do not rewrite movement wholesale.

For an airborne target, avoid canceling a stronger existing upward arc with a weaker hit: vertical velocity=min(current_y,-launch_y) at accepted hit; horizontal combat launch is set to signed profile magnitude once. Cap this encounter's outward combat launch at320px/s and upward launch at300px/s; avoid modifying normal dash/jump velocity outside hit handling. Grounded launches must release floor adhesion for the actual launch tick so the y impulse is not swallowed by floor snap. Gravity remains1250px/s² or the controller's actual current value. Stop launch motion against real walls; never teleport or push through terrain. Player KO supersedes hitstun safely.

Respect existing post-hit invulnerability; do not shorten it to fit barrage. Hitstun is always shorter than the existing immunity duration and must not grow when several overlapping effects report the same hit. No chain-locking against arena walls. At edges, physics may reduce actual displacement; measure commanded impulse separately from traveled distance. Optional hitstop/screen shake can reinforce tiers but cannot substitute for knockback; if used, make one nonstacking cosmetic pause and preserve physics/event timing consistency.

## Required validation and delivery

Provide a test-scene move selector and attack-source-specific debug hit exercise using the real damage receiver. Test grounded AND airborne player hits for every profile; both directions; blocked wall launch; held movement input; duplicate/rejected hits; reset/death. Log attack source, event ID, accepted/rejected, requested vector, actual velocity, lock duration and resulting displacement. Assert magnitude ordering from profile table, not displacement ordering when walls intervene. Verify player control returns, normal jumps/dodges work afterward, and ordinary fights remain escapable with no guaranteed barrage follow-up.

Run real ordinary-damage playthroughs after these changes; stronger launches can change wave recontacts, camera coverage and punish windows. Keep the existing moderate tell/wave-speed/recovery baseline unless evidence requires tuning. Include a report of all sprite/FX bindings, knockback profiles, test outcomes and any remaining art cleanup. Missing frames may be supplemented, but walking/hurt coverage and all required VFX behaviors must be implemented, not merely listed.
