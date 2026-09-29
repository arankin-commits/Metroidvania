extends "res://scripts/combat_projectile.gd"

const FIST = preload("res://assets/effects/temple_rocket_fist.png")
const SHOT = preload("res://assets/effects/temple_charged_shot.png")

func return_position() -> Vector2:
	return owner_actor.rocket_wrist()

func _draw() -> void:
	if kind == "fist":
		if is_instance_valid(owner_actor):
			var anchor := to_local(owner_actor.rocket_wrist())
			var distance := anchor.length()
			var axis := anchor.normalized()
			draw_line(Vector2.ZERO,anchor,Color("163a46"),5)
			for index in range(1,int(distance/12.0)):
				var point := axis * index * 12.0
				draw_set_transform(point,anchor.angle())
				draw_arc(Vector2.ZERO,5,0,TAU,8,Color("52bbc7"),2)
			draw_set_transform(Vector2.ZERO)
		# The stone knuckles fit the radius15 core; glow behind them is decorative.
		draw_texture_rect(FIST,Rect2(-30,-25,50,50),false)
	else:
		# The cyan diamond is centered on the radius21 swept contact core.
		draw_texture_rect(SHOT,Rect2(-170,-51,214,102),false)
