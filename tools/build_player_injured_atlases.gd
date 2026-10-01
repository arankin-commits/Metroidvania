extends SceneTree

# Paint the wake cutout's dark red injury pattern onto the registered player poses.
# Keeping each source pixel's alpha preserves every silhouette, blade and dash trail.
const SHEETS := [
	["hooded_player_complete", 224, 8, 67, Vector2i(96, 160)],
	["hooded_player_atlas", 128, 4, 16, Vector2i(64, 96)],
	["hooded_player_heavy", 192, 3, 9, Vector2i(72, 128)],
]
const DEEP := Color(0.27, 0.025, 0.035)
const DRIED := Color(0.43, 0.045, 0.055)
const FRESH := Color(0.68, 0.085, 0.09)

func _initialize() -> void:
	for sheet in SHEETS:
		var name: String = sheet[0]
		var cell: int = sheet[1]
		var columns: int = sheet[2]
		var count: int = sheet[3]
		var pivot: Vector2i = sheet[4]
		var source := Image.load_from_file("res://assets/characters/%s.png" % name)
		assert(source != null, "Missing player sheet: " + name)
		source.convert(Image.FORMAT_RGBA8)
		var result := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
		result.fill(Color.TRANSPARENT)
		for index in count:
			var frame := source.get_region(Rect2i(Vector2i(index % columns, index / columns) * cell, Vector2i(cell, cell)))
			paint_frame(frame, pivot)
			result.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(index % columns, index / columns) * cell)
		assert(result.save_png("res://assets/characters/%s_injured.png" % name) == OK)
	print("PLAYER_INJURED_ATLASES_READY: 67 complete, 16 special, 9 heavy frames")
	quit()

func paint_frame(frame: Image, pivot: Vector2i) -> void:
	# Find the dark armor beneath the hood. This follows the torso when a pose leans.
	var total := 0.0
	var weighted_x := 0.0
	for y in range(pivot.y - 43, pivot.y - 19):
		for x in range(pivot.x - 16, pivot.x + 18):
			var c := frame.get_pixel(x, y)
			if c.a > 0.55 and is_armor(c):
				weighted_x += x * c.a
				total += c.a
	var torso_x := roundi(weighted_x / total) if total > 0 else pivot.x
	for y in range(maxi(0, pivot.y - 54), mini(frame.get_height(), pivot.y + 1)):
		for x in range(maxi(0, torso_x - 28), mini(frame.get_width(), torso_x + 27)):
			var c := frame.get_pixel(x, y)
			if c.a < 0.28: continue
			var dx := x - torso_x
			var up := pivot.y - y
			var noise := hash_pixel(x - torso_x, up)
			var wet := false
			var stain := false
			if is_armor(c):
				# Torn chest, right arm, both gloves and streaks down the trousers.
				stain = ellipse(dx, up, 3, 31, 7, 10) or ellipse(dx, up, 9, 25, 4, 10)
				stain = stain or ellipse(dx, up, -7, 19, 4, 8) or ellipse(dx, up, 6, 8, 3, 11)
				stain = stain or ellipse(dx, up, -4, 7, 3, 9)
				wet = noise > 0.35 or (abs(dx - 4) < 2 and up > 21 and up < 37)
			else:
				# Sparse stains on the cape hem; leave the hood and most cyan cloth clear.
				stain = is_cape(c) and up < 39 and up > 13 and dx < 2 and dx > -21
				wet = noise > 0.85 and ((up + dx) % 7 < 3)
			if not stain or not wet: continue
			var dye := DEEP if noise < 0.52 else DRIED if noise < 0.79 else FRESH
			var amount := 0.74 if is_armor(c) else 0.52
			var mixed := c.lerp(dye, amount)
			mixed.a = c.a
			frame.set_pixel(x, y, mixed)

func is_armor(c: Color) -> bool:
	return c.r < 0.52 and c.g < 0.50 and c.b < 0.59 and not is_cape(c)

func is_cape(c: Color) -> bool:
	return c.b > c.r * 1.3 and c.b > c.g * 1.12 and c.b > 0.25

func ellipse(x: int, y: int, cx: int, cy: int, rx: int, ry: int) -> bool:
	return pow(float(x - cx) / rx, 2) + pow(float(y - cy) / ry, 2) < 1.0

func hash_pixel(x: int, y: int) -> float:
	# Anchor the flecks to the torso so adjacent animation frames do not flicker.
	return float(posmod(x * 37 + y * 73 + x * y * 11, 101)) / 100.0
