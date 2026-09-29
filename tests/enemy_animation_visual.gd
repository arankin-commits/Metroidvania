extends SceneTree
const ENEMY=preload("res://scripts/enemies/reference_enemy.gd")
var gallery_view: SubViewport
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	var viewport: Viewport=gallery_view if is_instance_valid(gallery_view) else root
	assert(viewport.get_texture().get_image().save_png("res://design/reviews/enemies-%s.png" % name)==OK)
func run() -> void:
	for kind in ENEMY.LIBRARY:
		var frames: SpriteFrames=ENEMY.LIBRARY[kind]
		var names:=frames.get_animation_names()
		gallery_view=SubViewport.new()
		gallery_view.size=Vector2i(2048,names.size()*150+30)
		gallery_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(gallery_view)
		var gallery:=Node2D.new()
		gallery_view.add_child(gallery)
		var sprites: Array[Sprite2D]=[]
		for row in names.size():
			var label:=Label.new()
			label.text="%s / %s" % [kind,names[row]]
			label.position=Vector2(12,row*150)
			gallery.add_child(label)
			for index in frames.get_frame_count(names[row]):
				var foot:=Node2D.new()
				foot.position=Vector2(78+index*164,130+row*150)
				gallery.add_child(foot)
				var line:=Line2D.new()
				line.points=PackedVector2Array([Vector2(-65,0),Vector2(65,0)])
				line.width=1
				line.default_color=Color(.25,.3,.35)
				foot.add_child(line)
				var sprite:=Sprite2D.new()
				sprite.centered=false
				sprite.position=Vector2(-128,-224)
				sprite.texture=frames.get_frame_texture(names[row],index)
				foot.add_child(sprite)
				sprites.append(sprite)
		await snap(kind+"-right")
		for sprite in sprites: sprite.get_parent().scale.x=-1
		await snap(kind+"-left")
		gallery_view.queue_free()
		await process_frame
	root.size=Vector2i(1024,640)
	DisplayServer.window_set_size(root.size)
	change_scene_to_file("res://tests/scenes/enemy_animation_lab.tscn")
	for tick in 5: await physics_frame
	var lab: Node2D=current_scene
	lab.player.controls_enabled=false
	for index in ENEMY.LIBRARY.size():
		lab.select_kind(index)
		for tick in 10: await physics_frame
		await snap("lab-"+lab.actor.enemy_kind)
		for sequence in ENEMY.ATTACKS[lab.actor.enemy_kind]:
			lab.actor.play_sequence(sequence)
			var fps: float=lab.actor.sprite.sprite_frames.get_animation_speed(sequence)
			var cue_frame: int=ENEMY.CUES[sequence][0]
			var active_tick:=ceili((cue_frame+.2)/fps*60)
			for tick in active_tick: await physics_frame
			await snap("lab-%s-%s" % [lab.actor.enemy_kind,sequence])
			for tick in 65: await physics_frame
	print("ENEMY_VISUAL_PASS: all reference frames both facings and six actors/attacks in the live player lab")
	quit()
