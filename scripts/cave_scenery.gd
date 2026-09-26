extends Node2D

const LAYOUT = preload("res://scripts/cave_layout.gd")
var world: Node2D
var age := 0.0
var glow_texture: GradientTexture2D

func _ready() -> void:
	z_index = -5
	glow_texture = GradientTexture2D.new()
	glow_texture.width = 128
	glow_texture.height = 128
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.16), Color(1, 1, 1, 0)])
	glow_texture.gradient = gradient

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	# Recessive scenery: only playable stone receives the bright top-edge treatment.
	for room in range(1, 5):
		var bounds: Vector2 = LAYOUT.BOUNDS[room - 1]
		var tint := Color(0.025, 0.045, 0.08, 0.30)
		if room == 1:
			tint = Color(0.055, 0.035, 0.075, 0.38)
		elif room == 3:
			tint = Color(0.02, 0.065, 0.065, 0.30)
		draw_rect(Rect2(bounds.x, -60, bounds.y - bounds.x, 780), tint)
		for x in range(int(bounds.x) + 150, int(bounds.y) - 60, 280):
			var height := 120.0 + posmod(x, 5) * 21.0
			draw_rect(Rect2(x, 600 - height, 25, height), Color(0.075, 0.12, 0.16, 0.58))
			draw_rect(Rect2(x - 5, 594 - height, 35, 8), Color(0.13, 0.20, 0.22, 0.55))
	# Each room has one unmistakable landmark.
	_arch(Vector2(-1125, 600), 130, 310, Color(0.28, 0.26, 0.35, 0.72))
	for x in [-1080.0, -1020.0, -380.0]:
		draw_rect(Rect2(x, 575, 24, 25), Color(0.19, 0.19, 0.25))
		draw_line(Vector2(x - 5, 575), Vector2(x + 29, 575), Color(0.35, 0.32, 0.39), 3)
	# Suspended gallery slabs have recessed chains, not misleading solid columns.
	for x in [575.0, 675.0, 748.0, 873.0, 952.0, 1020.0]:
		var bottom := 365.0 if x > 700 and x < 900 else 445.0 if x < 700 else 430.0
		for y in range(190, int(bottom), 14):
			draw_rect(Rect2(x, y, 4, 9), Color(0.22, 0.31, 0.33, 0.65), false, 1)
	_glow(Vector2(805, 325), Color(0.45, 0.78, 0.67), 88)
	# The hand is an inhabited refuge: a warm niche after the cold chasm.
	_arch(Vector2(2610, 600), 150, 295, Color(0.25, 0.36, 0.33, 0.65))
	_glow(Vector2(2610, 520), Color(0.94, 0.66, 0.32), 145)
	for x in [2558.0, 2648.0]:
		draw_rect(Rect2(x, 582, 5, 18), Color(0.55, 0.50, 0.34))
		draw_rect(Rect2(x, 574, 4, 7), Color(0.99, 0.83, 0.48))
		_glow(Vector2(x + 2, 578), Color(0.94, 0.66, 0.32), 23)
	_glow(LAYOUT.NOTE + Vector2(0, -12), Color(0.70, 0.78, 0.52), 65)
	# Tall, broken ribs frame the arena; leave the entire fight floor clear.
	_arch(Vector2(3510, 600), 540, 365, Color(0.22, 0.26, 0.32, 0.62))
	for x in [3275.0, 3745.0]:
		draw_rect(Rect2(x, 345, 28, 255), Color(0.12, 0.17, 0.22, 0.85))
		draw_rect(Rect2(x - 8, 332, 44, 13), Color(0.26, 0.29, 0.32, 0.7))
	draw_circle(Vector2(3510, 350), 62, Color(0.30, 0.34, 0.34, 0.15))
	draw_arc(Vector2(3510, 350), 46, 0.2, 5.3, 20, Color(0.38, 0.39, 0.35, 0.36), 7)
	_glow(Vector2(4400, 485), Color(0.32, 0.64, 0.37), 140)
	for x in [3990.0, 4155.0, 4310.0]:
		draw_polyline(PackedVector2Array([Vector2(x, 300), Vector2(x + 12, 375), Vector2(x - 9, 410)]), Color(0.20, 0.33, 0.23, 0.7), 4)
	# Sparse drifting spores are restricted to the current room and stay behind actors.
	if is_instance_valid(world):
		var bounds: Vector2 = LAYOUT.BOUNDS[world.current_room - 1]
		for i in 14:
			var x := bounds.x + fposmod(i * 113.0 + age * (3.0 + i % 3), bounds.y - bounds.x)
			var y := 320.0 + fposmod(i * 47.0 - age * 8.0, 260.0)
			draw_rect(Rect2(x, y, 2, 2), Color(0.54, 0.75, 0.68, 0.22 + 0.10 * sin(age + i)))

func _arch(base: Vector2, width: float, height: float, ink: Color) -> void:
	var left := base.x - width * 0.5
	var top := base.y - height
	draw_polyline(PackedVector2Array([Vector2(left, base.y), Vector2(left, top + 70), Vector2(left + width * 0.25, top + 15), Vector2(base.x, top), Vector2(left + width * 0.75, top + 15), Vector2(left + width, top + 70), Vector2(left + width, base.y)]), ink, 13)

func _glow(center: Vector2, color: Color, radius: float) -> void:
	draw_texture_rect(glow_texture, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)
