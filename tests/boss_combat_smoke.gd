extends SceneTree
const PLAYER=preload("res://scripts/player.gd")
const GOBLIN=preload("res://scripts/boss.gd")
const HUNTER=preload("res://scripts/bow_boss.gd")
const GUARDIAN=preload("res://scripts/forest_temple_guardian.gd")
const SLOTS=preload("res://scripts/save_slots.gd")
const SAVE_ROOT="res://tests/.boss_combat_saves"
var arena: Node2D
var player: CharacterBody2D

func _initialize() -> void: call_deferred("run")

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func key(code: Key,down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)

func frames(count: int) -> void:
	for i in count: await physics_frame

func floor_fixture() -> void:
	arena=Node2D.new()
	root.add_child(arena)
	var floor_body:=StaticBody2D.new()
	floor_body.position=Vector2(2500,625)
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(5000,50)
	collision.shape=shape
	floor_body.add_child(collision)
	arena.add_child(floor_body)
	player=PLAYER.new()
	player.position=Vector2(1000,577)
	arena.add_child(player)

func ground_dash(upgraded: bool) -> float:
	player.position=Vector2(1000,577)
	player.reset_movement_state()
	player.has_dash=upgraded
	await frames(15)
	var start:=player.position.x
	key(KEY_K,true)
	await frames(1)
	key(KEY_K,false)
	await frames(11)
	return player.position.x-start

func new_boss(script: Script) -> Node2D:
	var boss: Node2D=script.new()
	boss.position=Vector2(1500,553)
	boss.player=player
	arena.add_child(boss)
	boss.arena_bounds=Vector2(200,4500)
	boss.active=true
	boss.state_time=100
	return boss

func finish_attack(boss: Node2D) -> void:
	for i in 700:
		await physics_frame
		if boss.state=="idle": return
	fail("Attack failed to return to idle: "+boss.attack_name)

func clear_shots() -> void:
	for shot in get_nodes_in_group("combat_projectiles"): shot.queue_free()

