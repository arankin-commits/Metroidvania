extends "res://scripts/combat_boss.gd"
var phase_two_started:=false

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(62,61),Vector2(124,108))

func _ready() -> void:
	super._ready()
	arena_bounds=Vector2(22900,23900)
	max_health=6
	health=max_health

func choose_attack() -> String:
	if health<=max_health*.5 and not phase_two_started:
		phase_two_started=true
		return "fire"
	if absf(player.global_position.x-global_position.x)<175:
		return "punch_combo" if randi()%2==0 else "slam"
	if health<max_health*.5:
		return "fire" if randi()%2==0 else "rocket_punch"
	if health==max_health*.5: return "fire"
	return "rocket_punch"

func reset_encounter() -> void:
	phase_two_started=false
	super.reset_encounter()

func attack_phases(name: String) -> Array[Dictionary]:
	match name:
		"rocket_punch":
			return [{"state":"tell_rocket","time":.65},
				{"state":"rocket","time":.05,"projectile":"fist"},
				{"state":"recover","time":1.35}]
		"fire":
			return [{"state":"charge_fire","time":1.05,"invulnerable":true},
				{"state":"fire","time":.12,"projectile":"beam","damage":2.0},
				{"state":"recover","time":1.0}]
		"slam":
			return [{"state":"tell_slam","time":.8,"preview":Rect2(-130,-20,260,67)},
				{"state":"slam","time":.18,"hit":Rect2(-130,-20,260,67)},
				{"state":"recover","time":.9}]
	var result: Array[Dictionary]=[]
	for i in 3:
		result.append({"state":"tell_punch","time":.55 if i==0 else .25,"preview":Rect2(20,-35,130,75)})
		result.append({"state":"punch","time":.15,"hit":Rect2(20,-35,130,75)})
		result.append({"state":"combo_pause","time":.2})
	result.append({"state":"recover","time":.9})
	return result

func _draw() -> void:
	if health<=0: return
	var stone:=Color("849b94") if hurt_flash<=0 else Color("f1e3bb")
	draw_rect(Rect2(-41,-40,82,61),Color("354f56"))
	draw_rect(Rect2(-35,-35,70,55),stone)
	draw_rect(Rect2(-28,-61,56,30),stone)
	draw_rect(Rect2(-24,-50,48,7),Color("1d393f"))
	for x in [-17,11]: draw_rect(Rect2(x,-49,6,4),Color("b6e5d4"))
	for x in [-39,13]: draw_rect(Rect2(x,20,26,27),stone)
	draw_line(Vector2(-16,-24),Vector2(15,14),Color("354f56"),3)
	var hand:=Vector2(facing*63,10)
	if state=="charge_fire" or state=="fire":
		hand=Vector2(facing*58,-7)
		draw_line(Vector2(-facing*35,-20),hand+Vector2(-facing*13,-12),stone,17)
		draw_rect(Rect2(hand-Vector2(12,12),Vector2(24,24)),Color("e4ab6f"))
	else:
		draw_line(Vector2(-34,-18),Vector2(-62,13),stone,19)
		draw_line(Vector2(34,-18),Vector2(62,13),stone,19)
	draw_rect(Rect2(hand-Vector2(15,12),Vector2(30,27)),stone,false,4)
	draw_attack()
