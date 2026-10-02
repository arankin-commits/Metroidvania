> Revision 2: Read IMPLEMENTATION_CORRECTIONS.md first. Its required VFX coverage, sprite playback bindings and attack-specific knockback supersede conflicting earlier guidance.

# Ironback: moderate-difficulty encounter specification

This is a proposed playable tuning profile. The included Python policy is executable attack-selection reference logic, not an engine-integrated boss. Difficulty must be judged in the real game with its actual controller, animations and damage rules. This file supersedes earlier timing/count proposals where they differ.

## Arena and player assumptions

Build a separate, opt-in test scene using the EXISTING player controller and combat receiver. Start with a 1400px-wide clear fighting floor, physical enclosing walls and substantial stone foundations. Recess background machinery; no foreground occluders, platforms or consumable progression gates. Camera must show boss anticipation and approaching waves at the active gameplay zoom. Do not solve camera coverage by shrinking the player or disabling normal jump follow.

Archive player baseline: speed255px/s, jump velocity-500px/s, gravity1250px/s², body28x46; normal jump rises roughly100px and lasts0.8s. Use basic ground dodge225px/s for0.17s; air/enhanced dash OFF for baseline tests. Preserve actual dodge/hurt invulnerability durations. At test start refill health and weapon resources only inside isolated test state. Do not mutate real save slots.

Start boss at arena center, player on a safe entry side roughly450px from boss body edge. Boss health24 basic-hit equivalents (basic hit1). All attacks deal1 basic enemy-hit equivalent; no instant kills. Target roughly60–100 seconds for a learning player and40–70 seconds for a practiced run; these are tuning goals, not measured outcomes. Do not add armor/invulnerability in charge, phase change or recovery. Attack commitment can resist stagger while still taking damage.

## Attack profile — world units

| Attack | Tell | Active / motion | Vulnerable recovery | Start cooldown |
|---|---:|---|---:|---:|
| Seismic smash |0.80s|Downstroke0.15s; local impact0.10s; spawn pair at0.95s|0.95s|2.50s|
| Backhand |0.50s|0.15s visible sweep, maximum95px beyond body front|0.75s|3.50s|
| Bounding impact |0.65s|Ballistic jump0.75–0.95s, travel at most420px; impact on actual landing0.10s|0.90s|6.00s|
| Piston rush |0.65s|340px/s for at most0.70s (238px), shorten for wall margin; brake0.20s harmless|0.80s|7.00s|
| Faultline barrage, phase2 |0.90s|Downstroke0.15s; impacts at1.05/2.30/3.55s; each local impact0.10s|1.10s after final impact window|12.00s|

Seismic total2.00s; barrage total4.75s. After complete recovery wait0.50–0.75s in phase1,0.35–0.55s in phase2 AND wait for owned shockwaves to disappear before any new attack. Walking during this wait must not crowd the player; default hold position while waves are active.

Cooldowns start on commitment. Animation holds, paused playback and visual interpolation do not restart them. Keep wave speed, crest height, tell times and damage the SAME after half health. Phase2 adds a familiar three-impact sequence and a modestly shorter decision pause, not hidden speed-ups.

Large wave initial travel360px/s, bright visible crest50px tall x56px wide; collision starts48px tall x28px wide INSIDE the bright leading crest. Small landing wave speed300px/s, crest36px tall, collision32px x24px. Adjust visuals to match resulting bounds. Main signature should look powerful through pose, wide spreading trails and sound, not an unjumpably tall hitbox. Wave directions are -1/+1, snapped to actual support; sweep collision so fast motion does not tunnel. Stop on arena walls or loss of supporting floor; clear by bounded lifetime5.0s as a failsafe, never let a damaging wave vanish unexpectedly before a reachable wall because a lifetime is too short.

Smash local hitbox initial width220px centered beneath fists, height60px above floor, damage only during impact0.10s. This is a starting envelope: register to visible fists/impact, not entire character rectangle. Small landing footprint initial width200px/height50px. Spawn waves just outside the local footprint, with visible crest origin and no invisible gap in the effect. Each impact has a unique event ID. A target can receive damage once per impact event across its local hitbox and BOTH waves; distinct barrage impacts are separate events. Use the player's existing hurt invulnerability too. Boss body has no always-on contact damage in this test scene; attacks own danger.

## Decision policy

