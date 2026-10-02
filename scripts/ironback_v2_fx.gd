extends Node2D

const SPRITE_ROOT := "res://assets/ironback-boss-handoff/ironback-full-boss-integration-v2/sprites/"

var kind := "dust"
var lifetime := 0.3
var age := 0.0
var direction := 1
var scale_factor := 1.0

func _ready() -> void:
	add_to_group("ironback_v2_fx")
	z_index = 1 if kind in ["dust", "trail", "rush_dust", "settle"] else 4
	if kind == "impact":
		var supplied_sprite := Sprite2D.new()
		supplied_sprite.texture = load(SPRITE_ROOT + "impact_fx.png")
		supplied_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		supplied_sprite.centered = false
		supplied_sprite.scale = Vector2(0.55, 0.55)
		supplied_sprite.position = Vector2(-192.0, -340.0) * 0.55
		add_child(supplied_sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	if kind == "trail" or kind == "rush_dust":
		position.x -= float(direction) * 70.0 * delta
	if age >= lifetime:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0 - clampf(age / lifetime, 0.0, 1.0)
	var amber := Color(1.0, 0.62, 0.2, alpha)
	var pale := Color(1.0, 0.85, 0.48, alpha)
	var smoke := Color(0.62, 0.67, 0.67, alpha * 0.45)
	match kind:
		"vent":
			draw_circle(Vector2.ZERO, 18.0 * scale_factor, Color(1.0, 0.57, 0.18, alpha * 0.3))
			draw_line(Vector2(-8.0, 0.0), Vector2(-24.0, -12.0), pale, 3.0)
			draw_line(Vector2(8.0, 0.0), Vector2(24.0, -12.0), amber, 3.0)
		"chips":
			for index in 5:
				var angle := -PI * 0.9 + float(index) * PI * 0.45
				draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * (18.0 + index * 5.0), pale, 2.0)
		"dust", "settle", "rush_dust":
			for index in 4:
				draw_circle(Vector2(float(index - 2) * 12.0, -float(index % 2) * 5.0), 5.0 + index, smoke)
		"trail":
			draw_line(Vector2(-18.0, 4.0), Vector2(20.0, -10.0), smoke, 3.0)
			draw_line(Vector2(-12.0, 12.0), Vector2(28.0, 2.0), amber, 2.0)
		"arc":
			draw_arc(Vector2.ZERO, 42.0, -PI * 0.8, PI * 0.45, 16, amber, 4.0)
		"sparks":
			for index in 4:
				var spark_x := float(index - 2) * 10.0
				draw_line(Vector2(spark_x, 0.0), Vector2(spark_x + 6.0, -18.0 - index * 3.0), pale, 2.0)
		"smoke":
			draw_circle(Vector2(-8.0, -12.0), 13.0, smoke)
			draw_circle(Vector2(10.0, -24.0), 9.0, Color(smoke, smoke.a * 0.7))
		"brake":
			draw_line(Vector2(-24.0, 4.0), Vector2(16.0, -4.0), pale, 3.0)
