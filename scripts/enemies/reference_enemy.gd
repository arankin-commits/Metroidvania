extends CharacterBody2D
## Unplaced prefab: only the animation lab currently instantiates this actor.
signal attack_cue(kind: String, origin: Vector2, direction: int)
signal sequence_finished(sequence: StringName)

const LIBRARY = {
	"goblin": preload("res://assets/characters/enemies/goblin.tres"),
	"goblin_dog": preload("res://assets/characters/enemies/goblin_dog.tres"),
	"goblin_sentinel": preload("res://assets/characters/enemies/goblin_sentinel.tres"),
	"kobold_archer": preload("res://assets/characters/enemies/kobold_archer.tres"),
	"kobold_clubber": preload("res://assets/characters/enemies/kobold_clubber.tres"),
	"kobold_summoner": preload("res://assets/characters/enemies/kobold_summoner.tres")
}
const SIZES = {"goblin":Vector2(30,56),"goblin_dog":Vector2(48,36),"goblin_sentinel":Vector2(34,68),"kobold_archer":Vector2(32,65),"kobold_clubber":Vector2(42,82),"kobold_summoner":Vector2(34,70)}
const ATTACKS = {"goblin":["horizontal_slash","upward_slash","downward_slam"],"goblin_dog":["jump_attack","bite"],"goblin_sentinel":["thrust","combo"],"kobold_archer":["shoot"],"kobold_clubber":["slam","combo"],"kobold_summoner":["summon"]}
const CUES = {"horizontal_slash":[3],"upward_slash":[3],"downward_slam":[2],"jump_attack":[3],"bite":[2,4],"thrust":[2],"combo":[1,4],"slam":[3],"shoot":[4],"summon":[5]}

@export_enum("goblin","goblin_dog","goblin_sentinel","kobold_archer","kobold_clubber","kobold_summoner") var enemy_kind := "goblin"
var facing := 1:
	set(value):
		facing = -1 if value<0 else 1
		if is_instance_valid(visual): visual.scale.x=facing
var visual: Node2D
var sprite: AnimatedSprite2D
var collision: CollisionShape2D
var target: Node2D
var ai_enabled := false
var locomotion := false
var sequence_time := 0.0
var emitted_frames := {}
var hold_pose := false
var cooldown := 0.0
var attack_index := 0
var jump_pending := false

func _ready() -> void:
	collision_layer=2
	collision_mask=1
	visual=get_node_or_null("Visual")
	if visual==null:
		visual=Node2D.new()
		visual.name="Visual"
		add_child(visual)
	sprite=visual.get_node_or_null("Sprite")
	if sprite==null:
		sprite=AnimatedSprite2D.new()
		sprite.name="Sprite"
		visual.add_child(sprite)
	sprite.sprite_frames=LIBRARY[enemy_kind]
	sprite.centered=false
	sprite.position=Vector2(-128,-224)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	collision=get_node_or_null("Collision")
	if collision==null:
		collision=CollisionShape2D.new()
		collision.name="Collision"
		add_child(collision)
	var shape:=RectangleShape2D.new()
	shape.size=SIZES[enemy_kind]
	collision.shape=shape
	collision.position.y=-shape.size.y/2
	facing=facing
	play_sequence("idle")

func animations() -> PackedStringArray: return sprite.sprite_frames.get_animation_names()

func combat_bounds() -> Rect2:
	var size: Vector2=SIZES[enemy_kind]
	return Rect2(global_position-Vector2(size.x/2,size.y),size)

func play_sequence(sequence: StringName, move := false, hold := false) -> void:
	assert(sprite.sprite_frames.has_animation(sequence))
	sprite.animation=sequence
	sprite.frame=0
	sprite.pause()
	sequence_time=0.0
	emitted_frames.clear()
	locomotion=move
	hold_pose=hold
	velocity.x=0
	jump_pending=sequence==&"jump_attack" and is_on_floor()

func take_hit(_damage := 1.0) -> void:
	play_sequence("posture_break")
	cooldown=1.2

func tick_animation(delta: float) -> void:
	var sequence:=sprite.animation
	var frames:=sprite.sprite_frames.get_frame_count(sequence)
	var fps:=sprite.sprite_frames.get_animation_speed(sequence)
	var old_frame:=int(sequence_time*fps)
	sequence_time+=delta
	var elapsed_frame:=int(sequence_time*fps)
	if CUES.has(String(sequence)):
		for cue in CUES[String(sequence)]:
			if cue>=old_frame and cue<=elapsed_frame and not emitted_frames.has(cue):
				emitted_frames[cue]=true
				attack_cue.emit(String(sequence),global_position+Vector2(facing*24,-SIZES[enemy_kind].y*.6),facing)
	if sprite.sprite_frames.get_animation_loop(sequence): sprite.frame=elapsed_frame%frames
	else:
		sprite.frame=mini(elapsed_frame,frames-1)
		if elapsed_frame>=frames and not hold_pose:
			sequence_finished.emit(sequence)
			play_sequence("idle")

func _physics_process(delta: float) -> void:
	cooldown=maxf(0,cooldown-delta)
	if jump_pending and sequence_time+delta>=2.0/sprite.sprite_frames.get_animation_speed("jump_attack"):
		jump_pending=false
		velocity=Vector2(facing*110,-260)
	if ai_enabled and is_instance_valid(target):
		var distance:=target.global_position.x-global_position.x
		if sprite.animation==&"idle" or sprite.animation==&"walk" or sprite.animation==&"run":
			facing=int(signf(distance)) if absf(distance)>1 else facing
			var ranged:=enemy_kind=="kobold_archer" or enemy_kind=="kobold_summoner"
			if absf(distance)>(240 if ranged else 85):
				if sprite.animation!=&"walk": play_sequence("walk",true)
			elif cooldown<=0:
				var attacks: Array=ATTACKS[enemy_kind]
				play_sequence(attacks[attack_index%attacks.size()])
				attack_index+=1
				cooldown=1.6
			elif sprite.animation!=&"idle": play_sequence("idle")
	if locomotion: velocity.x=facing*(115.0 if sprite.animation==&"run" else 55.0)
	elif sprite.animation!=&"jump_attack": velocity.x=move_toward(velocity.x,0,700*delta)
	velocity.y+=(1300.0 if sprite.animation==&"jump_attack" else 900.0)*delta
	move_and_slide()
	tick_animation(delta)
