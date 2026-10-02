> Revision 2: Read IMPLEMENTATION_CORRECTIONS.md first. Its required VFX coverage, sprite playback bindings and attack-specific knockback supersede conflicting earlier guidance.

# Ironback full boss handoff

Start with INTEGRATION_PROMPT.md: copy its body into the Game-dev agent chat with this ZIP attached/extracted.

## Revision 2 additions

IMPLEMENTATION_CORRECTIONS.md requires the missing VFX to be created as separate effect layers, actual walking/hurt sprite playback with coverage logging, and eight per-source player knockback profiles. This revision changes instructions, not the PNG artwork; the integration agent must implement the missing effects and validate the fight.

## Contents

- AI_AND_TEST_SCENE.md: moderate tuning, complete moveset, state ownership, safe AI decisions and test-scene acceptance.
- ai/ironback_ai.py: executable engine-independent attack scheduler reference; port to Godot, not a runtime Python dependency.
- ai/test_policy.py: six passing scheduler tests; run `python ai/test_policy.py`.
- sprites/: 30 separate RGBA body/FX key poses, measured manifest, source atlas and art status.
- reference/: original design sheet, original animation proposal, exact generation prompt.

AI_AND_TEST_SCENE.md supersedes older timing and sprite-size proposals. sprites/manifest.json owns the ACTUAL delivered canvas sizes and paths. The reference document's 256x256/12-frame/18-frame targets are full-animation authoring goals, not the number or sizes of delivered PNGs.

## Verification performed in this handoff

Six Python scheduler tests pass: attack commitment/pause, old-wave exclusion, queued single phase transition, phase-one/safety restrictions, cooldown/repeat limits and dead/inactive/airborne restrictions. Every separate PNG decodes and has genuine transparent background pixels. Sprite bounds/registration metadata is provided. No actual game project, boss physics, Godot scene or real-controller playtest is included here. Moderate difficulty remains a proposed profile for integration and measurement.

The source atlas was generated with built-in imagegen. Python/Pillow was used for the user-requested sprite separation into individual files and a verification preview; original generated artwork and alpha are preserved. No background chroma-keying, painted checkerboard removal or unverified full-frame animation claim.
