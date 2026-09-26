extends RefCounted

# Room geometry is authored in world pixels. See design/ROOM_DESIGN_MEMORY.md.
const NAMES := ["THE SEALED WATCH", "THE SPLIT GALLERY", "THE HAND'S REFUGE", "WARDEN'S HALL"]
const BOUNDS := [Vector2(-1200, 0), Vector2(0, 1700), Vector2(1700, 3070), Vector2(3070, 4450)]
const NOTE := Vector2(2920, 334)
const GALLERY_CACHE := Vector2(805, 340)
const WATCH_CACHE := Vector2(-530, 339)
const WINCH := Vector2(2510, 559)
const BRIDGE := Rect2(2160, 600, 290, 24)
const EXIT_WALL := Rect2(3850, 300, 32, 300)

static func platforms() -> Array[Rect2]:
	return [
		# Main path, combat space, and the two established tutorial gaps.
		Rect2(-1200, 600, 1200, 120), Rect2(0, 600, 690, 120),
		Rect2(840, 600, 1320, 120), Rect2(2450, 600, 2000, 120),
		Rect2(380, 525, 155, 18), Rect2(1040, 510, 120, 90),
		Rect2(1350, 520, 170, 18), Rect2(2010, 470, 150, 130),
		Rect2(2730, 520, 150, 18),
		# Watch: optional climb to a cache that responds to the Warden's Will.
		Rect2(-970, 525, 145, 30), Rect2(-785, 445, 165, 30), Rect2(-605, 365, 155, 30),
		# Gallery: an upper loop over the pit, returning above the sentinel.
		Rect2(560, 445, 130, 24), Rect2(730, 365, 160, 24), Rect2(935, 430, 100, 24),
		# Refuge: climb right, double back left, then cross to the note alcove.
		Rect2(2680, 440, 100, 24), Rect2(2810, 365, 160, 24),
		# Quiet transition into the forest after the arena and heavy-attack gate.
		Rect2(4020, 540, 130, 60), Rect2(4190, 505, 100, 95),
	]

static func _roof_control_points(room: int) -> PackedVector2Array:
	match room:
		1:
			return PackedVector2Array([Vector2(-1200, 300), Vector2(-1040, 285), Vector2(-900, 195), Vector2(-650, 175), Vector2(-460, 180), Vector2(-260, 275), Vector2(-100, 330), Vector2(0, 330)])
		2:
			return PackedVector2Array([Vector2(0, 330), Vector2(220, 300), Vector2(400, 215), Vector2(670, 170), Vector2(940, 185), Vector2(1210, 255), Vector2(1480, 295), Vector2(1700, 340)])
		3:
			return PackedVector2Array([Vector2(1700, 340), Vector2(1860, 300), Vector2(2050, 255), Vector2(2220, 160), Vector2(2420, 210), Vector2(2570, 265), Vector2(2680, 220), Vector2(2820, 165), Vector2(2970, 190), Vector2(3070, 330)])
		_:
			return PackedVector2Array([Vector2(3070, 330), Vector2(3220, 240), Vector2(3390, 145), Vector2(3640, 145), Vector2(3780, 245), Vector2(3850, 300), Vector2(4010, 315), Vector2(4190, 230), Vector2(4450, 300)])

static func roof_edge(room: int) -> PackedVector2Array:
	var control := _roof_control_points(room)
	var edge := PackedVector2Array()
	var segment := 0
	for x in range(int(control[0].x), int(control[-1].x), 24):
		while segment < control.size() - 2 and x >= control[segment + 1].x:
			segment += 1
		var a: Vector2 = control[segment]
		var b: Vector2 = control[segment + 1]
		var y := snappedf(lerpf(a.y, b.y, (x - a.x) / (b.x - a.x)), 8.0)
		y += posmod(int(x / 24.0) * 17, 3) * 4.0
		var start := Vector2(x, y)
		if edge.is_empty() or edge[-1] != start:
			edge.append(start)
		edge.append(Vector2(minf(x + 24, control[-1].x), y))
	return edge

static func roof_polygon(room: int) -> PackedVector2Array:
	var bounds: Vector2 = BOUNDS[room - 1]
	var points := PackedVector2Array([Vector2(bounds.x, -160), Vector2(bounds.y, -160)])
	var edge := roof_edge(room)
	edge.reverse()
	points.append_array(edge)
	return points
