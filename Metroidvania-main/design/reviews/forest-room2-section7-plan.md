# Forest Room 2 Section 7 proposal

Status: approved and implemented. See [verified Section7 review](forest-room2-section7.md).

Read ROOM_DESIGN_MEMORY and ART_DESIGN_MEMORY, global Layout.png, Section7 reference, raised Section6 geometry, and neighboring Section8.2 reference. Section7 continues east at x11400..12600 in ForestRoom2; it is not a new save/map room ID.

The supplied painting has clear high-left / middle / low-right progression, substantial right pedestal, banner arches and waterfall depth. Its literal vertical and horizontal gaps exceed the controller's reliable ordinary jumps. Section6's recent96px rise also means simply aligning all original source heights would strand the return climb.

Only the three red-marked objects and floor are playable. The low right pedestal's blue-marked stone mass is solid to ground. Other architecture, foliage, crystals and apparent ruin ledges remain background. Remove annotations, painted player and moon. Do not add sun/moon or new footholds. Keep plants behind entities with no collision.

Ground y162.202 stays aligned with Section6. Proposed cap heights:

| Object | World cap y | Rise from previous takeoff |
| --- | --- | --- |
| Right solid pedestal | 50.202 | 112px from ground |
| Middle floating platform | -61.798 | 112px from pedestal |
| Highest left floating platform | -173.798 | 112px from middle |
| Section6 east high platform | -250.106 | 76.308px from Section7 highest |

The three112px rises use the already-tested jump/ledge-grab controller, without changing movement or hitboxes. The high Section7-to6 link is an upward jump. Section6's higher96px entrance from Section5 remains intact, and its own floor still cannot reach its platforms.

Keep the high-left and center spatial order; move the lowest pedestal approximately80 world pixels left to reduce its center-platform gap from about186px to about106px. Preserve the whole stone object's scale and all attached decoration through the same transform. Its eastern side ends about80px before the section boundary, giving a visible ground receiving pocket toward Section8.2. Final x gaps may be adjusted within the same three-object composition based on actual-input results; no extra shelves. Verify blue pedestal collision against both side silhouettes. Trace stone only, excluding vines and background pockets.

Routes: Section6 high -> Section7 high -> middle -> low pedestal -> ground; ground -> low pedestal -> middle -> highest -> Section6. The lower approach from Section6 reaches the pedestal via ground and climbs it. Section8.2's lower entry is reserved at aligned ground; its upper/lower branch and purple drop-through floor are future work, not implemented in this pass.

Art: extend shared Sections2-6 recessed panorama to Section7 naturally, keeping world camera coverage and continuous banner/forest/waterfall composition. Continue the common Sections4-6 masonry/root foundation beneath the new floor; no independent rectangular reset, repeated image, flipped extension, crossfade, stretched source-edge pixels or neutral-matte rectangles. Keep landing caps brighter than recessed ruin crests. Inspect actual platform sides, underside texture and full foliage bounds at gameplay zoom.

Files/assets expected: new forest_return_gallery_layout.gd and forest_return_gallery.gd; clean Section7 stone/decoration source; extended shared background/foundation; forest_stair.gd/layout, connected foundation shader registration, forest_world_layout.gd, forest_entry.gd and map_art.gd; route/structural/live visual drivers; review, README and relevant room memory after verification. Refine ART memory only if testing discovers a new durable lesson. Existing registered-object, scenery/collision separation, reachable-route, camera-envelope and continuous-seam rules already cover this plan.

Room2 becomes x3600..12600,width9000. Move temporary outer doorway to12600, downstream boss bounds12600..14000 and handroom14000..15400, handx14380; preserve relative actors and checkpoint/save semantics. Camera remains shared across sections; map derives new caps and solid pedestal from authoritative geometry.

Verification: complete real-controller Sections1-7 progression; every new landing and reverse climb, ground-to-pedestal from both sides, Section7 highest -> raised Section6 east cap, continued Section6 traversal; repeat Section6 floor denial and Section5 upward-entry checks. Match every rendered solid polygon to collision, full-body queries beside pedestal/under hanging plants, ground-shell sweep, camera jump coverage and smooth seams, both outer doorway receiving directions, map and isolated checkpoint persistence. Running-game gameplay-scale screenshots at both high/ground joins, all new landings, pedestal sides and map. No user save slots mutated. No new enemies/rewards/abilities in this section.
