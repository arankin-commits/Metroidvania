extends Node2D

signal collected(amount: int)

var amount := 1
var target: Node2D
var age := 0.0

func _ready() -> void:
	add_to_group("will_orb")

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	age += delta
	if age < 0.22:
		position.y -= 115.0 * delta
	else:
		var destination := target.global_position + Vector2(0, -12)
		var speed := minf(760.0, 170.0 + age * 470.0)
		global_position = global_position.move_toward(destination, speed * delta)
		if global_position.distance_to(destination) < 20.0:
			collected.emit(amount)
			queue_free()
	queue_redraw()

func _draw() -> void:
	var pulse := 0.83 + 0.17 * sin(age * 12.0)
	var radius := 11.0 if amount >= 50 else 8.0
	draw_circle(Vector2.ZERO, radius * 2.3, Color(0.22, 0.95, 0.81, 0.12 * pulse))
	draw_circle(Vector2.ZERO, radius, Color(0.34, 0.96, 0.84, 0.45 * pulse))
	draw_rect(Rect2(-4, -4, 8, 8), Color(0.85, 1.0, 0.89))
	draw_rect(Rect2(-2, -radius - 6, 4, 4), Color(0.60, 1.0, 0.85, 0.8))
