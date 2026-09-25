class_name BowArrow
extends Node2D

const SPEED := 520.0
const LIFETIME := 2.2

var direction := Vector2.RIGHT
var target: Node
var lifetime := LIFETIME
var arrow_color := Color("#f5e9bf")

func setup(start_position: Vector2, shot_direction: Vector2, shot_target: Node) -> void:
	global_position = start_position
	z_index = 6
	direction = shot_direction.normalized()
	target = shot_target
	rotation = direction.angle()
	queue_redraw()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction * SPEED * delta
	if is_instance_valid(target):
		var target_bounds := Rect2(target.global_position - Vector2(18, 28), Vector2(36, 56))
		if target_bounds.has_point(global_position):
			if target.has_method("take_hit"):
				target.take_hit(1.0)
			elif target.has_method("take_damage"):
				target.take_damage(1, global_position.x)
			queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(-13, 0), Vector2(10, 0), arrow_color, 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(7, -4), Vector2(7, 4)]), arrow_color)
	draw_line(Vector2(-10, -3), Vector2(-14, -7), arrow_color, 2.0, true)
	draw_line(Vector2(-10, 3), Vector2(-14, 7), arrow_color, 2.0, true)
