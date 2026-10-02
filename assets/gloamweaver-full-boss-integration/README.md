# Gloamweaver — ground revision 3

This package replaces the ceiling encounter. Implement a floor-supported spider with ground crawl, fang bite, web-assisted ground charge, and silk snare. Remove pendulum swing, double swing, ceiling crawl, ceiling grip, reattachment, aerial zip, and ceiling drop from the active encounter. No attack requires ceiling geometry.

Read INTEGRATION_PROMPT.md, AI_AND_TEST_SCENE.md, and ANIMATION_VFX_AND_IMPACT.md. ANIMATION_BINDINGS.json is a declarative blueprint, not an engine resource. ai/gloamweaver_ai.py is an executable selection reference, not Godot movement code.

The existing PNGs are retained for reuse and reference; no new art was generated for this revision. The original design sheet depicts the superseded ceiling concept. Existing zip poses need ground contact calibration and possibly pose edits. Dedicated grounded walking frames are missing: author them in the game's established art pipeline. SPRITE_STATUS.md explicitly identifies every retained asset's status. Do not present a single idle frame sliding across the floor as a finished walk animation.

Deliver an actual test scene with the unmodified player controller, collision, slow status, every active animation, charge cable/trails, hurt response, and defeat cleanup. Assets and policy alone are not a playable scene.
