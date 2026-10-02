> Revision 2 (2026-10-02): Read INTEGRATION_FIXES_V2.md first. Shared gameplay registration, continuous web sockets, swing/zip/drop motion VFX and guaranteed safe snare opportunities supersede conflicting earlier guidance.

# The Gloamweaver â€” full boss handoff

Spider-themed ceiling/silk boss built with the same design, artwork, AI reference and integration workflow as Ironback, including explicit VFX coverage, actual crawl/hurt playback requirements and per-attack knockback from its latest revision.

Copy the body of INTEGRATION_PROMPT.md into the Game-dev agent chat and attach/extract this ZIP. The agent should complete a runnable isolated test scene in the existing game. This package contains design assets and executable selection/status REFERENCE logic, not a Godot project or an already-playtested encounter.

## Revision 2 correction work

INTEGRATION_FIXES_V2.md is authoritative for shared gameplay coordinates, anatomical socket registration, continuous silk, required zip/drop wind and floor-contact dust, and actual snare execution. The scheduler now permits far-range snares and prioritizes safe ready snares after three other actions without bypassing low-recovery/safety rules. Ten reference tests pass. No PNG is changed and no actual game-scene fix has run here: the agent must implement and verify the prescribed corrections.

## Contents and authority

1. AI_AND_TEST_SCENE.md â€” full moderate encounter specification, ceiling/swing/zip safety, traps, selection and test-scene acceptance.
2. ANIMATION_VFX_AND_IMPACT.md â€” required bindings for every body and effect key, hurt handling and six player knockback profiles.
3. INTEGRATION_PROMPT.md â€” ready-to-copy instructions for the Game-dev agent.
4. ai/gloamweaver_ai.py and ai/test_policy.py â€” executable engine-independent attack scheduler and nonstacking grounded slow reference, ten passing behavioral tests.
5. sprites/ â€”30 individual transparent body keys, measured manifest, source atlas and checkerboard preview.
6. vfx/ â€”12 individual transparent FX keys covering hooks/anchor/cable/swing/seed/trap/deploy/trigger/dust/bite/hurt/dissolve, manifest and preview.
7. reference/ â€” original labeled boss design sheet, exact three built-in-imagegen prompts, separation provenance.

Read SPRITE_STATUS.md before importing or claiming animation completeness. Use individual PNGs, not unmeasured source atlas cells or labeled design-sheet panels. Manifests own actual sizes and root estimates. Preview JPGs have an intentional checkerboard, but PNGs have real alpha. Separation preserves image pixels/alpha without rescaling; common padded canvases do not establish anatomical registration.

## Verification performed

Ten Python checks pass (including far-range snare priority, safety-preserving snare deferral and ordinary ceiling-sequence snare use): safe initial swing/busy pause; deferred one-time phase transition; path/trap/phase limits; low-punish cadence; cooldown/repeat rules; floor behavior/reset; nonstacking grounded-only slow/expiry/clear. All42 separate PNGs decode, contain genuine transparency and match manifest dimensions. Body/FX contact sheets were visually inspected and neighboring-pose crop slivers corrected.

No Godot scene, actual movement/rope physics, player hit receiver or real-controller balance test has run here. Moderate difficulty is a proposed tuning profile to validate in integration. Artwork is key-pose/static FX material, not all hand-authored intermediate animation frames. Ceiling-foot/spinneret sockets, side orientation and full attack/VFX playback must be verified in the actual game. Original project philosophy remains: honest collision, readable tells, safe recovery, measured movement, owned cleanup and isolated saves.
