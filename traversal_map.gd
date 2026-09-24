extends Node2D

@onready var player: TraversalPlayer = $Player
@onready var exit_zone: Area2D = $ExitZone
@onready var message: Label = $HUD/Message
@onready var status: Label = $HUD/Status

var respawn_point := Vector2(100, 520)
var exit_open := false
var message_timer := 0.0

func _ready() -> void:
	exit_zone.body_entered.connect(_on_exit_body_entered)
	for hazard in $Hazards.get_children():
		if hazard is Area2D:
			hazard.body_entered.connect(_on_hazard_body_entered)
	message.text = "REACH THE BEACON"
	message_timer = 2.0
	queue_redraw()

func _process(delta: float) -> void:
	message_timer = maxf(message_timer - delta, 0.0)
	if message_timer <= 0.0 and message.text != "":
		message.text = ""
	status.text = "ARROW KEYS / A D  MOVE     SPACE / W  JUMP"
	if player.global_position.y > 760.0:
		_respawn_player()
	queue_redraw()

func _on_hazard_body_entered(body: Node2D) -> void:
	if body == player:
		_respawn_player()

func _on_exit_body_entered(body: Node2D) -> void:
	if body == player:
		exit_open = true
		message.text = "BEACON REACHED  -  TRAVERSAL COMPLETE"
		message_timer = 4.0

func _respawn_player() -> void:
	player.respawn(respawn_point)
	message.text = "WATCH YOUR STEP"
	message_timer = 1.5

func _draw() -> void:
	# Layered silhouettes keep the room readable while leaving collision in scene nodes.
	draw_rect(Rect2(0, 0, 1152, 648), Color("#101827"), true)
	draw_circle(Vector2(930, 112), 54.0, Color("#f5c451", 0.16))
	draw_circle(Vector2(930, 112), 36.0, Color("#f5c451", 0.12))
	for index in range(9):
		var x := float(index * 150 - 40)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 540), Vector2(x + 90, 360 - (index % 3) * 35),
			Vector2(x + 190, 540)
		]), Color("#16243a"))
	for x in range(0, 1152, 48):
		draw_line(Vector2(x, 0), Vector2(x, 648), Color(1, 1, 1, 0.025), 1.0)
	for y in range(0, 648, 48):
		draw_line(Vector2(0, y), Vector2(1152, y), Color(1, 1, 1, 0.025), 1.0)

	_draw_platform(Rect2(24, 576, 1104, 48), Color("#31556a"))
	_draw_platform(Rect2(54, 450, 220, 24), Color("#3d7180"))
	_draw_platform(Rect2(342, 365, 170, 24), Color("#3d7180"))
	_draw_platform(Rect2(610, 455, 180, 24), Color("#3d7180"))
	_draw_platform(Rect2(876, 360, 200, 24), Color("#3d7180"))
	_draw_platform(Rect2(1015, 280, 100, 24), Color("#3d7180"))
	_draw_platform(Rect2(700, 516, 42, 60), Color("#684a43"))
	_draw_platform(Rect2(475, 517, 54, 59), Color("#684a43"))

	for spike_x in [300.0, 330.0, 560.0, 590.0, 810.0, 840.0]:
		var points := PackedVector2Array([
			Vector2(spike_x, 576), Vector2(spike_x + 15, 550), Vector2(spike_x + 30, 576)
		])
		draw_colored_polygon(points, Color("#dd6a4e"))

	var beacon_color := Color("#f5c451") if exit_open else Color("#6de0c2")
	draw_line(Vector2(1058, 280), Vector2(1058, 212), Color("#8cb6b8"), 5.0)
	draw_circle(Vector2(1058, 203), 12.0, beacon_color)
	draw_circle(Vector2(1058, 203), 22.0, Color(beacon_color, 0.14))

func _draw_platform(rect: Rect2, color: Color) -> void:
	draw_rect(rect, Color("#0b101b"), true)
	draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size - Vector2(0, 3)), color, true)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("#9fe0ca"), 2.0)
