extends RefCounted

const ROOM_WIDTHS := [1200.0, 1700.0, 1370.0, 1380.0, 1200.0]
const ROOM_NAMES := ["OLD ENTRANCE", "FIRST STEPS", "HIDDEN WORD", "HOLLOW WARDEN", "FOREST EDGE"]
const TEAL := Color("78e4d4")
const CREAM := Color("f5e9bf")

static func room_center_world(room: int) -> float:
	var center := 0.0
	for index in clampi(room - 1, 0, ROOM_WIDTHS.size() - 1):
		center += ROOM_WIDTHS[index]
	return center + ROOM_WIDTHS[clampi(room - 1, 0, ROOM_WIDTHS.size() - 1)] * 0.5

static func layout(size: Vector2, focus_room: int = 0) -> Dictionary:
	var scale := 0.18 if focus_room > 0 else minf(0.105, (size.x - 100.0) / 6850.0)
	var origin_x := size.x * 0.6 - room_center_world(focus_room) * scale if focus_room > 0 else (size.x - 6850.0 * scale) * 0.5
	return {"scale": scale, "origin_x": origin_x, "y": size.y * 0.44}

static func draw(canvas: Control, size: Vector2, visited: Array, completed: Array, current_room: int, hands: Array, focus_room: int = 0, fast_travel: bool = false) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.07, 0.94 if fast_travel else 0.72))
	canvas.draw_string(font, Vector2(30 if not fast_travel else 340, 58), "FAST TRAVEL" if fast_travel else "MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, CREAM)
	var placement := layout(size, focus_room)
	var x: float = placement.origin_x
	var y: float = placement.y
	var scale: float = placement.scale
	for index in ROOM_WIDTHS.size():
		var number := index + 1
		var width: float = ROOM_WIDTHS[index] * scale
		if visited.has(number):
			var complete := completed.has(number)
			var height := 90.0 if number <= 4 else 72.0
			var rect := Rect2(x, y + (90.0 - height) * 0.5, width - 3.0, height)
			canvas.draw_rect(rect, Color(0.08, 0.30, 0.29) if complete else Color(0.32, 0.24, 0.14))
			canvas.draw_rect(rect, TEAL if complete else Color("e6bc75"), false, 3.0)
			if number == current_room:
				canvas.draw_circle(rect.position + Vector2(17, 18), 7, CREAM)
			for hand in hands:
				if int(hand.get("room", -1)) == number:
					_draw_hand(canvas, rect.get_center() + Vector2(0, -8), 2.0)
			canvas.draw_string(font, rect.position + Vector2(8, height - 13), ROOM_NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, width - 14.0, 13, CREAM)
		x += width
	_draw_legend(canvas, size, fast_travel)

static func _draw_hand(canvas: Control, center: Vector2, pixel: float) -> void:
	var dark := Color(0.20, 0.12, 0.13)
	var gold := Color("f3d78a")
	canvas.draw_rect(Rect2(center + Vector2(-7, -1) * pixel, Vector2(14, 12) * pixel), dark)
	canvas.draw_rect(Rect2(center + Vector2(-5, 1) * pixel, Vector2(10, 8) * pixel), gold)
	for finger in 4:
		canvas.draw_rect(Rect2(center + Vector2(-5 + finger * 3, -6) * pixel, Vector2(2, 8) * pixel), gold)
	canvas.draw_rect(Rect2(center + Vector2(-8, 2) * pixel, Vector2(4, 5) * pixel), gold)

static func _draw_legend(canvas: Control, size: Vector2, fast_travel: bool) -> void:
	var left := 318.0 if fast_travel else 24.0
	var width := minf(805.0, size.x - left - 24.0)
	var top := size.y - 83.0
	var font := ThemeDB.fallback_font
	canvas.draw_rect(Rect2(left, top, width, 65), Color(0.025, 0.07, 0.10, 0.87))
	canvas.draw_rect(Rect2(left, top, width, 65), TEAL, false, 2.0)
	var labels := ["EXPLORED", "100% COMPLETE", "YOU", "HAND"]
	for index in 4:
		var x := left + 14.0 + index * (width - 28.0) / 4.0
		canvas.draw_rect(Rect2(x, top + 19, 23, 23), Color(0.03, 0.12, 0.16))
		canvas.draw_rect(Rect2(x, top + 19, 23, 23), Color(0.45, 0.75, 0.73), false, 1.0)
		match index:
			0:
				canvas.draw_rect(Rect2(x + 5, top + 24, 13, 13), Color(0.32, 0.24, 0.14))
			1:
				canvas.draw_rect(Rect2(x + 5, top + 24, 13, 13), Color(0.08, 0.30, 0.29))
			2:
				canvas.draw_circle(Vector2(x + 11.5, top + 30.5), 6, CREAM)
			3:
				_draw_hand(canvas, Vector2(x + 11.5, top + 30.5), 0.75)
		canvas.draw_string(font, Vector2(x + 29, top + 36), labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CREAM)
