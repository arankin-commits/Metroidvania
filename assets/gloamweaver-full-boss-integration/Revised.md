# Prompt for the game-dev agent

Replace the current Gloamweaver encounter with revision 3's ground moveset. Read README.md, AI_AND_TEST_SCENE.md, ANIMATION_VFX_AND_IMPACT.md, SPRITE_STATUS.md, and ANIMATION_BINDINGS.json in this package. These files supersede the older ceiling design and video-fix prompt.

Inspect the actual engine project and player damage/movement interfaces first. Remove swing, ceiling crawl/grip, retract, reattach, aerial zip, drop, and double-swing selection, timers, transitions, and VFX callbacks. Spawn the spider on the real floor. Retain ground bite, snare, hurt, phase change, and defeat. Implement harmless ground crawl and the telegraphed web-assisted ground charge, using real wall anchors and horizontal collision-safe floor travel. No ceiling encounter state may remain reachable.

Use the existing player controller without altering jump or movement to accommodate the boss. Implement the existing damage acceptance interface and the two distinct knockback profiles. Implement snare overlap/status in the real movement controller and cleanup. Keep the boss hittable on the floor during every tell/recovery.

Import and explicitly bind all active body/VFX assets. Author the missing ground walk frames in the project's established art pipeline and refine reused charge poses if they do not support the floor. Retired assets may remain on disk but must not be included as active encounter clips. The original design sheet is historical reference; it no longer defines runtime behavior.

Calibrate per-pose feet and spinneret sockets; use dynamic cable endpoints, charge trails, skid dust, bite effects, and the complete snare effect chain. Integrate policy eligibility with real measured body-edge distance, validated wall/floor path, trap slots, and full-recovery completion. The Python module is selection reference, not a finished Godot boss.

Create an isolated test scene with the actual player, flat floor, side walls, safe spawn, and restart. Run the acceptance checklist in AI_AND_TEST_SCENE.md. Provide modified scene/scripts and evidence of every move, jump dodge, real HP damage, slowdown, hurt/walk playback, and cleanup. State any placeholder art or unverified engine behavior plainly. Do not report completion from static art or Python tests alone.
