extends CanvasLayer

const ROOM_WIDTHS := [1200.0, 1700.0, 1370.0, 1380.0, 1200.0]
const ROOM_NAMES := ["OLD ENTRANCE", "FIRST STEPS", "HIDDEN WORD", "HOLLOW WARDEN", "FOREST EDGE"]

var visited_rooms: Array[int] = []
var completed_rooms: Array[int] = []
var current_room := 2
var panel: Control

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.draw.connect(_draw_map)
	add_child(panel)
	visible = false

func show_map(visited: Array[int], completed: Array[int], room: int) -> void:
	visited_rooms = visited.duplicate()
	completed_rooms = completed.duplicate()
	current_room = room
	visible = true
	panel.queue_redraw()
	get_tree().paused = true

func hide_map() -> void:
	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_M, KEY_TAB, KEY_ESCAPE]:
		hide_map()
		get_viewport().set_input_as_handled()

func _draw_map() -> void:
	var size := panel.size
	var font := ThemeDB.fallback_font
	panel.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.07, 0.96))
	panel.draw_string(font, Vector2(55, 85), "MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 41, Color("f5e9bf"))
	panel.draw_string(font, Vector2(55, 115), "M / TAB / ESC TO CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("78e4d4"))
	var scale := minf(0.105, (size.x - 110.0) / 6850.0)
	var x := (size.x - 6850.0 * scale) * 0.5
	var y := size.y * 0.45
	for index in ROOM_WIDTHS.size():
		var number := index + 1
		var width: float = float(ROOM_WIDTHS[index]) * scale
		if visited_rooms.has(number):
			var completed := completed_rooms.has(number)
			var fill := Color(0.08, 0.30, 0.29) if completed else Color(0.32, 0.24, 0.14)
			var edge := Color("78e4d4") if completed else Color("e6bc75")
			var height := 86.0 if number <= 4 else 72.0
			var room_rect := Rect2(x, y + (86.0 - height) * 0.5, width - 3.0, height)
			panel.draw_rect(room_rect, fill)
			panel.draw_rect(room_rect, edge, false, 3.0)
			if number == current_room:
				panel.draw_circle(Vector2(room_rect.get_center().x, room_rect.position.y + 23), 7, Color("f5e9bf"))
			panel.draw_string(font, room_rect.position + Vector2(9, height - 14), ROOM_NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, width - 18.0, 13, Color("f5e9bf"))
			x += width
	panel.draw_rect(Rect2(55, size.y - 93, 19, 19), Color(0.32, 0.24, 0.14))
	panel.draw_string(font, Vector2(83, size.y - 77), "EXPLORED", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e6bc75"))
	panel.draw_rect(Rect2(220, size.y - 93, 19, 19), Color(0.08, 0.30, 0.29))
	panel.draw_string(font, Vector2(248, size.y - 77), "100% COMPLETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("78e4d4"))
