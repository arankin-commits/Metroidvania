# Metroidvania

Open this folder in Godot 4.7.2 and press **F5** to start at the main menu. Choose **Start Game**, then one of three save slots. Empty slots show **New Game**; occupied slots show the saved area, time played, and player level. The **Delete** button beside a slot asks for confirmation before clearing it. **Back** returns to the menu.

The cave has four rooms. Each room is continuous inside; crossing between rooms shows a brief loading screen. Each room has its own pixel-art backdrop positioned in the scrolling world, so more scenery comes into view as the player moves. The cave floor and raised platforms have detailed pixel-stone surfaces. New games start in **Cave Room 2** beside the glowing open-hand bench, the first respawn point. Room 1 holds the sealed entrance to the future End Area. Room 2 teaches jumping, ground dodging, striking, and healing with a harmless training post, then introduces lethal hazards and an enemy. An optional Cave Sigil sits on a raised platform off the main path; press **E** beside it to read its Heartroot lore close-up, and **E** again to close it. Room 3 holds a hidden lore note and the air-dash pickup. Room 4 holds the Hollow Warden. Once the fight starts, a barrier seals the entrance until the Warden dies or the player dies and returns to the last respawn point. Defeating the Warden grants a charged heavy attack that breaks the cracked wall before the forest exit. The exit leads to a small Forest Edge room that connects back to Cave Room 4.

The game saves play time every ten seconds and saves immediately at room entries, checkpoints, collectibles, and major victories. Existing slots resume in their saved room. Player level is currently 1 because the leveling system has not been built yet.

The menu has music, distinct hover and click sounds, volume controls under **Options**, and an **Achievements** panel. A short transition screen appears before the cave; its animation has not been added yet. During play, **Esc** opens a pause overlay with Resume, Options, and Main Menu.

The game HUD has no top header. Its unboxed upper-left display shows the level in a circle with a thin health bar beside it, smaller healing-charge fists below, and Will as a glowing orb. It uses icons and values without the words “level,” “health,” or “heal.” Defeated scouts release 5 Will and the Warden releases 50 Will; each reward appears as an orb that travels to the player before the total increases. Touching either enemy, including landing on top, causes damage. Press **F** to spend one healing charge and recover two health; the tutorial prompts you to heal after taking damage. Falling into a pit returns you to safe ground just before the pit and costs 20% of maximum health. Charges and Will are saved. The cave and Forest Edge use pixel-art backdrops matched to the title screen.

| Control | Key |
| --- | --- |
| Move | A / D or arrow keys |
| Jump | Space, W, or Up |
| Strike | J or X |
| Ground dodge / air dash after collecting the light | K or Shift |
| Read or close a nearby note or Cave Sigil | E |
| Charged heavy attack after defeating the Warden | Hold and release H |
| Heal (uses one charge) | F |
| Pause / resume | Esc |
| Restart | R |

The tutorial leads through a jump, a scout fight, a three-hit seal, the dash pickup and gap, a checkpoint, the Hollow Warden boss, and the cracked wall. The red ground mark warns of the Warden's charge. Death returns the player to the latest activated respawn point; simply entering another room does not move that point.

The cave and Forest Edge use pixel-art backgrounds with code-drawn foreground objects and generated collision shapes. The startup scene is `scenes/main_menu.tscn`; the cave scene is `scenes/tutorial.tscn`; the forest entry is `scenes/forest_entry.tscn`. Art and menu audio are in `assets/`.
