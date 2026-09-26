extends CanvasLayer

const ABILITY_ICON = preload("res://scripts/ability_icon.gd")
const MAP_ART = preload("res://scripts/map_art.gd")
const TEAL := Color("78e4d4")
const CREAM := Color("f5e9bf")
const TABS := ["STATUS", "WILLS", "NOTES", "ABILITIES", "MAP"]
const ABILITIES := [
	{"name": "Jump", "icon": "jump", "detail": "Leap over gaps and reach higher ground.", "cooldown": "None", "uses": "Unlimited"},
	{"name": "Ground dodge", "icon": "dodge", "detail": "Shift or K on the ground. Briefly avoids damage.", "cooldown": "0.75 seconds", "uses": "Unlimited"},
	{"name": "Air dash", "icon": "dash", "detail": "Shift or K in the air to cross gaps and pass through enemies.", "cooldown": "0.65 seconds", "uses": "Unlimited"},
	{"name": "Ledge climb", "icon": "climb", "detail": "Catch a clear edge at head height, then press Jump or move toward it.", "cooldown": "None", "uses": "Unlimited"},
	{"name": "Drop through", "icon": "drop", "detail": "Hold S or Down and press Jump on a thin platform.", "cooldown": "None", "uses": "Unlimited"},
	{"name": "Attack", "icon": "attack", "detail": "Press J or X to strike on the ground, in the air, or while hanging.", "cooldown": "0.30 seconds", "uses": "Unlimited"},
	{"name": "Healing", "icon": "heal", "detail": "Press F to restore 2 HP after a short meditation. Damage interrupts it.", "cooldown": "0.65 second cast", "uses": "Healing charges"},
]
const BOSS_WILLS := [
	{"name": "Charged heavy attack", "icon": "heavy", "detail": "Won from the Hollow Warden. Hold H to charge, then release to break cracked stone and strike hard.", "cooldown": "0.65 seconds", "uses": "Unlimited"},
]

var world: Node2D
var current_tab := 0
var return_to_hand := false
var previous_button: Button
var next_button: Button
var tab_buttons: Array[Button] = []
var pages: Array[Control] = []
var status_text: Label
var will_list: VBoxContainer
var will_icon: Control
var will_name: Label
var will_detail: Label
var will_cooldown: Label
var will_uses: Label
var ability_list: VBoxContainer
var ability_icon: Control
var ability_name: Label
var ability_detail: Label
var ability_cooldown: Label
var ability_uses: Label
var notes_list: VBoxContainer
var note_title: Label
var note_body: Label
var map_canvas: Control
var selected_ability := 0
var selected_note := 0

func _ready() -> void:
	layer = 170
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.012, 0.027, 0.045, 0.68)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1060, 610)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	previous_button = _button(header, "Q  ◀")
	previous_button.custom_minimum_size.x = 86
	previous_button.pressed.connect(func() -> void: _show_tab(current_tab - 1))
	for index in TABS.size():
		var button := _button(header, TABS[index])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_show_tab.bind(index))
		tab_buttons.append(button)
	next_button = _button(header, "▶  E")
	next_button.custom_minimum_size.x = 86
	next_button.pressed.connect(func() -> void: _show_tab(current_tab + 1))
	var close_button := _button(header, "CLOSE")
	close_button.custom_minimum_size.x = 170
	close_button.pressed.connect(close_menu)
	var body := Control.new()
	body.custom_minimum_size = Vector2(1000, 485)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_build_status(body)
	_build_wills(body)
	_build_notes(body)
	_build_abilities(body)
	_build_map(body)
	visible = false

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.095, 0.86)
	style.border_color = TEAL
	style.set_border_width_all(4)
	style.set_content_margin_all(20)
	return style

func _label(parent: Node, value: String, size: int, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("081923"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.13, 0.17, 0.8)
	normal.border_color = Color(0.27, 0.54, 0.55)
	normal.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = TEAL
	hover.border_color = CREAM
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override("hover", hover)
	parent.add_child(button)
	return button

func _page(parent: Control) -> HBoxContainer:
	var page := HBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 22)
	parent.add_child(page)
	pages.append(page)
	return page