func run() -> void:
	floor_fixture()
	await frames(20)
	var basic:=await ground_dash(false)
	var enhanced:=await ground_dash(true)
	if basic<30 or absf(enhanced/basic-2)>0.05: fail("Ground dash is not exactly half before boss: %s/%s"%[basic,enhanced]); return
	player.reset_movement_state()
	player.position=Vector2(1000,350)
	player.has_air_dash=false
	await frames(1)
	key(KEY_K,true); await frames(2); key(KEY_K,false)
	if player.dash_time>0: fail("Pre-boss air dash available"); return
	await frames(1)
	player.has_air_dash=true; key(KEY_K,true); await frames(2); key(KEY_K,false)
	if player.dash_time<=0: fail("Post-boss air dash missing"); return
	player.reset_movement_state()
	player.position=Vector2(1560,577)
	player.health=100
	player.controls_enabled=false
	var goblin:=new_boss(GOBLIN)
	for name in ["spin_combo","overhead_combo","mid_combo","jump_slam","charge_swing"]:
		clear_shots()
		goblin.position=Vector2(1500,553)
		player.position=Vector2(1600,577)
		player.velocity=Vector2.ZERO
		player.invulnerability=0
		var before: float=player.health
		goblin.begin_attack(name)
		await frames(8)
		if player.health!=before: fail("Goblin damages during anticipation: "+name); return
		await finish_attack(goblin)
		if player.health>=before: fail("Goblin attack never hit its visible close/landing lane: "+name); return
	goblin.active=false
	goblin.queue_free(); clear_shots(); await frames(2)
	# Fractional projectile damage, with a swept hit between frames.
	player.position=Vector2(1100,577); player.velocity=Vector2.ZERO; player.invulnerability=0
	var wind:=preload("res://scripts/combat_projectile.gd").new()
	wind.position=Vector2(1000,577); wind.direction=Vector2.RIGHT; wind.damage=.5; wind.target=player; wind.kind="wind"
	wind.radius=preload("res://scripts/combat_projectile.gd").WIND_RADIUS
	arena.add_child(wind)
	var before: float=player.health
	await frames(30)
	if not is_equal_approx(before-player.health,.5): fail("Wind does not deal half damage"); return
	var hunter:=new_boss(HUNTER)
	player.position=Vector2(2100,577); player.invulnerability=100
	for name in ["charged_arrow","rapid_fire","knife_combo","retreat_dash","flipping_volley","summon"]:
		clear_shots()
		hunter.position=Vector2(1500,553)
		hunter.begin_attack(name)
		var seen: Dictionary={}
		var down_only:=true
		for i in 700:
			await physics_frame
			for shot in get_nodes_in_group("combat_projectiles"):
				if shot.owner_actor==hunter:
					seen[shot.get_instance_id()]=true
					if shot.homing_down and shot.direction.y<=0: down_only=false
			if hunter.state=="idle": break
		if name=="rapid_fire" and seen.size()!=5: fail("Rapid fire must shoot five arrows"); return
		if name=="flipping_volley" and (seen.size()!=3 or not down_only): fail("Flipping volley must shoot three downward-only targeting arrows"); return
		if name=="summon" and hunter.summons.size()!=3: fail("Summon wave must have three enemies"); return
	hunter.active=false; await frames(2)
	if not get_nodes_in_group("forest_boss_summons").is_empty(): fail("Summons survived arena deactivation"); return
	hunter.queue_free(); clear_shots(); await frames(2)
	var guardian:=new_boss(GUARDIAN)
	guardian.health=3
	guardian.begin_attack("fire")
	guardian.take_hit(1)
	if guardian.health!=3: fail("Guardian vulnerable during charging"); return
	for i in 100:
		await physics_frame
		if guardian.state=="fire": break
	guardian.take_hit(1)
	if guardian.health!=2: fail("Guardian remains invulnerable after firing"); return
	await finish_attack(guardian)
	for name in ["rocket_punch","punch_combo","slam"]:
		guardian.begin_attack(name); await finish_attack(guardian)
	guardian.active=false; guardian.queue_free(); clear_shots(); await frames(2)
	player.controls_enabled=true
	player.health=5; player.max_health=5; player.invulnerability=0; player.has_wrath=true
	player.take_damage(1,0)
	if player.damage_multiplier()!=1.25: fail("Wrath missing after actual damage"); return
	var remaining: float=player.wrath_time
	player.take_damage(1,0)
	if player.health!=4 or player.wrath_time!=remaining: fail("Invulnerable hit triggered Wrath"); return
	await frames(250)
	if player.damage_multiplier()!=1: fail("Wrath never expires"); return
	player.position=Vector2(1000,577); player.reset_movement_state(); await frames(20)
	player.has_scimitar=true; player.has_gauntlet=true; player.has_bow=true
	player.equipped_weapon="scimitar"
	var boxes: Array[Rect2]=[]
	player.attacked.connect(func(box: Rect2): boxes.append(box))
	key(KEY_U,true); await frames(2); key(KEY_U,false)
	if boxes.is_empty() or boxes.back().size!=Vector2(130,28): fail("Scimitar thrust input missing"); return
	await frames(60)
	player.equipped_weapon="gauntlet"
	key(KEY_U,true); await frames(54); key(KEY_U,false)
	var beams: Dictionary={}
	for i in 70:
		await physics_frame
		for shot in get_nodes_in_group("combat_projectiles"):
			if shot.friendly and shot.kind=="beam": beams[shot.get_instance_id()]=shot.damage
	if beams.size()!=4 or beams.values().min()!=2: fail("Charged gauntlet input does not fire four stronger beams"); return
	clear_shots(); await frames(2)
	var shield_target:=new_boss(GUARDIAN)
	shield_target.position.x=1300
	shield_target.begin_attack("fire")
	player.position=Vector2(1000,577); player.invulnerability=100; player.ability_cooldown=0
	key(KEY_U,true); await frames(2); key(KEY_U,false); await frames(45)
	if shield_target.health!=shield_target.max_health: fail("Player beam penetrated guardian charge protection"); return
	await finish_attack(shield_target)
	shield_target.state_time=100
	player.wrath_time=4; player.ability_cooldown=0
	key(KEY_U,true); await frames(2); key(KEY_U,false); await frames(45)
	if not is_equal_approx(shield_target.health,shield_target.max_health-1.25): fail("Wrath does not increase actual friendly projectile damage"); return
	shield_target.active=false; shield_target.queue_free(); clear_shots(); await frames(2)
	player.wrath_time=0; player.ability_cooldown=0; player.equipped_weapon="bow"; player.bow_ammo=3
	key(KEY_U,true); await frames(2); key(KEY_U,false)
	var arrows: Dictionary={}
	for i in 80:
		await physics_frame
		for shot in get_nodes_in_group("combat_projectiles"):
			if shot.friendly and shot.kind=="arrow":
				if shot.direction.y<=0: fail("Player volley arrow travels upwards"); return
				arrows[shot.get_instance_id()]=true
	if arrows.size()!=3 or player.bow_ammo!=2: fail("Player flipping volley input or ammo incorrect"); return
	clear_shots(); arena.queue_free(); await frames(2)
	await persistence()

