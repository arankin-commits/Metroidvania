extends Control

var ability := "jump"

func _ready() -> void:
	custom_minimum_size = Vector2(128, 128)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_ability(value: String) -> void:
	ability = value
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 128, 128), Color(0.04, 0.10, 0.14, 0.8))
	draw_rect(Rect2(4, 4, 120, 120), Color(0.32, 0.66, 0.64), false, 4)
	var gold := Color("f3d78a")
	var teal := Color("78e4d4")
	match ability:
		"jump":
			draw_colored_polygon(PackedVector2Array([Vector2(64, 22), Vector2(35, 65), Vector2(52, 65), Vector2(52, 96), Vector2(76, 96), Vector2(76, 65), Vector2(93, 65)]), gold)
		"dodge", "dash":
			for i in 3:
				draw_rect(Rect2(25 + i * 16, 39 + i * 17, 53, 8), teal)
			draw_colored_polygon(PackedVector2Array([Vector2(78, 30), Vector2(108, 64), Vector2(78, 98)]), gold)
		"climb":
			draw_rect(Rect2(80, 22, 19, 79), gold)
			draw_rect(Rect2(51, 22, 48, 14), gold)
			draw_rect(Rect2(40, 66, 37, 12), teal)
			draw_rect(Rect2(34, 55, 17, 23), teal)
		"drop":
			draw_rect(Rect2(22, 35, 84, 10), teal)
			draw_colored_polygon(PackedVector2Array([Vector2(64, 106), Vector2(35, 64), Vector2(53, 64), Vector2(53, 48), Vector2(75, 48), Vector2(75, 64), Vector2(93, 64)]), gold)
		"attack", "heavy":
			draw_line(Vector2(37, 90), Vector2(91, 33), gold, 14 if ability == "heavy" else 8)
			draw_rect(Rect2(29, 78, 42, 10), teal)
			draw_rect(Rect2(31, 85, 12, 19), teal)
		"heal":
			draw_rect(Rect2(52, 27, 24, 74), teal)
			draw_rect(Rect2(27, 52, 74, 24), teal)
			draw_rect(Rect2(59, 34, 10, 60), gold)
			draw_rect(Rect2(34, 59, 60, 10), gold)
