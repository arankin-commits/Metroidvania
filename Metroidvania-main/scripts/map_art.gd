extends RefCounted

const GALLERY = preload("res://scripts/split_gallery_layout.gd")
const FOREST_ARRIVAL = preload("res://scripts/forest_arrival_layout.gd")
const FOREST_STAIR = preload("res://scripts/forest_stair_layout.gd")
const FOREST_UPPER = preload("res://scripts/forest_upper_gallery_layout.gd")
const FOREST_SMASH = preload("res://scripts/forest_smash_corridor_layout.gd")
const FOREST_STEPPED = preload("res://scripts/forest_stepped_gallery_layout.gd")
# Baseline door-to-door spans; Room 2 also extends west above Room 1.
const FOREST_ELEVATED=preload("res://scripts/forest_elevated_gallery_layout.gd")
const FOREST_RETURN=preload("res://scripts/forest_return_gallery_layout.gd")
const FOREST_SPLIT=preload("res://scripts/forest_split_hall_layout.gd")
const FOREST_DASH=preload("res://scripts/forest_dash_galleries_layout.gd")
const FOREST_FINAL=preload("res://scripts/forest_final_stair_layout.gd")
const FOREST_WORLD=preload("res://scripts/forest_world_layout.gd")
const ROOM_WIDTHS := [1200.0, 5000.0, 1370.0, 1380.0, 3600.0, 14400.0, 1600.0, 1400.0, 0.0, 0.0]
const TEAL := Color("78e4d4")
const CREAM := Color("f5e9bf")

static func room_center_world(room: int) -> float:
	if room==9: return room_center_world(6)-ROOM_WIDTHS[5]*0.5+FOREST_DASH.PORTAL.x-3600
	if room==10: return room_center_world(9)-1300
	if room==8: return room_center_world(6)+ROOM_WIDTHS[5]*0.5+700
	if room==7: return room_center_world(8)+700+800
	var center := 0.0
	for index in clampi(room - 1, 0, ROOM_WIDTHS.size() - 1):
		center += ROOM_WIDTHS[index]
	return center + ROOM_WIDTHS[clampi(room - 1, 0, ROOM_WIDTHS.size() - 1)] * 0.5

static func layout(size: Vector2, focus_room: int = 0) -> Dictionary:
	var total_width := 0.0
	for room_width in ROOM_WIDTHS:
		total_width += room_width
	var scale := 0.18 if focus_room > 0 else minf(minf(0.105, (size.x - 100.0) / total_width), (size.y - 220.0) / GALLERY.EXTENT.size.y)
	var origin_x := size.x * 0.6 - room_center_world(focus_room) * scale if focus_room > 0 else (size.x - total_width * scale) * 0.5
	var baseline:=size.y*0.60
	if focus_room>0 and focus_room!=2:
		baseline-=_room_height_offset(focus_room)*scale
	return {"scale": scale, "origin_x": origin_x, "y": baseline}

