extends Control

var health := 5
var max_health := 5
var level := 1
var will_amount := 0
var healing_charges := 3
var max_healing_charges := 3
var has_dash := false
var has_heavy := false
var has_bow := false
var bow_ammo := 0
var prompt := ""
var notice := ""
var area := "THE FORGOTTEN PASSAGE"
var boss_health := 0
var boss_max_health := 8
var boss_title := "THE HOLLOW WARDEN"
var finished := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := size.x
	var left := 18.0
	# A block-built badge and orb keep the HUD at the artwork's pixel scale.
	draw_rect(Rect2(left + 12, 24, 32, 50), Color(0.53, 0.83, 0.72))
	draw_rect(Rect2(left + 5, 31, 46, 36), Color(0.53, 0.83, 0.72))
	draw_rect(Rect2(left + 12, 29, 32, 40), Color(0.08, 0.17, 0.23))
	draw_rect(Rect2(left + 10, 36, 36, 26), Color(0.08, 0.17, 0.23))
	draw_string(font, Vector2(left + 6, 56), str(level), HORIZONTAL_ALIGNMENT_CENTER, 44, 22, Color(0.97, 0.92, 0.72))
	draw_rect(Rect2(left + 66, 35, 212, 12), Color(0.43, 0.67, 0.66))
	draw_rect(Rect2(left + 69, 38, 206, 6), Color(0.07, 0.12, 0.17))
	draw_rect(Rect2(left + 69, 38, floorf(206.0 * float(health) / float(maxi(1, max_health))), 6), Color(0.88, 0.33, 0.41))
	for i in max_healing_charges:
		_draw_fist(Vector2(left + 69 + i * 27, 53), i < healing_charges)
	draw_rect(Rect2(left + 233, 55, 18, 18), Color(0.20, 0.70, 0.68, 0.30))
	draw_rect(Rect2(left + 237, 51, 10, 26), Color(0.20, 0.70, 0.68, 0.30))
	draw_rect(Rect2(left + 236, 58, 12, 12), Color(0.37, 0.95, 0.84))
	draw_rect(Rect2(left + 239, 54, 6, 20), Color(0.37, 0.95, 0.84))
	draw_rect(Rect2(left + 240, 59, 4, 8), Color(0.87, 1.0, 0.88))
	draw_string(font, Vector2(left + 260, 71), str(will_amount), HORIZONTAL_ALIGNMENT_LEFT, 100, 20, Color(0.88, 1.0, 0.88))
	if has_bow:
		draw_line(Vector2(left + 285, 43), Vector2(left + 304, 43), Color("f3d78a"), 3)
		draw_colored_polygon(PackedVector2Array([Vector2(left + 307, 43), Vector2(left + 300, 38), Vector2(left + 300, 48)]), Color("f3d78a"))
		draw_string(font, Vector2(left + 316, 49), "%d/%d" % [bow_ammo, 3], HORIZONTAL_ALIGNMENT_LEFT, 75, 18, Color("f3d78a"))
	_draw_ability_strip()
	if not prompt.is_empty():
		var prompt_width := minf(width - 240.0, font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 32.0)
		var prompt_x := (width - prompt_width) * 0.5
		draw_rect(Rect2(prompt_x, size.y - 51, prompt_width, 31), Color(0.025, 0.055, 0.075, 0.9))
		draw_string(font, Vector2(prompt_x + 12, size.y - 30), prompt, HORIZONTAL_ALIGNMENT_CENTER, prompt_width - 24, 17, Color(0.88, 0.91, 0.78))
	if boss_health > 0:
		var bar_width := minf(430.0, width * 0.5)
		var x := (width - bar_width) * 0.5
		draw_rect(Rect2(x, 38, bar_width, 19), Color(0.12, 0.16, 0.23))
		draw_rect(Rect2(x + 3, 41, (bar_width - 6) * float(boss_health) / float(boss_max_health), 13), Color(0.93, 0.36, 0.43))
		draw_string(font, Vector2(x, 32), boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.83, 0.68))
	if not notice.is_empty():
		var notice_width := minf(width * 0.64, 760.0)
		var notice_x := (width - notice_width) * 0.5
		draw_rect(Rect2(notice_x, 83, notice_width, 36), Color(0.025, 0.055, 0.095, 0.78))
		draw_string(font, Vector2(notice_x + 12, 108), notice, HORIZONTAL_ALIGNMENT_CENTER, notice_width - 24, 19, Color(0.97, 0.93, 0.78))
	if finished:
		draw_rect(Rect2(width * 0.17, size.y * 0.29, width * 0.66, 190), Color(0.025, 0.07, 0.12, 0.94))
		draw_rect(Rect2(width * 0.17, size.y * 0.29, width * 0.66, 3), Color(0.35, 0.89, 0.82))
		draw_string(font, Vector2(width * 0.23, size.y * 0.38), "THE PASSAGE OPENS", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.97, 0.91, 0.69))
		draw_string(font, Vector2(width * 0.23, size.y * 0.44), "Tutorial complete  ·  The world beyond awaits", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.68, 0.85, 0.83))
		draw_string(font, Vector2(width * 0.23, size.y * 0.49), "Press R to play again", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.50, 0.70, 0.72))

