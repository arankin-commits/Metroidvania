# Forest Room 2 Section 6

Approved elevated gallery at x10200..11400 in ForestRoom2. Ground y162.202 aligns with Section5. Exactly three red-marked floating stone objects plus solid ground; arches, banners, plants and crystals are noncolliding recessed scenery. No new footholds, enemies, rewards or abilities.

West/east caps are y-250.106, center y-138.106, raised96px at the user's request. The west landing is96px above Section5 highest and requires an upward jump. Internal changes remain112px. Ground-to-cap distances are412.308/300.308/412.308px. Actual input traverses Section5 highest -> all three caps -> Section5 highest, without teleporting between landings. Local floor jumping and directional air dashing remain below the ledge-grab envelope and recover on ground. Section7's elevated connection is reserved, not implemented or claimed tested.

Assets: section6.png (1448x1086) provides registered stone; section6_props.png (1447x1087, measured within one pixel of source registration) uses a neutral RGB matte removed by the existing cutout shader, behind entities. The rejected checkerboard output was not used. Sections2–6 share sections23456_background.png (2152x731) across x5000..11400,y-950..810. Sections4–6 share sections456_foundation.png (2172x724), world-space fill3600x700 from(7800,60). Generated outputs are measured and registered explicitly; prompts do not guarantee dimensions or transforms. The live ground pass caught texture-edge clamping below the source painting. Growth preservation is limited to UV.y<=1; deeper terrain uses the shared fill, avoiding stretched last-row vegetation. No image flip, repetition, crossfade, moon or sun.

Room2 width7800; temporary doorway11400. Boss bounds11400..12800, handroom12800..14200, handx13180. Camera stays zoom0.96/top-760/bottom720 with shared smooth limits, no section resets. Receiving positions, map extent and downstream actors follow the expanded bounds.

Verification: forest_upper_gallery_smoke includes continuous Sections1–6 progression and reverse route, physical three-platform climb/return, floor-access denial, four exact terrain/collision polygons, vine clearance, ground shell sweep, outer doorway receiving and isolated-save checkpoint preservation. Gallery, stair, camera-limit, forest-regression and Twisted-Forest tests pass. Existing restricted log/certificate diagnostics and shutdown resource leaks remain; PASS markers checked separately. Live review uses slot0. A fresh game launch also verified the final shader and assets: [final startup](forest-room2-section6-final-startup.png). Screenshots: [ground seam](forest-room2-section6-seam.png), [west cap](forest-room2-section6-cap1.png), [center](forest-room2-section6-cap2.png), [east cap](forest-room2-section6-cap3.png), [ground](forest-room2-section6-floor.png), [map](forest-room2-section6-map.png).

Built-in imagegen followed the imagegen skill. PIL inspected dimensions/alpha only; code defines native terrain and world registration. Supplied references remain untouched. Exact prompts below, including the rejected extraction and replacement.

## plate

Edit target image into a clean game terrain source plate. Preserve dimensions 1448x1087, exact platform silhouettes and locations: left floating stone x45..450 top315, center x565..885 top495, right x1000..1385 top315; ground top885. Remove all red drawn circles, painted teal character bottom left, and the moon. Reconstruct clean foliage and blue cloud sky where removed. Keep crisp detailed pixel art, cyan moss caps, stone underside, vines, ferns, crystals, dark banner arches. No UI, text, annotation, sun or moon. Preserve source registration.

## background

Outpaint the existing wide panorama to the RIGHT by 23.0769 percent of its original width, so original content occupies exactly 81.25 percent of final width, same height. Preserve existing left scenery, scale, camera perspective and pixel detail. Continue naturally into the supplied section 6 style: three tall recessed arches, old vertical banners, lush deep blue forest and waterfalls through openings, clouds above canopy. Everything is recessed scenery; no bright cyan horizontal playable platforms or foreground floor. No moon, sun, player, annotations, repeated/mirrored image or crossfade strip. Single coherent continuous panorama.

## foundation

Extend this foundation painting to the RIGHT by 50 percent original width, same height, original occupies left two thirds. Continue the same dark detailed pixel masonry, connected roots and hanging teal vines with varied natural damage. Preserve original brick scale, lighting and connected silhouette through join. Fill the entire image with solid stone masonry/root foundation; no windows, empty sky, platform cap, text, characters, sun or moon. No repetition or reflection. One coherent continuous foundation painting.

## Rejected checkerboard extraction

Extract ONLY attached decorative plants, cyan moss fringes, crystals, ferns and hanging vines from the three floating platforms and the floor in this source image. Preserve exact pixel coordinates and image dimensions 1448x1086. All stone, arches, banners, sky, forest, waterfalls and empty space must be fully transparent alpha zero. Platform decoration left x45..450 y255..460, center x565..885 y425..625, right x1000..1385 y255..460; floor decoration y780..1050. Genuine transparent RGBA PNG, never checkerboard or flat matte. Do not move or redraw objects. No player, moon, sun, annotation.

## Final matte extraction

Make a registered decorative extraction of this exact source at 1448x1086. Keep original plants/crystals/vines pixel-for-pixel in original positions; no enlargement or rearrangement. Replace all sky, architecture, stone and empty areas with a perfectly flat solid neutral gray RGB128,128,128 matte. Keep ONLY colored plants/crystals/cyan moss fringe attached to left platform x45..450 top315, center x565..885 top495, right x1000..1385 top315 and floor top885. Remove stone supports but keep hanging foliage. No checkerboard, no fake transparency, no shadows on matte, no other objects. Exact source coordinates essential.


## Raised entrance revision

All three platforms move upward96px through their shared object transforms, including stone, collision and attached foliage. The full forest_upper_gallery_smoke passes with the raised route, including reverse traversal and floor denial. Running-game review_raised_entry uses an explicitly isolated no-jump fixture: walking from Section5 fails to enter or grab Section6, then an actual jump reaches it and the complete elevated route returns successfully. Slot0 only. [Current entrance view](forest-room2-section6-raised-entry.png) and cap1/cap2/cap3 screenshots show the revised heights. Earlier floor/map/startup screenshots above precede this height revision. No new durable art rule was needed; existing registered-object and real-controller rules apply.
