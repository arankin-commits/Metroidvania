extends Control

var health := 5
var max_health := 5
var level := 1
var will_amount := 0
var healing_charges := 3
var max_healing_charges := 3
var has_dash := false
var has_heavy := false
var prompt := ""
var area := "THE FORGOTTEN PASSAGE"
var boss_health := 0
var boss_max_health := 8
var finished := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := size.x
	var left := 18.0
	draw_arc(Vector2(left + 28, 49), 25, 0, TAU, 24, Color(0.63, 0.89, 0.77), 3)
	draw_circle(Vector2(left + 28, 49), 21, Color(0.10, 0.19, 0.25))
	draw_string(font, Vector2(left + 6, 56), str(level), HORIZONTAL_ALIGNMENT_CENTER, 44, 22, Color(0.97, 0.92, 0.72))
	draw_rect(Rect2(left + 67, 34, 210, 10), Color(0.07, 0.12, 0.17))
	draw_rect(Rect2(left + 69, 36, 206.0 * float(health) / float(maxi(1, max_health)), 6), Color(0.88, 0.33, 0.41))
	for i in max_healing_charges:
		_draw_fist(Vector2(left + 69 + i * 26, 51), i < healing_charges)
	draw_circle(Vector2(left + 242, 64), 15, Color(0.20, 0.93, 0.85, 0.13))
	draw_circle(Vector2(left + 242, 64), 9, Color(0.38, 0.98, 0.88, 0.35))
	draw_circle(Vector2(left + 242, 64), 5, Color(0.78, 1.0, 0.9))
	draw_rect(Rect2(left + 240, 53, 4, 4), Color(0.93, 1.0, 0.93))
	draw_string(font, Vector2(left + 260, 71), str(will_amount), HORIZONTAL_ALIGNMENT_LEFT, 100, 20, Color(0.88, 1.0, 0.88))
	if boss_health > 0:
		var bar_width := minf(430.0, width * 0.5)
		var x := (width - bar_width) * 0.5
		draw_rect(Rect2(x, 38, bar_width, 19), Color(0.12, 0.16, 0.23))
		draw_rect(Rect2(x + 3, 41, (bar_width - 6) * float(boss_health) / float(boss_max_health), 13), Color(0.93, 0.36, 0.43))
		draw_string(font, Vector2(x, 32), "THE HOLLOW WARDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.83, 0.68))
	var prompt_width := minf(width - 340.0, 760.0)
	draw_rect(Rect2(14, size.y - 119, prompt_width, 73), Color(0.025, 0.055, 0.095, 0.82))
	draw_string(font, Vector2(27, size.y - 94), area, HORIZONTAL_ALIGNMENT_LEFT, prompt_width - 26, 15, Color(0.52, 0.84, 0.83))
	draw_string(font, Vector2(27, size.y - 65), prompt, HORIZONTAL_ALIGNMENT_LEFT, prompt_width - 26, 18, Color(0.97, 0.93, 0.78))
	draw_rect(Rect2(0, size.y - 39, width, 39), Color(0.025, 0.055, 0.095, 0.86))
	draw_string(font, Vector2(25, size.y - 13), "A / D MOVE    SPACE JUMP    J STRIKE    K / SHIFT DODGE    H CHARGE    E INTERACT    M / TAB MAP    ESC PAUSE", HORIZONTAL_ALIGNMENT_LEFT, width - 30, 15, Color(0.67, 0.78, 0.79))
	if finished:
		draw_rect(Rect2(width * 0.17, size.y * 0.29, width * 0.66, 190), Color(0.025, 0.07, 0.12, 0.94))
		draw_rect(Rect2(width * 0.17, size.y * 0.29, width * 0.66, 3), Color(0.35, 0.89, 0.82))
		draw_string(font, Vector2(width * 0.23, size.y * 0.38), "THE PASSAGE OPENS", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.97, 0.91, 0.69))
		draw_string(font, Vector2(width * 0.23, size.y * 0.44), "Tutorial complete  ·  The world beyond awaits", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.68, 0.85, 0.83))
		draw_string(font, Vector2(width * 0.23, size.y * 0.49), "Press R to play again", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.50, 0.70, 0.72))

func _draw_fist(origin: Vector2, available: bool) -> void:
	var color := Color(0.98, 0.78, 0.47) if available else Color(0.29, 0.37, 0.43)
	draw_rect(Rect2(origin + Vector2(2, 6), Vector2(17, 13)), Color(0.05, 0.11, 0.16))
	draw_rect(Rect2(origin + Vector2(3, 7), Vector2(15, 10)), color)
	for i in 4:
		draw_rect(Rect2(origin + Vector2(4 + i * 3, 2), Vector2(3, 7)), color)
	draw_rect(Rect2(origin + Vector2(0, 10), Vector2(5, 6)), color)
