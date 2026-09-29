# HTML Game Version
https://arankin-commits.github.io/Metroidvania/

# Metroidvania

The GitHub Pages version shows **Turn on sound for the best experience** immediately for two seconds. It then shows **METROIDVANIA**, the menu's cave artwork, **Loading...**, and a progress bar driven by the actual Godot downloads. The overlay stays until the game menu is ready; the web game skips the later sound splash. A failed download shows an error and a Retry button.

The persistent web loading template is `web/loading.html`, selected by the Web export preset. Its artwork is `docs/loading-art.png`, copied from `assets/menu_cave.png`; refresh that copy if the menu artwork changes. Export to `docs/index.html` to rebuild the Pages version. Run `node tests/web_loading_smoke.cjs` to check intro timing, cached startup, progress reporting, menu handoff, and failure handling.

Open this folder in Godot 4.7.2 and press **F5** to start at the main menu. Choose **Start Game**, then one of three save slots. Empty slots show **New Game**; occupied slots show the saved area, time played, and player level. The **Delete** button beside a slot asks for confirmation before clearing it. **Back** returns to the menu.

The cave has four rooms, with continuous scrolling inside each room and masked doorway transitions. New games start in Cave Room 2. Room 1 holds the sealed future End Area and a later charged-attack reliquary. Room 2 teaches jumping, dodging, aerial strikes, dropping and healing in the Split Gallery. Room 3 offers ledge climbing, normal jumps across existing basin ledges, lore and the first hand checkpoint. Room 4 holds the large scimitar-wielding goblin. Defeating it grants the Goblin Scimitar, charged wall breaking and Will of Wrath. Forest Room 2 now contains eleven continuous ruined-gallery sections; its stairs reach the boss hand room before Bow Hunter. The lower temple doorway leads to a separate hand room, with the stone guardian arena to its left. Forest boss victory grants the bow plus air/enhanced dash; temple victory grants the Stone Gauntlet. Existing routes are unchanged. Before the forest boss, the player has a half-distance ground dodge and no air dash; the highest Sections 9.2/10.2 galleries remain a later dash route.

The game saves play time every ten seconds and saves at room entries, checkpoints, collectibles, major victories, or when Save is selected at a hand. Interacting with the hand restores health and healing charges, activates its checkpoint, and respawns regular enemies without resetting bosses; the player hops onto it to meditate. The translucent hand menu sits on the left and offers Fast Travel, Abilities, Save, and Hop Off. Fast Travel opens a full-screen map with a translucent list of unlocked hands on the left; selecting one centers its room around 60% of the map width. A second hand is available in Forest Room 4 after it is activated. Abilities opens the main in-game menu and returns to the hand when closed. Press **E** again or choose Hop Off to leave the hand. Existing slots resume at their latest checkpoint. Player level is currently 1 because the leveling system has not been built yet. Press **M** during play for the quick map, or **Tab** for the translucent Status, Wills, Notes, Abilities, and Map menu. Wills contains passive boss rewards, currently Will of Wrath. Weapons, charged wall breaking and movement unlocks are described under Abilities. Click a section, use the Q/E header buttons, or press **Q** and **E** to switch. Every map has a boxed symbol legend and marks rooms with unlocked hands. The map shows only rooms you have visited, with room shapes scaled to their physical size; the expanded Split Gallery shows its stacked passage silhouette and the player's actual position. Completed rooms use a different color. Cave Room 1 is complete after opening its reliquary, Room 2 after the Sigil and upper-gallery offering, Room 3 after the note, and Room 4 after the Warden. Forest Rooms 1 and 2 complete when visited. Forest Room 3 completes after the Bow Hunter, and Forest Room 4 completes after bow training. Map discovery is saved per slot.

The game opens with a two-second black screen prompting players in white text to turn on sound. The menu has music, distinct hover and click sounds, volume controls under **Options**, and an **Achievements** panel. The cave and forest each have their own looping track. Music continues through the Tab menu, quick map, Fast Travel, and pause overlay. In-game menu selection, fast travel selection and confirmation, and mounting or leaving the hand have their own effects. Warden music takes over when the fight starts; cave music resumes after victory or a respawn. Player attacks, heavy attacks, jumping, dodging, and healing have distinct effects, as do regular enemy contact attacks. The goblin uses scimitar combos, jump slams and charged wind swings. Bow Hunter summons scouts and uses arrow bursts, knife combos and aerial volleys. The temple guardian uses chain fists, punches, slams and a protected projectile charge. A short transition screen appears before the cave; its animation has not been added yet. During play, **Esc** opens a pause overlay with Resume, Options, and Main Menu.

