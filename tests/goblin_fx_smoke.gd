extends SceneTree
const BOSS=preload("res://scripts/goblin_boss.gd")
func _initialize() -> void:
	for path in ["res://assets/effects/goblin_wind.png","res://assets/effects/goblin_charge_wake.png"]:
		var texture: Texture2D=load(path)
		var pixels:=texture.get_image()
		if pixels.is_compressed(): pixels.decompress()
		assert(pixels.get_pixel(0,0).a==0,"VFX matte is opaque")
		var occupied:=0
		for y in pixels.get_height():
			for x in pixels.get_width():
				var color:=pixels.get_pixel(x,y)
				if color.a>.1:
					occupied+=1
					assert(not(color.r>.8 and color.b>.8 and color.g<.2),"VFX magenta survived")
		assert(occupied>1000,"VFX crop is empty")
	var boss:=BOSS.new()
	boss.phase={"hit":Rect2(20,-43,170,86),"sprite_pose":5,"style":"swing"}
	boss.state="charge"
	boss.facing=-1
	boss.combat_fx.release(boss)
	assert(boss.combat_fx.wakes.size()==1 and boss.combat_fx.motes.size()==14)
	boss.combat_fx.tick(boss,.04)
	assert(boss.combat_fx.ghosts.size()==1)
	boss.phase={}
	boss.state="recover"
	for i in 30: boss.combat_fx.tick(boss,.025)
	assert(boss.combat_fx.wakes.is_empty() and boss.combat_fx.ghosts.is_empty() and boss.combat_fx.motes.is_empty(),"Effects did not expire")
	boss.state="slam"
	boss.phase={"hit":Rect2(-65,0,130,48),"sprite_pose":15}
	boss.combat_fx.release(boss)
	assert(boss.combat_fx.motes.size()==30 and boss.combat_fx.wakes.is_empty())
	boss.combat_fx.tick(boss,.1)
	for mote in boss.combat_fx.motes: assert(mote.position.y<=boss.home_y+47,"Debris fell through ground")
	boss.reset_encounter()
	assert(boss.combat_fx.motes.is_empty(),"Effects survived reset")
	boss.free()
	print("GOBLIN_FX_PASS: directed release, afterimages, lifetime, ground debris, reset")
	quit()
