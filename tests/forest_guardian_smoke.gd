extends SceneTree
const BOSS=preload("res://scripts/forest_hunter_combat.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for texture in [BOSS.RIGHT_ATLAS,BOSS.LEFT_ATLAS]:
		var atlas: Image=texture.get_image()
		if atlas.is_compressed(): atlas.decompress()
		assert(atlas.get_size()==Vector2i(1280,1600))
		for index in 20:
			var start:=Vector2i(index%4,index/4)*320
			var opaque:=0
			for y in 320:
				for x in 320:
					var pixel:=atlas.get_pixelv(start+Vector2i(x,y))
					if pixel.a>.1:
						assert(x>0 and x<319 and y>0 and y<319,"Clipped Guardian pose")
						assert(not(pixel.r>.65 and pixel.b>.65 and pixel.g<.35),"Magenta matte survived")
						opaque+=1
			assert(opaque>1000,"Missing Guardian pose")
	var boss:=BOSS.new()
	root.add_child(boss)
	boss.set_physics_process(false)
	var player:=CharacterBody2D.new()
	root.add_child(player)
	boss.player=player
	boss.position=Vector2(20200,553)
	boss.home_y=553
	player.position=Vector2(20400,577)
	var seen: Dictionary={0:true,18:true}
	for name in ["summon","charged_arrow","rapid_fire","knife_combo","retreat_dash","flipping_volley"]:
		var shots:=0
		var hits:=0
		for phase in boss.attack_phases(name):
			seen[int(phase.sprite_pose)]=true
			if phase.has("projectile"):
				shots+=1
				if name=="charged_arrow": assert(phase.projectile_damage==2)
			if phase.has("hit"):
				hits+=1
				assert(phase.move>0,"Knife combo lost forward momentum")
		if name=="rapid_fire": assert(shots==5)
		if name=="knife_combo": assert(hits==3)
	assert(seen.size()==20,"Supplied poses are unreachable")
	boss.health=boss.max_health * 0.6
	boss.mobility_cooldown=0
	assert(boss.choose_attack()!="flipping_volley")
	boss.health=boss.max_health * 0.4
	assert(boss.choose_attack()=="flipping_volley")
	boss.summon_marks=boss._summon_positions()
	boss.summon_enemies()
	assert(boss.summons.size()==1, "First summon should spawn 1 random summon")
	boss.summon_enemies()
	assert(boss.summons.size()==2, "Second summon should spawn 1 different type")
	assert(boss.summons[0].variant!=boss.summons[1].variant, "Second summon must be a different type")
	boss.summon_enemies()
	assert(boss.summons.size()==3, "Third summon should spawn 1 different type")
	var summoned_variants: Array = [boss.summons[0].variant, boss.summons[1].variant, boss.summons[2].variant]
	summoned_variants.sort()
	assert(summoned_variants == [0, 1, 2], "All 3 summons must be of distinct types")
	for i in 3:
		assert(is_equal_approx(boss.summons[i].position.y+BOSS.SCOUT.HEIGHT/2,600),"Summon feet miss floor")
	boss.summon_enemies()
	assert(boss.summons.size()==3,"Summon cap exceeded when 3 are on field")
	boss.health=boss.max_health * 0.6
	boss.attack_cycles_since_summon=3
	assert(boss.choose_attack()!="summon","Boss chose summon with 3 living summons on field")
	boss.begin_attack("summon")
	assert(boss.attack_name!="summon","Blocked summon still played its animation")
	for enemy in boss.summons: enemy.health=0
	boss.attack_cycles_since_summon=3
	assert(boss.choose_attack()=="summon","Defeated wave prevents resummoning after 3 attack cycles")
	boss.state="air_dash"
	boss.phase={"sprite_pose":15}
	boss.combat_fx.tick(boss,.016)
	boss.combat_fx.land(boss)
	assert(not boss.combat_fx.ghosts.is_empty() and not boss.combat_fx.dust.is_empty())
	boss.reset_encounter()
	assert(boss.summons.is_empty() and boss.combat_fx.ghosts.is_empty() and boss.combat_fx.dust.is_empty())
	await process_frame
	print("FOREST_GUARDIAN_SMOKE_PASS: 20 poses in both facings, phases, summon cap, grounded feet, phase gate, FX cleanup")
	quit()
