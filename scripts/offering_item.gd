extends Node2D

signal collected

var item_id: String = ""
var will_reward: int = 25
var is_collected: bool = false
var time: float = 0.0

func _ready() -> void:
	z_index = -80

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	if is_collected:
		return
	var pulse := 0.85 + 0.15 * sin(time * 4.0)
	var glow_col := Color(0.44, 0.94, 0.76, 0.20 * pulse)
	var stone_col := Color(0.22, 0.43, 0.40)
	var crystal_col := Color(0.81, 1.0, 0.78)
	var bright_col := Color(1.0, 1.0, 0.92)

	# Stone pedestal base
	draw_rect(Rect2(-10, 0, 20, 8), stone_col)
	draw_rect(Rect2(-6, -10, 12, 10), Color(0.18, 0.35, 0.32))

	# Soft ambient pulsing glow
	draw_circle(Vector2(0, -18), 18.0 * pulse, glow_col)
	draw_circle(Vector2(0, -18), 9.0, Color(0.44, 0.94, 0.76, 0.35 * pulse))

	# Floating relic crystal
	var float_y := -18.0 + sin(time * 3.0) * 3.0
	var diamond := PackedVector2Array([
		Vector2(0, float_y - 10),
		Vector2(7, float_y),
		Vector2(0, float_y + 10),
		Vector2(-7, float_y)
	])
	draw_colored_polygon(diamond, crystal_col)
	var inner := PackedVector2Array([
		Vector2(0, float_y - 6),
		Vector2(4, float_y),
		Vector2(0, float_y + 6),
		Vector2(-4, float_y)
	])
	draw_colored_polygon(inner, bright_col)