func persistence() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var data:=SLOTS.new_slot()
	# Legacy true flag must not override forest boss progression.
	data["has_air_dash"]=true
	SLOTS.write_slot(1,data,SAVE_ROOT)
	if SLOTS.load_slot(1,SAVE_ROOT).has_air_dash: fail("Legacy air dash flag bypasses boss unlock"); return
	set_meta("save_root",SAVE_ROOT); set_meta("active_save_slot",1)
	change_scene_to_file("res://scenes/tutorial.tscn"); await scene_changed; await frames(3)
	var cave:=current_scene
	if cave.player.has_dash: fail("Cave grants early enhanced dash"); return
	# Existing Refuge basin ledges provide a normal-jump crossing; no geometry edit.
	cave.player.set_injured(false)
	cave.current_room=3
	cave.player.position=Vector2(2135,447)
	cave.player.reset_movement_state()
	cave._set_camera_room()
	await frames(15)
	for destination in [2218.0,2390.0,2500.0]:
		key(KEY_SPACE,true); key(KEY_D,true)
		var arrived:=false
		for i in 200:
			if i==3: key(KEY_SPACE,false)
			await physics_frame
			if cave.player.position.x>=destination-3: key(KEY_D,false)
			if i>8 and absf(cave.player.position.x-destination)<30 and cave.player.is_on_floor():
				arrived=true
				break
		key(KEY_D,false); key(KEY_SPACE,false)
		if not arrived: fail("Unchanged Refuge route cannot be crossed without air dash at %s, ended %s"%[destination,cave.player.position]); return
		await frames(12)
	if cave.player.has_air_dash: fail("Normal chasm route granted air dash"); return
	cave._on_boss_defeated()
	data=SLOTS.load_slot(1,SAVE_ROOT)
	if not data.has_scimitar or not data.has_wrath or data.has_air_dash: fail("Cave rewards incorrect"); return
	set_meta("forest_entry_room",8)
	change_scene_to_file("res://scenes/forest_entry.tscn"); await scene_changed; await frames(3)
	var forest:=current_scene
	forest._on_hunter_defeated()
	forest._on_guardian_defeated()
	forest.player.equipped_weapon="gauntlet"
	forest._save_progress()
	data=SLOTS.load_slot(1,SAVE_ROOT)
	if not data.has_air_dash or not data.has_gauntlet or not data.has_bow: fail("Forest/temple rewards not saved"); return
	change_scene_to_file("res://scenes/tutorial.tscn"); await scene_changed; await frames(3)
	cave=current_scene
	if not cave.player.has_air_dash or not cave.player.has_gauntlet or cave.player.equipped_weapon!="gauntlet": fail("Biome return loses rewards/loadout"); return
	cave._save_progress()
	change_scene_to_file("res://scenes/main_menu.tscn"); await scene_changed; await frames(3)
	SLOTS.delete_slot(1,SAVE_ROOT)
	print("BOSS_COMBAT_SMOKE_PASS")
	quit()
