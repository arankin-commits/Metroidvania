extends StaticBody2D

var health := 8.0
var hits := 0

func receive_downstrike(payload: Dictionary) -> bool:
	health -= float(payload.get("amount", 0.0))
	hits += 1
	queue_redraw()
	return true

func _draw() -> void:
	draw_rect(Rect2(-18.0, -30.0, 36.0, 60.0), Color("c75b62"))
	draw_rect(Rect2(-14.0, -26.0, 28.0, 52.0), Color("7e2f48"))
	draw_string(ThemeDB.fallback_font, Vector2(-22.0, -38.0), "%d" % maxi(0, int(health)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f8d7b0"))