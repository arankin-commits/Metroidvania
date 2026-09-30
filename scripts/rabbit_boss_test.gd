extends Node2D

@onready var rabbit_boss: RabbitBoss = $RabbitBoss
@onready var player_target: CharacterBody2D = $PlayerTarget

func _ready() -> void:
	rabbit_boss.player = player_target
	rabbit_boss.active = true
	rabbit_boss.global_position = Vector2(320.0, 220.0)
	player_target.global_position = Vector2(530.0, 220.0)
