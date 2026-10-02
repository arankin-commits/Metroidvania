extends Node2D
const PLAYER = preload("res://tests/player_downstrike_demo/player.gd")
const TARGET = preload("res://tests/player_downstrike_demo/target.gd")
const CRACKED = preload("res://scripts/cracked_floor.gd")

func _ready() -> void:
	_floor(Vector2(220, 460), Vector2(440, 32), false)
	_floor(Vector2(510, 460), Vector2(140, 32), true)
	_floor(Vector2(760, 460), Vector2(360, 32), false)
	_floor(Vector2(510, 600), Vector2(180, 32), false)
	for p in [Vector2(280, 421), Vector2(350, 421), Vector2(700, 421), Vector2(700, 320)]:
		var target := TARGET.new()
		target.position = p
		target.collision_layer = 4
		target.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 46)
		shape.shape = rect
		target.add_child(shape)
		add_child(target)
	var player := PLAYER.new()
	player.position = Vector2(120, 350)
	add_child(player)
	var label := Label.new()
	label.text = "A/D move | Space jump | E downstrike (ground or air) | R restart\nRed blocks: damage targets. Gold floor: breakable by direct slam landing.\nBlue body while idle is a demo placeholder; ability uses supplied character sprites."
	label.position = Vector2(15, 15)
	add_child(label)

func _floor(pos: Vector2, size: Vector2, cracked: bool) -> void:
	var body: StaticBody2D = CRACKED.new() if cracked else StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-size/2, Vector2(size.x/2,-size.y/2), size/2, Vector2(-size.x/2,size.y/2)])
	visual.color = Color(0.8,0.6,0.2) if cracked else Color(0.25,0.35,0.45)
	body.add_child(visual)
	add_child(body)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
