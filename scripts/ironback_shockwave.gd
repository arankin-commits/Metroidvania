extends Node2D

var direction := 1
var speed := 340.0
var lifetime := 1.4
var damage := 1.0
var target: CharacterBody2D
var arena_left := 80.0
var arena_right := 1200.0
var has_hit := false
var age := 0.0

func _ready() -> void:
	add_to_group("ironback_shockwaves")
	z_index = 2
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	position.x += float(direction) * speed * delta
	if is_instance_valid(target) and not has_hit:
		var wave_bounds := Rect2(global_position + Vector2(-18.0, -18.0), Vector2(36.0, 36.0))
		if wave_bounds.intersects(Rect2(target.global_position - Vector2(14.0, 23.0), Vector2(28.0, 46.0))):
			has_hit = true
			target.take_damage(damage, global_position.x, true)
	if age >= lifetime or global_position.x < arena_left or global_position.x > arena_right:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var alpha := 1.0 - progress
	var crest := Color(1.0, 0.63, 0.2, alpha)
	var glow := Color(1.0, 0.86, 0.45, alpha * 0.35)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20.0, 12.0), Vector2(-7.0, -5.0), Vector2(0.0, -27.0),
		Vector2(8.0, -7.0), Vector2(21.0, 12.0)
	]), glow)
	draw_line(Vector2(-13.0, 12.0), Vector2(0.0, -18.0), crest, 4.0)
	draw_line(Vector2(0.0, -18.0), Vector2(14.0, 12.0), crest, 4.0)
	draw_line(Vector2(-22.0, 14.0), Vector2(22.0, 14.0), Color(0.76, 0.42, 0.18, alpha * 0.8), 2.0)