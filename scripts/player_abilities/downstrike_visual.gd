extends Sprite2D
## Child of player, reference visual only during ability. Separate from normal art.
var clip := &""
var age := 0.0
var textures: Array[Texture2D] = []
const KEYS = ["windup_01", "windup_02", "windup_03", "windup_04", "plunge_01", "plunge_02", "impact_01", "impact_02", "recover_01", "recover_02", "recover_03", "idle"]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for key in KEYS:
		textures.append(load("res://assets/player_downstrike/" + key + ".png") as Texture2D)
	visible = false

func request(name: StringName) -> void:
	clip = name
	age = 0.0
	visible = true

func finish() -> void:
	visible = false
	clip = &""

func _process(delta: float) -> void:
	if not visible or textures.is_empty():
		return
	age += delta
	var index := 0
	match clip:
		&"slam_windup": index = mini(3, int(age / 0.035))
		&"slam_plunge": index = 4 + int(age / 0.08) % 2
		&"slam_land": index = mini(10, 6 + int(age / 0.06))
	texture = textures[index]
