# Rabbit Boss Room Design Guide

This boss is built around fast, vertical, and surface-driven pressure. The room should support a boss that spends time on the ground, jumps aggressively, and can cling to climbable walls before lunging again. The goal is to make the boss feel like a hunter that uses the arena geometry instead of a simple wall-to-wall melee enemy.

## Boss identity

The rabbit boss is not a heavy bruiser. It is a mobile, opportunistic predator with:

- quick ground approaches
- decisive pounce attacks
- wall-climbing pressure
- a clear warning before a high-speed attack
- a repeated cycle of approach, leap, climb, and reset

The design should emphasize momentum, verticality, and repositioning, rather than long stand-up trades.

## Current prototype behavior

The isolated prototype in [scenes/rabbit_boss_test.tscn](../../scenes/rabbit_boss_test.tscn) currently includes the following implementation details:

- The six rabbit pose PNGs have transparent backgrounds; only the sprite artwork is rendered.
- The boss has a body collider and a `combat_bounds()` rectangle for player attacks.
- The test scene uses the real player controller and the project HUD. The HUD shows player health, boss health, the boss title, pounce warnings, hit/miss feedback, and blocked-hit feedback.
- The boss stops completely while preparing its pounce. The red warning line and preview mark the attack lane during this stationary telegraph.
- When the pounce begins, the boss keeps its forward momentum, receives a small upward movement arc, and lifts its sprite 8 pixels so the pounce pose is visually distinct from the ground poses.
- A pounce can damage the player once on contact. Player invulnerability and knockback use the existing `player.gd` damage behavior.
- The boss actively seeks a nearby climbable surface, jumps toward it, clings briefly, then returns to the arena after a short re-grab cooldown. The wall must be a real collision object in the `climbable_surface` group.

The test scene is a behavior harness, not the final boss room. It provides a visible floor, a climb wall, the actual player controller, and HUD feedback so movement, telegraphs, damage, and state transitions can be evaluated before the authored room exists.

### Test-scene controls

Open `scenes/rabbit_boss_test.tscn` and run the current scene with F6. Use the same player controls as the main game:

- A/D: move
- Space: jump
- J: basic attack

Stand in the boss’s pounce lane to verify player damage. Strike the boss at close range to verify the boss health bar and hit feedback. The red warning and HUD notice should appear before each pounce, while the boss remains still.

## Core move logic the room must support

### 1. Ground approach
The boss moves toward the player on the floor and tries to close distance quickly.

Design the room so:

- the player has a safe lane to move through
- the boss can reach the player without being trapped in a tiny box
- combat still has some room to strafe, dodge, and reposition

Avoid designing a narrow corridor where the boss can instantly pin the player without options.

### 2. Jump and fall state
The boss uses a jump state for vertical repositioning and to escape poor spacing.

The room should include:

- enough vertical space for meaningful jumps
- a few platforms or ledges that create alternate jump routes
- a floor layout that does not force the boss into impossible or unnatural jumps

The room should support bursts of upward motion without making the boss feel like it is floating with no consequence.

### 3. Pounce attack
The rabbit boss uses a fast pounce when the player gets too far away or when the boss decides to commit to pressure.

This attack should be readable and punishable if the player reacts.

Room guidance:

- leave clear movement space in front of the boss and around the player
- avoid excessive clutter in the boss lane where the pounce would become impossible to read
- place the boss in a room where the player has enough room to dodge sideways or away
- do not put this boss in a cramped arena with tight ground objects that cancel its read time

The pounce should feel fast and decisive, not ambiguous.

### 4. Climbing and cling behavior
This is the boss’s defining mechanic. It can intentionally grab climbable surfaces and stay attached while changing pressure.

The room should include multiple climbable surfaces, not just one wall.

Good room structure:

- at least one primary climb wall or pillar
- optional second climb surface for variation
- enough spacing so the boss can climb from one route and reposition across the arena
- clear line-of-sight between the player and the boss while climbing

Important rule: the boss should never feel like it is stuck on a single wall forever. The room should allow it to detach, reorient, and attack again.

### 5. Telegraphed attack warning
Before the pounce lands, the boss shows a red warning line and red hitbox preview. This is a key readability cue.

The room should support this by:

