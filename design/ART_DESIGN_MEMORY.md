# Art design memory

Established 2026-09-26. Applies to existing and future cave and forest rooms.

Read both this note and [ROOM_DESIGN_MEMORY](ROOM_DESIGN_MEMORY.md) before creating
or adjusting rooms. This note extends its visual rules; it does not change movement,
collision, progression, save behavior, or the approval required for major room changes.
Preserve the project's pixel art, teal traveller, hand-chair checkpoints, Will,
Heartroot history, and inherited Wills. Art must help players understand and remember
the authored space.

For supplied images, follow the [circle-color gameplay key and room reference
catalog](ROOM_DESIGN_MEMORY.md#supplied-image-annotations-and-room-references).
Those annotations define terrain and interaction roles; visual decoration must
preserve their intended behavior. Forest Room 2's section paintings and layout are
stored in [references/forest-room2](references/forest-room2/README.md).

## Foreground/background readability and layer separation

- Extend the room note's hierarchy: player and attack tells first, usable edges and
  rewards next, landmarks next, distant scenery last. Keep local value contrast around
  the teal traveller even in green forest foliage or teal cave lighting.
- Use crisp pixel silhouettes and clear surface edges for playable terrain. Recess
  decoration through lower contrast, quieter detail, and muted color. Use palette and
  detail density to suggest softness without blurring the pixel-art style.
  Judge this at the final camera zoom: a background scaled across a large room can
  turn small painted details into competing shapes. Keep distant edges below the
  contrast of support edges, and use broad quiet areas behind combat lanes.
  Compose distant landmarks for the actual world-space camera views above the
  registered terrain. Overlay the route silhouette and camera rectangles when
  planning a background: a forest or waterfall visible in the complete painting
  may disappear behind a solid foreground foundation in play. Raise or reposition
  that recessed composition while preserving terrain registration; verify the
  resulting depth and landmarks in the running game at the route and jump apex.
- Distinguish distant scenery, playable terrain, and true foreground occluders.
  Assign depth deliberately; a dark or large trunk is not automatically foreground.
  Respect the user's layer assignment and keep its whole silhouette in that layer,
  including roots and branches. Carry the same depth role across neighboring sections
  where scenery forms a continuous transition; avoid partial masks that switch depth
  midway through a trunk.
  A nearby but separate tree can have a different depth assignment. Apply a
  screenshot-specific correction only to that identified tree; adjacency alone does
  not authorize changing another trunk's layer.
  When moving scenery behind terrain in a flattened painting, restore any usable
  support edges that were baked behind it; removing the mask alone can leave the
  player standing on a hidden floor. Match those edges to authoritative collision.
  Background roots and arches sit behind terrain and entities. Near trunks, roots,
  foliage and framing sit in front of BOTH the floor and the player: their opaque
  silhouettes hide everything behind them while the player walks past. Keep this
  consistent with any foreground parallax. Separate foreground art into transparent
  layers or precise masks; a flattened backdrop cannot supply correct occlusion.
  Never draw a floor cap, moss line, navigation trace or player over an opaque near
  trunk to reveal the hidden route. Preserve continuous collision behind the occluder;
  decorative foreground does not automatically become a physical barrier. Check
  that canopy and adjacent terrain collision do not create hidden barriers behind
  a decorative trunk, especially across section joins. Test walking and full jumps
  through the occluded route from both sides; visual coverage cannot justify an
  invisible obstacle. Deliberate solid obstacles must be visibly readable.
  Verify occlusion in motion from both directions, including any player glow or attack effect:
  opaque foreground must cover those pixels too. A useful rendered check compares
  player-visible and player-hidden frames inside the mask; checking z values alone
  cannot establish that the player actually disappears behind the silhouette.
  Validate generated cutout alpha: bark intended to be opaque must have full opacity,
  otherwise a faint player/glow leaks through even with correct layer order. Keep
  partial alpha at silhouette edges only; verify both interior coverage and real
  transparency outside the shape in rendered frames.
  Foreground masks must trace the CURRENT displayed artwork under its actual
  registration. Whenever a painting is replaced, regenerated, scaled or repositioned,
  revalidate every affected mask; never assume the old trunk outline still matches.
  All opaque visible bark must cover the character, glow and effects behind it.
  Check the full crossing in both directions, including silhouette edges and branches,
  rather than only a few interior sample positions. A mask-interior pixel test cannot
  detect visible bark omitted from that mask; compare coverage against the displayed
  silhouette too. Do not accept any player pixels drawn over opaque foreground bark.
  Choose acceptance samples from the displayed painting independently of the mask:
  include opaque bark edges AND nearby open air. The open-air samples must keep the
  player visible; an oversized mask can hide a character behind background pixels.
  Check each foreground object individually, including its reachable branches;
  successful samples on one tree or an overlapping seam trunk do not validate another.
  Before correcting a screenshot defect, locate the exact pictured object in the
  running room using surrounding landmarks, then match it to its rendering node and
  source painting. Ordinal descriptions such as "second tree" are insufficient.
  Reproduce the defect on that object and verify that same view after the change;
  never substitute a nearby object's passing checks or claim all objects are fixed.

## Parallax and depth

- If parallax is used, move distant layers more slowly than nearer scenery. Keep
  movement restrained enough that players can track platforms, opponents, and exits.
- Keep collision-bearing terrain, gates, doors, rewards, and their visual anchors in
  world space. A background architectural feature that explains a route must not drift
  away from that route. Reserve parallax for genuinely distant elements.
  A composed artwork plate containing foreground terrain must stay fixed in world
  space. Separate distant layers before introducing parallax; moving the entire plate
  would detach visible support edges from collision.
- Preserve crisp pixels through consistent scale, nearest-neighbor sampling, and
  stable positioning. Review depth during camera movement for shimmer, distracting
  motion, exposed background edges, and apparent gaps in the cave shell.

## Biome and room visual identity

- Caves share substantial stone, ruined architecture, cool shadow, and restrained
  accents. Forests express related history through bark, roots, canopy, and weathered
  remains. Carry Heartroot motifs between biomes without making their materials alike.
- Give each room a recognizable silhouette, landmark, material arrangement, and
  lighting emphasis tied to its room brief. The Split Gallery's suspended stone
  galleries and the Hand's Refuge's sheltered resting space should remain distinct.
  Write one physical cause for its present condition (failed suspension, root pressure,
  erosion). Express that cause at three scales: chamber silhouette, distinctive
  architecture, then sparse damage details. A common cause ties different chambers
  together more convincingly than placing the same prop in every chamber.
- Keep warm hand-chair light and established interaction cues recognizable across
  biomes. Local palettes must preserve these meanings and the player's visibility.

## Asset diversity versus repetition

- Reuse a coherent material kit; vary exposed rock shapes, structural damage, root
  growth, and architectural placement to serve different chambers. Do not substitute
  random rotations or clutter for an identifiable place.
- Extend the room note's continuous-background rule: compose one room-specific scene
  around its actual chambers and levels. Repeated motifs may connect areas; repeated
  copies of the same whole background or landmark must not erase their identities.
- Join terrain texture and silhouettes across connected surfaces. Follow the existing
  continuous-rock rule: construction seams, mismatched blocks, and background slivers
  must not divide what should read as one mass.
  Share world-space texture coordinates across floors, slopes and shell polygons.
  Define the density of stone detail in world pixels, independently of panorama
  resolution and room width. Extending a foundation field must not enlarge its bricks,
  chips or leaf patterns into soft blocks. Supply enough authored detail, or combine a
  continuous broad color/weathering field with crisp native world-space material detail;
  inspect both at gameplay zoom. Keep that same detail scale through earlier foundations
  when the shared field changes. Distant architecture may use broader, quieter shapes,
  while playable masonry needs smaller, crisp detail and a clear support edge.
  Independently registered section paintings may have incompatible foundation fills
  even when their floor edges align. Use one continuous material fill beneath those
  contours, preserving registered moss silhouettes and gate marks; inspect the
  foundations below the route as well as the support edges at the join.
  Restrict texture variation to the material fill; preserve the readable caps and gate
  marks. Avoid uniformly spaced decorative dashes or identical support pairs on every
  platform. Attach visible chains to plausible supports at both ends.

## Visual language for ability gates

- Maintain a consistent cue dictionary. Amber fractures identify heavy stone; current
  breakable walls must communicate the charged attack earned from the first boss.
  Show solidity and a deliberate breakable material, not an arbitrary barrier.
- A fractured floor must read as a floor requiring downward force, distinct from the
  wall gate. The planned downward smash is unimplemented: keep that floor sealed and
  do not imply current attacks or drop-through input can open it.
- Derive drop-through markings from actual one-way terrain. Structural floors remain
  visually solid. Show a descent's destination and landing, and tease future routes
  without presenting them as currently reachable. Use the room note's movement
  measurements for every apparent jump or dash opportunity.

## Environmental landmarks and navigation

- Use distinctive architecture, root formations, memorials, or hand-chair alcoves at
  meaningful junctions. Make landmarks recognizable from both travel directions and
  from neighboring vertical levels; avoid interchangeable decorations at every turn.
- Let Heartroot traces and inherited-Will imagery suggest a place's history using
  established lore. Keep decorative lore marks distinct from rewards and interactable
  objects. Will rewards must stand out from ambient particles and background glints.
- Preserve navigation anchors after rewards are collected or shortcuts open. A return
  visit should still reveal where the player is and what route has changed.

## Framing and composition

- When modeling, adapting, editing or extending an environment from an image, omit
  moons and suns unless the user's prompt explicitly requests them. Their presence
  in the reference image does not authorize retaining or reproducing them. Include
  this exclusion in image-generation/edit prompts and verify the delivered artwork.
- Compose at gameplay camera scale. Arches, rock openings, light, and sparse foreground
  shapes should frame useful destinations or deliberate future gates. Show some
  destinations before arrival without revealing the whole interconnected room at once.
  Verify the presented game window as well as the internal viewport texture. A
  viewport capture can show the complete composition while the actual embedded
  window clips it. Keep the authored logical resolution stable and scale its whole
  view to fit smaller windows, preserving aspect ratio and nearest-neighbor sampling.
  Integer scaling with a minimum of1x cannot fit a window below the logical size;
  test undersized, native and differently proportioned windows, including menu titles,
  HUD edges and input alignment. Check the final window transform, not just a resized
  copy of the internal render texture, before claiming screen framing is correct.
  Paint enough scenery above every elevated ledge for the camera to follow a full
  normal jump at the actual viewport and zoom, including ledges beside section joins.
  Never suppress upward camera movement to conceal missing artwork. Extend the
  environment naturally, then verify camera follow with actual jumps in the running
  game; a standing screenshot or manually placed jump apex is insufficient.
  A continuous room must not visibly snap when crossing a camera-limit threshold
  or artwork seam. Use a consistent camera envelope or smoothly varying limits,
  with painted coverage throughout the transition. Review both travel directions,
  jumps and reversals near the boundary at gameplay scale.
  Expanding the shared camera envelope for a lower branch also changes earlier
  ground views. Recheck every affected foundation and stair underside; continue
  their real solid mass and authored material below the new visible extent before
  changing limits. An old bitmap-bottom cutoff must not become a floating floor,
  exposed void, or stretched last-row texture elsewhere in the same room.
  Test the response at camera limits as well as at section seams. Position smoothing
  alone does not smooth Godot's hard limits; enable limit smoothing where the camera
  should ease into the bound. Measure consecutive frames through ascent, apex and
  descent: total camera travel and artwork coverage can pass while the view still
  stops abruptly against a clamp and restarts on landing.
- Keep takeoff edges, landings, ledge grips, exits, interaction cues and attack tells
  readable through placement. Brief player occlusion behind an actual foreground
  trunk is intentional during safe walking; render it correctly. Keep such occluders
  away from hazardous jumps, combat and interactions, and show the route before and
  after the obstruction. Do not solve readability by drawing the player or floor
  through the foreground silhouette.
  Foliage beside takeoff edges, receiving ledges and landings must remain behind the
  player so their position and footing stay visible. Do not include such plants in
  a broad foreground mask just because they share a flattened painting with a near
  trunk. Trace occluders individually; if a true near silhouette overlaps a critical
  landing, change its placement or shape and verify approach and landing in motion.
- Use localized light to emphasize a route decision, reward, or resting place. Keep
  quiet areas visually quieter; avoid making every platform equally bright or ornate.
  Establish one dominant environmental emphasis per camera view. Secondary light
  connects adjoining views at lower intensity. Prefer soft gradients over concentric
  rings, and retain a physical landmark after a reward and its glow disappear.

## Enemy and attack readability

- Extend the room note's encounter and negative-space rules: reserve clear space around
  silhouettes and combat lanes. Check enemies against the actual local background,
  including both approach directions and vertical views.
  Compose the background using the encounter's actual movement and projectile lanes,
  rather than an empty-arena screenshot. Place the dominant architectural landmark
  outside those lanes, or recess its edges enough that anticipation, projectiles and
  recovery remain distinct as both actors move. Inspect active attacks at the entrance,
  center and retreat positions; a clear central view does not validate the whole arena.
  Practice targets in a rest room need their own quiet aiming alcove, clear of the
  chair approach and dismount. Assign them an explicit blocking or nonblocking role;
  an enemy-shaped teaching target must not become an accidental wall across the rest route.
- The Temple Guardian mini boss reference is
  `references/temple-boss/temple-guardian-design-sheet.png`: a massive moss-covered
  stone construct with cyan chest diamond, runes, slit visor and hanging temple
  banners. Use its distinct chain-fist windup/extension/retraction, two-handed
  braced shot, three punches and raised-arm slam as the visual reference. Its
  half-health phase cue brightens the chest and runes.
  Its thirteen action/idle poses share a 144px standing scale and local foot y47;
  build from measured delivered cutouts, since image extraction may reposition
  sprites. Keep the detached fist and projectile separate from body poses, and
  center their opaque contact cores on the swept gameplay collision. The firing
  muzzle flare must fade before a crop edge rather than ending in a bright rectangle.
- Preserve distinct anticipation, attack direction, and recovery cues. Scimitar
  thrusts, overheads, spins and jump landings need different silhouettes, motion and
  timing; guardian punches, slams and braced firing must also differ in pose so color
  alone does not carry their meaning.
  Temporary boss protection needs a distinct pose and silhouette/glow cue, separate
  from a damage flash. Tie its visible onset and end to the actual attack phase:
  a charging guardian braces its firing wrist and shows protection; that cue ends
  on projectile launch so the player can read the newly available punish window.
  Verify the charging and post-launch views against actual melee/projectile damage.
- Keep particles, reward effects, foliage, and overlapping enemies from masking danger.
  An encounter must become readable before it can punish the player's approach;
  decoration must not disguise unfair attacks from outside the camera view.

## Animation and hitbox clarity

- The supplied cave and forest enemy designs are cataloged in
  [references/enemies](references/enemies/README.md): goblin, goblin combo,
  goblin dog, goblin sentinel, kobold archer, kobold clubber and kobold summoner.
  Consult the relevant original sheet when authoring those enemies; the reference
  catalog itself does not add encounters or change progression.
- Will of Wrath retains its damage bonus without a rectangular outline around
  the traveller. Preserve charge-ready white blinking as its own combat cue.
- The Forest Guardian reference is a moss-covered hooded kobold archer with luminous
  blue eyes, branch bow and stocked quiver. Its summon channel/emergence, aiming/full
  charge/release, five rapid shots, arrow pull/slash/stab, leap/dash/landing and volley
  poses remain distinct.
  The Forest Boss summons (Earthen Bear, Earthen Troll, Tree Ent) use authored 5-row
  sprite sheets preserved in `assets/references/forest_boss_summons/` and transparent
  isolated game atlases in `assets/characters/` (`summon_bear_atlas.png`,
  `summon_troll_atlas.png`, `summon_ent_atlas.png`).
  Each entity implements full animation states across 5 rows: Row 0 Idle (6 frames),
  Row 1 Walk (8 frames bear/ent, 6 troll), Row 2 Run (8 frames bear/ent, 6 troll),
  Row 3 Attack (8 bear, 6 troll, 12 ent), and Row 4 Recoil/Hurt (6 frames).
  Extract connected character silhouettes from the overlapping storyboard panels;
  uniform column cuts clip limbs and root effects and can carry labels into play.
  Summons emerge with root effects, face their movement/target direction, and ground their
  feet to match collision bounds.
  Preserve the reference arrow, root and impact effects separately when a storyboard panel
  contains effects rather than the boss. The authored facings use independent registered
  cutouts; isolate neighboring silhouettes before packing cells, and verify each pose in the arena.
  Reference impact panels may contain arrows still descending above the contact
  burst. Render only the burst on collision; replaying the whole panel at a target
  invents an apparent follow-up attack. Preserve the source and separate its roles.
- Match visible attack timing and reach to the real active hitbox. Wind-up and recovery
  must be distinguishable from damaging frames; decorative trails must not imply extra
  damage range. Projectiles and impact effects must agree with actual contact.
  Do not turn damage bounds into generic bright arcs, rings or wedges on every
  melee strike. Use the weapon pose and motion as the primary cue. Any added trail
  must follow that weapon's actual sweep and the reference's effect language;
  reserve visible hitbox outlines for explicit debug views.
  Afterimages, dust, wind and impact debris are essential combat cues when the
  reference calls for them. Rejecting generic hitbox arcs does NOT mean removing
  those effects. Build a textured, tapering blade wake along the authored sweep,
  with successive fading weapon/body afterimages; distinguish a rising/overhead
  cut, reverse swing, horizontal spin and straight thrust by their trajectories.
  Forceful grounded motion kicks dust backward from actual feet; landing erupts
  dust and stone outward from actual ground contact. Traveling wind has a bright
  contact core and softer layered trailing ribbons. Stagger emission and decay,
  rather than showing a fixed outline throughout the active phase. Keep the current
  silhouette and steel crisp over translucent wakes, limit lingering clutter, and
  inspect anticipation, release, contact and recovery in motion in both directions.
  Decorative dust/debris must never gain collision or imply a new damaging lane.
  If a reference depends on smoky curls, mottled highlights and crimson streaks,
  a smooth procedural band is not a sufficient visual match. Use an isolated
  textured VFX asset, verify genuine alpha and matte-free edges, then animate its
  direction, release and decay. Keep a crisp contacting crest and subdued broader
  wakes separate, and register any ground-skimming slash above the floor plane.
  Match effect scale relative to its actor in the reference, not just its texture
  shape. Check both at gameplay zoom; resizing a bright contacting crest requires
  reviewing its damage footprint, launch height and leading wall clearance together.
  A blade aura must register to the actual steel outline in each facing and pose,
  build during anticipation, and flare on release. Render its glow behind the steel
  so the weapon remains legible; remove detached indicators when the blade itself
  carries the charge cue. Do not mirror aura coordinates across independently
  authored character views.
  The traveller blinks white only at full heavy charge, starting immediately when
  ready and repeating while held. Preserve texture alpha; a white tint multiplied
  into the colored atlas cannot produce this cue. While charging and walking on
  the ground, retain the charge pose above the hips and animate walking legs below
  them. Move the torso, hands and sword with the same gait's hip rise and sway;
  align the leg crops to the hip pivot and overlap the moving waist seam to avoid
  detached halves. Keep feet grounded and collision unchanged. Release/reset
  clears the blink.
  Give a heavy attack weight through timing and body commitment: a deliberate
  build, fast release, brief contact hold and slower follow-through/recovery.
  Synchronize the blade flare and low attack sound with release. Apply any contact
  pause only after real damage, clear it on encounter reset, and keep controls
  responsive. Bigger generic effects or increased damage alone do not convey mass.
- Align standing feet, ledge-gripping hands, landing poses, and weapon origins with the
  controller and collision measurements in the room note. Do not change movement or
  hitboxes merely to accommodate a new sprite.
  The approved hooded traveller reference is stored in
  `references/player/character-animation-reference.png`. Preserve the previous
  58-pixel standing hood-to-boot silhouette and the separate 28-by-46 controller
  body. Measure visible body height rather than the atlas canvas, blade trails or
  raised cape. Register boots at the controller's floor contact; calibrate a
  generated standing variation if its body scale differs. Keep the new identity
  through healing, meditation and death, and preserve earned weapon/ability gates.
  Map every reference combo hit to its own ordinary-attack pose: horizontal,
  upward, then downward. A single working slash does not verify the combo, and
  assigning the remaining poses only to heavy attacks leaves the normal chain
  incomplete. Verify successive real input presses, both facings and chain reset.
  For character atlases, measure each delivered pose instead of trusting a generated
  grid. Use a shared body scale and foot pivot, preserve space for the complete blade,
  and exclude neighboring silhouettes from every crop. Verify real alpha, opaque
  interiors, transparent gutters and grounded foot alignment across all poses before
  importing. A painted checkerboard is not transparency.
  Register the measured opaque boot row after resizing; a scaled source floor
  coordinate can drift by a pixel or two through rounding.
  Preserve every supplied animation frame unless the user explicitly authorizes
  removing frames. Do not silently reduce a reference sequence to representative
  poses, discard transition frames, or replace the complete sequence with a smaller
  generated atlas. Retain the supplied frame order when preparing runtime assets.
  Record per-sequence counts and source regions in a frame catalog; verify every
  catalog entry appears in ordered runtime playback, including each slash's
  preparation and recovery. The traveller sheet supplies 67 character frames
  across 15 sequences; keep its extended horizontal wake with the active frame.
  Keep anticipation, active and recovery poses tied to the actual combat phases;
  render damaging trails within
  their authored volume and verify facing in both directions at gameplay scale.
  Anatomical handedness belongs to the character, not the screen direction. A
  horizontal reflection swaps weapon hands and asymmetric equipment. When a hand
  is specified, author opposite facing poses separately; trace shoulder, elbow,
  wrist and grip in every pose, including overheads, spins and airborne frames.
  Check exactly two arms and a free opposite hand. Generation prompts are not
  evidence of correctness: inspect the delivered sheet and its running animations.
  For advancing melee, anticipate the full lunge and sweep the active collision
  between physics positions. Stop the body before walls; keep windup/recovery
  harmless. Bright projectile cores describe contact; faint wakes are decoration.
- Keep the traveller identifiable during damage, healing, charge, dash, and ledge states.
  Effects and animation should clarify the state without prolonged disappearance or
  hiding nearby threats. Verify these states in motion, not only in still images.

## Art supporting traversal and room layout

- Build art from the approved chamber structure and purposeful placements. Reinforce
  routes with connected floors, walls, ceilings, supports, and readable thresholds;
  scenery must support the geometry rather than substitute for it.
  Every bright, flat platform cap is a route promise: show and physically provide a
  reachable takeoff chain from the entrance and a safe return unless the location is
  explicitly framed as a future gate or clearly recessed, nonplayable scenery.
  A decorative ruin crest should not use the same edge contrast as a landing. Check
  the complete chain in play; isolated support and camera fixtures are insufficient.
  Vertical reach alone does not establish a valid jump: a higher gallery can clip
  the head while the player approaches a lower shelf. Reserve an open takeoff pocket
  outside both overlapping undersides, with clearance for the whole body. If the
  route returns through a one-way floor, leave full standing headroom beneath that
  panel on the last return shelf, then provide a normal jump through it. Upward
  passage alone does not prove a ledge-grab landing is clear: the controller's
  landing-space query can still detect the panel. Verify descent, the complete
  return climb, ordinary support after landing and a repeated drop/return cycle.
  If the
  approved composition permits only specific ledges, adjust those ledges rather than
  adding unapproved footholds. Test continuous input from the actual previous landing.
  If a supplied section explicitly makes its stair the sole route, treat broad
  landings as part of one connected stair mass and keep all other ruin ledges as
  background. Seal the space under that mass with the same registered collision;
  decorative arches beneath it do not create a lower route or separate platforms.
  For a supplied composition with painted playable surfaces, establish one pixel-to-world
  transform and trace the solid tops, undersides and support volumes under that transform.
  If marked objects must move independently to meet the movement envelope, define
  each object's source-to-world transform once. Move its terrain, collision, attached
  plants and crystals together; keep the floor registration independent. A floor
  decoration crop must exclude plants belonging to moved platforms even when their
  source silhouettes overlap that crop. Partition the extraction by ownership: otherwise
  those plants appear twice, with ghost vines at their old coordinates. Generated
  artwork may ignore requested object positions, so measure its actual silhouettes
  and test the authored transforms rather than trusting prompt coordinates.
  Remove painted characters/UI before placing live entities. Replace the previous floor
  when the painting changes its height; a legacy collider behind the new art creates
  invisible footing or buries the receiving spawn. Physically test both directions and
  neighboring room entrances at their destination elevations.
  Trace platform sides and undersides as carefully as their tops. Broad polygons must
  not turn recessed stone, roots, plants or visibly open pockets into hidden barriers.
  Validate full-body clearance at every visible approach, including jumps beside
  walls, ledge catches and movement beneath overhangs, from both directions. A passing
  main route does not prove adjacent openings are usable. Fix inaccurate terrain
  collision rather than changing the player's hitbox or movement to fit the artwork.
  Audit each shelf individually: a corrected neighboring threshold or pillar does
  not validate that shelf's side or underside. Reproduce the reported blocked
  position and identify the actual collider before editing. Clearance checks must
  require the body to enter the pictured opening; a generous route-arrival tolerance
  can incorrectly pass while the character remains outside the old invisible wall.
  A hanging plant does not inherit collision from the platform it grows on. Keep
  the usable cap and actual stone supports solid, and exclude recessed foliage from
  their support volumes. Test airborne passage through the plant's height; walking
  below it or landing on the cap does not validate the hanging space.
  Recessed ruin spires, wall relief and arch piers are scenery unless explicitly
  assigned a traversal role. Give collision to usable moss-capped supports, not every
  painted stone silhouette. Verify the route still works when scenery is nonblocking.
  Multiple supplied sections may belong to one room: establish their shared scale,
  floor alignment and full camera envelope before tracing local geometry. An artwork
  entrance/exit arrow establishes the crossing location, not necessarily the next
  ground elevation. Record floor anchors separately from route entry heights:
  when a gallery leads into a drop, align the neighboring lower floors and preserve
  the elevated takeoff. Never raise the next section's entire foundation to an upper
  exit merely to make the crossing level. Check the join from the lower floor too.
  An artwork
  boundary must not become a room transition. Blend only the visual threshold;
  preserve the registered terrain contours on both sides. Author missing scenery to
  cover the full camera envelope without rectangular blank bands. Never flip, mirror,
  reflect or repeat an existing image to fill missing room artwork, whether in an
  asset or a shader. Continue the depicted environment in its natural direction:
  above a forest, trunks lead into treetops and canopy, with sky/clouds beyond;
  below it, roots and foundations continue plausibly. Preserve scale, perspective,
  lighting and depth while adding new composition. Never conceal a mismatched
  extension with a horizontal crossfade, transparency band, blur or shader gradient.
  This produces ghost branches, doubled silhouettes and a visible strip instead of
  continuity. Use a single coherent painting or author a precisely registered join;
  branches must connect with the same direction, width, bark detail and lighting.
  Inspect the actual join at gameplay scale while the camera moves across it; a
  pleasing overview and passing traversal tests do not establish visual acceptance.
  When independent plates cannot join cleanly, compose the adjoining recessed
  scenery as one painting and render registered terrain separately from shared
  draw/collision polygons. Keep attached plants and crystals in noncolliding scenery
  layers behind entities; separating terrain must not crop away its decorative
  silhouettes. Size cutout bounds around the full plant/crystal silhouettes, including
  hanging tips and edge leaves, rather than around only the stone cap. When ground
  polygons extend below the source bitmap, stop source-growth preservation at the
  bitmap boundary; continue deeper material with authored world-space fill. Source-growth masks must distinguish attached plants from blue sky, waterfall haze and recessed architecture; broad color tests can preserve background patches inside solid masonry. Tune and inspect the mask for each source before applying it to the enclosing mass. Clamped
  last-row pixels must not become stretched vegetation or false vertical supports. Validate extraction outputs for real transparency, source registration
  and opaque coverage before use. If an output contains a neutral matte, remove it
  explicitly and inspect rendered edges; do not present the matte as transparency.
  Keep textured terrain polygons inside the actual stone silhouette: including even
  a small pocket of source sky in an underside produces a blue patch and an invisible
  collider. Verify the rendered underside independently of the platform top.
  Foreground occlusion still applies
  across image joins; do not paint usable-edge traces across near trunks.
  Verify the actual rendered quad dimensions:
  UI texture minimum sizes can stretch a painting despite correct collision math.
  Walk across each join both ways without resetting the camera, and review the seam
  at gameplay zoom before accepting the room as continuous.
  Plan the entire cave silhouette, major voids, routes, encounter clearances and
  distant composition before local detail. Complete the enclosing shell first. Divide
  implementation along chambers, tunnels and thresholds; never expose work-unit borders
  through texture resets, repeated entrance arches, rectangular light fields or abrupt
  palette changes. Carry a material, damage direction or recessed structure across
  each transition while changing chamber proportions and landmark silhouettes.
- Use Room 3's enclosure and solidity as the cave baseline, as required by the room
  note. Thin suspended galleries can express Room 2's identity inside that shell;
  they must not make outer boundaries appear to be floating platforms.
- Distinguish deliberate descent shelves, solid receiving floors, combat spaces, and
  optional paths through their construction and framing. Avoid decorative obstacles
  that suggest false routes or force untested jumps. Forest branches and roots follow
  the same support-versus-scenery distinction.

## Review and references

Unplaced enemy art can be reviewed through reusable prefabs and a test-only scene
using the real player controller. Keep those prefabs outside the normal room scene
dependency graph until placement is authorized. Crowded storyboard rows need
silhouette-aware cuts: vertical cell boundaries can truncate a neighboring bow,
spear, staff or cape. Review every delivered pose in both facings, register feet
after resampling, and blit only each cutout's used bounds so transparent pixels
cannot overwrite another atlas cell. For a physics-driven leap, register the
airborne body's feet rather than applying the storyboard's vertical offset twice.
For a prone-to-standing opening, keep every pose on the collision floor, align the
body pivot as it rises, and keep floor blood in the room plate while clothing blood
travels with the character. Register the plate's painted floor to the real collider;
keep authoritative terrain drawn above the plate wherever their silhouettes differ.
When an injury changes clothing across a full animation set, paint registered alternate
atlases for every pose family and switch sheets from the player state. Preserve each
frame's alpha and pivot so blood follows moving limbs without changing silhouettes,
collision, sword effects, or animation timing. Keep the waking poses' existing blood.
While injured, moving on the ground uses the bloodied walk cycle at every speed;
airborne, combat, idle, and special poses retain their own animations.

Review at gameplay scale and in motion: both route directions, camera extremes,
combat effects, landings, gates, checkpoints, and collected-reward states. Check art
against collision and the map using the room note's verification process. Record only
reusable lessons in the relevant existing memory note.
During sectional work, reread both memories and the global plan before each unit,
inspect its neighbors, and check every completed seam immediately. Traverse the whole
room after three or four units. Finish with a zoomed-out composition check AND normal
camera checks: an overview cannot establish enemy readability or usable headroom.
Inspect doorway views beyond the painted backdrop too; transition openings need
recessed continuation rather than exposing the viewport clear color.

The [room memory's reference section](ROOM_DESIGN_MEMORY.md#intent-and-references)
contains the project's genre references. Extract principles from Hollow Knight, Ori,
Ender Lilies, Dead Cells, and other games; do not copy their layouts, assets, characters,
palettes wholesale, animation signatures, or interface treatments.
