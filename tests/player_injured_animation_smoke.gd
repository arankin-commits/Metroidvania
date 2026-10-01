extends SceneTree

const ART = preload("res://scripts/player_presentation.gd")
const SHEETS := [
	[ART.COMPLETE, ART.INJURED_COMPLETE, 224, 8, 67],
	[ART.ATLAS, ART.INJURED_ATLAS, 128, 4, 16],
	[ART.HEAVY, ART.INJURED_HEAVY, 192, 3, 9],
]

func _initialize() -> void:
	for sheet in SHEETS:
		var clean: Image = sheet[0].get_image()
		var injured: Image = sheet[1].get_image()
		if clean.is_compressed(): clean.decompress()
		if injured.is_compressed(): injured.decompress()
		assert(clean.get_size() == injured.get_size())
		var cell: int = sheet[2]
		var columns: int = sheet[3]
		for index in sheet[4]:
			var top_left := Vector2i(index % columns, index / columns) * cell
			var blood_pixels := 0
			for y in cell:
				for x in cell:
					var point := top_left + Vector2i(x, y)
					var before := clean.get_pixelv(point)
					var after := injured.get_pixelv(point)
					assert(absf(before.a - after.a) < 0.01, "Injured art changed frame silhouette %d" % index)
					if after.r > before.r + 0.03 and after.r > after.g * 1.3:
						blood_pixels += 1
			assert(blood_pixels >= 4, "Missing blood in frame %d" % index)
	assert(ART.INJURED_COMPLETE != ART.COMPLETE and ART.INJURED_ATLAS != ART.ATLAS and ART.INJURED_HEAVY != ART.HEAVY)
	print("PLAYER_INJURED_ANIMATION_PASS: blood in every playable pose, original silhouettes retained")
	quit()
