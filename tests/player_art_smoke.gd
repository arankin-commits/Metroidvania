extends SceneTree
const PLAYER = preload("res://scripts/player.gd")
const ART = preload("res://scripts/player_presentation.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var pixels := ART.ATLAS.get_image()
	if pixels.is_compressed(): pixels.decompress()
	assert(pixels.get_size() == Vector2i(512, 512))
	for index in 16:
		var cell := pixels.get_region(Rect2i(Vector2i(index % 4, index / 4) * 128, Vector2i(128, 128)))
		var used := cell.get_used_rect()
		assert(used.size.x > 20 and used.size.y > 30)
		assert(used.position.x > 0 and used.end.x < 128 and used.position.y > 0 and used.end.y == 96, "Pose lost foot pivot or transparent gutter")
		if index in [0, 1, 9]: assert(used.size.y == 58, "Standing height changed")
		for y in 128:
			for x in 128:
				var color := cell.get_pixel(x, y)
				assert(color.a == 0 or color.a == 1, "Opaque body leaked background alpha")
				assert(not(color.a > 0 and color.r > 0.65 and color.b > 0.65 and color.g < 0.4), "Matte survived")
	var player := PLAYER.new()
	root.add_child(player)
	assert(player.get_child(0).shape.size == Vector2(28, 46), "Collision changed with artwork")
	var attacks: Array[Rect2] = []
	player.attacked.connect(func(bounds: Rect2): attacks.append(bounds))
	for direction in [-1, 1]:
		player._reset_sword_combo()
		player.facing = direction
		player._normal_attack()
		for i in 11: await physics_frame
		assert(attacks.back().size == Vector2(72, 56), "Visual swap changed melee volume")
		assert(ART.sequence(player) == "slash_horizontal")
		player.attack_style = "thrust"
		assert(ART.pose(player) == 13)
		player.attack_time = 0
		player.heavy_attack_time = 0.15
		assert(ART.sequence(player) == "slash_downward")
		player.heavy_attack_time = 0
		player.dash_time = 0.17
		assert(ART.sequence(player).ends_with("dash"))
		player.dash_time = 0
	player.queue_free()
	await process_frame
	print("PASS: player alpha, 16 foot pivots, standing height, both facings, state selection and unchanged body/melee sizes")
	quit()
