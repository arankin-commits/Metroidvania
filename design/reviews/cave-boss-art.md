# Cave Boss character art (2026-09-28)

The Cave Boss now follows the user's supplied charcoal ape-like goblin, skull face
armor, red eyes, leather bindings, burgundy cloth and chipped scimitar design.
The current arena, routes, body bounds, damage and rewards are preserved. The later
momentum revision below changes active movement and dash-thrust duration.

Runtime asset: [cave_goblin_atlas.png](../../assets/characters/cave_goblin_atlas.png),
1152x1152 RGBA per facing, 16 poses each. It is a compact pose animation set, with idle breathing,
different anticipation/active/recovery silhouettes, tucked leap and landing crouch.
Walk/stride poses are available in the source atlas but no new locomotion AI was added.
This is not a fully inbetweened frame-by-frame walk/run cycle.

The generated sheet did not honor its requested pixel dimensions, grid margins or
transparency: initial versions baked a checkerboard and let blades cross cells.
They were rejected. The accepted matte source is 1254x1254; measured crop regions
and anchors in [build_cave_boss_atlas.gd](../../tools/build_cave_boss_atlas.gd) remove
its magenta background, isolate each complete pose and register at a shared scale
and foot pivot. Tiny neighboring blade fragments were excluded from two crops.
The final runtime PNG has real transparency and nearest-neighbor sampling.
Feet register at local y47, matching the existing ground at boss home_y553.

[scripts/goblin_boss.gd](../../scripts/goblin_boss.gd) selects poses by combat phase;
second swings use a reverse pose, thrusts extend forward, overheads raise then lower
the sword, spins reach both sides, and the leap tucks the legs before landing.
Slash/impact effects use the authored damage rectangles; the base combat controller
still owns damage and vulnerability. Opposite character facings are authored separately;
only directional combat effects are reflected. Body bounds remain unchanged.

Verification passed:

- cave_boss_art_smoke: actual alpha, complete isolated cells, grounded foot stability,
  attack pose registration and unchanged directional hit/body bounds.
- boss_combat_smoke: actual input, all original attacks, half-damage wind, reward/save
  progression, weapon abilities and denied early air/enhanced dash. The test now
  waits for scene_changed rather than assuming three physics frames establish a
  completed scene replacement; the original timing race produced a null scene.
- Existing running-game boss_combat_visual completed in inactive slot0 without failure.
  Updated [overhead](boss-combat-goblin-overhead.png),
  [wind](boss-combat-goblin-wind.png) and [leap](boss-combat-goblin-jump.png) were inspected;
  further live reviews inspected right-facing thrust, left-facing spin and landing.
- Local Web export rebuilt: 68,499,304 bytes (68.499 MB), 281 packed entries and 142
  audited resources. All 61 previous live media resources remain byte-identical;
  the new atlas is included, while design references and tests remain excluded.

## Momentum and handedness revision

Wind-scale correction: increased the bright wind slash from65x36 to195x108,
approximately the boss's standing height. The dim rear curl is300x108; its lower
edge and the main crest stay above the floor at launch. Contact radius scales
18->54, while speed440 and half damage remain unchanged. Solid-wall casts start
at the bright leading crest. Reviewed the enlarged effect in both travel directions.

Reference-fidelity/contact correction: contact damage was missing entirely; an
active living Cave Boss now checks its body against the player every physics tick,
using normal1-damage knockback/i-frames. `goblin_contact_smoke.gd` walks into it
from both sides and verifies protected/inactive/dead behavior. Anticipation tests
now stand outside the body while testing the harmless attack windup.

Built-in imagegen authored `cave-boss-effects-matte.png` from the supplied wind and
charged-release close-ups: isolated ivory smoky curled wind on the left and a thick
ivory-peach/crimson charged C-sweep on the right, pure magenta matte, no actor/UI.
Prompt required layered ragged pixel strands and red inner streaks rather than a
flat vector ring. Delivered source2056x765 was inspected and measured; reproducible
matte decontamination/crops are in `tools/build_goblin_effects.gd`. Runtime wind
and charged-wake textures live in `assets/effects/`. This replaces the procedural
charged band, preserves normal-strike effects, and keeps wind's radius18/half damage.
Transparent alpha and matte removal are verified by the FX smoke test. Both views
are captured with separate wind/charged-release frames at gameplay scale.

Combat-effects correction: the orange hitbox-outline rejection never prohibited
reference-style afterimages/dust/wind. `goblin_combat_fx.gd` now provides tapered,
filled, frayed three-layer blade wakes differentiated by attack trajectory, fading
actual directional actor poses, rearward foot dust and ballistic dust/stone/red
impact flecks from the landing plane. Wind gained layered ribbons and broken edge
highlights around its unchanged contact core. Effects have capped counts/lifetimes
and clear on reset or inactive/dead encounters; they add no collision or damage.
`goblin_fx_smoke.gd` verifies release/ghost/lifetime/ground/reset behavior. Expanded
live captures include both facing spins and slam impacts.

