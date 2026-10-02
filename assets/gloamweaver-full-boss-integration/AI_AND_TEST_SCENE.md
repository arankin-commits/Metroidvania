> Revision 2 (2026-10-02): Read INTEGRATION_FIXES_V2.md first. Shared gameplay registration, continuous web sockets, swing/zip/drop motion VFX and guaranteed safe snare opportunities supersede conflicting earlier guidance.

# The Gloamweaver â€” spider boss encounter

Original boss design and test-scene handoff. All numbers are moderate-difficulty starting targets, not measured balance. Follow this file and ANIMATION_VFX_AND_IMPACT.md alongside the current project's room/art memories. This task authorizes an isolated test scene, not an existing-room redesign or progression reward.

## Character and encounter purpose

An enormous eight-legged spider with dark plum/charcoal abdomen, ivory chitin joints, restrained violet highlights, four magenta eyes and visible spinneret. Its long legs grip ceilings; its heavy abdomen hangs below them. Pale ivory/violet silk contrasts with the teal traveller and amber heavy-gate cracks. Keep the creature purely arachnid, without humanoid anatomy or unrelated elemental attacks.

Movement identity: ceiling crawler -> hanging pendulum -> straight grapple zip -> temporary floor snares. The player learns to read the silk anchor and committed trajectory, move clear of the attack, and strike during LOW recovery. A melee-only player must have regular real punish opportunities; do not make the encounter depend on bow/ammo or earned air dash.

## Arena and controller baseline

Start with an opt-in, physically enclosed 1400px-wide room, clear flat floor, and continuous solid ceiling roughly560px above it. Use the actual player controller, camera and damage receiver. Suggested local interior x100..1500, ceiling y60, floor y620; change registration consistently if the game's normal scene conventions differ. Quiet recessed ruined forest architecture and sparse silk in background; no foreground combat occluders, bright false platforms or suns/moons. Floor/ceiling/walls use matching rendered/collision contours and full-body containment. Camera exposes the approaching spider/tether/zip target before damage. Inspect ceiling art at gameplay zoom, not only overview.

Archive baseline speed255px/s, jump-500px/s, gravity1250px/sÂ², body28x46. Basic ground dodge225px/s for0.17s, earned air dash OFF for baseline testing. Preserve actual controller values if they have changed. No normal movement/hitbox changes to fit this boss. Boss initial health24 basic-hit equivalents; attacks1 basic-hit equivalent; traps cause no damage. Balance goals60â€“100s for learning player,40â€“70s practiced, to be measured. Start boss attached at x850 ceiling, player safely at x300 floor. No entry attack until player control/camera is ready and a full visible tell can play.

## Moveset

| Action | Tell and commitment | Active behavior | Vulnerable recovery / cooldown |
|---|---|---|---|
| Ceiling crawl |Short visible leg turn before reversal|Eight-leg contact cycle; speed90px/s; physical underside tracking|Harmless, damageable; no contact damage|
| Pendulum rake |0.90s, attach visible silk to measured ceiling anchor; extend legs to show sweep|Real tether swing, roughly1.10s pass; damaging leading leg/fang sweep ONLY for0.22s near low crossing, matched to visible contact; no damaging cable|0.90s LOW settle with body reachable by ordinary jump/melee, then0.60s retract; cooldown4.0s|
| Grapple zip |0.85s aim, visible destination anchor pulse and committed straight-line corridor; hook shot then taut cable|Hook speed900px/s; stop at first valid ceiling/wall anchor; boss follows exact anchor segment at600px/s, max distance1300px/max travel2.2s; active front/body area only while visibly traveling|Arrival legs catch and settle0.80s; cooldown6.5s; zip is primarily repositioning|
| Silk snare |0.80s spinneret curl; preview chosen floor patch before release|A harmless visible silk seed travels to floor; trap deploy0.35s with no slow until armed; floor patch100px wide|0.80s settle; cooldown8.0s; no damaging drop/projectile|
| Committed drop |0.90s legs gather plus a clearly marked landing footprint|Release grip and drop under actual gravity toward locked safe floor target, horizontal travel at most180px; local impact active0.12s on actual landing, not timer|1.15s exposed FLOOR recovery; cooldown6.0s|
| Fang bite |0.55s front legs brace/fangs lift; lock facing|0.14s short lunge, visible reach80px beyond front; bounded50px body travel|0.85s floor recovery; cooldown3.5s; no immediate bite after landing|
| Frayed double swing, phase2 |1.00s distinct silk fraying/paired leg lift tell|Two regular rakes, each0.22s active; harmless visible higher lift/reversal between; low crossings at least1.25s apart|1.20s LOW final settle,0.60s retract; cooldown11.0s|

