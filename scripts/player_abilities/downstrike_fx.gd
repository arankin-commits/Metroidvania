extends Node2D
## Lightweight separate world-space shockwave, impact flash, and dust.
var radius := 72.0
var age := 0.0
var duration := 0.32

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()

func _draw() -> void:
	var t := clampf(age / duration, 0.0, 1.0)
	var color := Color(0.35, 0.90, 1.0, 1.0 - t)
	for side in [-1.0, 1.0]:
		var x: float = side * radius * t
		draw_line(Vector2(x - side * 12, -2), Vector2(x, -10 * (1.0-t)), color, 3)
		for i in range(5):
			var progress := float(i) / 4.0
			var p := Vector2(side * (12 + progress * radius) * t, -sin(t * PI) * (5 + progress * 12))
			draw_rect(Rect2(p, Vector2(3, 3)), Color(0.64, 0.72, 0.78, (1.0-t)*0.7))
	if t < 0.3:
		draw_line(Vector2(-12, -1), Vector2(12, -1), color, 4)
