extends SceneTree
const ENEMY=preload("res://scripts/enemies/reference_enemy.gd")
const PLAYER=preload("res://scripts/player.gd")
var cues: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func fail(message: String) -> void:
	push_error(message)
	quit(1)
func run() -> void:
	var floor_body:=StaticBody2D.new()
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(4000,100)
	collision.shape=shape
	floor_body.position=Vector2(0,650)
	floor_body.add_child(collision)
	root.add_child(floor_body)
	var player:=PLAYER.new()
	player.position=Vector2(-200,577)
	root.add_child(player)
	player.controls_enabled=false
	var total:=0
	for kind in ENEMY.LIBRARY:
		var prefab: PackedScene=load("res://scenes/enemies/%s.tscn" % kind)
		if prefab==null: fail("Missing prefab: "+kind); return
		var actor: CharacterBody2D=prefab.instantiate()
		actor.position=Vector2(0,550)
		root.add_child(actor)
		actor.attack_cue.connect(func(sequence: String,_origin: Vector2,_direction: int): cues.append(sequence))
		for tick in 60: await physics_frame
		if not actor.is_on_floor() or absf(actor.position.y-600)>.1: fail("Feet/collision not grounded: "+kind); return
		actor.set_physics_process(false)
		for direction in [-1,1]:
			actor.facing=direction
			if actor.visual.scale.x!=direction: fail("Wrong facing: "+kind); return
			for anim in actor.animations():
				actor.play_sequence(anim,false,true)
				cues.clear()
				var frames: int=actor.sprite.sprite_frames.get_frame_count(anim)
				var fps: float=actor.sprite.sprite_frames.get_animation_speed(anim)
				for index in frames:
					var texture: AtlasTexture=actor.sprite.sprite_frames.get_frame_texture(anim,index)
					var image:=texture.atlas.get_image()
					if image.is_compressed(): image.decompress()
					var bounds:=image.get_region(Rect2i(texture.region)).get_used_rect()
					if bounds.size.y<20 or bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=320 or bounds.end.y>=320:
						fail("Empty/clipped frame: %s %s %d" % [kind,anim,index]); return
					actor.tick_animation(1.0/fps+.000001)
				if actor.sprite.sprite_frames.get_animation_loop(anim):
					if actor.sprite.frame!=0: fail("Loop did not wrap: "+anim); return
				elif actor.sprite.frame!=frames-1: fail("Lost final pose: "+anim); return
				if ENEMY.CUES.has(String(anim)) and cues.size()!=ENEMY.CUES[String(anim)].size(): fail("Missing/repeated active cues: "+anim); return
				if direction==1: total+=frames
		actor.play_sequence("walk",true)
		actor.set_physics_process(true)
		var start_x:=actor.position.x
		for tick in 30: await physics_frame
		if actor.position.x-start_x<20: fail("Walk did not translate: "+kind); return
		actor.take_hit()
		if actor.sprite.animation!=&"posture_break": fail("Missing recoil: "+kind); return
		for tick in 90: await physics_frame
		if actor.sprite.animation!=&"idle": fail("Recoil did not recover: "+kind); return
		if kind=="goblin_dog":
			actor.play_sequence("jump_attack")
			var ground_y:=actor.position.y
			var apex:=ground_y
			for tick in 70:
				await physics_frame
				apex=minf(apex,actor.position.y)
			if ground_y-apex<20 or not actor.is_on_floor(): fail("Dog leap did not leave/return to the floor"); return
		actor.target=player
		actor.ai_enabled=true
		actor.position.x=player.position.x+70
		actor.cooldown=0
		cues.clear()
		for tick in 80: await physics_frame
		if cues.is_empty(): fail("Lab AI did not reach its attack cue: "+kind); return
		actor.queue_free()
		await process_frame
	if total!=217: fail("Expected 217 reference body poses, got %d" % total); return
	print("ENEMY_ANIMATION_PASS: six prefabs; 217 frames in both facings; feet, collisions, loops, active cues, locomotion and recoil with real player")
	quit()
