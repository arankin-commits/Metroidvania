extends Node

const CAVE_MUSIC = preload("res://assets/cave_music.wav")
const FOREST_MUSIC = preload("res://assets/forest_music.wav")
const WARDEN_MUSIC = preload("res://assets/warden_music.wav")
const EFFECTS := {
	"attack": preload("res://assets/attack.wav"),
	"heavy_attack": preload("res://assets/heavy_attack.wav"),
	"jump": preload("res://assets/jump.wav"),
	"dodge": preload("res://assets/dodge.wav"),
	"heal": preload("res://assets/heal.wav"),
	"enemy_attack": preload("res://assets/enemy_attack.wav"),
	"warden_charge_tell": preload("res://assets/warden_charge_tell.wav"),
	"warden_charge": preload("res://assets/warden_charge.wav"),
	"warden_slam_tell": preload("res://assets/warden_slam_tell.wav"),
	"warden_slam": preload("res://assets/warden_slam.wav"),
	"ui_move": preload("res://assets/menu_hover.wav"),
	"ui_confirm": preload("res://assets/menu_click.wav"),
	"fast_travel_select": preload("res://assets/fast_travel_select.wav"),
	"fast_travel_confirm": preload("res://assets/fast_travel_confirm.wav"),
	"hand_mount": preload("res://assets/hand_mount.wav"),
	"hand_dismount": preload("res://assets/hand_dismount.wav"),
}

var music: AudioStreamPlayer
var effects: Dictionary = {}
var current_track := ""
var music_volume := 0.55
var sound_volume := 0.75
var option_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = AudioStreamPlayer.new()
	music.name = "Music"
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.finished.connect(func() -> void:
		if not current_track.is_empty():
			music.play())
	add_child(music)
	for cue in EFFECTS:
		var player := AudioStreamPlayer.new()
		player.name = str(cue)
		player.stream = EFFECTS[cue]
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		effects[cue] = player
	_refresh_options()

func _process(delta: float) -> void:
	option_timer -= delta
	if option_timer <= 0.0:
		option_timer = 0.25
		_refresh_options()

func play_cave() -> void:
	_set_track("cave", CAVE_MUSIC)

func play_forest() -> void:
	_set_track("forest", FOREST_MUSIC)

func play_boss() -> void:
	_set_track("warden", WARDEN_MUSIC)

func play_effect(cue: String) -> void:
	if effects.has(cue):
		(effects[cue] as AudioStreamPlayer).play()

func _set_track(track: String, stream: AudioStream) -> void:
	if current_track == track and music.playing:
		return
	current_track = track
	music.stop()
	music.stream = stream
	music.play()

func _refresh_options() -> void:
	var config := ConfigFile.new()
	if config.load("user://menu_options.cfg") == OK:
		music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
		sound_volume = clampf(float(config.get_value("audio", "sound", sound_volume)), 0.0, 1.0)
	music.volume_db = -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)
	for player in effects.values():
		(player as AudioStreamPlayer).volume_db = -80.0 if sound_volume <= 0.0 else linear_to_db(sound_volume)
