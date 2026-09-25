extends Node2D

signal defeated

var player: CharacterBody2D
var health := 2
var hit_cooldown := 0.0

func _process(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	if player == null or health <= 0:
		return
	var bounds := Rect2(global_position - Vector2(20, 27), Vector2(40, 54))
	var player_bounds := Rect2(player.global_position - Vector2(14, 23), Vector2(28, 46))
	if hit_cooldown <= 0.0 and bounds.intersects(player_bounds):
		player.take_damage(1, global_position.x)
		hit_cooldown = 0.8
	if bounds.intersects(player_bounds) and player.global_position.x < global_position.x:
		# Its body occupies the landing spot even during damage invulnerability.
		player.ledge_grabbed = false
		player.ledge_climb_time = 0.0
		player.global_position.x = minf(player.global_position.x, global_position.x - 36.0)
		player.velocity.x = minf(player.velocity.x, -220.0)
	queue_redraw()

func take_hit() -> void:
	if health <= 0:
		return
	health -= 1
	queue_redraw()
	if health <= 0:
		defeated.emit()
		queue_free()

func _draw() -> void:
	# This rooted creature stays on its ledge and guards the landing space.
	draw_rect(Rect2(-18, -21, 36, 42), Color(0.12, 0.19, 0.24))
	draw_rect(Rect2(-14, -25, 28, 9), Color(0.54, 0.33, 0.43))
	draw_rect(Rect2(-20, -9, 40, 19), Color(0.49, 0.23, 0.35))
	draw_rect(Rect2(-14, 10, 28, 12), Color(0.28, 0.17, 0.30))
	draw_rect(Rect2(-11, -10, 8, 5), Color(1.0, 0.76, 0.48))
	draw_rect(Rect2(4, -10, 8, 5), Color(1.0, 0.76, 0.48))
	for i in health:
		draw_rect(Rect2(-9 + i * 10, -32, 7, 3), Color(0.96, 0.59, 0.42))