Weighted charge revision:1.3s build;64px cubic-eased burst over0.12s;0.08s release
hold;0.18s low follow-through;1.05s recovery. Landed melee adds0.055s boss-only
contact pause, cleared on reset. Existing charge tell/heavy attack audio cues align
with windup/release. Aura ramps late, flares strongly, then decays during the hold.
Damage and projectile rules remain unchanged. Contact/miss/reset/world-time checks
extend the existing momentum test; full combat regression passes.

Charge-aura correction: removed the detached red anticipation arc. A layered red
aura follows measured steel outlines in each facing's cells4/5, behind the weapon
art. It grows during charging and flares ivory-red on release only. Live inspection
covered anticipation and release in both directions; collision/damage remain unchanged.

Follow-up correction: removed generic orange slash arcs, spin rings, thrust wedges
and preview lines. They visualized damage bounds rather than the actual blade's
motion and repeated across dissimilar attacks. Melee now reads through the sprite
and forward movement; charged anticipation, wind projectile and landing impact remain.
The damage and movement code is unchanged; combat regression passes.

Thrust is now a140px dash over0.22s; swings step28px, overhead44px and spin32px.
Charged swings step36px. Anticipation shows the full advancing reach; wall casts
limit grounded body motion and swept active melee prevents skipped contacts.
Wind now has an ivory crescent and two subdued gray wakes; radius18, speed440
and half damage remain unchanged. The player's rewarded ability was not changed
because the active request discusses the boss.

Both facing sheets are independently authored. Right overhead anticipation reuses
the verified raised-left-arm cell4: generated cell10 was rejected for switching
shoulders. Do not blindly import all sixteen requested cells. Both atlases pass
alpha, gutter and foot tests. The actual arena was reviewed in both directions,
including dash thrust, overhead, charge and leap; screenshots are named
`cave-boss-left-*` and `cave-boss-right-*`. `cave-boss-wind-detail.png` shows the
contacting crescent. Momentum and complete combat/progression regression checks pass.

Generation brief for this revision (built-in imagegen; user sheet and old atlas as
references):

```text
Edit the supplied goblin sprite atlas. Reference image1 is the current atlas identity and pose order; image2 is the user's character reference. Preserve charcoal ape-like goblin, bone skull face armor, red eyes, chipped heavy curved scimitar, fur, brown bindings, burgundy cloth, crisp pixel art. The character MUST ALWAYS grip the scimitar in its ANATOMICAL LEFT HAND across all 16 poses, with a burgundy cloth wrist wrap on the weapon-bearing left wrist and plain brown bindings on the free right wrist. The right hand stays empty, no two-handed grips, no switching the blade between arms. Draw the complete weapon in EVERY cell including crouch. Preserve the same armor/strap asymmetries rather than exchanging left and right sides.
Production sheet: exactly 4 columns x4 rows, equal cells, square canvas. Flat pure magenta #FF00FF background for keying, no checkerboard/no gradients/no shadows. Characters and all blades fully isolated within their individual cells with at least25px empty magenta gutters. Same body scale and foot registration across poses, no neighbor fragments. Body mass about200pixels tall in each 320-ish cell, extended blade/raised arm may go taller. No text,labels,grid,scenery,UI,moon,sun.
Pose order reading order: row1 idle, idle breathing, strideA, strideB; row2 high-back swing anticipation, forward slash, low-back reverse anticipation, rising reverse slash; row3 retract horizontal scimitar to hip anticipating a dash-thrust, active dash-thrust lunging forward with left arm/blade straight ahead and right fist pulled back, one-handed left-arm overhead anticipation, one-handed downward overhead strike in crouch; row4 spinning slash left arm extended sideways, deep jump-anticipation crouch with scimitar visible in left hand, airborne knees-tucked left sword raised, deep landing crouch with left blade low. Each pose must show the same left wrist gripping the hilt and the right fist visibly free. Fix anatomy, not merely screen-space weapon position.
```

Directional refinement: right-facing characters use the designated left weapon
arm; left-facing characters show the other side of the same left-handed character,
not a reflected right-handed one. Follow-up edits explicitly traced the weapon
shoulder, removed extra arms, left the opposite fist empty and corrected the
raised-arm side in right cell4. Generated output still required individual-cell
inspection and rejection/reuse; wrist-color instructions alone were insufficient.

No browser playtest or final difficulty balancing is claimed. The existing tenets
for foreground occlusion, clear combat lanes and unchanged movement still apply.

