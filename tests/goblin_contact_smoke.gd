extends SceneTree
const BOSS=preload("res://scripts/goblin_boss.gd")
const PLAYER=preload("res://scripts/player.gd")
func _initialize() -> void: call_deferred("run")
func key(code: Key,down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code; event.keycode=code; event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	var arena:=Node2D.new()
	root.add_child(arena)
	var floor_body:=StaticBody2D.new()
	floor_body.position=Vector2(1000,625)
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(3000,50)
	collision.shape=shape; floor_body.add_child(collision); arena.add_child(floor_body)
	var player:=PLAYER.new()
	player.position=Vector2(700,577); arena.add_child(player)
	var boss:=BOSS.new()
	boss.position=Vector2(1000,553); boss.player=player; arena.add_child(boss)
	boss.active=true; boss.state_time=100
	for direction in [-1,1]:
		player.position=Vector2(1000-direction*150,577)
		player.reset_movement_state(); player.health=5; player.invulnerability=0
		var code:=KEY_D if direction>0 else KEY_A
		key(code,true)
		for i in 50: await physics_frame
		key(code,false)
		assert(player.health==4,"Walking into idle boss did not cause exactly one contact hit")
		player.position=Vector2(1000,577); player.invulnerability=1
		for i in 8: await physics_frame
		assert(player.health==4,"Contact ignored player invulnerability")
	boss.active=false; player.invulnerability=0; player.position=boss.position+Vector2(0,24)
	for i in 4: await physics_frame
	assert(player.health==4,"Inactive boss still hurts")
	boss.active=true; boss.health=0
	for i in 4: await physics_frame
	assert(player.health==4,"Defeated boss still hurts")
	print("GOBLIN_CONTACT_PASS: real walking both directions, i-frames, inactive/dead")
	quit()
