extends CharacterBody2D

signal defeated
signal attack_landed

const GRAVITY := 1250.0
var health := 2.0
var max_health := 2.0
var origin_x := 0.0
var player: CharacterBody2D
var hit_cooldown := 0.0
var facing := -1

func _ready() -> void:
	add_to_group("mcp_watch")
	origin_x = global_position.x
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 34)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	var direction := facing
	if player != null and absf(player.global_position.x - global_position.x) < 230.0:
		direction = 1 if player.global_position.x > global_position.x else -1
	elif absf(global_position.x - origin_x) > 78.0:
		direction = -1 if global_position.x > origin_x else 1
	facing = direction
	velocity.x = direction * 72.0
	velocity.y += GRAVITY * delta
	move_and_slide()
	if is_on_wall():
		facing *= -1
	var enemy_bounds := Rect2(global_position - Vector2(16, 17), Vector2(32, 34))
	var player_bounds := Rect2(player.global_position - Vector2(14, 23), Vector2(28, 46)) if player != null else Rect2()
	if player != null and hit_cooldown <= 0.0 and enemy_bounds.grow(4.0).intersects(player_bounds):
		var health_before: int = player.health
		player.take_damage(1, global_position.x)
		if player.health < health_before:
			attack_landed.emit()
		hit_cooldown = 0.8
	queue_redraw()

func take_hit(amount: float = 1.0) -> void:
	health -= amount
	if health <= 0:
		defeated.emit()
		queue_free()
	else:
		velocity.x = -facing * 180.0
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 24, Color(0.96, 0.35, 0.36, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 15), Vector2(-16, -9), Vector2(-7, -19), Vector2(8, -19), Vector2(18, -6), Vector2(16, 15)]), Color(0.41, 0.21, 0.35))
	draw_rect(Rect2(-12, -9, 24, 12), Color(0.85, 0.30, 0.39))
	draw_circle(Vector2(facing * 6, -5), 3, Color(1.0, 0.86, 0.55))
	draw_line(Vector2(-10, 15), Vector2(-15, 22), Color(0.18, 0.13, 0.26), 5)
	draw_line(Vector2(10, 15), Vector2(15, 22), Color(0.18, 0.13, 0.26), 5)
	draw_rect(Rect2(-19, -34, 38, 7), Color(0.04, 0.10, 0.14))
	draw_rect(Rect2(-17, -32, 34, 3), Color(0.25, 0.32, 0.36))
	draw_rect(Rect2(-17, -32, 34.0 * float(health) / float(max_health), 3), Color(0.91, 0.44, 0.47))

func _mcp_state() -> Dictionary:
	return {"health": health}
