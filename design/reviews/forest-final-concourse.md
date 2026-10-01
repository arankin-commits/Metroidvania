# Forest Room 2 final stairs and connected encounters

Approved topology: Section10.2 FLOOR -> Section11 -> boss hand sanctuary ->
Bow Hunter. Section10.1 interactable doorway -> temple hand -> guardian arena
on the LEFT. The highest10.2 gallery's right wall remains solid above the floor
passage. The lower10.1 blue wall and future downward-smash floor remain sealed.
The existing room identities, earned abilities and hand checkpoint IDs are retained.

## Geometry and connections

Section11 spans16200..18000, starting at162.277 and ending at-317.723.
Twelve40px rises use80px treads and50px beveled transitions; the solid stair
mass extends to1302. It is the only route, with no penetrable arch space below.
Ceiling continues-950..-530. Highest10.2 wall Rect2(16170,-530,30,356.277).
Both render and collision use the same three polygons. Room2's camera stays
continuous at its artwork seams and follows the full crest jump.

| Room | World span | Floor | Key anchor |
|---|---|---|---|
| ForestRoom2, ID6 |3600..18000|varied; stair crest-317.723|Floor-level Section11 entrance16200|
| Boss hand, ID8 |18000..19400|600|Chair18620,546|
| Bow Hunter, ID7 |19400..21000|600|Initial boss20100,553|
| Temple guardian, ID10 |22800..24000|600|Return arch23735,570|
| Temple hand, ID9 |24000..25400|600|Chair24695,546; left doorway24165,570|

Masked outer-room transitions receive at each destination's actual floor; the
return to Room2 uses the stair crest. The map draws hand8 before boss7 and guardian10
left of hand9; numeric save IDs no longer determine horizontal ordering. The boss's
right boundary reserves the future lake connection, which is not implemented here.

The original bow-practice targets now occupy a separate right alcove at19050/19250.
They are nonblocking and do not attack the player. Neither hand approach nor room
entry activates a checkpoint. E at the chair activates it in memory; Save and normal
progress saving persist it. Fast travel does not replace the last activated hand.

## Art and environmental identity

The entire new sequence uses weathered small masonry, hanging ferns, roots and
the biome's cool depth. The stair shares continuous world-space stone detail with
10.2. Sparse attached growth stays behind entities; no terrain is added to background
arches. Warm hand alcoves remain distinct from fighting chambers. Root pressure is
expressed through the Bow Hunter's fractured ceremonial arch and the guardian's
collapsed memorial canopy. Quiet standing/attack lanes keep silhouettes and tells clear.
No moon/sun, flipped scene, tiled backdrop, crossfade seam or near combat occluder.

| Final asset | Delivered size | Registration |
|---|---|---|
|[shared Room2 panorama](../../assets/forest_room2_sections234567891011_background.png)|2172x724|x5000..18000,y-950..1300|
|[boss hand painting](../../assets/forest_boss_hand_environment.png)|1672x940|source floor657 -> world600|
|[Bow Hunter arena](../../assets/forest_bow_arena_environment.png)|1672x941|source floor606 -> world600|
|[guardian arena](../../assets/forest_temple_guardian_environment.png)|1672x941|source floor634 -> world600|
|[opened temple hand](../../assets/forest_temple_hand_open_environment.png)|1681x936|source floor665 -> world600|

Separate chamber paintings start at world y-60; their measured source floors own
vertical registration. The stair geometry and support edge remain code-authoritative.
Assets were generated with the built-in imagegen skill and copied into the project.
[Exact prompts](forest-final-prompts.md) record every selected bitmap's brief.

## Encounters and verification

Bow Hunter retains existing attacks, arena lock and inherited bow/refill behavior.
The temple guardian reuses the established charge/slam encounter with six health,
authored bounds22900..23900 and independent temple_guardian_defeated persistence.
The cave Warden keeps its original default bounds. Guardian defeat completes its
own room and does not grant a duplicate bow or an unrequested traversal ability.

Passed: forest_final_concourse_smoke, forest_dash_galleries_smoke,
forest_upper_gallery_smoke, forest_gallery_smoke, forest_stair_smoke,
forest_camera_limit_smoke, forest_regression_smoke, twisted_forest_smoke and
save_slots_smoke. The final-area test uses actual stair and attack input, independent
walking/jump fixtures for the preserved crown wall, under-stair point sweeps,
door/chair interaction separation, both encounters, bow inheritance, completion,
save/reload, cave travel/death, forest death and fast travel. Isolated test save roots
are used; visual review uses slot0. Invulnerability isolates route/combat integration
and does not establish difficulty balance. Some older tests report shutdown resource
warnings after their PASS marker; Windows log/certificate access messages are separate
from gameplay assertions.

Local running-game review completed with no failure. Screenshot capture caused
occasional render stalls with multiple physics ticks between presented frames;
the camera trace records raw steps and physics/render frame counts separately.
The local review's maximum camera movement per physics tick was3.602px. The existing
fixed-frame camera-limit samples remained4.690px maximum with one initial delayed
frame, preserving the earlier regression check. No seam-limit or camera-reset change
was introduced. Final fresh-instance whole-room review passed Sections1–11,
both active encounters, hand interactions and the connected return routes without
failure. The final overview, map, floor seam and hand-room captures were inspected.

Screenshots: [10/11 floor seam](forest-final-10-11-seam.png),
[stair crest](forest-final-stair-crest.png), [boss hand](forest-final-boss-hand.png),
[Bow Hunter](forest-final-boss-tell.png), [temple entrance](forest-final-temple-door.png),
[guardian attack](forest-final-guardian-tell.png), [guardian cleared](forest-final-guardian-cleared.png).
Whole-room evidence: [Room2 overview](forest-final-overview.png),
[connected map](forest-final-map.png).

## Scope and review sequence

The approved [global plan](forest-room2-section11-plan.md) defined all shells before
local decoration. Work units follow the stair threshold, safe hand chamber, boss
arena and guardian branch. These four units include the final original Room2 zone
and three connected room passes; they do not subdivide the finished room visually.
Local seam/controller checks are followed by whole-room review. Section3's sealed
reverse drop remains one-way; its old descent/Section2 return and the separate lower
branch receiving fixture are explicitly identified in the route drivers.
