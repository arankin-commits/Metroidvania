extends Node

# Navigation owns this state.
# Combat enemies read it to decide how to traverse toward the player.
var enemy_ai_traverse: Dictionary = {}

func update_enemy_ai_traverse(
	enemy: CharacterBody2D,
	player: CharacterBody2D,
	origin_x: float,
	current_facing: int,
	detection_range: float = 230.0,
	patrol_range: float = 78.0
) -> Dictionary:

	var enemy_id := enemy.get_instance_id()

	var previous: Dictionary = enemy_ai_traverse.get(enemy_id, {})
	var direction: int = int(previous.get("direction", current_facing))

	var mode := "patrol"
	var target_x := origin_x

	# Navigation reacts when terrain blocks the enemy.
	if enemy.is_on_wall():
		direction *= -1
		mode = "blocked"

	# If the player is close enough, Navigation directs the enemy
	# toward the player's position.
	elif player != null and absf(
		player.global_position.x - enemy.global_position.x
	) < detection_range:

		direction = 1 if player.global_position.x > enemy.global_position.x else -1
		target_x = player.global_position.x
		mode = "chase"

	# Otherwise keep the enemy inside its patrol area.
	elif absf(enemy.global_position.x - origin_x) > patrol_range:
		direction = -1 if enemy.global_position.x > origin_x else 1
	
	var traversal := {
		"direction": direction,
		"target_x": target_x,
		"mode": mode
	}

	enemy_ai_traverse[enemy_id] = traversal

	return traversal


func remove_enemy(enemy: Node) -> void:
	enemy_ai_traverse.erase(enemy.get_instance_id())
