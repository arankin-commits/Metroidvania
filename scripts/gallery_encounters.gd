extends Node2D

const LAYOUT = preload("res://scripts/split_gallery_layout.gd")
const SCOUT = preload("res://scripts/scout.gd")
const SENTINEL = preload("res://scripts/ledge_sentinel.gd")
var world: Node2D
var enemies: Array[Node2D] = []

func _ready() -> void:
	name = "GalleryEncounters"
	_spawn()

func _spawn() -> void:
	for placement in LAYOUT.encounters():
		if world.gallery_defeated.has(placement.id):
			continue
		var enemy: Node2D = SCOUT.new() if placement.kind == "scout" else SENTINEL.new()
		enemy.name = placement.id
		enemy.position = placement.position
		enemy.player = world.player
		if placement.kind == "scout":
			enemy.patrol_bounds = placement.patrol
			enemy.awareness_height = 80.0
		add_child(enemy)
		enemies.append(enemy)
		enemy.defeated.connect(func() -> void:
			if world.gallery_defeated.has(placement.id):
				return
			world.gallery_defeated.append(placement.id)
			world._spawn_will_orb(enemy.global_position, 5)
			world._save_progress()
		)
		enemy.attack_landed.connect(func() -> void: world.game_audio.play_effect("enemy_attack"))
	set_active(world.current_room == 2)

func set_active(active: bool) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		enemy.visible = active
		enemy.set_process(active)
		enemy.set_physics_process(active)
		if enemy is CharacterBody2D:
			enemy.collision_layer = 1 if active else 0

func reset_at_hand() -> void:
	set_active(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
		enemies.clear()
	world.gallery_defeated.clear()
	_spawn()

func targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			result.append(enemy)
	return result

func strike(hitbox: Rect2, amount: float) -> void:
	for enemy in targets():
		var half := Vector2(17,20) if enemy is CharacterBody2D else Vector2(20,27)
		if hitbox.intersects(Rect2(enemy.global_position-half,half*2)):
			enemy.take_hit(amount)
