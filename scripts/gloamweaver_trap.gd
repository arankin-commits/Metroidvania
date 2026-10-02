extends Area2D

var lifetime := 8.0
var age := 0.0
var armed := false
var boss_owner: Node
var visual: Sprite2D
var last_trigger_time := -1.0

func _ready() -> void:
	add_to_group("gloamweaver_traps")
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	monitorable = true
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(100.0, 24.0)
	shape.shape = rectangle
	shape.position = Vector2(0.0, -12.0)
	add_child(shape)
	visual = Sprite2D.new()
	visual.texture = load("res://assets/gloamweaver-full-boss-integration/vfx/trap_unfold.png")
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = false
	visual.scale = Vector2(0.34, 0.34)
	visual.position = Vector2(-320.0, -392.0) * 0.34
	add_child(visual)
	set_deferred("monitoring", false)

func arm() -> void:
	armed = true
	set_deferred("monitoring", true)
	visual.texture = load("res://assets/gloamweaver-full-boss-integration/vfx/trap_active.png")
	visual.scale = Vector2(0.26, 0.26)
	visual.position = Vector2(-320.0, -392.0) * 0.26

func _physics_process(delta: float) -> void:
	age += delta
	if armed and age >= lifetime:
		queue_free()
	if armed and monitoring:
		for body in get_overlapping_bodies():
			if body.has_method("apply_gloamweaver_slow") and body.is_on_floor():
				var now := Time.get_ticks_msec() / 1000.0
				if now - last_trigger_time >= 0.50:
					last_trigger_time = now
					body.apply_gloamweaver_slow(1.0)
					if is_instance_valid(boss_owner) and boss_owner.has_method("spawn_trap_trigger"):
						boss_owner.spawn_trap_trigger(global_position)