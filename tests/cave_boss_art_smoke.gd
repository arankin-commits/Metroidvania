extends SceneTree
const GOBLIN=preload("res://scripts/goblin_boss.gd")
func _initialize() -> void:
	for texture in [GOBLIN.ATLAS,GOBLIN.LEFT_ATLAS]:
		var atlas: Image=texture.get_image()
		if atlas.is_compressed(): atlas.decompress()
		var cell: int=GOBLIN.FRAME_SIZE
		assert(atlas.get_size()==Vector2i(cell*4,cell*4))
		var baseline:=-1
		for index in 16:
			var start:=Vector2i(index%4,index/4)*cell
			var bottom:=-1
			var opaque:=0
			for y in cell:
				for x in cell:
					var pixel:=atlas.get_pixelv(start+Vector2i(x,y))
					if pixel.a>.1:
						assert(x>1 and x<cell-2 and y>1 and y<cell-2,"Pose touches its cell edge")
						assert(not(pixel.r>.65 and pixel.b>.65 and pixel.g<.35),"Chroma matte survived")
						bottom=y
						opaque+=1
			assert(opaque>4000,"Missing pose")
			if index==14: continue
			if baseline<0: baseline=bottom
			assert(absi(bottom-baseline)<=2,"Grounded feet jitter")
	var boss:=GOBLIN.new()
	for attack in ["spin_combo","overhead_combo","mid_combo","jump_slam","charge_swing"]:
		for phase in boss.attack_phases(attack):
			if phase.has("hit") or phase.has("preview") or phase.state=="jump": assert(phase.has("sprite_pose"))
	boss.position=Vector2(300,553)
	boss.phase={"hit":Rect2(30,-18,190,28)}
	boss.attack_direction=1
	assert(boss.attack_box()==Rect2(330,535,190,28))
	boss.attack_direction=-1
	assert(boss.attack_box()==Rect2(80,535,190,28))
	assert(boss.combat_bounds()==Rect2(234,492,132,108))
	boss.free()
	print("CAVE_BOSS_ART_SMOKE_PASS: both facings, transparent poses, stable feet, damage registration")
	quit()
