# HTML Game Version
https://arankin-commits.github.io/Metroidvania/

# Metroidvania

Open this folder in Godot 4.7.2 and press **F5** to start at the main menu. Choose **Start Game**, then one of three save slots. Empty slots show **New Game**; occupied slots show the saved area, time played, and player level. The **Delete** button beside a slot asks for confirmation before clearing it. **Back** returns to the menu.

The cave has four rooms. Each room is continuous inside; moving fully past the screen edge fades quickly into the next room. Each room has its own pixel-art backdrop positioned in the scrolling world, so more scenery comes into view as the player moves. The cave floor and raised platforms have detailed pixel-stone surfaces. New games start in **Cave Room 2** at an initial respawn position. Room 1 holds the sealed entrance to the future End Area. Room 2 teaches jumping, ground dodging, aerial strikes against a stationary enemy guarding a raised ledge, dropping through a platform, and healing. An optional Cave Sigil sits on a raised platform off the main path; press **E** beside it to read its Heartroot lore close-up, and **E** again to close it. The Sigil disappears after reading. Room 3 teaches climbing at the edge of a raised stone shelf and air dashing across a gap. Its hand chair, shaped after the supplied reference image, is the next checkpoint. Press **E** there to view abilities, save and rest, or reread collected notes. Room 3 also holds a hidden lore note. Air dash is available from the start, and the note disappears after reading. Room 4 holds the Hollow Warden. Once the fight starts, a barrier seals the entrance until the Warden dies or the player dies and returns to the last respawn point. Defeating the Warden grants a charged heavy attack that breaks the cracked wall before the forest exit. The stone arch at the far right uses the same fade as other room exits and leads to a small Forest Edge room that connects back to Cave Room 4.

The game saves play time every ten seconds and saves immediately at the hand, room entries, checkpoints, collectibles, and major victories. Existing slots resume at their latest checkpoint. Player level is currently 1 because the leveling system has not been built yet. Press **M** or **Tab** during play to open the map. It shows only rooms you have visited, with each room's box scaled to its horizontal size; completed rooms use a different color. Room 2 is complete after the Sigil, Room 3 after the note, and Room 4 after the Warden. Room 1 and Forest Edge have no current collectibles or bosses and complete when visited. Map discovery is saved per slot.

The menu has music, distinct hover and click sounds, volume controls under **Options**, and an **Achievements** panel. A short transition screen appears before the cave; its animation has not been added yet. During play, **Esc** opens a pause overlay with Resume, Options, and Main Menu.

The game HUD has no top header or bottom-left tutorial panel. Its unboxed upper-left display shows the level in a circle with a thin health bar beside it, smaller healing-charge fists below, and Will as a glowing orb. Tutorial controls are painted into the cave scenery beside the corresponding obstacles. Defeated scouts release 5 Will and the Warden releases 50 Will; each reward appears as an orb that travels to the player before the total increases. Touching either enemy, including landing on top, causes damage. Walking on the ground plays a stone footstep sound. Press **F** to begin a short healing animation; one charge is spent and two health are restored when it completes. Taking damage interrupts it. Falling into a pit returns you to safe ground just before the pit and costs 20% of maximum health. Charges and Will are saved. The cave and Forest Edge use pixel-art backdrops matched to the title screen.

| Control | Key |
| --- | --- |
| Move | A / D or arrow keys |
| Jump | Space, W, or Up |
| Strike | J or X |
| Ground dodge / air dash | K or Shift |
| Climb a held ledge | Space, W, or Up |
| Drop through a platform | Hold S or Down, then press Jump |
| Interact with the hand or read or close a nearby note or Cave Sigil | E |
| Charged heavy attack after defeating the Warden | Hold and release H |
| Heal (uses one charge) | F |
| Open / close map | M or Tab |
| Pause / resume | Esc |
| Restart | R |

The tutorial leads through a jump, an aerial strike against the ledge enemy, a drop-through platform, a scout fight, a three-hit seal, the Room 3 ledge climb and air-dash gap, the hand checkpoint, the Hollow Warden boss, and the cracked wall. The red ground mark warns of the Warden's charge. Death returns the player to the latest activated respawn point; simply entering another room does not move that point.

The cave and Forest Edge use pixel-art backgrounds with code-drawn foreground objects and generated collision shapes. The startup scene is `scenes/main_menu.tscn`; the cave scene is `scenes/tutorial.tscn`; the forest entry is `scenes/forest_entry.tscn`. Art and menu audio are in `assets/`.
