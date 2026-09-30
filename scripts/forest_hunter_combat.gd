extends "res://scripts/combat_boss.gd"
const SCOUT=preload("res://scripts/scout.gd")
var summons: Array[Node]=[]
var mobility_cooldown:=0.0
var summon_cooldown:=0.0

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(31,52),Vector2(62,99))

func _ready() -> void:
	super._ready()
	arena_bounds=Vector2(19490,20910)
	health=10
	max_health=10
	add_to_group("bow_targets")

func _physics_process(delta: float) -> void:
	mobility_cooldown=maxf(0,mobility_cooldown-delta)
	summon_cooldown=maxf(0,summon_cooldown-delta)
	if not active or health<=0: clear_summons()
	super._physics_process(delta)

func clear_summons() -> void:
	for enemy in summons:
		if is_instance_valid(enemy): enemy.queue_free()
	summons.clear()

func reset_encounter() -> void:
	clear_summons()
	mobility_cooldown=0
	summon_cooldown=0
	super.reset_encounter()

func choose_attack() -> String:
	var distance:=absf(player.global_position.x-global_position.x)
	if health<max_health*.5 and mobility_cooldown<=0 and distance<450:
		mobility_cooldown=5
		return "flipping_volley"
	if distance<130:
		if attack_count%2==0 and mobility_cooldown<=0:
			mobility_cooldown=4
			return "retreat_dash"
		return "knife_combo"
	if summon_cooldown<=0 and attack_count%3==0:
		summon_cooldown=9
		return "summon"
	return "rapid_fire" if attack_count%2==0 else "charged_arrow"

func attack_phases(name: String) -> Array[Dictionary]:
	match name:
		"summon": return [{"state":"tell_summon","time":.9},{"state":"summon","time":.2,"summon":true},{"state":"recover","time":.8}]
		"charged_arrow": return [{"state":"telegraph","time":.9,"cue":"bow_charge"},{"state":"shoot","time":.1,"projectile":"arrow"},{"state":"recover","time":.8}]
		"retreat_dash": return [{"state":"tell_dash","time":.4},{"state":"air_dash","time":.55,"retreat":true,"height":90},{"state":"recover","time":.6}]
		"flipping_volley": return [{"state":"tell_volley","time":.65},{"state":"flipping_volley","time":1.2,"over_player":true,"height":200,"volley":true},{"state":"recover","time":.85}]
	var result: Array[Dictionary]=[]
	if name=="rapid_fire":
		result.append({"state":"tell_rapid","time":.7,"cue":"bow_charge"})
		for i in 5: result.append({"state":"shoot","time":.16,"projectile":"arrow"})
	else:
		for i in 3:
			result.append({"state":"tell_knife","time":.5 if i==0 else .2,"preview":Rect2(10,-27,88,63)})
			result.append({"state":"knife","time":.14,"hit":Rect2(10,-27,88,63)})
			result.append({"state":"combo_pause","time":.17})
	result.append({"state":"recover","time":.8})
	return result

func summon_enemies() -> void:
	# At most one living wave of three; never spawn into the player's body.
	for enemy in summons:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion(): return
	summons.clear()
	for offset in [-260.0,0.0,260.0]:
		var x:=clampf(global_position.x+offset,arena_bounds.x+40,arena_bounds.y-40)
		if absf(x-player.global_position.x)<120: x=clampf(x+(-160 if player.global_position.x>x else 160),arena_bounds.x+40,arena_bounds.y-40)
		var enemy:=SCOUT.new()
		enemy.player=player
		enemy.position=Vector2(x,577)
		enemy.collision_layer=2
		enemy.collision_mask=1
		enemy.patrol_bounds=arena_bounds
		enemy.spawn_grace=.8
		get_parent().add_child(enemy)
		enemy.add_to_group("combat_targets")
		enemy.add_to_group("forest_boss_summons")
		summons.append(enemy)

func _draw() -> void:
	if health<=0: return
	var cloth:=Color("567c80") if hurt_flash<=0 else Color("f5deb0")
	draw_colored_polygon(PackedVector2Array([Vector2(-30,47),Vector2(-27,-29),Vector2(-12,-52),Vector2(18,-49),Vector2(31,-19),Vector2(28,47)]),cloth)
	draw_rect(Rect2(-18,-27,36,22),Color("1c2934"))
	draw_rect(Rect2(facing*11-3,-20,6,5),Color("ffd77a"))
	draw_rect(Rect2(-facing*29-8,-20,16,44),Color("594839"))
	for i in 3: draw_line(Vector2(-facing*27+i*4,-17),Vector2(-facing*27+i*4,-40),Color("b7c2a8"),2)
	if "knife" in state:
		draw_line(Vector2(facing*22,0),Vector2(facing*65,-8),Color("f5d991"),4)
	else:
		draw_arc(Vector2(facing*22,-8),27,-PI*.5 if facing>0 else PI*.5,PI*.5 if facing>0 else PI*1.5,16,Color("c9ab74"),4)
		draw_line(Vector2(facing*22,-35),Vector2(facing*22,19),Color("e7dac0"),2)
	if state in ["telegraph","tell_rapid"]:
		draw_line(Vector2(facing*25,-8),to_local(player.global_position),Color(.95,.65,.4,.5),2)
	if state=="tell_summon":
		for x in [-70,0,70]: draw_rect(Rect2(x-7,23,14,20),Color("d7ab76"),false,2)
	draw_attack()
