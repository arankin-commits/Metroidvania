# Boss combat and reward revision

All routes and arena shells are unchanged. The three simplified encounters now
implement the user's goblin/scimitar, forest archer and stone guardian brief.
The forest/temple actors use native drawn pixel silhouettes and phase-driven effects.
The Cave Boss now uses the user's supplied character direction in a registered
generated sprite atlas; see [Cave Boss art review](cave-boss-art.md).

## Progression and controls

Before the forest boss: basic ground dodge225px/s for0.17s; no air dash.
After victory: enhanced ground dash450px/s for0.17s and air dash780px/s for0.23s.
Defeat state overrides old saves' unconditional has_dash=true value.

| Reward | Controls |
|---|---|
| Goblin Scimitar |1 equip; J/X swing; U thrust|
| Bow |2 equip; J/X or L shoot; U flipping volley|
| Stone Gauntlet |3 equip; J/X punch; U beam; hold/release U stronger rapid fire|
| Charged wall breaking |Hold/release H after cave victory; no bottom-left slot|
| Air/enhanced dash |K/Shift after forest victory; no bottom-left slot|
| Will of Wrath |Passive after cave victory; actual damage triggers its bonus|

The HUD shows the equipped weapon and weapon ability. The menu describes owned
and locked weapons/abilities separately from passive Wills. Hand meditation refills
bow ammo; the two unspecified forest/temple Wills remain unspecified.

Initial balance choices: Wrath+25% for4s, refresh without stacking; basic damage1,
wind0.5; basic gauntlet beam1, four charged beams2 each; flipping volley spends one
ammo charge. These are tunable defaults. Invulnerability rejected hits do not grant
Wrath. Fractional damage is kept in health and status display.

## Encounter behavior

- Goblin: jump slam closes distance; two swings/thrust/spin or three swings/long
  overhead at close range; thrust/swing at mid-range; charged swing emits wind.
- Hunter: three scouts per summon wave, charged arrow, five-arrow burst, three-hit
  arrow knife, retreat air dash; below half health a cooldown-controlled dash over
  the player fires three targeting arrows constrained to downward travel.
- Guardian: fast returning chain fist, wrist-braced charged large projectile,
  three punches or slam. The first half-health phase introduces firing. Subsequent
  ranged choices below half health are randomized between fist and firing; close
  choices remain randomized. Charge immunity ends exactly on projectile launch.

Boss and projectile phases own tell/active/recovery timing. Friendly and enemy
damage uses each boss's shared combat_bounds so melee and projectile reception
agree with its body silhouette rather than using separate legacy rectangles.
Friendly and enemy
projectiles sweep their motion, respect solid terrain, and clean up on encounter
deactivation/defeat. Summons have spawn clearance, attack grace and arena bounds;
one living wave prevents unlimited accumulation. Death resets queued attacks and
phase protection. Saves preserve rewards/loadout through cave/forest travel and
retain the last activated hand.

## Verification

Passed boss_combat_smoke, forest_preboss_smoke, gallery_playthrough_smoke,
forest_final_concourse_smoke, forest_regression_smoke, cave_rooms_smoke,
save_slots_smoke and menu_smoke. Combat fixtures grant invulnerability to isolate
encounter integration, so these checks do not establish final difficulty balance.
Some existing tests report resource cleanup warnings after PASS; Windows log and
certificate access messages are unrelated to gameplay assertions.

Pre-boss room traversal uses actual input with air dash disabled. Forest Sections
1–11 and their return route pass. The highest9.2/10.2 galleries remain an earned
dash test; their floor route reaches Section11 before the boss. The existing Refuge
basin ledges permit ordinary jumps before the direct air-dash crossing is earned.

Running-game scenario review completed and screenshots were inspected:
[goblin overhead](boss-combat-goblin-overhead.png),
[wind swing](boss-combat-goblin-wind.png), [jump slam](boss-combat-goblin-jump.png),
[hunter summons](boss-combat-hunter-summons.png),
[rapid fire](boss-combat-hunter-rapid.png), [volley](boss-combat-hunter-volley.png),
[guardian charge](boss-combat-guardian-charge.png),
[guardian fired](boss-combat-guardian-fire.png),
[gauntlet HUD](boss-combat-gauntlet-reward.png).