The HUD shows level, health, healing-charge fists, Will, and bow arrows in the upper left. Circular bottom-left icons show the equipped weapon and its weapon ability. Movement upgrades and charged wall breaking do not occupy these slots. Healing charges and arrows refill when meditating at a hand. Regular enemies show health bars above their heads. The cave shows one nearby control prompt at a time near the bottom of the screen. Learned tutorial prompts disappear, and that progress is saved. The player can dash through the Room 2 ledge enemy; touching it outside a dash causes damage. Ledges with no standing room above them cannot be climbed. Dropping through a platform uses normal falling gravity. Defeated scouts release 5 Will and the Warden releases 50 Will; each reward appears as an orb that travels to the player before the total increases. The Warden's Will does not restore health. Walking on the ground plays a stone footstep sound. Press **F** to begin a short healing animation; one charge is spent and two health are restored when it completes. Taking damage interrupts it. Cave drops land inside solid enclosed terrain. The hole fall-damage and recovery mechanic has been removed; ledge catching and climbing remain. Charges and Will are saved. The cave and Twisted Forest use pixel-art backdrops matched to the title screen.

| Control | Key |
| --- | --- |
| Move | A / D or arrow keys |
| Jump | Space, W, or Up |
| Strike | J or X |
| Ground dodge / air dash | K or Shift |
| Climb a held ledge | Space, W, Up, or the forward movement key |
| Drop through a platform | Hold S or Down, then press Jump |
| Interact with the hand or read or close a nearby note or Cave Sigil | E |
| Charged wall breaking after defeating the cave goblin | Hold and release H |
| Equip scimitar / bow / gauntlet after earning them | 1 / 2 / 3 |
| Equipped weapon ability (hold/release to charge gauntlet beam) | U |
| Heal (uses one charge) | F |
| Fire bow after defeating the Bow Hunter | L |
| Open / close quick map | M |
| Open / close Status, Wills, Notes, Abilities, and Map menu | Tab |
| Switch menu section left / right | Q / E |
| Pause / resume | Esc |
| Restart | R |

Cave exploration includes jumps, the optional ledge enemy, a drop-through platform, a scout fight, a three-hit seal, the Room 3 ledge climb and air-dash gap, the hand checkpoint, the Hollow Warden boss, and the cracked wall. The red ground mark warns of the Warden's charge; the amber mark warns of its slam. Enemy and boss deaths play a brief collapse-and-dissolve animation before respawn; all deaths use the normal combat-death flow. Death returns the player to the starting spawn until a hand is activated, then to the last activated hand. Entering a room alone does not change the death checkpoint.

The cave and Twisted Forest use pixel-art backgrounds with code-drawn foreground objects and generated collision shapes. The startup scene is `scenes/main_menu.tscn`; the cave scene is `scenes/tutorial.tscn`; the forest entry is `scenes/forest_entry.tscn`. Art and menu audio are in `assets/`.

## Cave room design

The four cave rooms now have solid, stepped ceilings, distinct landmarks, sheltered entrances and optional vertical routes:

- **The Sealed Watch (Room 1):** climb the memorial shelves to a cracked reliquary. Return with the Warden's heavy attack to claim 25 Will. The future End Area gate remains sealed.
- **The Split Gallery (Room 2):** enter from Room 1 at the bottom left and climb the Broken Balcony, Chain Well, offering galleries and Crown Passage toward Room 3 at the top right. The western Sigil memorial, Eastern Overlook, Drop Bay and Undercroft form optional exploration loops. A carved memorial, root-cradled offering and damaged suspension machinery distinguish chambers inside one continuous stone shell and background. Nineteen existing-roster enemies occupy combat approaches; rewards and receiving doors stay quiet. Both winches open local return connections. After the Warden, the heavy-gated eastern service shaft and basal tunnel provide a faster return toward Room 1. The fractured undercroft floor remains closed for an unimplemented downward smash; it is the only entrance and exit of its reserved pocket. The offering grants 12 Will. Room extent remains about 4.9 by 5.8 gameplay screens; tested supporting surface totals 39,914.76px, excluding the future pocket.
- **The Hand's Refuge (Room 3):** cross the climb-and-dash chasm, then press **E** at the far-side winch to lower a permanent return bridge. Rest in the warm hand alcove or climb the turning upper route to the weathered note.
- **Warden's Hall (Room 4):** fight on an open floor framed by ruined arches. The heavy-attack wall joins the ceiling; beyond it, raised stone and green growth lead toward the forest.

Room 2 uses one continuous unique background, `assets/split_gallery_background.png`, rather than a tiled copy. Room 3's chasm now has a physical basin and return ledges.

Forest Room 1 contains three supplied forest-ruin sections in one 3600px room. The camera side-scrolls from the arrival basin through Section 2's crest into Section 3's clearing, terraces and ruined arch, with no transitions at either artwork seam. Foreground trunks cover terrain and the passing traveller. The lower arch route and attached return tread reconnect with the clearing. [Section 3 review and asset prompts](design/reviews/forest-section3.md).