- keeping the boss’s telegraph visible from normal player positions
- giving the player enough room to recognize the strike before it happens
- avoiding decoration that hides the warning line in the arena art
- keeping the boss in an open enough lane that the player can see the telegraph and dodge naturally

The warning is part of the boss’s readability. If the room hides the warning, the boss becomes unfair.

## Arena layout recommendations

### Basic structure
A good rabbit boss room should have:

- a main floor lane for roaming and approach
- a climbable vertical surface or wall segment
- a side or upper ledge for repositioning
- enough open space for full pounces and dodges
- no visual clutter directly in the boss’s attack path

### Recommended shape
The ideal arena is not a flat box. It should have some vertical interest, such as:

- a central wall the boss can climb
- a raised platform or shelf on one side
- a lower fallback lane beneath the climb zone
- enough room behind the wall for the boss to retreat after a pounce

### Avoid these mistakes
Do not build a boss room with:

- extremely narrow halls
- obstructed sightlines to the warning line
- climb surfaces placed behind solid decoration
- tiny ledges that trap the boss or player in poor positions
- repeated obstacles directly on the pounce path

## Player readability and fairness

The boss should always be readable before it attacks.

The player should be able to tell:

- whether the boss is grounded, climbing, or preparing to lunge
- where the warning line is pointing
- whether the boss is about to attack outward, upward, or across the floor
- whether there is a safe dodge angle in the arena

The room should never hide a boss action behind foreground clutter or dense background detail. The telegraph should remain visible.

## Surfaces and arena logic

The boss logic relies on real environment references, not hard-coded coordinates. That means the room designer should build surfaces carefully using the project’s actual collision/climbable architecture.

### Climbable surface requirements
Climbable surfaces should be:

- distinct and obvious in the environment
- physically valid for wall cling
- placed where the boss can reasonably reach them
- not too close together so the boss gets stuck in a repetitive loop

The boss is meant to use the arena geometry, not a single static stuck wall.

## Suggested room pacing

A healthy boss encounter should feel like this:

1. Boss closes distance on foot.
2. Boss chooses a jump or pounce pressure move.
3. Boss telegraphs the strike.
4. Player dodges, gets a read on spacing, or punishes.
5. Boss climbs or repositions.
6. Repeat with a new angle or lane.

This pacing keeps the encounter active without becoming too spammy.

## Step-by-step implementation guide for the main game

Use this order when integrating the rabbit boss into the real game.

### 1. Add the boss to the world script
Create the boss in the same place the project creates other bosses. Follow the pattern in [scripts/tutorial_world.gd](../../scripts/tutorial_world.gd):

- instance the boss node
- set its `name`
- set its `position`
- assign the player reference
- add it to the scene tree
- connect `defeated`
- connect `attack_cued` if you want audio cues

Do this in the room script that owns the arena, not in a detached test scene.

### 2. Trigger it only when the player enters the arena
The boss should not start active in the whole world. Use a room trigger, threshold, or room-state check.

Recommended behavior:

- player enters the arena
- boss becomes `active = true`
- boss begins its idle or approach state
- any intro music or alarm is triggered

This follows the current boss activation pattern used in [scripts/tutorial_world.gd](../../scripts/tutorial_world.gd).

### 3. Wire up combat hit detection
The boss must be able to receive damage from the player’s attack system. The real project checks boss combat bounds inside the world script and applies damage when the player hitbox intersects the boss hitbox.

Make sure the rabbit boss supports:

- a valid `combat_bounds()` method
- `take_hit(amount)` for player damage
- `defeated.emit()` when health reaches zero
- a room callback that triggers the reward or room completion logic

The rabbit’s pounce must also be wired to the player’s existing damage API. During the active pounce window, check the real player body bounds against the boss attack bounds and call `player.take_damage(amount, boss_x)` once per pounce. Do not apply damage during the telegraph; the telegraph is stationary and gives the player time to react.

This is the same pattern used for current bosses in the project.

### 4. Add the boss to the room’s progression logic
When the rabbit boss is defeated, the room should:

- update room completion state
- award the player the wall-cling ability
- clear the arena lock if the room uses one
- update any save data for the encounter

If the room is a required boss gate, the player should only be allowed through after the encounter is won.

### 5. Add HUD and boss title support
Follow the same boss HUD pattern already used by the project:

- boss title text
- boss health bar
- boss max health value
- updates while the boss is active

