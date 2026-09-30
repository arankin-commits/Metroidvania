# Split Gallery — approved whole-room plan

Approved direction: lower-left Room 1 connection, upper-right Room 3 connection,
heavy-gated express return, and a future chamber connected ONLY through its floor gate.
Root project only. This document is implementation tracking, not permanent art guidance.

## Global composition and topology

World envelope remains x=-600..5040, y=-1900..1850 (4.9 by 5.8 gameplay screens).
Entrance floor y=1500, receiving position (80,1473); initial position (120,1473).
Exit floor y=-1500, receiving position (4920,-1527). Neighbor receiving positions stay
Room 1 (-80,570), Room 3 (1780,570). Both maps must align with these new anchors.

Main route: lower entrance/broken balcony -> lower foundations -> full central
Chain Well -> offering ascent -> Crown Passage -> upper seal vestibule -> Room 3.
Memorial and offering remain pre-boss optional rewards. Eastern overlook, Drop Bay,
undercroft and eastern ascent form exploration/return connections, not a second entrance
to the future chamber. Both winches retain local utility. Stable encounter IDs persist.

Heavy return: branch below upper vestibule at the eastern brow -> vertical heavy wall
-> enclosed eastern service shaft -> basal tunnel -> entrance receiving junction.
Wall must join roof/floor; continuous western shaft wall prevents intermediate access.
Initial stretch target: <=50% of an ordinary return. Final controller measurement:
29.08 seconds via the heavy return versus 65.07 retracing the main ascent (44.7%).
This compares those two traversed routes with enemies disabled and no dash; it does
not establish a fastest possible opened-winch or speedrun route. The shaft includes
a climbable series of 75px footholds.

Future chamber lies below eastern undercroft, above the basal tunnel. Only its roof
gate connects it to accessible space. Current attacks cannot open it. Interior exit
steps lead back to the same future opening. No current completion objective inside.

Art: dark slate geology, embedded desaturated masonry, restrained aged-metal accents.
Lower foundation compression -> central suspended void -> surviving upper gallery.
Paired anchored chains define the well; memorial carved stone and offering root bowl
have different silhouettes. Falling masonry repeats the fracture direction above.
Quiet actor backgrounds; one environmental emphasis per important camera view.
Connected world-space strata and distant composition cross every work-zone boundary.

## Fourteen spatial work units

| Zone | Area | Adjacent zones | Status |
|---|---|---|---|
| 1 | Lower entrance and return receiving junction | 2,13 | complete; door, safe floor, return jumps checked |
| 2 | Broken Balcony | 1,3 | complete; original three jumps and sentinel retained |
| 3 | Foundation approach to well | 2,5,6,10 | complete; overlapping junction floor made suspended |
| 4 | Memorial approach and Sigil | 5,6 | complete; distinct carved slab; reward reached physically |
| 5 | Memorial return | 3,4,6 | complete; rejoin moved clear of main ramp |
| 6 | Chain Well | 3,4,5,7,10 | complete; paired anchored chains; full ascent/return checked |
| 7 | Offering loop | 6,8 | complete; root bowl; reward and return checked |
| 8 | Crown Passage | 7,9,12 | complete; quiet patrol backgrounds and embedded ribs |
| 9 | Eastern Overlook | 8,10,11,12 | complete; ramp grade and upper ledge connection corrected |
| 10 | Drop Bay and undercroft | 3,6,9,11,14 | complete; receiving floor and well rejoin checked |
| 11 | Eastern galleries/ascent | 9,10,12,14 | complete; staircase shifted clear of ramp underside |
| 12 | Upper seal vestibule | 8,9,11,13 | complete; gap, ordinary seal, jumping exit and receiving floor checked |
| 13 | Eastern return shaft and basal tunnel | 1,12; solid borders 10,11,14 | complete; descent, all climb links and timed return checked |
| 14 | Future floor and sealed pocket | 10 through floor only; solid border 13 | complete; sealed borders, empty interior and sole aperture audited |

Read both memories and this plan before every zone; inspect neighbors. Global shell
must pass before zone decoration. Finish one zone then check its seams. Running-game
reviews after 4,7,10,14. Final: continuous route in both directions, rewards physically
reachable, shortcut timing, sealed-pocket topology, shell/collision/map agreement,
save/reload/forest/checkpoint verification, moving-camera art and combat review.

## Verification record

Global shell was established before zone scenery. Both memories and neighboring
geometry were inspected during the individual zone passes. Continuous running-game
ascent reviews after zones 4, 7, 10 and 14 completed without route failure. Final review
added the running heavy return, gameplay-scale chamber views, overview and map views.

Initial strengths retained: working movement/encounters, optional Sigil and offering,
persistent winches, shared collision geometry, substantial outer enclosure and one
room-wide backdrop. Weaknesses addressed: interchangeable automatic chains, repetitive
surface dashes, weak chamber landmarks, overemphatic distant light, unclear connection
hierarchy and future-floor side access. New scenery uses one failed suspension system,
carved memorial stone, a root offering bowl, and displaced machinery below the well.

Existing art-memory rules applied: actor/edge/landmark/background hierarchy, honest
solid silhouettes, continuous geology, meaningful lighting, persistent navigation
anchors and explicit gate language. Durable refinements were recorded only after the
running review: three scales of damage storytelling, world-space material continuity,
camera-scale background contrast, plausible chain anchors, transitional motifs and
seam review cadence. Movement and attack tuning were not changed for this art pass.

Final checks passed:

- `gallery_section_smoke`: every route both ways, physical rewards, optional jumps,
  service-shaft climb, winches and exactly-once rewards.
- `gallery_progression_smoke`: continuous first visit and main-route return; ordinary
  three-hit seal, jumping doorway, checkpoint/reward/reload/forest state.
- `gallery_playthrough_smoke`: same journey with live enemies and ordinary attacks;
  nine authored encounters defeated. Invulnerability isolates integration, not difficulty.
- `gallery_joints_smoke`, `gallery_encounters_smoke`, `gallery_gates_smoke`: all links,
  spawn/patrol support, both combat approaches, charged gate input and persistence.
- `gallery_shell_audit`, `gallery_containment_smoke`: matching rock/collision, full
  boundaries, camera corners, solid floors, future pocket borders and sole aperture.
- `gallery_return_smoke`: 65.07s main return versus 29.08s heavy return.
- `gallery_space_audit`: 39,914.76px supporting length; 3,623,424px sampled body-center
  area. Future-pocket steps are excluded. Same external room envelope.
- `cave_design_smoke` and real-time `cave_rooms_smoke`: neighboring cave, drop gravity,
  combat, hand/menu/audio, boss, map and biome regression checks.
- `git diff --check`: no whitespace errors. Godot emits an environment certificate-store
  warning and some shutdown resource warnings; all listed tests emitted their PASS marker.

Screenshots and captions: [final review](split-gallery-final.html). These are captures
from the running root Godot project with no active player save slot. The quick map
shows Room 1 below-left and Room 3 above-right; fast travel keeps its selected hand
inside the viewport after the vertical doorway change.

## Background asset provenance

`assets/split_gallery_background.png` was generated with the built-in imagegen tool,
using this project's `assets/cave_room3.png` only as a material/style reference.
Brief: a continuous recessive pixel-art cave depth painting for the entire room;
dark slate/navy strata, eroded memorial architecture and restrained root traces;
quiet areas behind traversal; no bright central focal light, characters, UI, text,
collectibles, tiled panels or foreground playable platforms. Precise architecture,
landmarks and collision are authored separately in world space. No reference-game
assets, landmarks, compositions, palettes or layouts were copied.
