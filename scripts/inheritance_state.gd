extends RefCounted

# Inheritance owns boss rewards and acquired ability state.
# Navigation only calls has_ability(); it never grants abilities.
var _abilities: Dictionary = {"heavy_break": false}

func has_ability(ability: String) -> bool:
	return bool(_abilities.get(ability, false))

func on_boss_defeated(boss_id: String) -> void:
	if boss_id == "hollow_warden":
		_abilities["heavy_break"] = true
