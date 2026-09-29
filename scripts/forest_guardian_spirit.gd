extends "res://scripts/scout.gd"
const ATLAS = preload("res://assets/characters/forest_guardian_allies.png")
const ROOTS = [preload("res://assets/effects/forest_roots_1.png"), preload("res://assets/effects/forest_roots_2.png"), preload("res://assets/effects/forest_roots_3.png")]
var variant := 0
var visual_time := 0.0
const HEIGHT := 99.0 * 1.2
const ART_SCALE := HEIGHT / 38.0

func body_size() -> Vector2: return Vector2(32.0*ART_SCALE,HEIGHT)
func combat_bounds() -> Rect2: return Rect2(global_position-body_size()/2,body_size())

func _physics_process(delta: float) -> void:
	visual_time += delta
	super._physics_process(delta)

func _draw() -> void:
	var emergence := clampf(1.0 - spawn_grace / 0.8, 0, 1)
	if spawn_grace > 0:
		draw_texture_rect(ROOTS[variant], Rect2(-60, HEIGHT/2-90, 120, 90), false, Color(1, 1, 1, 1.0 - emergence * 0.6))
	var bob := absf(sin(visual_time * 12)) * 1.5 if spawn_grace <= 0 else 0.0
	draw_set_transform(Vector2(0, -bob), 0, Vector2(facing, 1))
	var scale := HEIGHT/119.0
	draw_texture_rect_region(ATLAS, Rect2(-128*scale, HEIGHT/2-192*scale, 256*scale, 256*scale), Rect2(variant * 256, 0, 256, 256), Color(1, 1, 1, emergence))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-30, -HEIGHT/2-12, 60, 5), Color("092027"))
	draw_rect(Rect2(-28, -HEIGHT/2-11, 56 * maxf(0, health) / max_health, 3), Color("71e6c5"))
