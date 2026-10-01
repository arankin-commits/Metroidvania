extends RefCounted

# Sections 9/10 occupy two continuous levels of Forest Room 2.
const PREVIOUS=preload("res://scripts/forest_split_hall_layout.gd")
const X:=13800.0
const WIDTH:=2400.0
const END:=X+WIDTH
const FLOOR:=PREVIOUS.EXIT_Y
const LOWER_FLOOR:=PREVIOUS.LOWER_Y
const HIGH:=FLOOR-336.0
const CAPS:=[Rect2(X,HIGH,1040,62),Rect2(X+1360,HIGH,1040,62)]
const LOWER_ORIGIN:=Vector2(12600,LOWER_FLOOR-573.0*900.0/768.0)
const LOWER_SIZE:=Vector2(3600,900)
const WALL_FLOOR_X:=12600.0+1955.0*3600.0/2048.0
# Measured from the final three-hall painting, not its requested coordinates.
const PORTAL:=Vector2(15440,LOWER_FLOOR-23)
const HAND_BOUNDS:=Vector2(24000,25400)
const HAND:=Vector2(24695,570)
const HAND_RETURN:=Vector2(25220,570)
const HAND_MINIBOSS:=Vector2(24165,570)

static func rectangle(r: Rect2) -> PackedVector2Array:
	return PREVIOUS.rectangle(r)

static func shell() -> Array[PackedVector2Array]:
	var wall:=PackedVector2Array([Vector2(lower_point(Vector2(1935,0)).x,FLOOR+40),lower_point(Vector2(1935,105)),lower_point(Vector2(1955,105)),lower_point(Vector2(1955,485)),lower_point(Vector2(1935,485)),lower_point(Vector2(1935,520)),lower_point(Vector2(1955,520)),lower_point(Vector2(1955,573)),lower_point(Vector2(2048,573)),Vector2(END,FLOOR+40)])
	return [rectangle(Rect2(X,FLOOR,WIDTH,40)),rectangle(Rect2(X,LOWER_FLOOR,WIDTH,440)),rectangle(Rect2(X,-950,WIDTH,420)),wall]

static func lower_point(p: Vector2) -> Vector2:
	return LOWER_ORIGIN+p/Vector2(2048,768)*LOWER_SIZE

static func solid_polygons() -> Array[PackedVector2Array]:
	var result:=shell()
	for c in CAPS: result.append(PREVIOUS.shelf(c))
	return result
