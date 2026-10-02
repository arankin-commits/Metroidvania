extends SceneTree
const ABILITY = preload("res://scripts/player_abilities/downstrike.gd")
const TARGET = preload("res://tests/player_downstrike_demo/target.gd")
const CRACKED = preload("res://scripts/cracked_floor.gd")
var player: CharacterBody2D
var slam: Node2D
var checks := 0
var errors := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		errors += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var floor := StaticBody2D.new()
	floor.position = Vector2(300, 416)
	floor.collision_layer = 1
	_shape(floor, Vector2(600,32))
	world.add_child(floor)
	player = CharacterBody2D.new()
	player.position = Vector2(300,377)
	player.collision_layer = 2
	player.collision_mask = 1
	_shape(player, Vector2(28,46))
	world.add_child(player)
	slam = ABILITY.new()
	player.add_child(slam)
	var target := TARGET.new()
	target.position = Vector2(350,377)
	target.collision_layer = 4
	_shape(target, Vector2(30,46))
	world.add_child(target)
	await physics_frame
	await physics_frame
	player.velocity = Vector2(0,30)
	player.move_and_slide()
	_check(player.is_on_floor(), "test fixture floor contact")
	_check(slam.begin(), "ground cast accepted")
	_check(not slam.begin(), "reentrant cast blocked")
	await _ticks(35)
	_check(target.hits == 1 and is_equal_approx(target.hp,6.5), "ground shockwave hits nearby target once for 1.5")
	_check(not slam.active(), "full recovery completes")
	await _ticks(50)
	# Put a thin target below an airborne cast: sweep catches descent at speed.
	target.position = Vector2(300,280)
	player.position = Vector2(300,190)
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	await physics_frame
	_check(slam.begin(), "air cast accepted")
	await _ticks(65)
	_check(target.hits == 2 and is_equal_approx(target.hp,5.5), "descent target receives one hit for 1.0")
	# Same target occupies both descent and landing volume; shared ID deduplicates.
	await _ticks(50)
	target.position = Vector2(300,377)
	player.position = Vector2(300,240)
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	await physics_frame
	slam.begin()
	await _ticks(65)
	_check(target.hits == 3, "plunge and landing do not double-hit same receiver")
	# Direct cracked-floor contact, then real fall through opening.
	floor.queue_free()
	var cracked := CRACKED.new()
	cracked.position = Vector2(300,416)
	cracked.collision_layer = 1
	_shape(cracked,Vector2(200,32))
	world.add_child(cracked)
	await physics_frame
	await physics_frame
	slam.reset()
	player.position = Vector2(300,240)
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	slam.begin()
	await _ticks(25)
	_check(not is_instance_valid(cracked), "direct landing destroys cracked panel")
	_check(player.position.y > 377, "recovery falls through broken floor")
	slam.reset()
	_check(slam.begin(), "cast after reset")
	slam.cancel()
	_check(not slam.active(), "cancel releases control")
	_check(not slam.begin(), "cancel retains cooldown")
	print("Downstrike checks: %d, failures: %d" % [checks,errors])
	quit(1 if errors else 0)

func _ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		if slam.before_move(1.0/60.0):
			player.move_and_slide()
			slam.after_move()
		else:
			player.velocity.y += 1250.0/60.0
			player.move_and_slide()

func _shape(body: Node, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	body.add_child(collision)
