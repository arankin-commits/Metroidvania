extends SceneTree

const PLAYER = preload("res://scripts/player.gd")
const ART = preload("res://scripts/player_presentation.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var floor_body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 50)
	collider.shape = shape
	floor_body.position.y = 625
	floor_body.add_child(collider)
	root.add_child(floor_body)
	var players: Array[CharacterBody2D] = []
	for row in 2:
		for slot in 5:
			var p := PLAYER.new()
			p.position = Vector2(slot * 180, 577)
			root.add_child(p)
			p.get_node("Camera2D").enabled = false
			players.append(p)
	for tick in 5: await physics_frame
	for row in 2:
		for slot in 5:
			var p := players[row * 5 + slot]
			p.set_physics_process(false)
			p.position = Vector2(140 + slot * 200, 270 + row * 260)
			p.scale = Vector2(3, 3)
			p.velocity = Vector2(127.5, 0)
			p.weapon_visible_time = 3
			p.visual_state = "unsheathed_walk" if row == 0 else "heavy_charge"
			p.visual_state_time = (slot + 0.2) / 12.0
			p.heavy_charge = 0 if row == 0 else 1
			p.heavy_ready_time = 0.15
	for direction in [1, -1]:
		for p in players:
			p.facing = direction
			p.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://design/reviews/player-charge-gait-%s.png" % direction)
	print("PLAYER_CHARGE_WALK_VISUAL_PASS: complete walk and charging gait, all five frames, both facings")
	quit()
