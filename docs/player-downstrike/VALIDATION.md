# Verification

Godot 4.7.2 headless execution: 13 checks passed, 0 failures. The test constructs real CharacterBody2D, Area2D, collision shapes, floor panels, and the ability component in an isolated physics world.

Verified: grounded start, reentrant cast blocking, one nearby ground-wave hit for 1.5 damage, full recovery, airborne start, one descent hit for 1.0 damage, shared plunge/landing target deduplication, direct cracked-floor destruction, fall-through during recovery, reset, cancellation, and retained cancellation cooldown.

Run: `godot --headless --path <this-package> --script res://demo/test_downstrike.gd`.

All twelve individual PNGs have real transparent alpha. ZIP CRC is checked during packaging. The source atlas was inspected to verify sheathed sword, fist smash, and isolated poses. Final engine asset import and demo startup were checked after the art replacement.

Not yet verified in the user's actual game: combat registry adapter, progression unlock/save integration, full player presentation and injury variants, slopes/moving/one-way platforms, wall occlusion under all map geometry, and persistent cracked TileMap cells. Those integration requirements are explicit in INTEGRATION_PROMPT.md. The demo is an isolated example, not a patch to the existing game.

This host's Godot reports a system certificate-store warning in headless mode. It did not prevent the physics tests or script execution; this package makes no network requests.
