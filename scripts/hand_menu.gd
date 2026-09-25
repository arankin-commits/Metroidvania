extends CanvasLayer

var world: Node2D
var title: Label
var content: Label
var status: Label

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.055, 0.16)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := Control.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 440)
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.12
	panel.offset_left = -464.0
	panel.offset_right = -24.0
	panel.offset_bottom = 440.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.09, 0.12)
	style.border_color = Color(0.42, 0.81, 0.72)
	style.set_border_width_all(4)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	title = Label.new()
	title.text = "THE OPEN HAND"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("e4d5a5"))
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	_add_button(row, "ABILITIES", _show_abilities)
	_add_button(row, "SAVE", _save)
	_add_button(row, "PREVIOUS NOTES", _show_notes)
	content = Label.new()
	content.custom_minimum_size = Vector2(390, 245)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", 18)
	content.add_theme_color_override("font_color", Color("e9ead8"))
	column.add_child(content)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 17)
	status.add_theme_color_override("font_color", Color("8de8d3"))
	column.add_child(status)
	_add_button(column, "CLOSE  [E / ESC]", hide_menu)
	visible = false

func _add_button(parent: Node, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(120, 43)
	button.pressed.connect(action)
	parent.add_child(button)

func show_menu() -> void:
	status.text = ""
	_show_abilities()
	visible = true

func hide_menu() -> void:
	if not visible:
		return
	visible = false
	world.end_hand_meditation()

func _show_abilities() -> void:
	title.text = "ABILITIES"
	content.text = "Jump: Space / W / Up\nGround dodge: K / Shift\nAir dash: K / Shift while airborne\nLedge climb: Jump / Up / toward ledge\nDrop through: hold S / Down + Jump\nAerial strike: J / X while airborne\nHeal: F\nCharged heavy attack: %s" % ("hold and release H" if world.player.has_heavy else "defeat the Hollow Warden")

func _show_notes() -> void:
	title.text = "PREVIOUS NOTES"
	var lines: Array[String] = []
	if world.secret_found:
		lines.append("CAVE SIGIL\nThe Heartroot once touched even the deepest stone. Its light marked the path between the four lands. When that light was sealed, the gates forgot their way.")
	if world.note_found:
		lines.append("WEATHERED NOTE\nThe four lands were once joined by the Heartroot. When its light was sealed, the paths grew hollow. The Warden keeps the first gate.")
	content.text = "\n\n".join(lines) if not lines.is_empty() else "No notes found yet. Explore the cave's hidden corners."

func _save() -> void:
	world.save_at_hand()
	title.text = "REST AT THE HAND"
	content.text = "Your journey is remembered here. Health and healing charges have been restored."
	status.text = "Saved in slot %d" % world.active_save_slot if world.active_save_slot > 0 else "Rested at the checkpoint"

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E, KEY_ESCAPE]:
		hide_menu()
		get_viewport().set_input_as_handled()
