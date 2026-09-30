extends Control

const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const BACKDROP = preload("res://assets/menu_cave.png")
const MUSIC = preload("res://assets/menu_music.wav")
const HOVER_SOUND = preload("res://assets/menu_hover.wav")
const CLICK_SOUND = preload("res://assets/menu_click.wav")

const INK := Color("101b29")
const TEAL := Color("78e4d4")
const CREAM := Color("f5e9bf")

var music: AudioStreamPlayer
var hover_audio: AudioStreamPlayer
var click_audio: AudioStreamPlayer
var menu_screen: Control
var slots_screen: Control
var options_screen: Control
var achievements_screen: Control
var transition_screen: Control
var transition_label: Label
var slot_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
var delete_dialog: ConfirmationDialog
var pending_delete_slot := 0
var achievement_label: Label
var music_slider: HSlider
var sound_slider: HSlider
var music_volume := 0.55
var sound_volume := 0.75
var last_hovered: Button
var transitioning := false
var save_root := "user://"

func _ready() -> void:
	_load_options()
	_build_background()
	_build_audio()
	menu_screen = _make_screen()
	slots_screen = _make_screen()
	options_screen = _make_screen()
	achievements_screen = _make_screen()
	transition_screen = _make_screen()
	_build_menu()
	_build_slots()
	_build_options()
	_build_achievements()
	_build_transition()
	_show_screen(menu_screen)
	music.play()

func _build_background() -> void:
	var background := TextureRect.new()
	background.texture = BACKDROP
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.07, 0.30)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	music.stream = MUSIC
	music.volume_db = linear_to_db(music_volume)
	music.finished.connect(func() -> void: music.play())
	add_child(music)
	hover_audio = AudioStreamPlayer.new()
	hover_audio.stream = HOVER_SOUND
	hover_audio.volume_db = linear_to_db(sound_volume)
	add_child(hover_audio)
	click_audio = AudioStreamPlayer.new()
	click_audio.stream = CLICK_SOUND
	click_audio.volume_db = linear_to_db(sound_volume)
	add_child(click_audio)

func _make_screen() -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	return screen

func _column(screen: Control, top: float, width: float = 0.43) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.anchor_left = 0.075
	column.anchor_right = 0.075 + width
	column.anchor_top = top
	column.anchor_bottom = 0.94
	column.add_theme_constant_override("separation", 12)
	screen.add_child(column)
	return column

func _label(parent: Node, value: String, font_size: int, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.01, 0.03, 0.06, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	parent.add_child(label)
	return label

func _style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _button(parent: Node, title: String, height: float = 52.0) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, height)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("081923"))
	button.add_theme_color_override("font_focus_color", CREAM)
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.075, 0.115, 0.88), Color(0.26, 0.54, 0.56)))
	button.add_theme_stylebox_override("hover", _style(TEAL, CREAM))
	button.add_theme_stylebox_override("pressed", _style(CREAM, TEAL))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), CREAM))
	button.mouse_entered.connect(func() -> void: _hover(button))
	button.mouse_exited.connect(func() -> void:
		if last_hovered == button:
			last_hovered = null)
	button.focus_entered.connect(func() -> void: _hover(button))
	parent.add_child(button)
	return button

func _build_menu() -> void:
	var column := _column(menu_screen, 0.14)
	_label(column, "METROIDVANIA", 48)
	_label(column, "THE HOLLOW PASSAGE", 19, TEAL)
	_spacer(column, 28)
	_button(column, "START GAME").pressed.connect(func() -> void: _open(slots_screen))
	_button(column, "OPTIONS").pressed.connect(func() -> void: _open(options_screen))
	_button(column, "ACHIEVEMENTS").pressed.connect(func() -> void: _open(achievements_screen))
	_button(column, "QUIT GAME").pressed.connect(_quit_game)
	_spacer(column, 10)
	_label(column, "A forgotten path waits beyond the stone.", 16, Color("9bbab9"))

