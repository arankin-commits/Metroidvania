# Ground encounter specification — revision 3

## Physical rules

Use the same world, physics plane, and floor as the player. The root is a physics body; visual offsets accommodate artwork, never fake physical elevation. Align calibrated foot contacts to the floor. Keep the hurtbox around the actual body and bite/charge hitboxes separate. Ordinary body overlap causes no extra damage. During every tell and recovery the boss is vulnerable to normal melee; confirm the actual player's attack intersects it. HP is 24 basic-hit equivalents.

Suggested flat test arena width 1400 px with solid side walls; adapt scale to the existing player. Do not require a special room ceiling. Crawl at 80 px/s with ordinary acceleration, stop outside body overlap, and keep feet planted. Crawl and idle are harmless. Attacks commit only while grounded; falling off support uses gravity and cancels active damage. Floor-valid path checks use swept body extents, walls, ledges, and ground support, not screen coordinates.

## Moveset and moderate tuning

| Move | Tell | Active / execution | Recovery | Cooldown |
|---|---|---|---|---|
| Fang bite | 0.60 s, raised fangs | 0.14 s, reach 80 px beyond front; forward travel at most 35 px | 0.90 s | 3.5 s |
| Web ground charge | 1.00 s aim/crouch with clear horizontal lane cue | Harmless web hook travels at 900 px/s; charge begins only on confirmed wall anchor, moves at 420 px/s, path 260–650 px, at most 1.55 s | 1.15 s, grounded skid then exposed pause | 7.0 s |
| Silk snare | 0.80 s, abdomen pulse and visible floor placement cue | One harmless seed at release; arm after floor arrival plus 0.35 s deploy | 0.85 s after release; arming proceeds independently | 8.0 s |

Bite and charge each deal one basic-hit equivalent on an accepted hit. Charge has one damage ID for the whole traversal, not one per frame or animation. Bite damages only during its fang window. Snare deals no damage and never immobilizes.

Charge is a straight horizontal pull along the floor. Pick facing toward the player's horizontal position at tell start, show the lane, and lock direction, anchor, and endpoint. Player movement/jumping must not redirect it. Aim the web at an actual side-wall socket at spinneret height, not at the ceiling or player. The boss can stop before the wall anchor: cap traversal at 650 px and leave its full body safely inside the room. The visible cable remains connected until the skid finishes, then dissolves. Anchor flight timeout 1.6 s; if the hook fails, execute a harmless 0.60 s abort recovery. Never leave the boss waiting forever. If the room has no suitable side-wall anchor, charge is ineligible; use crawl, bite, or snare.

Permit charge only when horizontal body-edge gap is at least 180 px and the floor path permits at least 260 px. If travel would pass through an armed slow trap, exclude that charge path: do not force a slowed player to evade the fastest attack. On wall obstruction, lost floor support, or arrival: disable charge damage immediately, stop horizontal pull, then recover without teleporting. A wall does not create a second impact attack.

Calibrate charge attack height to the existing jump: leave a tested gap under the airborne player at the crossing. Existing reference player jump rise is about 100 px; if the actual full-height hurtbox makes jumping impossible, author a lower charge pose and lower attack region rather than changing the player jump. Validate this with the real controller before finalizing the 420 px/s speed. No dash or bow is required.

Snare placement is visible and fixed at tell start, on floor 80–240 px ahead of the boss, optionally biased toward the player's then-current position. Exclude spawn/door pockets and preserve a safe escape side. Maximum 2 traps in phase 1, 3 in phase 2, including reserved and deploying slots. Width 100 px, minimum center separation 160 px, lifetime 8 s from arming. Revalidate before placement; on failure release the reservation and finish harmless recovery. No silent substitution or instant trap at the player's updated position.

Trap Area2D overlaps the actual floor and player's body layer. Handle overlap after arming and while staying inside. Grounded ordinary walking multiplier is 0.70, nonstacking, refreshed at most every 0.5 s with 1 s linger. Jump, gravity, airborne movement, dash, and combat knockback retain their existing behavior. Remove the source-owned status on death, reset, and unload.

## AI scheduling

At body-edge gap <=120 px: favor bite 65 / snare 35. At 120–179 px: favor snare, otherwise harmless crawl. At >=180 px: charge 60 / snare 40, filtered by validated safety, cooldown, and trap slots. No consecutive charge or snare; at most two consecutive bites. After charge, complete the entire 1.15 s recovery and force the next offensive commitment to be bite or snare; crawling to reach bite range is allowed. Never shorten the recovery to chase the player.

After three non-snare commitments, prioritize snare at the next safe eligible opportunity, still respecting cooldown, repeat limits, and trap caps. Idle/crawl does not increment this counter. If no action is eligible, return harmless crawl/idle; do not bypass limits. Cooldowns start on commitment; choose only after full recovery and a 0.55–0.80 s decision pause. Phase 2 (<=50% HP) queues a grounded 0.85 s transition after the current full recovery, remains vulnerable, increases trap cap to 3 and favors charge 70 / snare 30 at range. Familiar speeds/tells and the decision pause remain unchanged; no double charge.

The engine executor owns physics, animation events, actual hook completion, hit acceptance, recovery, and cleanup. It calls policy.finish() once after recovery, including abort. Log eligibility/rejection, physical support, current action, attack ID, trap slots, and slow multiplier.

## Test scene acceptance

Force bite, charge, snare, hurt, phase change, and defeat separately; then run normal AI. Verify floor alignment at every pose, working grounded walk animation, real melee HP loss, both charge facings, successful jump dodge with no dash, cable socket distance <=2 rendered px, walls/ledge cancellation, failed-hook timeout, one charge hit maximum, distinct knockback, full recovery, snare arming under an already-overlapping player, 70% walking speed, and death/reset cleanup. Do not regard policy unit tests as engine-scene verification.
