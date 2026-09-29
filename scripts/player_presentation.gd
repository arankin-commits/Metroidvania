extends RefCounted

# Artwork only: the controller, body and attack volumes remain authoritative.
const ATLAS = preload("res://assets/characters/hooded_player_atlas.png")
const CELL := 128
const FOOT := Vector2(64, 96)
const FRAME_RECT := Rect2(-64, -73, 128, 128)
const STANDING_HEIGHT := 58

const SEQUENCES := {
	"sheathed_idle": [0, 1, 2, 3, 4],
	"sheathed_walk": [5, 6, 7, 8, 9],
	"sheathed_run": [10, 11, 12, 13, 14],
	"sheathed_dash": [15, 16, 17, 18],
	"sheathed_jump": [19, 20, 21, 22],
	"sheathed_fall": [23, 24, 25, 26, 27],
	"unsheathed_idle": [28, 29, 30, 31, 32],
	"unsheathed_walk": [33, 34, 35, 36, 37],
	"unsheathed_run": [38, 39, 40, 41, 42],
	"unsheathed_dash": [43, 44, 45, 46],
	"unsheathed_jump": [47, 48, 49, 50],
	"unsheathed_fall": [51, 52, 53, 54, 55],
	"slash_horizontal": [56, 57, 58],
	"slash_upward": [59, 60, 61, 62],
	"slash_downward": [63, 64, 65, 66],
}

const COMPLETE = preload("res://assets/characters/hooded_player_complete.png")
const COMPLETE_CELL := 224
const COMPLETE_RECT := Rect2(-96, -137, 224, 224)

static func sequence(player: CharacterBody2D) -> String:
	var armed: bool = player.weapon_visible_time > 0.0 and player.equipped_weapon in ["starter", "scimitar"]
	var prefix := "unsheathed_" if armed else "sheathed_"
	if player.attack_time > 0.0 and player.attack_style == "swing":
		return ["slash_horizontal", "slash_upward", "slash_downward"][maxi(0, player.sword_combo_step)]
	if player.heavy_attack_time > 0.0: return "slash_downward"
	if player.dash_time > 0.0: return prefix + "dash"
	if not player.is_on_floor(): return prefix + ("jump" if player.velocity.y < -30 else "fall")
	if absf(player.velocity.x) > 180: return prefix + "run"
	if absf(player.velocity.x) > 10: return prefix + "walk"
	return prefix + "idle"

static func advance(player: CharacterBody2D, delta: float) -> void:
	var current := sequence(player)
	if current != player.visual_state:
		player.visual_state = current
		player.visual_state_time = 0.0
	else:
		player.visual_state_time += delta

static func frame_index(player: CharacterBody2D) -> int:
	var current := sequence(player)
	var frames: Array = SEQUENCES[current]
	var elapsed: float = player.visual_state_time if current == player.visual_state else 0.0
	var slot: int
	if current.begins_with("slash"):
		var duration := 0.3 if player.attack_time > 0 else 0.25
		var remaining: float = player.attack_time if player.attack_time > 0 else player.heavy_attack_time
		slot = mini(frames.size() - 1, int((1.0 - remaining / duration) * frames.size()))
	elif current.ends_with("dash"):
		var duration := 0.23 if player.dash_speed_current == player.DASH_SPEED else 0.17
		slot = mini(frames.size() - 1, int((1.0 - player.dash_time / duration) * frames.size()))
	elif current.ends_with("jump") or current.ends_with("fall"):
		slot = mini(frames.size() - 1, int(elapsed * 14))
	else:
		var fps := 6.0 if current.ends_with("idle") else 12.0
		slot = int(elapsed * fps) % frames.size()
	return frames[maxi(0, slot)]

static func pose(player: CharacterBody2D) -> int:
	if not player.meditation_state.is_empty(): return 15
	if player.ledge_grabbed or player.ledge_climb_time > 0: return 14
	if player.attack_time > 0 and player.attack_style == "thrust": return 13
	if player.heavy_charge > 0.4: return 9
	return -1

static func draw(player: CharacterBody2D, alpha: float, override_pose := -1) -> void:
	var index := pose(player) if override_pose < 0 else override_pose
	player.draw_set_transform(Vector2.ZERO, 0.0, Vector2(player.facing, 1))
	if index >= 0:
		player.draw_texture_rect_region(ATLAS, FRAME_RECT,
			Rect2(Vector2(index % 4, index / 4) * CELL, Vector2(CELL, CELL)), Color(1, 1, 1, alpha))
	else:
		index = frame_index(player)
		player.draw_texture_rect_region(COMPLETE, COMPLETE_RECT,
			Rect2(Vector2(index % 8, index / 8) * COMPLETE_CELL, Vector2(COMPLETE_CELL, COMPLETE_CELL)), Color(1, 1, 1, alpha))
	player.draw_set_transform(Vector2.ZERO)
