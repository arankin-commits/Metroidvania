extends RefCounted

const SLOT_COUNT := 3
const AREA_NAME := "Forgotten Passage"

static func path_for(slot: int, root: String = "user://") -> String:
	return root.path_join("save_slot_%d.cfg" % slot)

static func load_slot(slot: int, root: String = "user://") -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT:
		return {}
	var config := ConfigFile.new()
	if config.load(path_for(slot, root)) != OK:
		return {}
	return {
		"area": str(config.get_value("save", "area", AREA_NAME)),
		"room": int(config.get_value("save", "room", 3 if float(config.get_value("save", "checkpoint_x", 120.0)) >= 1700.0 else 2)),
		"seconds": float(config.get_value("save", "seconds", 0.0)),
		"level": int(config.get_value("save", "level", 1)),
		"will": int(config.get_value("save", "will", 0)),
		"healing_charges": int(config.get_value("save", "healing_charges", 3)),
		"checkpoint_x": float(config.get_value("save", "checkpoint_x", 120.0)),
		"hand_activated": bool(config.get_value("save", "hand_activated", false)),
		"has_dash": true,
		"aerial_practiced": bool(config.get_value("save", "aerial_practiced", false)),
		"sentinel_defeated": bool(config.get_value("save", "sentinel_defeated", config.get_value("save", "aerial_practiced", false))),
		"jump_practiced": bool(config.get_value("save", "jump_practiced", false)),
		"dodge_practiced": bool(config.get_value("save", "dodge_practiced", false)),
		"drop_practiced": bool(config.get_value("save", "drop_practiced", false)),
		"ledge_practiced": bool(config.get_value("save", "ledge_practiced", false)),
		"heal_practiced": bool(config.get_value("save", "heal_practiced", false)),
		"dash_gap_practiced": bool(config.get_value("save", "dash_gap_practiced", false)),
		"seal_broken": bool(config.get_value("save", "seal_broken", false)),
		"scout_defeated": bool(config.get_value("save", "scout_defeated", false)),
		"boss_defeated": bool(config.get_value("save", "boss_defeated", false)),
		"has_heavy": bool(config.get_value("save", "has_heavy", config.get_value("save", "boss_defeated", false))),
		"wall_broken": bool(config.get_value("save", "wall_broken", false)),
		"secret_found": bool(config.get_value("save", "secret_found", false)),
		"note_found": bool(config.get_value("save", "note_found", false)),
		"visited_rooms": Array(config.get_value("save", "visited_rooms", [2])),
	}

static func new_slot() -> Dictionary:
	return {
		"area": AREA_NAME,
		"room": 2,
		"seconds": 0.0,
		"level": 1,
		"will": 0,
		"healing_charges": 3,
		"checkpoint_x": 120.0,
		"hand_activated": false,
		"has_dash": true,
		"aerial_practiced": false,
		"sentinel_defeated": false,
		"jump_practiced": false,
		"dodge_practiced": false,
		"drop_practiced": false,
		"ledge_practiced": false,
		"heal_practiced": false,
		"dash_gap_practiced": false,
		"seal_broken": false,
		"scout_defeated": false,
		"boss_defeated": false,
		"has_heavy": false,
		"wall_broken": false,
		"secret_found": false,
		"note_found": false,
		"visited_rooms": [2],
	}

static func write_slot(slot: int, data: Dictionary, root: String = "user://") -> Error:
	if slot < 1 or slot > SLOT_COUNT:
		return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	for key in data:
		config.set_value("save", key, data[key])
	return config.save(path_for(slot, root))

static func delete_slot(slot: int, root: String = "user://") -> Error:
	if slot < 1 or slot > SLOT_COUNT:
		return ERR_INVALID_PARAMETER
	if not FileAccess.file_exists(path_for(slot, root)):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path_for(slot, root)))

static func format_time(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	return "%02d:%02d:%02d" % [int(total / 3600), int(total / 60) % 60, total % 60]
