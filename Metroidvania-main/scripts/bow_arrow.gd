class_name BowArrow
extends "res://scripts/combat_projectile.gd"

func setup(start_position: Vector2,shot_direction: Vector2,shot_target: Node,amount:=1.0) -> void:
	global_position=start_position
	direction=shot_direction.normalized()
	target=shot_target
	friendly=shot_target==null or shot_target.has_method("take_hit")
	damage=amount
	radius=5
	rotation=direction.angle()
