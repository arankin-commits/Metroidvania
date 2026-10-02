extends Node2D

const REFERENCE_ENEMY = preload("res://scripts/enemies/reference_enemy.gd")
var world: Node2D
var enemies: Array[Node2D] = []

const SPAWNS = [
	# Section 1
	{"id":"F1_Archer_0", "kind":"kobold_archer", "x":4186.5, "est_y":190.0, "patrol":Vector2(4050, 4320)},
	{"id":"F1_Archer_1", "kind":"kobold_archer", "x":3777.6, "est_y":360.0, "patrol":Vector2(3650, 3900)},
	{"id":"F1_Archer_2", "kind":"kobold_archer", "x":4651.7, "est_y":360.0, "patrol":Vector2(4500, 4800)},
	{"id":"F1_Goblin_0", "kind":"goblin", "x":4286.9, "est_y":570.0, "patrol":Vector2(4150, 4420)},
	{"id":"F1_Dog_0", "kind":"goblin_dog", "x":3919.3, "est_y":600.0, "patrol":Vector2(3800, 4050)},
	{"id":"F1_Dog_1", "kind":"goblin_dog", "x":4756.5, "est_y":600.0, "patrol":Vector2(4650, 4900)},

	# Section 2
	{"id":"F2_Archer_0", "kind":"kobold_archer", "x":6130.9, "est_y":280.0, "patrol":Vector2(6000, 6260)},
	{"id":"F2_Goblin_0", "kind":"goblin", "x":5683.1, "est_y":450.0, "patrol":Vector2(5550, 5820)},

	# Section 3
	{"id":"F3_Clubber_0", "kind":"kobold_clubber", "x":7553.1, "est_y":140.0, "patrol":Vector2(7400, 7700)},
	{"id":"F3_Archer_0", "kind":"kobold_archer", "x":7080.5, "est_y":270.0, "patrol":Vector2(6950, 7220)},
	{"id":"F3_Dog_0", "kind":"goblin_dog", "x":7118.3, "est_y":660.0, "patrol":Vector2(7000, 7250)},
	{"id":"F3_Dog_1", "kind":"goblin_dog", "x":7524.5, "est_y":660.0, "patrol":Vector2(7400, 7650)},

	# Section 4
	{"id":"F4_Goblin_0", "kind":"goblin", "x":8338.7, "est_y":560.0, "patrol":Vector2(8200, 8480)},
	{"id":"F4_Archer_0", "kind":"kobold_archer", "x":8465.5, "est_y":570.0, "patrol":Vector2(8350, 8600)},
	{"id":"F4_Dog_0", "kind":"goblin_dog", "x":8224.1, "est_y":600.0, "patrol":Vector2(8100, 8350)},

	# Section 5
	{"id":"F5_Archer_0", "kind":"kobold_archer", "x":9896.4, "est_y":240.0, "patrol":Vector2(9750, 10050)},
	{"id":"F5_Goblin_0", "kind":"goblin", "x":9509.0, "est_y":380.0, "patrol":Vector2(9380, 9640)},
	{"id":"F5_Dog_0", "kind":"goblin_dog", "x":9661.5, "est_y":730.0, "patrol":Vector2(9520, 9800)},
	{"id":"F5_Dog_1", "kind":"goblin_dog", "x":9964.2, "est_y":740.0, "patrol":Vector2(9820, 10100)},

	# Section 6
	{"id":"F6_Goblin_0", "kind":"goblin", "x":10530.2, "est_y":200.0, "patrol":Vector2(10400, 10660)},
	{"id":"F6_Archer_0", "kind":"kobold_archer", "x":11077.9, "est_y":210.0, "patrol":Vector2(10950, 11200)},
	{"id":"F6_Clubber_0", "kind":"kobold_clubber", "x":10809.6, "est_y":650.0, "patrol":Vector2(10680, 10940)},
	{"id":"F6_Dog_0", "kind":"goblin_dog", "x":10458.6, "est_y":660.0, "patrol":Vector2(10320, 10600)},
	{"id":"F6_Dog_1", "kind":"goblin_dog", "x":11194.4, "est_y":700.0, "patrol":Vector2(11060, 11330)},

	# Section 7
	{"id":"F7_Archer_0", "kind":"kobold_archer", "x":12530.0, "est_y":520.0, "patrol":Vector2(12400, 12600)},
	{"id":"F7_Dog_0", "kind":"goblin_dog", "x":11578.8, "est_y":650.0, "patrol":Vector2(11450, 11720)},
	{"id":"F7_Dog_1", "kind":"goblin_dog", "x":12227.4, "est_y":680.0, "patrol":Vector2(12100, 12360)},

	# Section 8
	{"id":"F8_Clubber_0", "kind":"kobold_clubber", "x":13595.6, "est_y":580.0, "patrol":Vector2(13450, 13740)},
	{"id":"F8_Dog_0", "kind":"goblin_dog", "x":13148.9, "est_y":610.0, "patrol":Vector2(13000, 13300)},
	{"id":"F8_Clubber_1", "kind":"kobold_clubber", "x":13430.1, "est_y":140.0, "patrol":Vector2(13300, 13560)},
	{"id":"F8_Archer_0", "kind":"kobold_archer", "x":13643.2, "est_y":180.0, "patrol":Vector2(13500, 13780)},
	{"id":"F8_Goblin_0", "kind":"goblin", "x":12875.9, "est_y":630.0, "patrol":Vector2(12740, 13010)},
	{"id":"F8_Goblin_1", "kind":"goblin", "x":13185.9, "est_y":640.0, "patrol":Vector2(13050, 13320)},

	# Section 9
	{"id":"F9_Clubber_0", "kind":"kobold_clubber", "x":14542.2, "est_y":570.0, "patrol":Vector2(14400, 14680)},
	{"id":"F9_Dog_0", "kind":"goblin_dog", "x":14009.5, "est_y":600.0, "patrol":Vector2(13880, 14140)},
	{"id":"F9_Goblin_0", "kind":"goblin", "x":14267.0, "est_y":610.0, "patrol":Vector2(14130, 14400)},
	{"id":"F9_Goblin_1", "kind":"goblin", "x":14357.8, "est_y":615.0, "patrol":Vector2(14220, 14490)},
	{"id":"F9_Archer_0", "kind":"kobold_archer", "x":14557.5, "est_y":190.0, "patrol":Vector2(14420, 14690)},
	{"id":"F9_Summoner_0", "kind":"kobold_summoner", "x":14401.3, "est_y":620.0, "patrol":Vector2(14260, 14540)},
	{"id":"F9_Summoner_1", "kind":"kobold_summoner", "x":14775.3, "est_y":590.0, "patrol":Vector2(14640, 14910)},
	{"id":"F9_Goblin_2", "kind":"goblin", "x":14163.4, "est_y":630.0, "patrol":Vector2(14020, 14300)},

	# Section 10
	{"id":"F10_Summoner_0", "kind":"kobold_summoner", "x":15141.0, "est_y":570.0, "patrol":Vector2(15020, 15260)},
	{"id":"F10_Summoner_1", "kind":"kobold_summoner", "x":15896.2, "est_y":600.0, "patrol":Vector2(15760, 16030)},
	{"id":"F10_Archer_0", "kind":"kobold_archer", "x":15322.0, "est_y":605.0, "patrol":Vector2(15190, 15450)},
	{"id":"F10_Archer_1", "kind":"kobold_archer", "x":15788.5, "est_y":580.0, "patrol":Vector2(15660, 15920)},
	{"id":"F10_Clubber_0", "kind":"kobold_clubber", "x":15617.5, "est_y":600.0, "patrol":Vector2(15480, 15750)},
	{"id":"F10_Clubber_1", "kind":"kobold_clubber", "x":16013.8, "est_y":605.0, "patrol":Vector2(15880, 16140)},
	{"id":"F10_Archer_2", "kind":"kobold_archer", "x":15900.7, "est_y":595.0, "patrol":Vector2(15770, 16030)},
]