func _build_status(parent: Control) -> void:
	var page := _page(parent)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	page.add_child(column)
	_label(column, "JOURNEY STATUS", 30, TEAL)
	status_text = _label(column, "", 22)

func _build_wills(parent: Control) -> void:
	var page := _page(parent)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 480
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	will_list = VBoxContainer.new()
	will_list.custom_minimum_size.x = 460
	will_list.add_theme_constant_override("separation", 8)
	scroll.add_child(will_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 11)
	page.add_child(right)
	will_icon = ABILITY_ICON.new()
	right.add_child(will_icon)
	will_name = _label(right, "", 27, TEAL)
	will_detail = _label(right, "", 19)
	will_detail.custom_minimum_size.y = 82
	will_cooldown = _label(right, "", 18)
	will_uses = _label(right, "", 18)

func _build_abilities(parent: Control) -> void:
	var page := _page(parent)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 480
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	ability_list = VBoxContainer.new()
	ability_list.custom_minimum_size.x = 460
	ability_list.add_theme_constant_override("separation", 8)
	scroll.add_child(ability_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 11)
	page.add_child(right)
	ability_icon = ABILITY_ICON.new()
	right.add_child(ability_icon)
	ability_name = _label(right, "", 27, TEAL)
	ability_detail = _label(right, "", 19)
	ability_detail.custom_minimum_size.y = 82
	ability_cooldown = _label(right, "", 18)
	ability_uses = _label(right, "", 18)

func _build_notes(parent: Control) -> void:
	var page := _page(parent)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 480
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	notes_list = VBoxContainer.new()
	notes_list.custom_minimum_size.x = 460
	notes_list.add_theme_constant_override("separation", 8)
	scroll.add_child(notes_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 20)
	page.add_child(right)
	note_title = _label(right, "", 27, TEAL)
	note_body = _label(right, "", 20)

func _build_map(parent: Control) -> void:
	var page := _page(parent)
	map_canvas = Control.new()
	map_canvas.custom_minimum_size = Vector2(995, 480)
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_canvas.draw.connect(_draw_map)
	page.add_child(map_canvas)

func open_section(section: String = "status", from_hand: bool = false) -> void:
	return_to_hand = from_hand
	_refresh_status()
	_refresh_wills()
	_refresh_abilities()
	_refresh_notes()
	var tab := TABS.find(section.to_upper())
	_show_tab(0 if tab < 0 else tab)
	visible = true
	get_tree().paused = true
	world.game_audio.play_effect("ui_confirm")

func close_menu() -> void:
	if not visible:
		return
	world.game_audio.play_effect("ui_confirm")
	visible = false
	get_tree().paused = false
	if return_to_hand and world.get("hand_menu") != null:
		world.hand_menu.show_menu()
	return_to_hand = false

func _show_tab(index: int) -> void:
	if visible and current_tab != posmod(index, TABS.size()):
		world.game_audio.play_effect("ui_move")
	current_tab = posmod(index, TABS.size())
	for i in pages.size():
		pages[i].visible = i == current_tab
		tab_buttons[i].modulate = CREAM if i == current_tab else Color.WHITE
	if current_tab == 4:
		map_canvas.queue_redraw()

func _refresh_status() -> void:
	var player: CharacterBody2D = world.player
	var visited: Array = world.visited_rooms
	var completed: Array = world._completed_rooms()
	var seconds := int(float(world.elapsed_seconds))
	var time_text := "%02d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60]
	var area := "THE TWISTED FOREST" if int(world.current_room) >= 5 else "CAVE ROOM %d" % int(world.current_room)
	var attack := 2 if player.has_heavy else 1
	status_text.text = "AREA  %s\n\nPROGRESS  %d / 8 rooms discovered  ·  %d / 8 complete\nPLAYTIME  %s\n\nLEVEL  %d\nATTACK  %d\nHP  %d / %d\nHEALING ITEMS  %d / %d\nHEALING PER ITEM  2 HP\nWILL  %d" % [area, visited.size(), completed.size(), time_text, int(world.player_level), attack, player.health, player.max_health, player.healing_charges, player.max_healing_charges, int(world.will_amount)]

