extends StaticBody2D
signal broken(point: Vector2)
@export var persistent_id := ""
var destroyed := false

func break_from_downstrike(point: Vector2, _attack_id: int) -> void:
	if destroyed:
		return
	destroyed = true
	# Defer collision removal; terrain remains authoritative during the landing query.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	broken.emit(point) # World save adapter records persistent_id here.
	queue_free()