Every recovery is damageable; no hidden armor or invulnerability. Attack superarmor means animation commitment survives a hit while HP still decreases. Telegraphs do no damage. Damage is owned by attack phases, not generic whole-body contact.

## Ceiling, swing and zip geometry

Use explicit anchors with full-body clearance, not raw viewport corners. Example ceiling endpoints x220/x1380 beneath ceiling y60. Crawler's contact feet follow actual underside normal and maintain stable leg anchors; an idle floor frame flipped upside down is insufficient. Place body below ceiling with a measured visual/physical grip offset. Attach/detach operations clear vertical motion and preserve collision; never snap the boss through walls or reparent its physics body carelessly.

Pendulum: fixed physical ceiling anchor, stable rope length selected before tell. Choose a path with full spider clearance, endpoints in arena, low point reaching an actual player-height lane. Use a constrained angular trajectory or tested rope solver; do not fake a straight diagonal with a curved painted string. Suggested swing length420â€“460px for the560px ceiling gap, adjusted to measured boss size so its active front-leg reach approaches floor while its body does not penetrate ground. Track body AND legs/collider sweep at samples along the entire arc. The0.22s window belongs to the actual low crossing; if contact geometry does not fit, correct the path/art. Low recovery holds body/fangs within normal jump/melee reach. No damage on retract or reversal.

Zip: aim hook at the OTHER usable end's ceiling/wall anchor, commit source/destination/facing after the tell. Raycast plus swept full-body segment check; the hook sticks to the first valid solid anchor, never traverses a wall to a desired coordinate. Use the actual anchor segment, not teleport/curve/homing. Check departure/arrival body clearance and reachable endpoint. Clamp destination before commitment. If unsafe, choose crawl/swing/drop; never perform an invisible teleport fallback. Hook head/cable are harmless. Zip's visible moving front owns its contact attack and pushes along horizontal travel direction; no damage before taut-cable travel starts or after arrival. Most ceiling-to-ceiling zips may be harmless repositioning because their corridor is above the player; that is acceptable if low punish cadence remains enforced.

Avoid attacks from offscreen: preflight camera visibility of tell, low swing lane, drop target and zip endpoint; reposition harmlessly or extend test-camera coverage when necessary. Do not read player input or retarget during an active attack.

## Slowing traps

Silk floor patches are physical nonblocking Areas/effects, not terrain colliders. Seed and deployment are harmless. Active patch slows only GROUNDED ordinary walk/run speed to70% for a lingering1.00s after leaving. Jump height, gravity, dodge/air-dash speed, damage, attack rate and input responsiveness are unchanged. Airborne player movement is not slowed. If the baseline controller lacks a status hook, add a source-tagged speed multiplier adapter with1.0 default; do not rewrite movement.

No stacking: all Gloamweaver traps share a single slow status, effective multiplier0.70; concurrent patches never multiply. Reentering an existing patch may refresh status only once per0.50s; no stronger slow or immobilization. Player still controls movement and can jump/dodge out. Slow clears immediately on death/reset/scene exit. Remove only this boss's source, not other effects. Restore walk speed naturally on airborne state or after the linger timer; don't restore it by overwriting controller constants.

Patch lifetime8.0s from arming; phase1 cap2, phase2 cap3, counting both deploying and armed patches. New trap cooldown8.0s at commitment. No refresh/relocation of already placed traps. Each destination has>=160px center separation from another, is>=180px from spawn/doors and>=100px from walls. Place at a committed recent player POSITION, not their future input; find nearest valid safe floor patch within180px of that snapshot or skip the move. Total patch coverage stays<=300px of1400px floor; leave at least one continuous160px clear floor pocket and a safe evasive path. Do not place a patch directly on a scheduled drop/rake landing or make a snare-to-hit unavoidable combo. Traps do not immobilize, damage, grapple the player, or persist into saves.