static func draw(canvas: Control, size: Vector2, visited: Array, completed: Array, current_room: int, hands: Array, focus_room: int = 0, fast_travel: bool = false, player_position: Vector2 = Vector2.INF, gallery_state: Dictionary = {}) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.07, 0.94 if fast_travel else 0.72))
	canvas.draw_string(font, Vector2(30 if not fast_travel else 340, 58), "FAST TRAVEL" if fast_travel else "MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, CREAM)
	var placement := layout(size, focus_room)
	var x: float = placement.origin_x
	var y: float = placement.y
	var scale: float = placement.scale
	for number in [1,2,3,4,5,6,8,7,9,10]:
		var index: int=number-1
		var width: float = ROOM_WIDTHS[index] * scale
		if visited.has(number):
			var complete := completed.has(number)
			if number == 2:
				_draw_gallery(canvas, Vector2(x, y), scale, complete, current_room == 2, player_position, gallery_state)
			elif number==5:
				_draw_forest_arrival(canvas,Vector2(x,y+_room_height_offset(number)*scale),scale,complete,current_room==5,player_position)
			elif number==6:
				_draw_forest_stair_room(canvas,Vector2(x,y+_room_height_offset(number)*scale),scale,complete,current_room==6,player_position)
			elif number==10:
				var room6_left: float=placement.origin_x+(room_center_world(6)-ROOM_WIDTHS[5]*0.5)*scale
				_draw_temple_guardian(canvas,Vector2(room6_left,y+_room_height_offset(6)*scale),scale,complete,current_room==10,player_position)
			elif number==9:
				var room6_left: float=placement.origin_x+(room_center_world(6)-ROOM_WIDTHS[5]*0.5)*scale
				_draw_temple_hand(canvas,Vector2(room6_left,y+_room_height_offset(6)*scale),scale,complete,current_room==9,player_position,hands)
			else:
				var room_y := y+_room_height_offset(number)*scale
				var rect := Rect2(x, room_y - 660 * scale, width - 3.0, 780 * scale)
				canvas.draw_rect(rect, Color(0.08, 0.30, 0.29) if complete else Color(0.32, 0.24, 0.14))
				canvas.draw_rect(rect, TEAL if complete else Color("e6bc75"), false, 2.0)
				if number == current_room:
					var marker:=rect.position+Vector2(12,12)
					if number in [7,8] and player_position!=Vector2.INF:
						marker=rect.position+(player_position-Vector2(FOREST_WORLD.BOUNDS[number-5].x,-60))*scale
					canvas.draw_circle(marker,5,CREAM)
				for hand in hands:
					if int(hand.get("room", -1)) == number:
						var at:=rect.get_center()+Vector2(0,-8)
						if number==8: at=rect.position+(hand.position-Vector2(FOREST_WORLD.BOUNDS[3].x,-60))*scale
						_draw_hand(canvas,at,2.0)

		x += width
	_draw_legend(canvas, size, fast_travel)

static func _room_height_offset(room: int) -> float:
	if room in [9,10]: return _room_height_offset(6)+FOREST_DASH.LOWER_FLOOR-600+690
	if room in [7,8]: return _room_height_offset(6)+FOREST_FINAL.EXIT_Y-600
	if room==1: return GALLERY.ENTRANCE.y-570
	var offset:=GALLERY.EXIT.y-570
	var arrival_left:=FOREST_ARRIVAL.point(Vector2(0,578)).y
	var arrival_right:=FOREST_ARRIVAL.section3_point(Vector2(1672,565)).y
	if room==5: offset+=600-arrival_left
	elif room>=6: offset+=arrival_right-arrival_left
	return offset

static func _draw_forest_arrival(canvas: Control,origin: Vector2,scale: float,complete: bool,current: bool,player_position: Vector2) -> void:
	var polygon:=PackedVector2Array()
	for p in FOREST_ARRIVAL.map_outline():
		polygon.append(origin+(p-Vector2(0,600))*scale)
	var ink:=TEAL if complete else Color("e6bc75")
	canvas.draw_colored_polygon(polygon,Color(0.08,0.30,0.29) if complete else Color(0.32,0.24,0.14))
	if not polygon.is_empty():
		polygon.append(polygon[0])
		canvas.draw_polyline(polygon,ink,2)
	for surface in FOREST_ARRIVAL.walkable_surfaces():
		canvas.draw_line(origin+(surface[0]-Vector2(0,600))*scale,origin+(surface[1]-Vector2(0,600))*scale,Color(ink,0.38),1)
	if current:
		var at:=FOREST_ARRIVAL.entry() if player_position==Vector2.INF else player_position
		canvas.draw_circle(origin+(at-Vector2(0,600))*scale,5,CREAM)

static func _draw_forest_stair_room(canvas: Control,origin: Vector2,scale: float,complete: bool,current: bool,player_position: Vector2) -> void:
	var polygon:=PackedVector2Array([origin+Vector2(0,0),origin+Vector2(1400,0)*scale])
	for native in FOREST_STAIR.stair_top():
		polygon.append(origin+(FOREST_STAIR.point(native)-Vector2(3600,600))*scale)
	polygon.append(origin+Vector2(3200,FOREST_UPPER.EXIT_Y-150-600)*scale)
	for native in FOREST_SMASH.ground_top():
		polygon.append(origin+(FOREST_SMASH.point(native)-Vector2(3600,600)-Vector2(0,150))*scale)
	polygon.append(origin+Vector2(5400,FOREST_STEPPED.cap(2).position.y-150-600)*scale)
	polygon.append(origin+Vector2(6600,FOREST_STEPPED.cap(2).position.y-150-600)*scale)
	polygon.append(origin+Vector2(7800,FOREST_ELEVATED.cap(2).position.y-150-600)*scale)
	polygon.append(origin+Vector2(9000,FOREST_RETURN.cap(0).position.y-150-600)*scale)
	polygon.append(origin+Vector2(14400,FOREST_FINAL.EXIT_Y-300-600)*scale)
	polygon.append(origin+Vector2(14400,FOREST_FINAL.EXIT_Y-600)*scale)
	var final_top:=FOREST_FINAL.top()
	final_top.reverse()
	for v in final_top:
		polygon.append(origin+(v-Vector2(3600,600))*scale)
	polygon.append(origin+Vector2(12600,FOREST_SPLIT.LOWER_Y+120-600)*scale)
	polygon.append(origin+Vector2(9000,FOREST_SPLIT.LOWER_Y+120-600)*scale)
	polygon.append(origin+Vector2(9000,120)*scale)
	polygon.append(origin+Vector2(0,120)*scale)
	var ink:=TEAL if complete else Color("e6bc75")
	canvas.draw_colored_polygon(polygon,Color(0.08,0.30,0.29) if complete else Color(0.32,0.24,0.14))
	polygon.append(polygon[0])
	canvas.draw_polyline(polygon,ink,2)
	for rect in FOREST_UPPER.ledges():
		var at:=FOREST_UPPER.point(rect.position)-Vector2(3600,600)
		canvas.draw_rect(Rect2(origin+at*scale,rect.size*FOREST_UPPER.SCALE*scale),ink)
	canvas.draw_line(origin+(FOREST_UPPER.point(Vector2(1051,468))-Vector2(3600,600))*scale,origin+(FOREST_UPPER.point(Vector2(1051,846))-Vector2(3600,600))*scale,ink,2)
	var top:=PackedVector2Array()
	for native in FOREST_SMASH.ground_top(): top.append(origin+(FOREST_SMASH.point(native)-Vector2(3600,600))*scale)
	canvas.draw_polyline(top,ink,2)
	canvas.draw_line(origin+Vector2(5400,FOREST_STEPPED.EXIT_Y-600)*scale,origin+Vector2(6600,FOREST_STEPPED.EXIT_Y-600)*scale,ink,2)
	for i in 3:
		var cap:=FOREST_STEPPED.cap(i)
		canvas.draw_rect(Rect2(origin+(cap.position-Vector2(3600,600))*scale,cap.size*scale),ink)
	canvas.draw_line(origin+Vector2(6600,FOREST_ELEVATED.EXIT_Y-600)*scale,origin+Vector2(7800,FOREST_ELEVATED.EXIT_Y-600)*scale,ink,2)
	for i in 3:
		var cap:=FOREST_ELEVATED.cap(i)
		canvas.draw_rect(Rect2(origin+(cap.position-Vector2(3600,600))*scale,cap.size*scale),ink)
	canvas.draw_line(origin+Vector2(7800,FOREST_RETURN.EXIT_Y-600)*scale,origin+Vector2(9000,FOREST_RETURN.EXIT_Y-600)*scale,ink,2)
	for i in 3:
		var cap:=FOREST_RETURN.cap(i)
		canvas.draw_rect(Rect2(origin+(cap.position-Vector2(3600,600))*scale,cap.size*scale),ink)
	canvas.draw_line(origin+(FOREST_SMASH.point(FOREST_SMASH.FUTURE_FLOOR.position)-Vector2(3600,600))*scale,origin+(FOREST_SMASH.point(Vector2(FOREST_SMASH.FUTURE_FLOOR.end.x,FOREST_SMASH.FLOOR))-Vector2(3600,600))*scale,Color("e6bc75"),3)
	for hall_polygon in FOREST_SPLIT.solid_polygons():
		var trace:=PackedVector2Array()
		for v in hall_polygon: trace.append(origin+(v-Vector2(3600,600))*scale)
		canvas.draw_colored_polygon(trace,Color(ink,0.7))
	for gallery_polygon in FOREST_DASH.solid_polygons():
		var trace:=PackedVector2Array()
		for v in gallery_polygon: trace.append(origin+(v-Vector2(3600,600))*scale)
		canvas.draw_colored_polygon(trace,Color(ink,0.7))
	canvas.draw_line(origin+(FOREST_SPLIT.DROP.position-Vector2(3600,600))*scale,origin+(FOREST_SPLIT.DROP.position+Vector2(FOREST_SPLIT.DROP.size.x,0)-Vector2(3600,600))*scale,Color("b9a5ef"),3)
	var doorway:=origin+(FOREST_DASH.PORTAL-Vector2(3600,600))*scale
	canvas.draw_arc(doorway+Vector2(0,-5),5,PI,TAU,12,CREAM,2)
	if current:
		var at:=Vector2(3690,570) if player_position==Vector2.INF else player_position
		canvas.draw_circle(origin+(at-Vector2(3600,600))*scale,5,CREAM)

static func _draw_temple_hand(canvas: Control,origin: Vector2,scale: float,complete: bool,current: bool,player_position: Vector2,hands: Array) -> void:
	var door:=origin+(FOREST_DASH.PORTAL-Vector2(3600,600))*scale
	var rect:=Rect2(origin+Vector2(FOREST_DASH.PORTAL.x-3600-700,FOREST_DASH.LOWER_FLOOR-600+300)*scale,Vector2(1400,780)*scale)
	canvas.draw_line(door,Vector2(door.x,rect.position.y),Color("e6bc75"),2)
	canvas.draw_rect(rect,Color(0.08,0.30,0.29) if complete else Color(0.32,0.24,0.14))
	canvas.draw_rect(rect,TEAL if complete else Color("e6bc75"),false,2)
	for hand in hands:
		if int(hand.get("room",-1))==9: _draw_hand(canvas,rect.position+Vector2(695,630)*scale,2.0)
	if current and player_position!=Vector2.INF:
		canvas.draw_circle(rect.position+(player_position-Vector2(24000,-60))*scale,5,CREAM)

static func _draw_temple_guardian(canvas: Control,origin: Vector2,scale: float,complete: bool,current: bool,player_position: Vector2) -> void:
	var rect:=Rect2(origin+Vector2(FOREST_DASH.PORTAL.x-3600-1900,FOREST_DASH.LOWER_FLOOR-600+300)*scale,Vector2(1200,780)*scale)
	canvas.draw_rect(rect,Color(0.08,0.30,0.29) if complete else Color(0.32,0.24,0.14))
	canvas.draw_rect(rect,TEAL if complete else Color("e6bc75"),false,2)
	canvas.draw_line(rect.position+Vector2(rect.size.x,630*scale),rect.position+Vector2(rect.size.x+60*scale,630*scale),CREAM,2)
	if current and player_position!=Vector2.INF:
		canvas.draw_circle(rect.position+(player_position-Vector2(22800,-60))*scale,5,CREAM)

static func _draw_hand(canvas: Control, center: Vector2, pixel: float) -> void:
	var dark := Color(0.20, 0.12, 0.13)
	var gold := Color("f3d78a")
	canvas.draw_rect(Rect2(center + Vector2(-7, -1) * pixel, Vector2(14, 12) * pixel), dark)
	canvas.draw_rect(Rect2(center + Vector2(-5, 1) * pixel, Vector2(10, 8) * pixel), gold)
	for finger in 4:
		canvas.draw_rect(Rect2(center + Vector2(-5 + finger * 3, -6) * pixel, Vector2(2, 8) * pixel), gold)
	canvas.draw_rect(Rect2(center + Vector2(-8, 2) * pixel, Vector2(4, 5) * pixel), gold)

static func _draw_legend(canvas: Control, size: Vector2, fast_travel: bool) -> void:
	var left := 318.0 if fast_travel else 24.0
	var width := minf(805.0, size.x - left - 24.0)
	var top := size.y - 83.0
	var font := ThemeDB.fallback_font
	canvas.draw_rect(Rect2(left, top, width, 65), Color(0.025, 0.07, 0.10, 0.87))
	canvas.draw_rect(Rect2(left, top, width, 65), TEAL, false, 2.0)
	var labels := ["EXPLORED", "100% COMPLETE", "YOU", "HAND"]
	for index in 4:
		var x := left + 14.0 + index * (width - 28.0) / 4.0
		canvas.draw_rect(Rect2(x, top + 19, 23, 23), Color(0.03, 0.12, 0.16))
		canvas.draw_rect(Rect2(x, top + 19, 23, 23), Color(0.45, 0.75, 0.73), false, 1.0)
		match index:
			0:
				canvas.draw_rect(Rect2(x + 5, top + 24, 13, 13), Color(0.32, 0.24, 0.14))
			1:
				canvas.draw_rect(Rect2(x + 5, top + 24, 13, 13), Color(0.08, 0.30, 0.29))
			2:
				canvas.draw_circle(Vector2(x + 11.5, top + 30.5), 6, CREAM)
			3:
				_draw_hand(canvas, Vector2(x + 11.5, top + 30.5), 0.75)
		canvas.draw_string(font, Vector2(x + 29, top + 36), labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CREAM)

static func _draw_gallery(canvas: Control, origin: Vector2, scale: float, complete: bool, current: bool, player_position: Vector2, gallery_state: Dictionary) -> void:
	GALLERY.map_space()
	var fill := Color(0.08, 0.30, 0.29) if complete else Color(0.32, 0.24, 0.14)
	var ink := TEAL if complete else Color("e6bc75")
	for cell: Vector2i in GALLERY.map_cells:
		var top_left := origin + (Vector2(cell) - Vector2(0, 600)) * scale
		var extent := Vector2.ONE * 64.0 * scale
		canvas.draw_rect(Rect2(top_left, extent + Vector2.ONE * 0.3), fill)
		for side in range(4):
			var offset: Vector2i = [Vector2i(0, -64), Vector2i(64, 0), Vector2i(0, 64), Vector2i(-64, 0)][side]
			if not GALLERY.map_cells.has(cell + offset):
				var corners := [top_left, top_left + Vector2(extent.x, 0), top_left + extent, top_left + Vector2(0, extent.y)]
				canvas.draw_line(corners[side], corners[(side + 1) % 4], ink, 1.3)
	for route: PackedVector2Array in GALLERY.routes().values():
		for i in route.size() - 1:
			canvas.draw_line(origin + (route[i] - Vector2(0, 600)) * scale, origin + (route[i + 1] - Vector2(0, 600)) * scale, Color(ink, 0.38), 1)
	for door: Vector2 in [Vector2(0, GALLERY.ENTRANCE.y), Vector2(5000,GALLERY.EXIT.y)]:
		var at := origin + (door - Vector2(0, 600)) * scale
		canvas.draw_line(at + Vector2(0, -5), at + Vector2(0, 5), CREAM, 3)
	if current:
		var at := GALLERY.START if player_position == Vector2.INF else player_position
		canvas.draw_circle(origin + (at - Vector2(0, 600)) * scale, 5, CREAM)
	if not gallery_state.get("heavy_open",false):
		var gate := origin+(GALLERY.HEAVY_WALL.get_center()-Vector2(0,600))*scale
		canvas.draw_line(gate-Vector2(0,GALLERY.HEAVY_WALL.size.y*scale/2),gate+Vector2(0,GALLERY.HEAVY_WALL.size.y*scale/2),Color("e6bc75"),3)
	var floor_left := origin+(GALLERY.SMASH_FLOOR.position-Vector2(0,600))*scale
	canvas.draw_line(floor_left,floor_left+Vector2(GALLERY.SMASH_FLOOR.size.x*scale,0),Color("e6bc75"),3)