func _draw_fist(origin: Vector2, available: bool) -> void:
	var outline := Color(0.04, 0.11, 0.15)
	var palm := Color(0.90, 0.65, 0.38) if available else Color(0.30, 0.38, 0.43)
	var highlight := Color(1.0, 0.86, 0.57) if available else Color(0.44, 0.51, 0.55)
	var shadow := Color(0.57, 0.35, 0.27) if available else Color(0.20, 0.27, 0.32)
	var pixels := ["..OOOOOO..", ".OHHHHHHO.", ".OHOHOHHO.", ".OHHHHHHO.", "OOOPPPPPO.", "OHHPPPPPO.", "OPPPPPPSO.", ".OPPPSSSO.", "..OSSSSO.."]
	for y in pixels.size():
		for x in pixels[y].length():
			var symbol: String = pixels[y].substr(x, 1)
			if symbol == ".":
				continue
			var ink := outline if symbol == "O" else highlight if symbol == "H" else shadow if symbol == "S" else palm
			draw_rect(Rect2(origin + Vector2(x * 2, y * 2), Vector2(2, 2)), ink)

func _draw_ability_strip() -> void:
	var entries: Array[Dictionary] = [
		{"kind": "attack", "key": "J", "amount": "∞"},
	]
	if has_heavy:
		entries.append({"kind": "heavy", "key": "H", "amount": "∞"})
	if has_bow:
		entries.append({"kind": "bow", "key": "L", "amount": "%d/%d" % [bow_ammo, 3]})
	var center_y := size.y - 58.0
	for index in entries.size():
		_draw_ability_circle(Vector2(52.0 + index * 79.0, center_y), entries[index])

func _draw_ability_circle(center: Vector2, entry: Dictionary) -> void:
	var teal := Color("78e4d4")
	var gold := Color("f3d78a")
	var font := ThemeDB.fallback_font
	draw_circle(center, 31, Color(0.01, 0.035, 0.055, 0.83))
	draw_arc(center, 31, 0, TAU, 40, Color(0.23, 0.55, 0.52), 3)
	draw_arc(center, 27, -PI * 0.5, PI * 0.70, 25, teal, 2)
	match str(entry.kind):
		"attack":
			draw_line(center + Vector2(-12, 14), center + Vector2(12, -13), gold, 4)
			draw_line(center + Vector2(-18, 6), center + Vector2(-5, 19), teal, 4)
		"heavy":
			draw_line(center + Vector2(-12, 14), center + Vector2(12, -13), gold, 6)
			draw_line(center + Vector2(-18, 6), center + Vector2(-5, 19), teal, 4)
		"bow":
			draw_arc(center + Vector2(-5, 0), 17, -PI * 0.5, PI * 0.5, 20, gold, 3)
			draw_line(center + Vector2(-5, -17), center + Vector2(-5, 17), teal, 2)
			draw_line(center + Vector2(-9, 0), center + Vector2(14, 0), gold, 3)
	draw_string(font, center + Vector2(-4, 25), str(entry.key), HORIZONTAL_ALIGNMENT_LEFT, 12, 12, Color.WHITE)
	var badge := center + Vector2(23, 23)
	draw_circle(badge, 17, Color(0.015, 0.045, 0.065, 0.96))
	draw_arc(badge, 17, 0, TAU, 24, teal, 2)
	draw_string(font, badge + Vector2(-14, 5), str(entry.amount), HORIZONTAL_ALIGNMENT_CENTER, 28, 12, Color.WHITE)