Forest Room 2 connects eleven supplied ruined-gallery sections in one side-scrolling room. Section 1's balconies have reachable masonry-step routes. [Section 2](design/reviews/forest-room2-section2.md) is a single stair ascent with no lower route. [Section 3](design/reviews/forest-room2-section3.md) climbs four ledges before dropping into Section 4; the right wall stays sealed below the highest gallery. [Section 4](design/reviews/forest-room2-section4.md) has aligned lower ground and a rounded rise, with its amber floor sealed for the future downward smash. [Section 5](design/reviews/forest-room2-section5.md) climbs a solid pedestal and two floating platforms, all reachable, leading into [Section 6](design/reviews/forest-room2-section6.md), whose three floating platforms are reachable only along the elevated route, not from its local floor. [Section 7](design/reviews/forest-room2-section7.md) descends through a middle platform to a solid right pedestal; its tested reverse climb jumps back into raised Section 6. Recessed architecture and plants do not collide. [Sections 8.2 and 8.1](design/reviews/forest-room2-section8.md) add an upper three-ledge gallery, a purple Down+Jump floor, and a lower hall with six return shelves. [Sections 9 and 10](design/reviews/forest-room2-section910.md) continue both levels: the high galleries require an air dash across their gap in either direction, and the lower corridor leads to an E-interactable Temple Hand doorway. Its separate checkpoint preserves the last activated hand through cave/forest travel; the temple guardian chamber now connects to its left. Sections 2 through 11 share extended scenery/foundation coverage, and Room 2 has one camera envelope spanning both levels. Section 11 connects from the Section 10.2 floor and preserves its highest-gallery right wall. The redesigned original forest hand now sits before Bow Hunter. Run `tests/forest_gallery_smoke.gd`, `tests/forest_stair_smoke.gd` and `tests/forest_upper_gallery_smoke.gd` for traversal, collision, seam, doorway, camera, sealed-floor and checkpoint checks.

Rewards can be claimed once, and the bridge, gallery shortcuts and rewards persist through saving and travel between biomes. The room analysis, reusable rules, movement measurements, reference research and future forest baseline are recorded in [project design memory](design/ROOM_DESIGN_MEMORY.md). `AGENTS.md` directs future room work to that guide. Room 2 uses `scripts/split_gallery_layout.gd` and `scripts/split_gallery.gd`; the other caves use `scripts/cave_layout.gd`. Room 2 scenery is in `scripts/gallery_art.gd`, and its continuous stone material is `assets/gallery_stone.gdshader`; other cave scenery remains in `scripts/cave_scenery.gd`. Major room changes require a layout report and explicit approval before implementation, as recorded in the memory guide.


Room 2 controller, persistence and playable-space checks:

```powershell
Godot --headless --path . --script res://tests/gallery_section_smoke.gd
Godot --headless --path . --script res://tests/gallery_progression_smoke.gd
Godot --headless --path . --script res://tests/gallery_space_audit.gd
Godot --headless --path . --script res://tests/gallery_containment_smoke.gd
Godot --headless --path . --script res://tests/gallery_encounters_smoke.gd
Godot --headless --path . --script res://tests/gallery_playthrough_smoke.gd
```

Use your installed Godot executable in place of `Godot`. Existing
`cave_rooms_smoke.gd` and `cave_design_smoke.gd` retain their original gameplay checks
with fixtures updated for the expanded layout. All use isolated test save roots.

Run `tests/gallery_joints_smoke.gd` for the authored climb links and `tests/gallery_gates_smoke.gd` for the moved entrance, solid receiving floor, heavy shortcut, and reserved smash floor. Use ordinary real-time runs for tests that compare audio playback clocks.

The approved fourteen-zone plan, final screenshots and test record are in [Split Gallery review](design/reviews/split-gallery-plan.md). Run `tests/gallery_return_smoke.gd` for the timed return comparison and `tests/gallery_shell_audit.gd` for the sealed-pocket and shell audit.

Forest Room 2 now includes Section 11: solid stairs from the Section 10.2 floor, with its highest-gallery right wall retained. The main hand sits before Bow Hunter; a separate temple guardian chamber connects to the LEFT of the Section 10.1 hand sanctuary. See [final concourse review](design/reviews/forest-final-concourse.md) for layout, assets, prompts and verification.

The [boss combat review](design/reviews/boss-combat.md) records the move sets, rewards, dash progression, verification and running-game screenshots. Forest and temple passive Wills remain unspecified.

The Web PCK is **67.91 MB**, including the Cave Boss sprite atlas. Its export preset selects audited runtime resources rather than all project resources; development artwork and reviews stay in the workspace. Run `python tools/web_pack_audit.py --refresh-export` after adding content, export Web, then run `python tools/web_pack_audit.py --verify`. See the [pack size audit](design/reviews/web-pack-size.md) for inventory and isolated packaged-resource verification.
