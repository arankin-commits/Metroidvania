extends CanvasLayer

var curtain: ColorRect
func _ready() -> void:
	layer = 100
	curtain = ColorRect.new()
	curtain.color = Color("060d13")
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(curtain)
	visible = false

func cover_room() -> void:
	visible = true
	curtain.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(curtain, "modulate:a", 1.0, 0.16)
	await tween.finished

func reveal_room() -> void:
	visible = true
	curtain.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(curtain, "modulate:a", 0.0, 0.16)
	await tween.finished
	visible = false
