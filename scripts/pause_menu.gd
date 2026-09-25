extends CanvasLayer

const TEAL := Color("78e4d4")
const CREAM := Color("f5e9bf")

var main_page: VBoxContainer
var options_page: VBoxContainer
var music_slider: HSlider
var sound_slider: HSlider
var music_volume := 0.55
var sound_volume := 0.75

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_options()
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.07, 0.68)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 390)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.085, 0.13, 0.97)
	panel_style.border_color = TEAL
	panel_style.set_border_width_all(3)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var pages := Control.new()
	pages.custom_minimum_size = Vector2(366, 336)
	panel.add_child(pages)
	main_page = _page(pages)
	options_page = _page(pages)
	_build_main()
	_build_options()
	options_page.visible = false
	visible = false

func _page(parent: Control) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 14)
	parent.add_child(page)
	return page

func _label(parent: Node, value: String, size: int, color: Color = CREAM) -> void:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _button(parent: Node, value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 56
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("081923"))
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.075, 0.115), Color(0.26, 0.54, 0.56)))
	button.add_theme_stylebox_override("hover", _style(TEAL, CREAM))
	button.add_theme_stylebox_override("pressed", _style(CREAM, TEAL))
	button.pressed.connect(action)
	parent.add_child(button)

func _style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	return style

func _build_main() -> void:
	_label(main_page, "PAUSED", 39, TEAL)
	_button(main_page, "RESUME", _resume)
	_button(main_page, "OPTIONS", _show_options)
	_button(main_page, "MAIN MENU", _main_menu)

func _build_options() -> void:
	_label(options_page, "OPTIONS", 35, TEAL)
	_label(options_page, "MUSIC VOLUME", 18)
	music_slider = _slider(options_page, music_volume)
	music_slider.value_changed.connect(_music_changed)
	_label(options_page, "SOUND EFFECTS", 18)
	sound_slider = _slider(options_page, sound_volume)
	sound_slider.value_changed.connect(_sound_changed)
	_button(options_page, "BACK", _show_main)

func _slider(parent: Node, amount: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = amount
	slider.custom_minimum_size.y = 34
	parent.add_child(slider)
	return slider

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		var map: Variant = get_parent().get("world_map")
		if map is CanvasLayer and map.visible:
			map.hide_map()
			return
		var hand: Variant = get_parent().get("hand_menu")
		if hand is CanvasLayer and hand.visible:
			hand.hide_menu()
			return
		if visible and options_page.visible:
			_show_main()
		elif visible:
			_resume()
		elif _can_pause():
			_open()

func _can_pause() -> bool:
	var overlay: Variant = get_parent().get("loading_overlay")
	var map: Variant = get_parent().get("world_map")
	var hand: Variant = get_parent().get("hand_menu")
	return not (overlay is CanvasLayer and overlay.visible) and not (map is CanvasLayer and map.visible) and not (hand is CanvasLayer and hand.visible)

func _open() -> void:
	main_page.visible = true
	options_page.visible = false
	visible = true
	get_tree().paused = true

func _resume() -> void:
	get_tree().paused = false
	visible = false

func _show_options() -> void:
	main_page.visible = false
	options_page.visible = true

func _show_main() -> void:
	main_page.visible = true
	options_page.visible = false

func _main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _load_options() -> void:
	var config := ConfigFile.new()
	if config.load("user://menu_options.cfg") == OK:
		music_volume = float(config.get_value("audio", "music", music_volume))
		sound_volume = float(config.get_value("audio", "sound", sound_volume))

func _music_changed(value: float) -> void:
	music_volume = value
	_save_options()

func _sound_changed(value: float) -> void:
	sound_volume = value
	_save_options()

func _save_options() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sound", sound_volume)
	config.save("user://menu_options.cfg")
