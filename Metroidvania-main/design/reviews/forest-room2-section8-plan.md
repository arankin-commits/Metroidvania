# Forest Room 2 Sections 8.2 and 8.1 proposal

Status: approved and implemented; Section9.1 is reserved to the RIGHT of8.1, with return platforms into8.2. Whole-room controller and running-game review passed. See forest-room2-section8.md for measured geometry and verification.

Section8 is interpreted as the upper reference labeled8.2;8.1 is directly below it in Layout.png. Both memories, Sections7/8.2/8.1/9.2/9.1 and the global layout were reviewed. Both new areas remain parts of ForestRoom2, not separate save/transition IDs.

Upper8.2 has three red-marked ledges, a blue upper-left wall/roof mass, ground and a purple descent panel toward its right side. Lower8.1 retains its continuous floor and blue wall mass, with explicitly requested return platforms added. Its arch piers, banners, crystal-bearing ruin crests and plants are background, not unmarked playable platforms. Open upper forest/waterfall depth transitions to darker enclosed lower masonry and blue crystal niches. Remove annotations and painted players; omit every sun/moon, including the upper reference's moon.

Upper ground aligns with Section7's collision floor162.277. Allocate x12600..13800,1200px, about one gameplay viewport in width. Lower8.1 shares the same horizontal span, with its floor approximately700px below upper ground, at862.277. Preserve the height and spacious hall proportions of the supplied lower image rather than squashing it to fit the old camera. Enclose its left side with the blue wall and its bottom with substantial ground. Its future RIGHT continuation into9.1 is reserved; upper future continuation is9.2 to the right. Exact shell/cutout joins are measured from final artwork and shared with collision.

Upper red-ledges proposal: low y50.277, middle-61.723, high-173.723,112px successive climbs. Keep exactly the three depicted main ledges; shorten/reposition the nearly touching lower pair so visible open gaps and takeoff pockets replace their stitched appearance. Starting horizontal arrangement: low near localx960..1170, middle370..835, highest330..1200. This preserves the long upper gallery and mid-level gallery, separates the low-to-mid gap by125px and provides open launch space outside overlapping undersides. Adjust within this same composition using actual-controller results; no movement/hitbox changes or arbitrary extra footholds in the upper route.

Purple ground panel uses actual one-way/drop-through collision and the controller's existing Down+Jump input. Landing/walking on it must work normally, ordinary jumping below must pass through, and deliberate descent must land safely on8.1's ground. Its cue must differ from the still-sealed amber downward-smash floor in Section4. No current heavy/basic attack opens that reserved floor.

Confirmed lower route (latest user correction, 2026-09-28): Section9.1 is RIGHT of8.1, consistent with Layout.png. Add visible return platforms from8.1 to8.2; the descent is not one-way. Preserve the solid blue left wall and reserve the ground-level continuation to the right. Until9.1 is built, close that future continuation with a visible temporary boundary, never an invisible wall; the return climb keeps the lower branch safe and usable.

Use a compact return shaft with approximately six visible stone footholds rising at tested112px intervals, staggered naturally within the right-side pocket. Place its upper takeoff in an open pocket under the purple panel, outside overhanging main-platform stone. Register every added platform with its collision and attached scenery; never infer colliders from decorative crystal crests. Keep the broad lower corridor clear. Verify the complete climb from the lower floor and the final jump through the purple panel with the actual controller.

Proposed side view:

Section7 -> 8.2 ground / low -> middle -> highest -> reserved9.2
                         purple descent
                               |
                  blue wall | 8.1 floor -> reserved9.1
                               ^
                       reachable return platforms

Existing art rules apply: authoritative solid silhouettes, scenery versus terrain, registered object/plant transforms, extraction ownership, readable one-way cues, body-clear jump pockets, coherent depth/light transition and no image flips/repetition/crossfade cover-ups. New durable lessons will be recorded only after tested implementation; none is yet established by this review.

Assets/files expected: upper/lower registered source art and attached scenery; coherent vertical section scenery with a continuous floor-to-ceiling join; extended shared background/foundation coverage; new branch layout/rendering scripts; forest_entry.gd, forest_world_layout.gd, map_art.gd, shared scenery registration, one-way setup using existing player drop fields, controller-driven smoke/live visual tests, review/README/relevant memory. Do not mirror changes to the nested project or alter player saves.

The shared camera envelope must cover the lower hall, with bottom limit around1200. Extend scenery below all affected views before increasing that limit; verify earlier Sections1-7 too. Never switch camera limits at the descent threshold or reset smoothing within Room2. Background/foundation continuation cannot simply stretch or clamp their last rows. Upper floors over the lower hall must have actual finite thickness; an old full-depth ground collider must not fill the new playable lower corridor.

Room2 would expand to x3600..13800,width10200. Move the temporary UPPER outer doorway to13800; downstream boss bounds13800..15200, handroom15200..16600, handx15580, retaining relative actors/checkpoints. Lower8.1 returns upward or eventually continues RIGHT into9.1. Keep that lower-right continuation visibly closed until9.1 is implemented; do not route it into the temporary upper boss doorway. No new enemies/rewards/abilities proposed.

Verification: real-input upper climb and reverse; reachable main ledges with whole-body headroom; deliberate drop, ordinary jump-through and reattachment; full lower-floor traversal; blue wall solidity and nonblocking arch/crystal scenery; complete return-platform climb and the reserved lower-right passage; both high/ground Section7 joins; exact render/collision shapes and shell sweep; full camera follow at both heights without snap, artwork coverage and map placement; complete Sections1-8 traversal preserving raised Section5/6 entry, Section6 local floor denial, Section7 return, sealed future-smash floor, outer receiving, save/checkpoint semantics. Use slot0 or isolated saves. Visually review every new vertical/horizontal seam and the global room before accepting.
