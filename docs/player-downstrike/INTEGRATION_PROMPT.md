# Game-dev integration prompt

Add Groundbreaker/downstrike to the root Metroidvania Godot project. This package was tailored by reading scripts/player.gd and player_presentation.gd: player root is body center, half-height 23, gravity 1250, speed 255, jump velocity -500; normal attacks emit world Rect2 signals and enemies generally expose take_hit(amount). Preserve ordinary movement and existing weapon behavior. Do not edit the separate nested Metroidvania-main project.

Copy scripts and sprites into a named ability directory and adjust res:// paths in downstrike.gd/downstrike_visual.gd (the package uses its own project root). Instantiate the downstrike component as a player child and set player, foot_offset=(0,23), enemy/terrain masks to actual project layers. Do not assume demo mask values (terrain 1, player 2, enemy 4) match the real project. Set damage_multiplier from player.damage_multiplier() at cast start.

## Controller ownership and input

Add has_downstrike and an edge-triggered input (suggest E; optionally Down+attack if it does not conflict with platform drop). Persist its unlock only through the existing progression/save system. Default gameplay unlock is false; the isolated demo enables it. Gate begin() on controls_enabled, alive, unlock, no hitstun, dash, attack, heavy charge, heal, ledge grab/climb, platform-drop exception, volley/beam, meditation, or death sequence.

Insert handling after higher-priority dead/cutscene/hitstun/traversal branches but before normal action initiation and before ordinary velocity computation. Call before_move(delta) every eligible physics tick so cooldown advances even while idle. When it returns true, call move_and_slide() exactly once, then after_move(), update input-edge bookkeeping, presentation, and return. Never also execute the normal movement branch on the same tick. On a newly accepted cast clear jump buffer/coyote and combo/attack pending timers; prevent queued ordinary sword hits or buffered jumps during the lock. Sample relevant input-held state during the lock to prevent a held attack/dash firing on exit. On accepted incoming damage call cancel() before applying existing recoil; cancellation must not overwrite that recoil. Cancel/reset on death, teleport, room unload, and respawn. No second auto-processing movement script.

Example ownership pattern (adapt the surrounding player's branches):

```gdscript
if slam_pressed_edge and can_start_downstrike():
    downstrike.damage_multiplier = damage_multiplier()
    if downstrike.begin():
        jump_buffer = 0.0
        coyote_time = 0.0
if downstrike.before_move(delta):
    move_and_slide()
    downstrike.after_move()
    update_input_edges_and_presentation()
    return
# Existing ordinary controller continues here.
```

## Combat adapter

The component finds PhysicsBody2D/Area2D overlaps using swept descent volumes and a floor-local shockwave volume. It resolves a hitbox child up to one receiver, sharing one target set across descent/landing to avoid duplicate damage. For physics enemies implementing take_hit(amount), the existing fallback works. It intentionally does not overwrite their own recoil.

Some root-world encounters use manually intersected Rect2 bounds instead of physics hurtboxes. Add Area2D hurtboxes on a dedicated enemy layer to those receivers, or extend the component's query adapter to the authoritative registry using swept and landing Rect2 tests with the SAME per-cast deduplication and wall-occlusion rule. Do not simultaneously send legacy attacked/heavy_attacked signals and component damage to the same enemy.

For precise impact, implement receive_downstrike(payload) in the enemy damage adapter: validate alive/invulnerability, accept amount, then apply impulse once, preserving its existing damage receiver behavior. Payload has source, unique per-player attack_id, kind, origin, amount, impulse. Plunge impulse (0,+100), impact impulse away from player (+/-180,-130). Bosses may resist knockback through existing policy. If routing damage_requested through your central combat system, set auto_dispatch_damage=false to avoid duplicate dispatch.

## Art and VFX

Connect animation_requested to the supplied ability visual or add the manifest clips to the real presentation system. While active, hide/suppress normal player drawing so two characters do not overlap; restore it on finished/cancel. The existing project uses custom _draw presentation, so hiding only a Sprite2D is insufficient: add an early return in the normal drawing path while the ability visual is visible.

Imported body canvases are 512x512 with registration point (256,420). Start with uniform scale 0.22 and offset (0,23-164*0.22); adjust against existing sprite proportions. Registration is hand-estimated; inspect every pose, both facings. All poses register the boots/body floor contact, and impact hands strike ahead of the boots. The sword remains sheathed: no blade stab, sword-active hitbox, or sword-through-floor pose. Descent damage is the compact descending body/feet; impact is a two-handed smash. Keep physics unchanged and never let damage penetrate solid floors. Nearest-neighbor filtering. World-space shockwave and dust already spawn separately at the actual floor collision. Add a short descent streak through the game's effect pipeline if desired; it is cosmetic, not another damage source.

## Cracked floors

For a standalone panel attach cracked_floor.gd to its StaticBody2D, give it a CollisionShape2D and matching visible art, and connect broken to your existing world-state service keyed by stable persistent_id. Persist broken IDs and reapply removal on room reload. The sample script does not write a save file or alter checkpoints. On break disable both collision and rendered terrain; preserve unrelated tiles and geometry. If terrain is TileMapLayer, implement break_from_downstrike(point,attack_id) on the contacted terrain adapter and map the world contact to the correct cell; remove only cells flagged cracked and update their visual/collision/save state. Seam contacts must choose the actual contact cell rather than indiscriminately clearing a radius. Recovery uses gravity so the player falls through the opened hole. Do not instantly warp them beneath the floor.

## Acceptance

Verify ground cast, descending cast, cast during jump ascent, thin-enemy descent hit, one target across plunge+impact (one hit), several separate shockwave targets, wall blocking, airborne enemies outside shockwave height, slopes/one-way/moving platforms, floor contacts at different render frame rates, hurt interruption, no stale pending attacks, cooldown, no extra invulnerability, both sprite facings, broken floor visuals/collision, fall-through, respawn and save/reload persistence. Report actual scene verification separately from the package's isolated tests.
