extends Area2D
var hp := 8.0
var hits := 0
var last_kind := ""

func receive_downstrike(payload: Dictionary) -> bool:
	hp -= float(payload.amount)
	hits += 1
	last_kind = str(payload.kind)
	queue_redraw()
	return true

func _draw() -> void:
	draw_rect(Rect2(-15, -23, 30, 46), Color(0.9, 0.35, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(-28, -30), "%s HP %.1f" % [last_kind, hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
