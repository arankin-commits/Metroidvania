extends Node2D

const SPRITE_ROOT := "res://assets/ironback-boss-handoff/ironback-full-boss-integration-v2/sprites/"

var direction := 1
var speed := 360.0
var lifetime := 5.0
var crest_height := 50.0
var target: CharacterBody2D
var owner_boss: Node
var damage_event := 0
var impact_profile: Dictionary = {}
var arena_left := 100.0
var arena_right := 1300.0
var age := 0.0
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("ironback_v2_waves")
	z_index = 2
	sprite = Sprite2D.new()
	sprite.texture = load(SPRITE_ROOT + "shockwave_fx.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(0.72, 0.72) * (0.72 if crest_height < 45.0 else 1.0)
	sprite.position = Vector2(-192.0, -340.0) * sprite.scale.x
	sprite.flip_h = direction < 0
	add_child(sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	position.x += float(direction) * speed * delta
	if is_instance_valid(owner_boss) and is_instance_valid(target):
		var wave_bounds := Rect2(global_position + Vector2(-14.0, -crest_height), Vector2(28.0, 48.0))
		if wave_bounds.intersects(Rect2(target.global_position - Vector2(14.0, 23.0), Vector2(28.0, 46.0))):
			owner_boss.apply_wave_damage(damage_event, global_position.x, impact_profile)
	if age >= lifetime or global_position.x < arena_left or global_position.x > arena_right:
		queue_free()