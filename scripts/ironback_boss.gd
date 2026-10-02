extends CharacterBody2D

signal defeated
signal attack_cued(cue: String)

const SHOCKWAVE_SCRIPT := preload("res://scripts/ironback_shockwave.gd")

var player: CharacterBody2D
var health := 12.0
var max_health := 12.0
var active := false
var state := "idle"
var state_time := 0.75
var attack_name := ""
var facing := -1
var hurt_flash := 0.0
var invulnerability := 0.0
var impact_emitted := false
var home_y := 504.0
var arena_left := 80.0
var arena_right := 1200.0
var attack_cooldown := 0.0

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	home_y = position.y
	queue_redraw()

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	if not active or health <= 0.0 or not is_instance_valid(player):
		queue_redraw()
		return
	if state == "idle":
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
		if attack_cooldown <= 0.0 and state_time <= 0.0:
			begin_attack("seismic_smash")
		else:
			state_time -= delta
	else:
		state_time -= delta
		if state == "smash_tell":
			velocity = Vector2.ZERO
		elif state == "smash_impact":
			velocity = Vector2.ZERO
			if not impact_emitted:
				_emit_smash_impact()
		elif state == "smash_recovery":
			velocity = Vector2.ZERO
		if state_time <= 0.0:
			_advance_smash_state()
	queue_redraw()

func begin_attack(name: String = "seismic_smash") -> void:
	if not active or health <= 0.0 or state != "idle":
		return
	attack_name = name
	facing = 1 if player.global_position.x >= global_position.x else -1
	if name != "seismic_smash":
		name = "seismic_smash"
	state = "smash_tell"
	state_time = 0.65
	impact_emitted = false
	attack_cued.emit("ironback_smash_tell")

func _advance_smash_state() -> void:
	match state:
		"smash_tell":
			state = "smash_impact"
			state_time = 0.10
			impact_emitted = false
			attack_cued.emit("ironback_smash")
		"smash_impact":
			state = "smash_recovery"
			state_time = 0.85
			attack_cued.emit("ironback_recovery")
		"smash_recovery":
			state = "idle"
			state_time = 0.35
			attack_cooldown = 0.45

func _emit_smash_impact() -> void:
	impact_emitted = true
	if is_instance_valid(player):
		var local_impact := Rect2(global_position + Vector2(-58.0, -4.0), Vector2(116.0, 44.0))
		if local_impact.intersects(Rect2(player.global_position - Vector2(14.0, 23.0), Vector2(28.0, 46.0))):
			player.take_damage(1.0, global_position.x, true)
	for direction in [-1, 1]:
		var wave := SHOCKWAVE_SCRIPT.new()
		wave.direction = direction
		wave.target = player
		wave.global_position = global_position + Vector2(direction * 54.0, 18.0)
		wave.arena_left = arena_left
		wave.arena_right = arena_right
		get_parent().add_child(wave)

func combat_bounds() -> Rect2:
	return Rect2(global_position - Vector2(66.0, 61.0), Vector2(132.0, 108.0))

func take_hit(amount: float = 1.0) -> void:
	if not active or health <= 0.0 or invulnerability > 0.0:
		return
	health = maxf(0.0, health - amount)
	hurt_flash = 0.16
	invulnerability = 0.12
	if health <= 0.0:
		active = false
		state = "defeated"
		_clear_shockwaves()
		defeated.emit()
	queue_redraw()

func reset_encounter() -> void:
	_clear_shockwaves()
	health = max_health
	active = false
	state = "idle"
	state_time = 0.75
	attack_cooldown = 0.0
	impact_emitted = false
	position.y = home_y

func _clear_shockwaves() -> void:
	for wave in get_tree().get_nodes_in_group("ironback_shockwaves"):
		wave.queue_free()

func _draw() -> void:
	if health <= 0.0:
		return
	var body := Color("272c36") if hurt_flash <= 0.0 else Color("f1c0a0")
	var steel := Color("7e8b9b")
	var shadow := Color("141923")
	var amber := Color("e8872d")
	var fist_y := -8.0 if state == "smash_tell" else 18.0
	if state == "smash_impact": fist_y = 18.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-58.0, 12.0), Vector2(-44.0, -46.0), Vector2(-20.0, -66.0),
		Vector2(20.0, -66.0), Vector2(44.0, -46.0), Vector2(58.0, 12.0),
		Vector2(34.0, 44.0), Vector2(-34.0, 44.0)
	]), body)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26.0, -54.0), Vector2(0.0, -78.0), Vector2(26.0, -54.0),
		Vector2(18.0, -14.0), Vector2(-18.0, -14.0)
	]), shadow)
	draw_circle(Vector2(0.0, -37.0), 15.0, Color("4c5360"))
	draw_circle(Vector2(0.0, -39.0), 5.0, Color("171b23"))
	draw_rect(Rect2(-14.0, -82.0, 28.0, 12.0), amber)
	draw_line(Vector2(-44.0, -27.0), Vector2(-70.0, fist_y), steel, 17.0)
	draw_line(Vector2(44.0, -27.0), Vector2(70.0, fist_y), steel, 17.0)
	draw_circle(Vector2(-70.0, fist_y), 15.0, steel)
	draw_circle(Vector2(70.0, fist_y), 15.0, steel)
	draw_line(Vector2(-39.0, 30.0), Vector2(-49.0, 50.0), shadow, 16.0)
	draw_line(Vector2(39.0, 30.0), Vector2(49.0, 50.0), shadow, 16.0)
	if state == "smash_tell":
		draw_arc(Vector2(0.0, -76.0), 35.0, PI, TAU, 20, Color(1.0, 0.68, 0.25, 0.8), 3.0)
	if state == "smash_impact":
		draw_line(Vector2(-82.0, 48.0), Vector2(82.0, 48.0), Color(1.0, 0.68, 0.25, 0.9), 3.0)