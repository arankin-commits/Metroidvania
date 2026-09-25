extends CanvasLayer

const TEAL := Color("78e4d4")
const CREAM := Color("f5e9bf")

var world: Node2D
var title: Label
var subtitle: Label
var status: Label
var main_page: VBoxContainer
var panel: PanelContainer

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.055, 0.18)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(455, 520)
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.10
	panel.anchor_bottom = 0.10
	panel.offset_left = 24.0
	panel.offset_right = 479.0
	panel.offset_bottom = 520.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.085, 0.11, 0.78)
	style.border_color = TEAL
	style.set_border_width_all(4)
	style.set_content_margin_all(23)
	panel.add_theme_stylebox_override("panel", style)
	shade.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	title = _label(column, "THE OPEN HAND", 30, CREAM)
	subtitle = _label(column, "MEDITATE", 19, TEAL)
	var line := HSeparator.new()
	column.add_child(line)
	main_page = VBoxContainer.new()
	main_page.add_theme_constant_override("separation", 12)
	column.add_child(main_page)
	_button(main_page, "FAST TRAVEL", _show_travel)
	_button(main_page, "ABILITIES", _show_abilities)
	_button(main_page, "SAVE", _save)
	_button(main_page, "HOP OFF", hide_menu)
	status = _label(column, "", 17, TEAL)
	status.custom_minimum_size.y = 52
	visible = false

func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(390, 54)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("081923"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.12, 0.15, 0.75)
	normal.border_color = Color(0.30, 0.55, 0.54)
	normal.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = TEAL
	hover.border_color = CREAM
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func show_menu() -> void:
	status.text = ""
	_show_main()
	visible = true

func hide_menu() -> void:
	if not visible:
		return
	world.game_audio.play_effect("ui_confirm")
	visible = false
	world.end_hand_meditation()

func _show_main() -> void:
	main_page.visible = true
	subtitle.text = "MEDITATE"

func _show_travel() -> void:
	visible = false
	world.world_map.show_fast_travel(world)

func _show_abilities() -> void:
	visible = false
	world.game_menu.open_section("abilities", true)

func _save() -> void:
	world.game_audio.play_effect("ui_confirm")
	world.save_at_hand()
	status.text = "Saved in slot %d. Health and charges restored." % world.active_save_slot if world.active_save_slot > 0 else "Rested. Health and charges restored."

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E, KEY_ESCAPE]:
		hide_menu()
		get_viewport().set_input_as_handled()