func _ready() -> void:
	name = "ForestEncounters"
	call_deferred("_spawn")

func _spawn() -> void:
	var defeated_list: Array = world.get("forest_defeated") if world != null and world.get("forest_defeated") != null else []
	for data in SPAWNS:
		var enemy_id: String = data.id
		if defeated_list.has(enemy_id):
			continue
		var enemy = REFERENCE_ENEMY.new()
		enemy.enemy_kind = data.kind
		enemy.ground_origin = true
		enemy.name = enemy_id
		enemy.position = Vector2(data.x, data.est_y)
		_ground_enemy(enemy, data.x, data.est_y)
		enemy.set_meta("spawn_pos", enemy.position)
		if world != null:
			enemy.player = world.player
		enemy.patrol_bounds = data.patrol
		enemy.awareness_height = 450.0
		enemy.ai_enabled = true
		add_child(enemy)
		enemies.append(enemy)
		enemy.defeated.connect(func() -> void:
			if world != null:
				var def: Array = world.get("forest_defeated")
				if def != null and not def.has(enemy_id):
					def.append(enemy_id)
				if world.has_method("_spawn_will_orb"):
					world._spawn_will_orb(enemy.global_position, 5)
				if world.has_method("_save_progress"):
					world._save_progress()
		)
		enemy.attack_landed.connect(func() -> void:
			if world != null and world.game_audio != null:
				world.game_audio.play_effect("enemy_attack")
		)
	if world != null:
		set_active(world.current_room == 6)

func _ground_enemy(enemy: Node2D, target_x: float, est_y: float) -> void:
	if get_world_2d() == null:
		enemy.position = Vector2(target_x, est_y)
		return
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(Vector2(target_x, est_y - 80.0), Vector2(target_x, est_y + 160.0))
	query.collision_mask = 5
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		enemy.position = Vector2(target_x, hit.position.y)
	else:
		var query2 := PhysicsRayQueryParameters2D.create(Vector2(target_x, -500.0), Vector2(target_x, 1500.0))
		query2.collision_mask = 5
		var hit2 := space.intersect_ray(query2)
		if not hit2.is_empty():
			enemy.position = Vector2(target_x, hit2.position.y)
		else:
			enemy.position = Vector2(target_x, est_y)

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
	if world != null and world.get("forest_defeated") != null:
		world.forest_defeated.clear()
	_spawn()

func targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			result.append(enemy)
	return result

func strike(hitbox: Rect2, amount: float, posture_amount: float = -1.0) -> void:
	for enemy in targets():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var box: Rect2
		if enemy.has_method("combat_bounds"):
			box = enemy.combat_bounds()
		else:
			var half := Vector2(17, 20) if enemy is CharacterBody2D else Vector2(20, 27)
			box = Rect2(enemy.global_position - half, half * 2)
		if hitbox.intersects(box) or (enemy is CharacterBody2D and hitbox.intersects(Rect2(enemy.global_position - Vector2(17, 20), Vector2(34, 40)))):
			enemy.take_hit(amount, posture_amount)
