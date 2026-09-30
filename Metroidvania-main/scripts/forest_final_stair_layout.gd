extends RefCounted

const PREVIOUS=preload("res://scripts/forest_dash_galleries_layout.gd")
const X:=16200.0
const END:=18000.0
const FLOOR:=PREVIOUS.FLOOR
const EXIT_Y:=FLOOR-480.0
const CROWN_WALL:=Rect2(16170,-530,30,PREVIOUS.HIGH+530)

static func top() -> PackedVector2Array:
	var p:=PackedVector2Array([Vector2(X,FLOOR),Vector2(X+120,FLOOR)])
	for i in 12:
		var start:=X+120+i*130
		var y:=FLOOR-i*40
		p.append(Vector2(start+80,y))
		p.append(Vector2(start+130,y-40))
	p.append(Vector2(END,EXIT_Y))
	return p

static func surface_y(x: float) -> float:
	var p:=top()
	for i in p.size()-1:
		if x<=p[i+1].x:
			return lerpf(p[i].y,p[i+1].y,clampf((x-p[i].x)/maxf(1,p[i+1].x-p[i].x),0,1))
	return EXIT_Y

static func polygons() -> Array[PackedVector2Array]:
	var stair:=top()
	stair.append(Vector2(END,1302))
	stair.append(Vector2(X,1302))
	return [stair,PREVIOUS.rectangle(Rect2(X,-950,END-X,420)),PREVIOUS.rectangle(CROWN_WALL)]