## Selection and pressure limits

Use ai/gloamweaver_ai.py as selection reference, ported into the existing engine. Evaluate only in ready after all attack recovery completes. Gap means horizontal BODY-edge separation; floor/ceiling status comes from actual support.

Ceiling phase1 weights: swing60, zip20, trap20 when near/medium; at far gap>360 use swing35,zip45,drop20,trap20. A safe ready trap gains priority after3 other committed combat actions; preserve the first-swing lesson and required low-punish action before this priority. Counter resets on trap commitment/reset. See INTEGRATION_FIXES_V2.md for ordinary-fight snare acceptance and diagnostic requirements. Phase2 near adds double_swing20, keeping tell/velocity/damage unchanged. Filter cooldowns, support, path safety, trap limits and repeat rules BEFORE normalizing. No consecutive zip/trap/drop/bite/double swing; at most2 single swings. Floor close gap<=120: bite60,reattach40; floor farther: reattach only. Reattach is harmless physical return via validated hook route with visible cable, then arrival settle; no teleport. Avoid spending whole fight on floor or ceiling without the required recovery rhythm.

First action is a full-tell single swing if geometry is safe; otherwise harmless crawl until it is. At most ONE zip/trap reposition in succession: after it, force an eligible swing/drop/double swing that gives a low punish opportunity. If all eligible moves unsafe/on cooldown, hold/crawl safely rather than violating this rule. Traps do not block all attack selection the way Ironback waves did, because they are temporary nondamaging status patches; active zip seed/hook remains owned by current busy state.

Wait0.55â€“0.80s after complete recovery in phase1,0.45â€“0.65s in phase2. During ordinary ceiling gaps move slowly to improve a valid swing position, not endless chasing. On floor no instant turn-bite; visible turn0.15s, then full tell and facing lock. Always wait full breathing interval after drop; never chain impact into bite while player is stunned.

At HP<=50%, queue exactly one harmless0.85s frayed-silk transition AFTER complete recovery at stable support; remaining traps stay under ownership with their original TTL, phase cap rises3. Gain double swing, not faster familiar attacks or extra damage. Death supersedes every state instantly: disable attack areas, detach/clear threads, remove seeds/traps/status sources, disable movement damage, play floor-safe defeat pose and inert final state. A ceiling death falls under actual containment/gravity harmlessly before collapse; never leave a live trap or damaging falling corpse.

## Integration ownership and acceptance

State machine: READY/CEILING_CRAWL -> TELL -> SWING/ZIP/SEED/DROP/BITE -> RECOVERY -> READY, with ATTACH/REATTACH states and queued PHASE_CHANGE; DEAD supersedes all. One authoritative guarded event source controls hooks, trap seeds, contact windows and VFX. Animation playback cannot spawn duplicates on holds, hurt flashes or state reentry. Timers/cooldowns do not restart because a visual hurt overlay plays.

Build a runnable opt-in test scene with reset, seeded runs, forced actions, support/anchor/tether/zip corridor inspection, hitbox/status visualization, weapon/dash toggles and slow timer display. Use isolated save root/inactive slot; no production progression flag/reward. Existing room layout and controller stay intact. No invented inherited Will is required.

Run actual input tests: ceiling crawl/turn both directions without popping; valid pendulum arc and ordinary jump/dodge evasions; jump-melee damage in every low recovery; straight zip/correct anchor/blocked path denial; drop safe landing/cancel cleanup; trap arming, bounds, nonstacking, grounded-only slow and jump escape; two swing pass escape; all hurt/walk sprites in real playback; attack-specific knockback; defeat/reset/unload statuses and effects gone. Check packaged sprite alpha and registered anchors, camera extremes, both directions and actual hit windows. Scheduler tests alone and invulnerability fixtures do not establish moderate difficulty. Ordinary-damage learning/practiced runs determine tuning; adjust recovery/decision pause and trap count before speeding attacks or restricting player control.
