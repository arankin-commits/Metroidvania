extends Node2D

const ROOT := "res://assets/gloamweaver-full-boss-integration/vfx/"
var key := ""
var lifetime := 0.4
var age := 0.0
var direction := 1
var scale_factor := 0.55

func _ready() -> void:
	add_to_group("gloamweaver_fx")
	z_index = 2
	var sprite := Sprite2D.new()
	sprite.texture = load(ROOT + key + ".png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(-320.0, -320.0) * scale_factor
	sprite.flip_h = direction < 0
	add_child(sprite)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()