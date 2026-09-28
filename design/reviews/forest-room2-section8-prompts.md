# Section 8 bitmap prompts

Built-in imagegen, following the imagegen skill. Original references preserved. PIL used only for dimensions, alpha and registration inspection. The first upper edit retained a painted player; the second removes it. RGB checkerboard extractions require explicit matte removal and are not genuine transparency. Selected assets and measured registrations are recorded in the section review.

## upper

Use case: precise-object-edit. Edit target: attached Forest Room2 Section8.2 reference. Produce a clean game environment source plate at exactly 1448x1086. Remove ALL red/blue/purple drawn annotation circles, remove painted small player at bottom left, and remove the moon entirely replacing with natural blue cloud/forest sky. NO sun or moon anywhere. Preserve original pixel art, stone and moss geometry, three ledge positions and their top heights (highest y280 x350..1448, middle y600 x350..1110, small right y665 x1100..1390), ground top y810 and upper-left sloping solid mass. Preserve crisp texture details, blue forest waterfalls, recessed banner arches and full hanging vines. No new walkable platforms, no UI, no text, no circles, no added characters. This is an extraction/cleanup source; don't rearrange composition or resize objects.

## player

Precise object edit of attached clean Section8.2 plate. Remove the tiny glowing teal humanoid painted player at x90 y780 in the bottom left COMPLETELY, rebuilding the fern/air and moss floor behind it. Keep everything else pixel-for-pixel unchanged:1448x1086, all three ledges, stone, forests, cap coordinates, roof, plants. No humanoid silhouettes remain. No sun or moon, annotations, UI or text.

## lower

Use case: precise-object-edit. Attached reference is Forest Room2 Section8.1 lower hall. Produce clean registered game source at exactly1448x1086. Remove ALL blue hand drawn outline and completely remove the tiny teal player at x185,y770, replacing its surroundings with matching fern/air/moss. Preserve all original dark enclosed masonry, left solid pillar, banners, blue crystal niches, recessed arches, flat floor top y795, hanging moss silhouettes and composition exactly. Decorative crystal arch crests remain recessed scenery, do not add platforms. No characters, UI, markings or text. No moon or sun.

## background

Use case: compositing/outpaint. Create ONE continuous wide pixel-art recessed background for Forest Room2, about3:1 aspect ratio (2688x896). Image1 existing panorama is edit target and visual continuity source. Image2 upper8.2 and image3 lower8.1 are environment references ONLY, no characters/annotations/platform geometry. Extend existing panorama RIGHT by16% and DOWN by28%, preserving original first86% width/top78% forest, ruined banner arches and waterfalls in their positions. Far RIGHT14% becomes open blue forest gallery above a darker enclosed masonry hall below. Lower hall in rightmost14% spans approximately image y47%..87%, with recessed tall blue crystal niches, dark banner piers and hanging vegetation from image3; roof piers connect naturally upward to upper gallery. Paint scenery ONLY: remove all foreground walkable bright horizontal platform/floor bars, no near solid ledges or landing promises. Continue old view down into roots/deep ruined foundations, never stretching or clamping old last rows. Quiet blue shadow behind live terrain/player. Scale masonry to existing panorama; coherent single painting across new upper/lower transition and far-right view. No flipped/mirrored/repeated scenes, no collage boundaries, no fade/blur strips, no characters, text, UI, drawn circles, sun or moon. Clouds only in upper sky. Keep crisp pixel style and consistent lighting, blue forest depth, teal growth, naturally varied damage.

## upperprops

Use case: background-extraction. Attached clean upper Section8.2 source,1448x1086. Extract ONLY its plants, moss, bright blue crystals and hanging vines on the three playable ledges and on ground and upper-left roof mass. Preserve EXACT native image pixel positions and silhouette sizes, do not shift any objects: highest cap y280 x350..1448; midcapy600 x350..1110; lowcapy665 x1100..1380; floorcapy810. Every terrain stone and all background architecture/sky/trees/forest/blue glow wash must be removed. Keep full hanging tips and edge leaves. Render actual transparent background with real alpha, no painted checkerboard or white/gray shadows. If transparency impossible use flat neutral #808080 behind cutouts, with no gradient. No characters/text/annotations/sun/moon.