Only choose in a grounded ready state. Distance is the horizontal gap between player and boss BODY EDGES, not centers or attack-effect rectangles. First attack is a full-tell single smash. Thereafter:

| Band | Eligible base weights |
|---|---|
| Close, gap<100px |smash65, backhand35|
| Medium,100..300px |smash75, rush25|
| Far,>300px |leap70, rush30|

Phase2 adds barrage weight22 at close/medium distance. Filter cooldowns, unsafe travel/landing and repeat limits before normalizing weights. No consecutive leap/backhand/rush/barrage; at most2 smashes consecutively. If filtering leaves nothing, walk or hold; never bypass cooldowns or force an unsafe move. Safe walking speed90px/s toward preferred body-edge gap180–240px, maintaining at least100px gap; movement uses real collision. No chase while waves are active. Safety probes operate on full boss body and proposed landing, not only one floor ray.

At tell START face the player's last known side. Lock facing until complete recovery. Backhand/rush direction never tracks or reverses midattack. Leap records the player's position at start of crouch and locks a safe reachable destination at takeoff; no tracking in air. Preserve at least boss half-width+32px clearance from physical walls. If no valid landing, do not leap. Walking may turn only with a small0.15s visible turn pause; never cause unavoidable rear attacks by instant turning.

At health<=50%, queue ONE phase-change until current attack/recovery finishes and waves clear. Phase change0.80s: cracked reactor/vent pose, harmless and damageable. Then phase2 selection begins. Lethal damage interrupts any phase immediately, disables all hitboxes, cleans waves, plays defeat and holds inert final frame. Do not heal boss on phase change.

## State ownership and animation events

WAIT -> WALK/READY -> ANTICIPATION -> ACTIVE -> RECOVERY -> WAIT.
ACTIVE for leap contains TAKEOFF/AIRBORNE/LANDING; ACTIVE for barrage owns three distinct impact events and intervening harmless lift poses. PHASE_CHANGE is queued between moves; DEAD supersedes everything. A separate FX owner tracks all spawned waves and impact IDs.

AI chooses an intent once; combat state machine commits direction/target, timer phases and attack ID. Body animations reflect that state. Have ONE source of truth for damage/spawn events: guarded timeline events or AnimationPlayer method tracks, not both simultaneously. Recovery starts after the actual active window; wave danger can outlive it while boss remains damageable.

An ordinary hurt flash must not cancel a committed move, restart its timeline or multiply wave spawns. Cancellation/reset/defeat removes owned effects and disables active areas. Reset returns health, phase, cooldowns, history, position, actor velocity and event guards to initial state. A bounded scripted timeout restores safe grounded state if leap/rush is obstructed; do not leave an active hitbox stuck forever.

## Moderate difficulty checks

Run manual ordinary-damage attempts with the baseline player. Confirm a single jump can clear the main crest from several distances and both directions; a jump started AFTER visible impact is feasible at medium distance. Close-range punishment comes from the local footprint, with enough0.80s tell to leave it. Barrage spacing1.25s permits landing and another normal jump; check BOTH directions and arena corners. A successful evade should expose at least one ordinary melee strike without trading damage. Watch jump-landing into boss during backhand/rush. Do not make the scheduler react instantly to jump inputs or read intended player commands.

If too hard: enlarge breathing/recovery by0.15–0.25s, reduce wave speed toward320, reduce barrage weight toward15 before changing controller. If too easy: reduce boss health only for excessively long fights; otherwise modestly increase attack choice pressure or health toward28, keeping tells and punish opportunities. Do not jump straight to extra projectiles, invulnerability or faster phase2 waves.

Automated integration: each impact spawns exactly2 waves; barrage exactly6 total/3 event IDs; no wrong-phase barrage; selection cooldown/repeat rules; no active tell damage; no floor tunneling; wall termination; damage once per impact; no attacks during old waves; cleanup on death/reset/unload; state reset and isolated save protection. Controller tests must use actual input, including both-side wave jumps, barrage cycles, leap evasion, rush wall approach and full fight. Invulnerability is suitable only for integration checks, not balance claims.

Debug test scene controls: reset fight, pause/step attacks, deterministic seed, force each move, show state/timers/facing/hitboxes/wave count, toggle baseline/earned dash and weapon loadout. These controls belong only in test scene/debug mode. Provide a report with tests, ordinary attempts, remaining art limitations and measured timings.
