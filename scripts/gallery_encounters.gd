extends Node2D

const LAYOUT = preload("res://scripts/split_gallery_layout.gd")
const SCOUT = preload("res://scripts/scout.gd")
const SENTINEL = preload("res://scripts/ledge_sentinel.gd")
const REFERENCE_ENEMY = preload("res://scripts/enemies/reference_enemy.gd")
var world: Node2D
var enemies: Array[Node2D] = []

func _ready() -> void:
	name = "GalleryEncounters"
	_spawn()

func _spawn() -> void:
	for placement in LAYOUT.encounters():
		if placement.has("roster"):
			var roster: Array = placement.roster
			var offsets: Array = placement.get("offsets", [])
			for i in roster.size():
				var enemy_id: String = "%s_%d" % [placement.id, i]
				if world.gallery_defeated.has(enemy_id) or world.gallery_defeated.has(placement.id):
					continue
				var enemy = REFERENCE_ENEMY.new()
				enemy.enemy_kind = roster[i]
				enemy.ground_origin = false
				enemy.name = enemy_id
				var offset_x: float = offsets[i] if i < offsets.size() else (i * 30.0 - 15.0)
				enemy.position = placement.position + Vector2(offset_x, 0)
				enemy.set_meta("spawn_pos", enemy.position)
				enemy.player = world.player
				enemy.patrol_bounds = placement.patrol
				enemy.awareness_height = 450.0
				enemy.ai_enabled = true
				add_child(enemy)
				enemies.append(enemy)
				enemy.defeated.connect(func() -> void:
					if world.gallery_defeated.has(enemy_id):
						return
					world.gallery_defeated.append(enemy_id)
					var all_defeated := true
					for j in roster.size():
						if not world.gallery_defeated.has("%s_%d" % [placement.id, j]):
							all_defeated = false
							break
					if all_defeated and not world.gallery_defeated.has(placement.id):
						world.gallery_defeated.append(placement.id)
					world._spawn_will_orb(enemy.global_position, 5)
					world._save_progress()
				)
				enemy.attack_landed.connect(func() -> void: world.game_audio.play_effect("enemy_attack"))
		else:
			if world.gallery_defeated.has(placement.id):
				continue
			var enemy: Node2D = SCOUT.new() if placement.kind == "scout" else SENTINEL.new()
			enemy.name = placement.id
			enemy.position = placement.position
			enemy.set_meta("spawn_pos", enemy.position)
			enemy.player = world.player
			if placement.kind == "scout":
				enemy.patrol_bounds = placement.patrol
				enemy.awareness_height = 450.0
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
			enemy.collision_layer = 2 if active else 0
			enemy.collision_mask = 5 if active else 0
			if not active and enemy.has_meta("spawn_pos"):
				enemy.position = enemy.get_meta("spawn_pos")

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
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var box: Rect2
		if enemy.has_method("combat_bounds"):
			box = enemy.combat_bounds()
		else:
			var half := Vector2(17,20) if enemy is CharacterBody2D else Vector2(20,27)
			box = Rect2(enemy.global_position-half,half*2)
		if hitbox.intersects(box) or (enemy is CharacterBody2D and hitbox.intersects(Rect2(enemy.global_position - Vector2(17, 20), Vector2(34, 40)))):
			enemy.take_hit(amount)