## lowerprops

Use case: background-extraction. Attached clean lower8.1 image1448x1086. Extract ONLY the plants/crystals growing along actual ground at y795 and vines hanging BELOW this floor, preserving exact native positions, floor moss line y795. All pixels not belonging to those ground plants/vines must become genuinely transparent alpha. Remove ALL decorative arch crest crystal niches above y690, banners, ceiling plants, piers, walls and sky/backdrop. Do not shift/resize/crop image. Black/gray matte is acceptable only if no real alpha possible, absolutely no painted checkerboard or gray residual shadows. No player/UI/circles/text/sun/moon.

## lowprops

Use case: background-extraction. Edit target attached clean upper8.2 plate1448x1086. Extract ONLY the small lower-right playable platform's attached moss/plants/crystals/hanging vines at x1100..1380,y665. Keep exact original image coordinates and canvas1448x1086. Keep all full hanging vine tips of THIS ledge down to abouty785. Remove everything else, INCLUDING the ground plants near/above y810 which overlap the hanging vines, all middle platform plants nearx1100,y600, all terrain stone/arches/walls/sky/otherplants. Single isolated foliage object, at exactly its original location. Genuinely transparent alpha; NO checkerboard, matte/shadow residues. NO additional plants, characters/text/sun/moon. Need distinct ownership: hanging tips belonging to this platform only, never moss/fern row belonging to floor below.

## foundation

Use case: outpaint/stylized-concept. Attached masonry foundation is material reference. Create a SINGLE coherent larger buried stone foundation painting about2304x864,2.67:1 aspect. It will cover world6000x2250 including roof mass and deep foundations; keep small dark weathered brick texture, irregular masonry piers, natural thick root paths, sparse teal vines consistent with attached reference. Extend downward and to right with new naturally varied masonry rather than stretching, repeating, flipping or copying whole motifs. No bottom/side blank strip or vignette, full opaque material covers every pixel to all four edges. No sky openings, arches with blue voids, visible walkable bright ledges, floors/caps, characters, symbols, UI, text, sun or moon. Pixel art with crisp texture, subdued blue-black/brown stone and restrained teal growth, material under source registered moss. Avoid giant ornamental landmarks, uniform support pairs and texture resets; masonry courses connect.

## foundation_extension

Use case: outpaint. Attached foundation painting is edit target. Extend LEFT by46.667% of original width, retaining original content in RIGHT68.18% of final image with the SAME masonry and root scale. New final wide panorama approximately4:1 (3072x784 if possible), same height of depicted environment. This game material covers worldx5000..13800,y-950..1300 including stair mass and later foundations; keep every brick/root proportion undistorted, add NEW coherent masonry and natural roots to left. Dark weathered stone, sparse teal vines. Single continuous material with physically joined masonry/root paths at extension seam. Full opaque coverage all edges, no vignette, sky/window openings, bright walkable caps, characters, text, UI, sun/moon. No stretching, flips/mirrors, repetition, collage lines, crossfade strips or giant decorative landmarks.

## midprops

Use case: background-extraction. Attached clean upper8.2 plate1448x1086. Isolate ONLY foliage belonging to the MIDDLE long ledge at x350..1110,y600. Keep exact original image coordinates, native moss cap anchor y600 and original width760. Preserve full hanging tips of this ledge down to abouty756 and edge plants. Remove ALL floor plants even where they overlap hanging tips aroundy735..810; they are separate objects and must not appear floating when this ledge moves. Remove all small-right ledge plantsx1100..1380,y665, highest ledge plants, roof foliage, stone, architecture, sky/glow wash, ground, characters, text. Actual transparent background/real alpha if possible. Otherwise flat neutral RGB128 matte with no shadows or checkerboard. No relocation, enlargement, new plants or redesign. No moon or sun.

