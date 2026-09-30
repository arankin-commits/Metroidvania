extends RefCounted

# Upper 8.2 and lower 8.1 are one continuous branch of Forest Room 2.
const PREVIOUS=preload("res://scripts/forest_return_gallery_layout.gd")
const X:=12600.0
const WIDTH:=1200.0
const EXIT_Y:=PREVIOUS.EXIT_Y
const LOWER_Y:=EXIT_Y+700.0
const SCALE:=1200.0/1448.0
const UPPER_ORIGIN:=Vector2(X,EXIT_Y-810*SCALE)
const LOWER_ORIGIN:=Vector2(X,LOWER_Y-795*SCALE)
const UPPER_SOURCE:=[Rect2(350,280,1098,75),Rect2(350,600,760,67),Rect2(1100,665,280,65)]
const CAPS:=[Rect2(X+420,EXIT_Y-336,780,75*SCALE),Rect2(X+300,EXIT_Y-224,560,67*SCALE),Rect2(X+960,EXIT_Y-112,210,65*SCALE)]
const DROP:=Rect2(X+930,EXIT_Y,270,12)
const CAMERA_BOTTOM:=1200

static func return_cap(index: int) -> Rect2:
	var left:=950.0 if index%2==0 else 1100.0
	# Final shelf leaves the full standing body below the panel; finish with a
	# normal jump through it. A shelf only28px below intersects grab clearance.
	var rise:=640.0 if index==5 else 112.0*(index+1)
	return Rect2(X+left,LOWER_Y-rise,90 if index%2==0 else 70,26)

static func rectangle(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])

static func shelf(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position+Vector2(5,0),Vector2(rect.end.x-5,rect.position.y),rect.position+Vector2(rect.size.x,5),rect.end-Vector2(0,5),rect.end-Vector2(8,0),Vector2(rect.position.x+8,rect.end.y),Vector2(rect.position.x,rect.end.y-5),rect.position+Vector2(0,5)])

static func shell() -> Array[PackedVector2Array]:
	# Finite upper floor leaves the lower hall open. The purple section is separate.
	return [rectangle(Rect2(X,EXIT_Y,930,40)),rectangle(Rect2(X,LOWER_Y,WIDTH,440)),rectangle(Rect2(X,EXIT_Y+40,112,660)),PackedVector2Array([Vector2(X,-950),Vector2(X+365,-950),UPPER_ORIGIN+Vector2(440,20)*SCALE,UPPER_ORIGIN+Vector2(135,225)*SCALE,UPPER_ORIGIN+Vector2(135,565)*SCALE,UPPER_ORIGIN+Vector2(0,565)*SCALE])]

static func solid_polygons() -> Array[PackedVector2Array]:
	var result:=shell()
	for c in CAPS: result.append(shelf(c))
	for i in 6: result.append(shelf(return_cap(i)))
	return result
