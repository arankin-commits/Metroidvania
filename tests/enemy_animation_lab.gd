extends Node2D
## Native test entry only. No progress load/save, rewards, or room transitions.
const ENEMY=preload("res://scripts/enemies/reference_enemy.gd")
const PLAYER=preload("res://scripts/player.gd")
const BACKGROUND=preload("res://assets/forest_backdrop.png")
var actor: CharacterBody2D
var player: CharacterBody2D
var label: Label
var kind_index:=0
var sequence_index:=0
var arrows: Array[Node2D]=[]

func _ready() -> void:
	get_tree().set_meta("active_save_slot",0)
	var backdrop:=Sprite2D.new()
	backdrop.texture=BACKGROUND
	backdrop.centered=false
	backdrop.position=Vector2(-600,-300)
	backdrop.scale=Vector2(2,2)
	backdrop.modulate=Color(.4,.45,.5)
	add_child(backdrop)
	var floor_body:=StaticBody2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(2400,100)
	var collision:=CollisionShape2D.new()
	collision.shape=shape
	floor_body.position=Vector2(600,650)
	floor_body.add_child(collision)
	add_child(floor_body)
	var terrain:=Polygon2D.new()
	terrain.polygon=PackedVector2Array([Vector2(-600,600),Vector2(1800,600),Vector2(1800,700),Vector2(-600,700)])
	terrain.color=Color("172934")
	add_child(terrain)
	var edge:=Line2D.new()
	edge.points=PackedVector2Array([Vector2(-600,600),Vector2(1800,600)])
	edge.default_color=Color("45918c")
	edge.width=3
	add_child(edge)
	player=PLAYER.new()
	player.position=Vector2(420,577)
	player.has_heavy=true
	player.has_dash=true
	player.invulnerability=100000
	add_child(player)
	player.attacked.connect(hit_actor)
	player.heavy_attacked.connect(hit_actor)
	var camera: Camera2D=player.get_node("Camera2D")
	camera.position_smoothing_enabled=false
	camera.position=Vector2(100,-120)
	camera.limit_left=-600
	camera.limit_right=1800
	camera.limit_top=100
	camera.limit_bottom=800
	var ui:=CanvasLayer.new()
	add_child(ui)
	label=Label.new()
	label.position=Vector2(16,12)
	label.add_theme_color_override("font_color",Color.WHITE)
	ui.add_child(label)
	select_kind(0)

func select_kind(index: int) -> void:
	if is_instance_valid(actor): actor.queue_free()
	for arrow in arrows:
		if is_instance_valid(arrow): arrow.queue_free()
	arrows.clear()
	kind_index=posmod(index,ENEMY.LIBRARY.size())
	actor=ENEMY.new()
	actor.enemy_kind=ENEMY.LIBRARY.keys()[kind_index]
	actor.position=Vector2(650,600)
	actor.target=player
	add_child(actor)
	actor.attack_cue.connect(cue)
	sequence_index=0
	update_label()

func update_label() -> void:
	label.text="ENEMY ANIMATION LAB — testing only\n%s / %s\n1–6 enemy   Tab pose   V face   G AI   R reset\nA/D move   Space jump   J attack   H charge heavy" % [actor.enemy_kind,actor.sprite.animation]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_6: select_kind(event.physical_keycode-KEY_1)
	elif event.physical_keycode==KEY_TAB:
		actor.ai_enabled=false
		var names: PackedStringArray=actor.animations()
		sequence_index=(sequence_index+1)%names.size()
		actor.play_sequence(names[sequence_index],names[sequence_index] in ["walk","run"],true)
	elif event.physical_keycode==KEY_V: actor.facing=-actor.facing
	elif event.physical_keycode==KEY_G: actor.ai_enabled=not actor.ai_enabled
	elif event.physical_keycode==KEY_R:
		player.position=Vector2(420,577)
		select_kind(kind_index)
	update_label()

func hit_actor(hitbox: Rect2) -> void:
	if hitbox.intersects(actor.combat_bounds()): actor.take_hit()

func cue(kind: String, origin: Vector2, direction: int) -> void:
	if kind!="shoot": return
	var arrow:=Sprite2D.new()
	arrow.texture=preload("res://assets/characters/enemies/kobold_archer_arrow.png")
	arrow.scale=Vector2(direction*.5,.5)
	arrow.position=origin
	add_child(arrow)
	arrows.append(arrow)
	var tween:=create_tween()
	tween.tween_property(arrow,"position",origin+Vector2(direction*600,0),1.5)
	tween.tween_callback(arrow.queue_free)

func _process(_delta: float) -> void:
	arrows=arrows.filter(func(arrow: Node2D): return is_instance_valid(arrow))
	if is_instance_valid(actor):
		if actor.position.x<100 or actor.position.x>1150:
			actor.position.x=clampf(actor.position.x,100,1150)
			actor.facing=-actor.facing
		update_label()