Built-in imagegen was used, not the CLI fallback. The original character reference
is [cave-boss-design-sheet.png](../references/cave-boss/cave-boss-design-sheet.png).
The current sources are [right-facing](../references/cave-boss/cave-boss-right-matte.png)
and [left-facing](../references/cave-boss/cave-boss-left-matte.png). The older source
and prompts below document the initial iteration, superseded for handedness.

Initial generation prompt:

```text
Use case: stylized-concept. Asset type: production 2D pixel-art game character sprite atlas.
Image 1 is ONLY the user's character identity and attack-pose reference. Create a NEW clean transparent sprite sheet for this SAME large ape-like goblin with scimitar. Charcoal gray muscular skin, dark coarse fur on hunched back, long gorilla arms, short weight-bearing legs, snarling bone skull face armor with tusks and red eyes, worn brown leather bindings, ragged burgundy loincloth, heavy chipped curved scimitar. Preserve that design, no green cartoon goblin.
Output a square 2048x2048 atlas, exactly FOUR columns and FOUR rows, 16 equal 512x512 cells. One complete separate character per cell, all facing RIGHT. Genuine transparent background with alpha, NO checkerboard painting, NO scenery, NO text, NO grid, NO labels, NO floor, NO shadows, NO moon/sun. Crisp deliberate pixel art, NOT soft painted blur. Same character scale in EVERY cell; torso/legs about 220 pixels tall from shoulder to feet, body about 200 pixels wide. Body pelvis centered on cell x210; ground contact baseline y440 except airborne poses whose feet use the same sprite pivot. Every scimitar tip stays within its own cell with generous transparent gutters. Weapon is clearly attached to the SAME hand and anatomical limbs; no duplicated limbs. Strong differentiated readable pose silhouettes.
Cells in exact reading order:
row1: (1) idle hunched stance scimitar held low forwards; (2) idle breathing shoulders slightly raised; (3) locomotion stride left foot forward; (4) locomotion opposite stride right foot forward.
row2: (5) swing anticipation blade pulled high back over shoulder; (6) swing active broad forward slash blade extended right around chest height; (7) second reverse swing anticipation blade below/back; (8) reverse swing active scimitar forward/up.
row3: (9) thrust anticipation low stance blade pulled near hip pointing right; (10) thrust active full forward extension blade horizontal; (11) overhead anticipation two-handed blade raised straight high overhead; (12) overhead active deep crouch blade slammed forward/down.
row4: (13) spin active torso turned with sweeping blade extended right; (14) jump anticipation deep compressed crouch; (15) airborne jump knees tucked scimitar raised overhead; (16) landing impact broad deep crouch scimitar low to right.
No slash glow, no trails, no particles baked into frames: these will be tied to actual hitboxes by the game. Transparent isolated character sprite frames only. Keep the body registration stable so animation doesn't jitter.
```

Transparency/weapon correction prompt:

```text
Edit this sprite atlas for production use. Preserve this exact charcoal ape goblin identity, scimitar, pixel art detail, 4x4 arrangement, every distinct pose and same body size. REMOVE the gray-white checkerboard entirely: outside character silhouettes must be genuinely transparent alpha, not a painted checkerboard and not opaque white. Ensure exactly 16 complete separate characters in 4 rows and 4 columns with generous EMPTY transparent margins so no character or blade crosses the boundary into an adjacent cell. Restore the large chipped scimitar in the right hand of row1 column2 (idle) and row1 column4 (stride); every single pose must carry the same scimitar. The sheet should have no scenery, no text, no labels, no floor, no shadows, no moon/sun. Preserve full character and blade silhouettes, opaque bark/fur/skin/metal interiors, alpha transparency outside, without halos. Output transparent PNG RGBA sprite atlas.
```

Final accepted matte/gutter correction prompt:


```text
Production correction of this 4x4 sixteen-frame goblin sprite atlas. Keep ALL sixteen distinct poses and the same bone-mask red-eye charcoal ape goblin character and chipped scimitar. First change: replace ALL checkerboard with a completely uniform PURE MAGENTA #FF00FF flat background, no checkerboard anywhere, no shadows or gradients. This is a chroma matte for deterministic alpha extraction. Second change: fit each complete character AND full blade inside its own one of 16 equal square cells with at least 25 pixels magenta margin around the whole character/blade. Scale all characters down equally to leave those gutters, preserve same scale across all cells and consistent foot baseline in each row. Every blade tip must remain in its own cell, especially row2 column2 swing and row3 column2 thrust. Third change: row1 column4 walking pose MUST visibly carry a complete scimitar by its hilt in its front/right hand pointing forward/down, just as idle pose does; do not leave any character weaponless. No clipping. No grid lines, no text, no UI, no scenery, no sun/moon. Crisp pixel art. Exact 4 columns by4 rows matching input poses. Output PNG.
```
