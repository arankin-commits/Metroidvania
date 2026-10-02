extends Node2D

const LAYOUT = preload("res://scripts/forest_smash_corridor_layout.gd")
const ART = preload("res://assets/forest_room2_section4_extended.png")
const FOUNDATION = preload("res://assets/forest_room2_sections45678910_foundation.png")
const FOUNDATION_SHADER = preload("res://assets/forest_connected_foundation.gdshader")

var is_broken := false
var smash_body: StaticBody2D
var smash_shape: CollisionPolygon2D
var smash_terrain: Polygon2D

func _ready() -> void:
	name = "ForestRoom2Section4"
	var polygons := LAYOUT.solid_polygons()
	for i in polygons.size():
		var body := StaticBody2D.new()
		body.name = "FutureDownwardSmashFloor" if i == 1 else "GroundMass%d" % i
		if i == 1:
			smash_body = body
			body.set_meta("required_ability", "future_downward_smash")
		var shape := CollisionPolygon2D.new()
		shape.polygon = polygons[i]
		if i == 1:
			smash_shape = shape
		body.add_child(shape)
		add_child(body)
		var terrain := Polygon2D.new()
		terrain.polygon = polygons[i]
		var uv := PackedVector2Array()
		for vertex in terrain.polygon:
			uv.append((vertex - LAYOUT.ORIGIN) / LAYOUT.SCALE)
		terrain.uv = uv
		terrain.texture = ART
		var material := ShaderMaterial.new()
		material.shader = FOUNDATION_SHADER
		material.set_shader_parameter("foundation", FOUNDATION)
		material.set_shader_parameter("future_seal", i == 1)
		terrain.material = material
		terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index = -85
		if i == 1:
			smash_terrain = terrain
		add_child(terrain)

func break_floor(instant: bool = false) -> void:
	is_broken = true
	var cavity_poly := PackedVector2Array([
		LAYOUT.point(Vector2(60, 770)),
		LAYOUT.point(Vector2(245, 770)),
		LAYOUT.point(Vector2(245, LAYOUT.SOURCE_SIZE.y)),
		LAYOUT.point(Vector2(60, LAYOUT.SOURCE_SIZE.y))
	])
	if is_instance_valid(smash_shape):
		smash_shape.polygon = cavity_poly
	if is_instance_valid(smash_terrain):
		smash_terrain.polygon = cavity_poly
		var uv := PackedVector2Array()
		for vertex in smash_terrain.polygon:
			uv.append((vertex - LAYOUT.ORIGIN) / LAYOUT.SCALE)
		smash_terrain.uv = uv
		if smash_terrain.material is ShaderMaterial:
			smash_terrain.material.set_shader_parameter("future_seal", false)
	queue_redraw()

func _draw() -> void:
	if is_broken:
		var top_left := LAYOUT.point(Vector2(60, 707))
		var bottom_right := LAYOUT.point(Vector2(245, 770))
		var rect := Rect2(top_left, bottom_right - top_left)
		draw_rect(rect, Color(0.08, 0.12, 0.14))
		for y_off in range(12, int(rect.size.y), 16):
			draw_line(Vector2(rect.position.x, rect.position.y + y_off), Vector2(rect.end.x, rect.position.y + y_off), Color(0.05, 0.08, 0.10), 1.5)
