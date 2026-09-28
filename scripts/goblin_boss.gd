extends "res://scripts/combat_boss.gd"

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(66,61),Vector2(132,108))

func choose_attack() -> String:
	var distance:=absf(player.global_position.x-global_position.x)
	if distance>290: return "jump_slam" if attack_count%2==0 else "charge_swing"
	if distance>150: return "mid_combo" if attack_count%2==0 else "charge_swing"
	return ["spin_combo","overhead_combo","charge_swing"][randi()%3]

func strike(reach: float,windup: float,style: String) -> Array[Dictionary]:
	var box:=Rect2(20,-43,reach,86)
	if style=="thrust": box=Rect2(30,-18,reach,28)
	if style=="overhead": box=Rect2(10,-85,reach,132)
	if style=="spin": box=Rect2(-150,-40,300,85)
	return [{"state":"tell_"+style,"time":windup,"preview":box,"style":style},
		{"state":style,"time":.16,"hit":box,"style":style},
		{"state":"combo_pause","time":.22}]

func attack_phases(name: String) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	match name:
		"jump_slam":
			return [{"state":"tell_jump","time":.7},
				{"state":"jump","time":.9,"target_jump":true,"height":210},
				{"state":"slam","time":.18,"hit":Rect2(-65,0,130,48),"damage":1.0},
				{"state":"recover","time":1.0}]
		"charge_swing":
			return [{"state":"telegraph","time":1.0,"preview":Rect2(20,-43,170,86),"style":"swing"},
				{"state":"charge","time":.2,"hit":Rect2(20,-43,170,86),"projectile":"wind","damage":1.0,"projectile_damage":.5,"style":"swing"},
				{"state":"recover","time":.95}]
		"spin_combo":
			result.append_array(strike(120,.6,"swing"))
			result.append_array(strike(130,.25,"swing"))
			result.append_array(strike(170,.35,"thrust"))
			result.append_array(strike(150,.4,"spin"))
		"overhead_combo":
			for i in 3: result.append_array(strike(120,.6 if i==0 else .25,"swing"))
			result.append_array(strike(205,.5,"overhead"))
		"mid_combo":
			result.append_array(strike(190,.65,"thrust"))
			result.append_array(strike(150,.3,"swing"))
	result.append({"state":"recover","time":.9})
	return result

func _draw() -> void:
	if health<=0: return
	var skin:=Color("92a45c") if hurt_flash<=0 else Color("f5deb0")
	var shadow:=Color("3f5139")
	# Broad hunched torso, long ape-like arms, tusked face, short weight-bearing legs.
	draw_colored_polygon(PackedVector2Array([Vector2(-50,22),Vector2(-46,-38),Vector2(-28,-61),Vector2(27,-61),Vector2(49,-34),Vector2(48,25)]),shadow)
	draw_rect(Rect2(-37,-49,74,68),skin)
	draw_rect(Rect2(-66,-24,22,65),skin)
	draw_rect(Rect2(44,-24,22,65),skin)
	draw_rect(Rect2(-41,19,29,28),shadow)
	draw_rect(Rect2(12,19,29,28),shadow)
	draw_rect(Rect2(-29,-59,58,31),skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-29,-49),Vector2(-50,-61),Vector2(-34,-28)]),skin)
	draw_colored_polygon(PackedVector2Array([Vector2(29,-49),Vector2(50,-61),Vector2(34,-28)]),skin)
	draw_rect(Rect2(-20,-46,40,8),Color("1d2930"))
	draw_rect(Rect2(-15,-45,6,4),Color("ffd28d"))
	draw_rect(Rect2(9,-45,6,4),Color("ffd28d"))
	for x in [-17,12]: draw_colored_polygon(PackedVector2Array([Vector2(x,-25),Vector2(x+3,-38),Vector2(x+7,-25)]),Color("e3d2a2"))
	var hand:=Vector2(facing*58,5)
	var blade:=PackedVector2Array([hand,hand+Vector2(facing*12,-70),hand+Vector2(facing*41,-91),hand+Vector2(facing*25,-30),hand+Vector2(facing*7,0)])
	if phase.has("hit"):
		blade=PackedVector2Array([hand,hand+Vector2(facing*85,-30),hand+Vector2(facing*112,-20),hand+Vector2(facing*75,0)])
	draw_colored_polygon(blade,Color("bdc7b6"))
	draw_line(hand,hand+Vector2(0,19),Color("765641"),7)
	draw_attack()