func _build_slots() -> void:
	var column := _column(slots_screen, 0.12, 0.56)
	_label(column, "CHOOSE A SAVE", 37)
	_label(column, "Select a slot to begin or continue.", 17, TEAL)
	_spacer(column, 12)
	for slot in range(1, SAVE_SLOTS.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		column.add_child(row)
		var chosen_slot := slot
		var play_button := _button(row, "", 76)
		play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play_button.pressed.connect(func() -> void: _start_slot(chosen_slot))
		slot_buttons.append(play_button)
		var delete_button := _button(row, "DELETE", 76)
		delete_button.custom_minimum_size.x = 110
		delete_button.pressed.connect(func() -> void: _delete_slot(chosen_slot))
		delete_buttons.append(delete_button)
	_spacer(column, 15)
	_button(column, "BACK").pressed.connect(func() -> void: _open(menu_screen))
	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "Delete save slot"
	delete_dialog.confirmed.connect(_confirm_delete)
	add_child(delete_dialog)
	_refresh_slots()

func _build_options() -> void:
	var column := _column(options_screen, 0.16)
	_label(column, "OPTIONS", 38)
	_spacer(column, 12)
	_label(column, "MUSIC VOLUME", 19, TEAL)
	music_slider = _slider(column, music_volume)
	music_slider.value_changed.connect(_music_changed)
	_spacer(column, 8)
	_label(column, "SOUND EFFECTS", 19, TEAL)
	sound_slider = _slider(column, sound_volume)
	sound_slider.value_changed.connect(_sound_changed)
	_spacer(column, 24)
	_button(column, "BACK").pressed.connect(func() -> void: _open(menu_screen))

func _slider(parent: Node, amount: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = amount
	slider.custom_minimum_size.y = 35
	parent.add_child(slider)
	return slider

func _build_achievements() -> void:
	var column := _column(achievements_screen, 0.16, 0.54)
	_label(column, "ACHIEVEMENTS", 38)
	_spacer(column, 18)
	achievement_label = _label(column, "", 21, CREAM)
	_spacer(column, 30)
	_button(column, "BACK").pressed.connect(func() -> void: _open(menu_screen))

func _build_transition() -> void:
	var dark := ColorRect.new()
	dark.color = INK
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_screen.add_child(dark)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_screen.add_child(center)
	transition_label = _label(center, "ENTERING THE CAVE...", 30, TEAL)

func _spacer(parent: Node, pixels: float) -> void:
	var space := Control.new()
	space.custom_minimum_size.y = pixels
	parent.add_child(space)

func _show_screen(active: Control) -> void:
	for screen in [menu_screen, slots_screen, options_screen, achievements_screen, transition_screen]:
		screen.visible = screen == active
	last_hovered = null

func _open(screen: Control) -> void:
	if transitioning:
		return
	click_audio.play()
	if screen == slots_screen:
		_refresh_slots()
	if screen == achievements_screen:
		_refresh_achievements()
	_show_screen(screen)

func _hover(button: Button) -> void:
	if not transitioning and button != last_hovered:
		last_hovered = button
		hover_audio.play()

func _refresh_slots() -> void:
	for i in range(SAVE_SLOTS.SLOT_COUNT):
		var data: Dictionary = SAVE_SLOTS.load_slot(i + 1, save_root)
		delete_buttons[i].disabled = data.is_empty()
		if data.is_empty():
			slot_buttons[i].text = "SLOT %d   ·   NEW GAME" % (i + 1)
		else:
			var location := str(data.area)
			if location == "Forgotten Passage":
				location += " / Room %d" % int(data.room)
			slot_buttons[i].text = "SLOT %d   ·   %s\nLEVEL %d   ·   %s PLAYED" % [i + 1, location, data.level, SAVE_SLOTS.format_time(data.seconds)]

func _refresh_achievements() -> void:
	var any_save := false
	var passage_cleared := false
	var sigil_found := false
	for slot in range(1, SAVE_SLOTS.SLOT_COUNT + 1):
		var data: Dictionary = SAVE_SLOTS.load_slot(slot, save_root)
		any_save = any_save or not data.is_empty()
		passage_cleared = passage_cleared or data.get("boss_defeated", false)
		sigil_found = sigil_found or data.get("secret_found", false)
	achievement_label.text = "%s  FIRST STEPS\n     Begin the journey\n\n%s  HIDDEN CORNER\n     Find the Cave Sigil\n\n%s  WARDEN FALLEN\n     Defeat the Hollow Warden" % ["[X]" if any_save else "[ ]", "[X]" if sigil_found else "[ ]", "[X]" if passage_cleared else "[ ]"]

func _start_slot(slot: int) -> void:
	if transitioning:
		return
	var data: Dictionary = SAVE_SLOTS.load_slot(slot, save_root)
	if data.is_empty():
		var result: Error = SAVE_SLOTS.write_slot(slot, SAVE_SLOTS.new_slot(), save_root)
		if result != OK:
			push_error("Could not create save slot %d: %s" % [slot, error_string(result)])
			return
	transitioning = true
	click_audio.play()
	get_tree().set_meta("active_save_slot", slot)
	get_tree().set_meta("save_root", save_root)
	transition_label.text = "ENTERING THE FOREST..." if data.get("area", "") == "Forest Edge" else "ENTERING THE CAVE..."
	_show_screen(transition_screen)
	await get_tree().create_timer(0.5).timeout
	var scene_path := "res://scenes/forest_entry.tscn" if data.get("area", "") == "Forest Edge" else "res://scenes/tutorial.tscn"
	get_tree().change_scene_to_file(scene_path)

func _delete_slot(slot: int) -> void:
	if transitioning:
		return
	click_audio.play()
	pending_delete_slot = slot
	delete_dialog.dialog_text = "Delete Slot %d? This cannot be undone." % slot
	delete_dialog.popup_centered()

func _confirm_delete() -> void:
	var result: Error = SAVE_SLOTS.delete_slot(pending_delete_slot, save_root)
	if result != OK:
		push_error("Could not delete save slot %d: %s" % [pending_delete_slot, error_string(result)])
	_refresh_slots()

func _quit_game() -> void:
	if transitioning:
		return
	transitioning = true
	click_audio.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _music_changed(value: float) -> void:
	music_volume = value
	music.volume_db = -80.0 if value <= 0.0 else linear_to_db(value)
	_save_options()

func _sound_changed(value: float) -> void:
	sound_volume = value
	hover_audio.volume_db = -80.0 if value <= 0.0 else linear_to_db(value)
	click_audio.volume_db = -80.0 if value <= 0.0 else linear_to_db(value)
	_save_options()

func _load_options() -> void:
	var config := ConfigFile.new()
	if config.load("user://menu_options.cfg") == OK:
		music_volume = float(config.get_value("audio", "music", music_volume))
		sound_volume = float(config.get_value("audio", "sound", sound_volume))

func _save_options() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sound", sound_volume)
	config.save("user://menu_options.cfg")
