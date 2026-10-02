extends Node2D

const SPRITE_ROOT := "res://assets/ironback-boss-handoff/ironback-full-boss-integration/sprites/"

var direction := 1
var speed := 360.0
var lifetime := 5.0
var crest_height := 50.0
var target: CharacterBody2D
var owner_boss: Node
var damage_event := 0
var arena_left := 100.0
var arena_right := 1300.0
var age := 0.0
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("ironback_shockwaves")
	z_index = 2
	sprite = Sprite2D.new()
	sprite.texture = load(SPRITE_ROOT + "shockwave_fx.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(0.72, 0.72)
	sprite.position = Vector2(-192.0, -340.0) * 0.72
	sprite.flip_h = direction < 0
	add_child(sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	position.x += float(direction) * speed * delta
	if is_instance_valid(owner_boss) and is_instance_valid(target):
		var wave_bounds := Rect2(global_position + Vector2(-14.0, -crest_height), Vector2(28.0, crest_height))
		if wave_bounds.intersects(Rect2(target.global_position - Vector2(14.0, 23.0), Vector2(28.0, 46.0))):
			owner_boss.apply_wave_damage(damage_event, global_position.x)
	if age >= lifetime or global_position.x < arena_left or global_position.x > arena_right:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0 - clampf(age / lifetime, 0.0, 1.0)
	var crest := Color(1.0, 0.63, 0.2, alpha)
	var glow := Color(1.0, 0.86, 0.45, alpha * 0.35)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28.0, 12.0), Vector2(-10.0, -crest_height * 0.25), Vector2(0.0, -crest_height),
		Vector2(12.0, -crest_height * 0.25), Vector2(28.0, 12.0)
	]), glow)
	draw_line(Vector2(-20.0, 12.0), Vector2(0.0, -crest_height * 0.75), crest, 4.0)
	draw_line(Vector2(0.0, -crest_height * 0.75), Vector2(20.0, 12.0), crest, 4.0)
	draw_line(Vector2(-28.0, 14.0), Vector2(28.0, 14.0), Color(0.76, 0.42, 0.18, alpha * 0.8), 2.0)