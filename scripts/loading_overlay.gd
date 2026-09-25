extends CanvasLayer

var curtain: ColorRect
var caption: Label

func _ready() -> void:
	layer = 100
	curtain = ColorRect.new()
	curtain.color = Color("101b29")
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(curtain)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.add_child(center)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 30)
	caption.add_theme_color_override("font_color", Color("78e4d4"))
	center.add_child(caption)
	visible = false

func show_room(room_name: String) -> void:
	caption.text = "ENTERING %s..." % room_name.to_upper()
	visible = true

func hide_room() -> void:
	visible = false
