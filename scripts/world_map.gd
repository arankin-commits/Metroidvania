extends CanvasLayer

const MAP_ART = preload("res://scripts/map_art.gd")

var visited_rooms: Array[int] = []
var completed_rooms: Array[int] = []
var current_room := 2
var unlocked_hands: Array[Dictionary] = []
var fast_travel := false
var selected_hand := -1
var travel_world: Node2D

var panel: Control
var travel_panel: PanelContainer
var travel_list: VBoxContainer
var travel_button: Button
var travel_hint: Label

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.draw.connect(_draw_map)
	add_child(panel)
	_build_travel_panel()
	visible = false

func _build_travel_panel() -> void:
	travel_panel = PanelContainer.new()
	travel_panel.anchor_top = 0.14
	travel_panel.anchor_bottom = 0.87
	travel_panel.offset_left = 24
	travel_panel.offset_right = 303
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.07, 0.10, 0.79)
	style.border_color = Color("78e4d4")
	style.set_border_width_all(3)
	style.set_content_margin_all(13)
	travel_panel.add_theme_stylebox_override("panel", style)
	add_child(travel_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	travel_panel.add_child(column)
	var header := Label.new()
	header.text = "UNLOCKED HANDS"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color("f5e9bf"))
	column.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	travel_list = VBoxContainer.new()
	travel_list.custom_minimum_size.x = 235
	scroll.add_child(travel_list)
	travel_hint = Label.new()
	travel_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel_hint.add_theme_color_override("font_color", Color("78e4d4"))
	column.add_child(travel_hint)
	travel_button = Button.new()
	travel_button.text = "TRAVEL TO SELECTED"
	travel_button.custom_minimum_size.y = 46
	travel_button.pressed.connect(_travel_to_selected)
	column.add_child(travel_button)
	var back := Button.new()
	back.text = "BACK TO HAND"
	back.custom_minimum_size.y = 42
	back.pressed.connect(hide_map)
	column.add_child(back)
	travel_panel.visible = false

func show_map(visited: Array[int], completed: Array[int], room: int, hands: Array[Dictionary] = []) -> void:
	_play_ui("ui_confirm")
	visited_rooms = visited.duplicate()
	completed_rooms = completed.duplicate()
	current_room = room
	unlocked_hands = hands.duplicate(true)
	fast_travel = false
	travel_panel.visible = false
	visible = true
	panel.queue_redraw()
	get_tree().paused = true

func show_fast_travel(source_world: Node2D) -> void:
	_play_ui("fast_travel_select")
	travel_world = source_world
	visited_rooms.assign(source_world.visited_rooms)
	completed_rooms.assign(source_world._completed_rooms())
	current_room = source_world.current_room
	unlocked_hands = source_world.get_fast_travel_hands()
	fast_travel = true
	travel_panel.visible = true
	selected_hand = -1
	for child in travel_list.get_children():
		child.queue_free()
	for index in unlocked_hands.size():
		var button := Button.new()
		button.text = str(unlocked_hands[index].get("name", "UNKNOWN HAND"))
		button.custom_minimum_size.y = 45
		button.pressed.connect(select_hand.bind(index))
		travel_list.add_child(button)
	if not unlocked_hands.is_empty():
		select_hand(0)
	else:
		travel_hint.text = "No hands unlocked yet."
		travel_button.disabled = true
	visible = true
	panel.queue_redraw()
	get_tree().paused = true

func select_hand(index: int) -> void:
	if index < 0 or index >= unlocked_hands.size():
		return
	if visible:
		_play_ui("fast_travel_select")
	selected_hand = index
	var hand: Dictionary = unlocked_hands[index]
	var room := int(hand.get("room", -1))
	travel_hint.text = "ROOM %d  ·  %s" % [room, "CURRENT HAND" if room == current_room else "READY TO TRAVEL"]
	travel_button.disabled = room == current_room
	panel.queue_redraw()

func _travel_to_selected() -> void:
	if selected_hand < 0 or travel_button.disabled or not is_instance_valid(travel_world):
		return
	_play_ui("fast_travel_confirm")
	var destination: Dictionary = unlocked_hands[selected_hand]
	hide_map(false)
	travel_world.fast_travel_to_hand(destination)

func hide_map(return_to_hand: bool = true) -> void:
	if return_to_hand:
		_play_ui("ui_confirm")
	var was_fast_travel := fast_travel
	visible = false
	fast_travel = false
	travel_panel.visible = false
	get_tree().paused = false
	if was_fast_travel and return_to_hand and is_instance_valid(travel_world):
		travel_world.hand_menu.show_menu()

func _play_ui(cue: String) -> void:
	var sound: Variant = get_parent().get("game_audio")
	if sound is Node:
		sound.play_effect(cue)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB:
			if fast_travel:
				hide_map()
			else:
				hide_map()
				var game: Variant = get_parent().get("game_menu")
				if game is CanvasLayer:
					game.open_section("map")
		KEY_M, KEY_ESCAPE:
			hide_map()
		_:
			return
	get_viewport().set_input_as_handled()

func _draw_map() -> void:
	var focus_room := int(unlocked_hands[selected_hand].get("room", 0)) if fast_travel and selected_hand >= 0 else 0
	MAP_ART.draw(panel, panel.size, visited_rooms, completed_rooms, current_room, unlocked_hands, focus_room, fast_travel)
	panel.draw_string(ThemeDB.fallback_font, Vector2(340 if fast_travel else 30, 88), "TAB / ESC  BACK TO HAND" if fast_travel else "M / ESC  CLOSE     TAB  MENU", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("78e4d4"))
