extends SceneTree

const SUMMON = preload("res://scripts/forest_guardian_spirit.gd")

func _initialize() -> void:
	for variant in 3:
		var image: Image = SUMMON.TEXTURES[variant].get_image()
		if image.is_compressed(): image.decompress()
		var counts: Array = SUMMON.FRAME_COUNTS[variant]
		assert(image.get_width() == counts.max() * SUMMON.CELL)
		assert(image.get_height() == 5 * SUMMON.CELL)
		for row in 5:
			for frame in counts[row]:
				var region := image.get_region(Rect2i(frame * SUMMON.CELL, row * SUMMON.CELL, SUMMON.CELL, SUMMON.CELL))
				var bounds := region.get_used_rect()
				assert(bounds.size.x > 50 and bounds.size.y > 70, "Missing summon body %d:%d:%d" % [variant, row, frame])
				assert(bounds.position.x >= 0 and bounds.end.x <= SUMMON.CELL and bounds.end.y == SUMMON.FOOT_Y, "Summon feet or crop misregistered %d:%d:%d" % [variant, row, frame])
				var face := 0
				for y in range(bounds.position.y, bounds.end.y):
					for x in range(bounds.position.x, bounds.end.x):
						var c := region.get_pixel(x, y)
						if c.a > 0.4 and c.b > 0.5 and c.g > 0.4 and c.r < 0.4: face += 1
				assert(face >= 10, "Summon face missing %d:%d:%d" % [variant, row, frame])
	assert(SUMMON.FRAME_COUNTS[2][3] == 12)
	print("FOREST_SUMMON_ANIMATION_PASS: 106 registered bear, troll and ent frames; all five states, complete Ent combo")
	quit()