func _refresh_wills() -> void:
	for child in will_list.get_children():
		child.queue_free()
	if not world.player.has_heavy:
		_label(will_list, "No boss Wills gained yet.", 20, CREAM)
		will_icon.visible = false
		will_name.text = "NO WILLS YET"
		will_detail.text = "Defeat a boss to inherit a new attack or ability."
		will_cooldown.text = ""
		will_uses.text = ""
		return
	will_icon.visible = true
	for index in BOSS_WILLS.size():
		var button := _button(will_list, BOSS_WILLS[index].name)
		button.pressed.connect(_select_will.bind(index))
	_select_will(0)

func _select_will(index: int) -> void:
	if visible:
		world.game_audio.play_effect("ui_confirm")
	var data: Dictionary = BOSS_WILLS[index]
	will_icon.show_ability(str(data.icon))
	will_name.text = str(data.name).to_upper()
	will_detail.text = str(data.detail)
	will_cooldown.text = "COOLDOWN  %s  ·  %.2f remaining" % [data.cooldown, world.player.heavy_cooldown]
	will_uses.text = "USES  %s" % data.uses

func _refresh_abilities() -> void:
	for child in ability_list.get_children():
		child.queue_free()
	for index in ABILITIES.size():
		var button := _button(ability_list, ABILITIES[index].name)
		button.pressed.connect(_select_ability.bind(index))
	selected_ability = mini(selected_ability, ABILITIES.size() - 1)
	_select_ability(selected_ability)

func _select_ability(index: int) -> void:
	if visible:
		world.game_audio.play_effect("ui_confirm")
	selected_ability = index
	var data: Dictionary = ABILITIES[index]
	ability_icon.show_ability(str(data.icon))
	ability_name.text = str(data.name).to_upper()
	ability_detail.text = str(data.detail)
	var current := ""
	match str(data.icon):
		"dodge", "dash":
			current = "  ·  %.2f remaining" % world.player.dash_cooldown
		"attack":
			current = "  ·  %.2f remaining" % world.player.attack_cooldown
	ability_cooldown.text = "COOLDOWN  %s%s" % [data.cooldown, current]
	ability_uses.text = "USES  %s" % ("%d / %d charges" % [world.player.healing_charges, world.player.max_healing_charges] if str(data.icon) == "heal" else data.uses)

func _refresh_notes() -> void:
	for child in notes_list.get_children():
		child.queue_free()
	for index in 2:
		var found := _note_found(index)
		var title := "CAVE SIGIL" if index == 0 else "WEATHERED NOTE"
		var button := _button(notes_list, title if found else "???")
		button.pressed.connect(_select_note.bind(index))
	_select_note(selected_note)

func _note_found(index: int) -> bool:
	var key := "secret_found" if index == 0 else "note_found"
	var local: Variant = world.get(key)
	if local != null:
		return bool(local)
	var saved: Dictionary = world.get("saved_data")
	return bool(saved.get(key, false))

func _select_note(index: int) -> void:
	if visible:
		world.game_audio.play_effect("ui_confirm")
	selected_note = index
	if not _note_found(index):
		note_title.text = "???"
		note_body.text = "This note has not been found. Explore hidden corners to reveal it."
	elif index == 0:
		note_title.text = "CAVE SIGIL"
		note_body.text = "The Heartroot once touched even the deepest stone. Its light marked the path between the four lands. When that light was sealed, the gates forgot their way."
	else:
		note_title.text = "WEATHERED NOTE"
		note_body.text = "The four lands were once joined by the Heartroot. When its light was sealed, the paths grew hollow. The Warden keeps the first gate."

func _draw_map() -> void:
	var visited: Array = world.visited_rooms
	var completed: Array = world._completed_rooms()
	var room := 5 if world.get("current_room") == null else int(world.current_room)
	MAP_ART.draw(map_canvas, map_canvas.size, visited, completed, room, world.get_fast_travel_hands())

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB, KEY_ESCAPE:
			close_menu()
		KEY_Q:
			_show_tab(current_tab - 1)
		KEY_E:
			_show_tab(current_tab + 1)
		KEY_M:
			_show_tab(4)
		_:
			return
	get_viewport().set_input_as_handled()
