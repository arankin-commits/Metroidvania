Fact: The intended world is an interconnected Metroidvania map with cave, forest, snow, and desert biomes and obstacles that reward exploration and backtracking.
Why: The user described the project vision.
How to apply: Use it to guide requested level design without adding unrequested content.

Fact: Each room is continuous inside, and crossing into any different room shows a loading screen even when both rooms are in the same biome.
Why: The user corrected the earlier assumption that loading screens belonged only between biomes.
How to apply: Treat rooms as the transition unit and biomes as groups of rooms.

Fact: The cave has four rooms. Room 1 has the End Area entrance; Room 2 is the new-game spawn and a low-threat tutorial for jumping, dodging, and attacking; Room 3 has a hidden lore note; Room 4 has the first boss and the forest exit. The boss grants a charged heavy attack for cracked walls, and a minor optional collectible sits off the early main path.
Why: The user specified the cave layout and first reward.
How to apply: Preserve these roles when changing the cave or adding connections.

Fact: The optional Cave Sigil is reached from a raised platform off Room 2's main path. It requires interaction to open a close-up with Heartroot lore; interacting again closes it.
Why: The user corrected the earlier automatic collectible behavior.
How to apply: Preserve the reachable platform and E interaction when editing Room 2.

Fact: Cave floors and raised platforms should look like detailed pixel-art cave stone. Cave room backgrounds occupy positions in the scrolling world, so parts extend off-screen and move with the side-scrolling camera.
Why: The user clarified that matching the menu's art style means matching its pixel detail, not reusing its image or fixing art to the screen.
How to apply: Keep the terrain cave-specific and anchor backgrounds to world coordinates.

Fact: The first respawn point is an open-hand bench at the Room 2 spawn. Room entry alone does not move the death respawn point. Once the Room 4 boss fight starts, the player stays in its arena until the boss is defeated or the player dies and respawns at an activated respawn point.
Why: The user specified the hand bench and boss fight boundary.
How to apply: Keep the Room 2 hand bench active from the start, preserve designated checkpoints, and close the arena entrance for the active boss fight.

Fact: The hand-chair checkpoint should match the open palm, four upright fingers, curled thumb, pedestal, and broad base in `C:\NCAT\hand chair.jpg`, rendered as cave pixel art.
Why: The user supplied a specific visual reference for the checkpoint.
How to apply: Preserve the recognizable silhouette when changing its sprite or placement.

Fact: The Cave Sigil and lore note disappear from the world after their first interaction. M or Tab opens a discovery map with only visited rooms. Room boxes scale with room size, and completed rooms have a distinct appearance after all current collectibles are found and bosses beaten.
Why: The user specified collectible removal and map behavior.
How to apply: Save visit state per slot and derive completion from each room's current objectives.

Fact: Room changes should happen at screen exits with a brief smooth fade. The cave-to-forest arch and forest-to-cave return use the same transition, without a blue portal circle. Walking plays a footstep sound.
Why: The user corrected the transition style and requested movement audio.
How to apply: Keep edge triggers, shared fade treatment, stone arches, and ground-walking audio.
