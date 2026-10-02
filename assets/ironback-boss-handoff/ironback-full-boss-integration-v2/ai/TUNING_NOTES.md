> Revision 2: Read ../IMPLEMENTATION_CORRECTIONS.md first. Its required VFX coverage, sprite playback bindings and attack-specific knockback supersede conflicting earlier guidance.

# Policy boundaries

Python policy controls selection, cooldowns, anti-repeat rules, phase2 entry and breathing intervals. It deliberately does not contain engine physics, hitboxes, animation clips, facing, repositioning, event guards, saves or actual attack execution. Context safety booleans must be calculated by the real controller using physical probes. Busy state ends only after complete recovery.

The choose() result None means no attack intent; the engine may hold/walk using the conditions in AI_AND_TEST_SCENE.md. During an attack the engine continues that committed move; it does not call finish merely because choose() returns None. Death must supersede/clean the engine encounter directly.

Run tests from the package root with `python ai/test_policy.py`. These tests do not prove actual wave jumpability, fight duration or difficulty. Initial values are moderate design targets and should be adjusted from ordinary playthrough evidence.
