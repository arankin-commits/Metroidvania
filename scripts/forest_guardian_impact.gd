extends Node2D
const FRAMES = [preload("res://assets/effects/forest_volley_impact_1.png"), preload("res://assets/effects/forest_volley_impact_2.png")]
var age := 0.0
var variant := 0
var owner_actor: Node

func _ready() -> void: z_index = 6
func _physics_process(delta: float) -> void:
	age += delta
	if age > 0.28 or (is_instance_valid(owner_actor) and (owner_actor.health <= 0 or not owner_actor.active)):
		queue_free()
	else: queue_redraw()
func _draw() -> void:
	# The reference panel includes descending arrows above the burst. Those
	# belong to the projectile, not a new attack appearing after contact.
	var texture: Texture2D = FRAMES[variant % 2]
	var size := texture.get_size()
	var burst := Rect2(0, size.y * 0.72, size.x, size.y * 0.28)
	draw_texture_rect_region(texture, Rect2(-24, -12, 48, 24), burst, Color(1, 1, 1, 1.0 - age / 0.28))