The prototype reuses [scripts/hud.gd](../../scripts/hud.gd) through a `CanvasLayer`. Preserve that layering in the real room so the boss bar remains above the world. Update the HUD from authoritative player and boss state rather than storing a second health value in the HUD.

For readability, retain a visible attack notice for at least the short feedback period used by the test harness. Recommended messages include a pounce warning, boss hit, miss, and blocked hit.

Use the structure already present in [scripts/hud.gd](../../scripts/hud.gd) and the world HUD updates in [scripts/tutorial_world.gd](../../scripts/tutorial_world.gd).

### 6. Save and restore boss state
This is required for any real boss that should survive reloads or room transitions.

Persist:

- whether the rabbit boss was defeated
- whether the boss was already active or currently in progress
- whether the reward was granted
- any arena-specific state that matters for progression or room completion

This matches the current save logic in the project’s world scripts.

### 7. Build the actual room around the boss logic
The room must be built around the boss’s actual move identity. See the design goals above.

The arena should include:

- a clear ground lane for approach
- a climbable wall or pillar the boss can use
- enough open space for pounces and dodges
- readable telegraph lines before attacks
- clean sightlines so the warning is visible
- no tight dead-end spaces that trap the player

The room is not just decorative. It must support the boss’s climb, leap, and dash pressure loops.

### 8. Test the encounter in the real world
After integrating it, verify the full loop in-place:

1. player enters the room
2. boss activates
3. boss closes distance and telegraphs attacks
4. player reads the warning and dodges or punishes
5. boss climbs or repositions
6. player continues pressure or escapes
7. boss is defeated
8. rewards and progression update correctly
9. continue/reload/room travel state remains consistent

Before testing the full room, run the isolated prototype with F6. Confirm that the player is visible, the HUD is visible, the boss can be damaged, the player loses health on a pounce contact, the boss remains motionless during its warning, the pounce pose is visibly elevated, and the boss can jump to and cling to a real climbable wall.

### 9. Keep the room readable and fair
Once the boss is in the game, the player must be able to tell:

- when the boss is approaching
- when the pounce is coming
- where the pounce will land
- when the boss is climbing and repositioning
- whether there is a safe dodge lane

If the room hides the warning or restricts the player too aggressively, the boss will feel unfair even if the code works.

## Recommended order summary

1. Add the boss to the world script
2. Trigger the encounter in the correct room
3. Connect player damage, combat, and defeat logic
4. Add HUD, attack feedback, and reward logic
5. Save state and progression
6. Build the arena to fit the boss move identity
7. Test the isolated prototype, then test in the real game and tune readability

This order keeps the boss implementation aligned with the project’s existing architecture and prevents the room, combat, and save systems from drifting out of sync.

## Final design goal

Build the room so the rabbit boss reads as a fast vertical predator that uses the stage instead of fighting in one flat plane. The room should reward the player for reading telegraphs, watching climb surfaces, and managing the boss’s pressure between ground approach and leap attacks.

If the room is designed well, the boss will feel like a creature that hunts in arcs, climbs to reposition, and strikes with clear intent rather than just dealing raw damage.

## Map design team handoff summary

Use this summary when pushing or reviewing the boss changes on GitHub:

> Added the rabbit boss prototype and test arena. The encounter is a fast, vertical fight built around ground approaches, stationary pounce telegraphs, momentum-preserving pounces, player damage on pounce contact, and jumps to real climbable walls. The test scene includes the real player controller, main-game HUD, boss health and hit feedback, visible arena geometry, and transparent rabbit sprites. Design the final boss room around open pounce lanes, readable warning sightlines, and climbable wall routes with enough space for the boss to detach and re-engage. Defeating the rabbit boss must unlock the player’s wall-cling ability, persist the reward, and make previously inaccessible wall routes traversable.

### Reward and room-design requirement

The rabbit boss’s defeat is both a combat victory and a traversal milestone. The final room may preview readable wall routes or unreachable wall-cling opportunities, but it must not require wall-cling to enter or complete the boss encounter. After defeat:

- grant and persist the player’s wall-cling ability
- allow the player to use the room’s climbable surfaces on the return visit
- update the map and room completion state
- provide a safe exit or return route that demonstrates the new ability
- ensure death, reload, biome travel, and checkpoint restoration do not remove the unlock
