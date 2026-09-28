extends Node2D

# World-space architecture. These work units share one material language and never
# clip to zone rectangles. Actor-facing scenery stays behind all collision terrain.
const L = preload("res://scripts/split_gallery_layout.gd")
const STONE = Color("253b45")
const EDGE = Color("3d5257")
const SHADOW = Color("101e2a")
const METAL = Color("5b6050")
var world: Node2D
var glow: GradientTexture2D

func _ready() -> void:
	z_index=-4
	glow=GradientTexture2D.new()
	glow.width=128
	glow.height=128
	glow.fill=GradientTexture2D.FILL_RADIAL
	glow.fill_from=Vector2(0.5,0.5)
	glow.fill_to=Vector2(1,0.5)
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color(1,1,1,0.20),Color(1,1,1,0)])
	glow.gradient=gradient

func _draw() -> void:
	_zone_01()
	_zone_02()
	_zone_03()
	_zone_04()
	_zone_05()
	_zone_06()
	_zone_07()
	_zone_08()
	_zone_09()
	_zone_10()
	_zone_11()
	_zone_12()
	_zone_13()
	_zone_14()

func _light(at: Vector2, radius: Vector2, tint: Color) -> void:
	draw_texture_rect(glow,Rect2(at-radius,radius*2),false,tint)

func _rib(points: PackedVector2Array, width: float=20) -> void:
	draw_polyline(points,SHADOW,width+10)
	draw_polyline(points,STONE,width)
	for i in range(1,points.size()):
		var a:=points[i-1]
		var b:=points[i]
		var n:=(b-a).normalized().orthogonal()*width*0.5
		for j in range(1,maxi(2,int(a.distance_to(b)/40))):
			var at:=a.lerp(b,float(j)/maxi(2,int(a.distance_to(b)/40)))
			draw_line(at-n,at+n,SHADOW,3)

func _chain(x: float, top: float, bottom: float, heavy: bool=false) -> void:
	var width:=10.0 if heavy else 5.0
	for y in range(int(top),int(bottom),20):
		draw_rect(Rect2(x-width/2,y,width,14),METAL if heavy else STONE,false,2)
	for y in [top,bottom]:
		draw_rect(Rect2(x-14,y-4,28,10),STONE)
		draw_rect(Rect2(x-4,y-2,8,6),METAL)

func _root(points: PackedVector2Array, width: float=7) -> void:
	draw_polyline(points,Color("263b38"),width)
	draw_polyline(points,Color("3b4b42"),2)

func _zone_01() -> void:
	# The entrance lintel and fossil root frame a quiet, safe receiving floor.
	_rib(PackedVector2Array([Vector2(-32,1500),Vector2(-32,1310),Vector2(20,1268),Vector2(170,1268),Vector2(250,1300)]),28)
	_root(PackedVector2Array([Vector2(280,1240),Vector2(235,1310),Vector2(180,1330),Vector2(146,1400)]),9)
	_light(Vector2(130,1390),Vector2(210,140),Color("769089"))
	# Persistent worn return-channel marker, deliberately unlike a collectible.
	draw_polyline(PackedVector2Array([Vector2(255,1440),Vector2(280,1452),Vector2(307,1440)]),METAL,3)

func _zone_02() -> void:
	# A broken gallery beam makes the jump's interruption meaningful. Recessed
	# masonry stays well below the support edge and out of the sentinel silhouette.
	_rib(PackedVector2Array([Vector2(420,1600),Vector2(460,1530),Vector2(625,1518)]),24)
	_rib(PackedVector2Array([Vector2(870,1530),Vector2(960,1540),Vector2(1030,1630)]),20)
	_chain(610,1190,1475)
	_chain(905,1270,1460)
	_light(Vector2(750,1480),Vector2(220,180),Color("607d85"))

func _zone_03() -> void:
	# Compression at the foundation throat opens onto the tall central well.
	_rib(PackedVector2Array([Vector2(1290,1200),Vector2(1310,1080),Vector2(1480,1015),Vector2(1620,1030)]),32)
	_rib(PackedVector2Array([Vector2(1790,1010),Vector2(1860,1060),Vector2(1890,1140)]),25)
	_root(PackedVector2Array([Vector2(1260,1050),Vector2(1360,1100),Vector2(1410,1180)]),6)
	_light(Vector2(1900,960),Vector2(260,240),Color("5d8b8b"))

func _zone_04() -> void:
	# One carved slab, not another arch. It remains after the Sigil is read.
	var slab:=PackedVector2Array([Vector2(-385,-750),Vector2(-385,-875),Vector2(-352,-920),Vector2(-267,-932),Vector2(-217,-883),Vector2(-225,-750)])
	draw_colored_polygon(slab,SHADOW)
	draw_polyline(slab,STONE,12)
	_root(PackedVector2Array([Vector2(-300,-805),Vector2(-312,-838),Vector2(-285,-868),Vector2(-300,-900)]),5)
	_root(PackedVector2Array([Vector2(-312,-838),Vector2(-345,-855),Vector2(-356,-882)]),4)
	_root(PackedVector2Array([Vector2(-285,-868),Vector2(-253,-878)]),4)
	_light(Vector2(-300,-815),Vector2(155,180),Color("a69a70"))
	# Approach markers are chipped, matte masonry; none resembles a reward.
	for at in [Vector2(120,-675),Vector2(485,-650)]:
		_rib(PackedVector2Array([at,at+Vector2(-6,-66),at+Vector2(12,-87)]),18)

func _zone_05() -> void:
	# Memorial masonry erodes into the foundation, without repeating the Sigil.
	_rib(PackedVector2Array([Vector2(-430,-525),Vector2(-420,-440),Vector2(-250,-380),Vector2(-120,-360)]),22)
	_root(PackedVector2Array([Vector2(610,-490),Vector2(550,-420),Vector2(580,-355),Vector2(690,-300)]),10)
	_rib(PackedVector2Array([Vector2(1100,-90),Vector2(1160,-185),Vector2(1280,-195)]),20)
	_light(Vector2(1490,20),Vector2(220,170),Color("506f78"))

func _zone_06() -> void:
	# Paired anchored suspension defines the room from several elevations.
	_chain(1670,-1080,995,true)
	_chain(2470,-820,790,true)
	_rib(PackedVector2Array([Vector2(1550,-1030),Vector2(1760,-1130),Vector2(2170,-1110),Vector2(2470,-850)]),32)
	for p in [Vector2(1740,-450),Vector2(2440,-225),Vector2(1740,450),Vector2(2440,675)]:
		_rib(PackedVector2Array([p+Vector2(0,34),p+Vector2(30,76),p+Vector2(92,92)]),18)
	_light(Vector2(1990,-700),Vector2(280,360),Color("55797e"))
	_light(Vector2(2100,520),Vector2(250,350),Color("4a6878"))
	# Missing teeth in the old winding wheel tell the same failure as the slabs.
	draw_arc(Vector2(2240,-980),72,0.6,5.1,24,STONE,16)
	for angle in [0.8,1.9,3.1,4.5]:
		var d:=Vector2.from_angle(angle)
		draw_line(Vector2(2240,-980)+d*18,Vector2(2240,-980)+d*64,STONE,7)

func _zone_07() -> void:
	# Roots cradle the offering; its low bowl contrasts with the tall memorial.
	_root(PackedVector2Array([Vector2(330,-1770),Vector2(400,-1700),Vector2(430,-1630),Vector2(560,-1580),Vector2(655,-1585),Vector2(740,-1670)]),13)
	_root(PackedVector2Array([Vector2(740,-1800),Vector2(720,-1730),Vector2(660,-1670),Vector2(620,-1625)]),8)
	draw_colored_polygon(PackedVector2Array([Vector2(562,-1590),Vector2(640,-1590),Vector2(626,-1575),Vector2(575,-1575)]),EDGE)
	_light(Vector2(600,-1650),Vector2(200,190),Color("7c9b78"))
	# One fractured support on the lower approach, off the scout's patrol lane.
	_rib(PackedVector2Array([Vector2(1120,-1230),Vector2(1110,-1390),Vector2(1010,-1470)]),26)

func _zone_08() -> void:
	# Surviving high masonry follows the cave shoulder, not the patrol silhouette.
	_rib(PackedVector2Array([Vector2(1710,-1640),Vector2(1830,-1760),Vector2(2160,-1710),Vector2(2430,-1510)]),30)
	_rib(PackedVector2Array([Vector2(3150,-1530),Vector2(3360,-1720),Vector2(3650,-1700),Vector2(3780,-1570)]),25)
	_light(Vector2(2310,-1590),Vector2(280,230),Color("637f8b"))
	_root(PackedVector2Array([Vector2(2750,-1690),Vector2(2780,-1590),Vector2(2870,-1550)]),8)

func _zone_09() -> void:
	# The overlook has a broken cantilever silhouette, with open space over its guard.
	_rib(PackedVector2Array([Vector2(4450,-970),Vector2(4390,-1130),Vector2(4240,-1180),Vector2(4160,-1150)]),26)
	_chain(4420,-1200,-995)
	_light(Vector2(4240,-1030),Vector2(290,190),Color("577c91"))
	_rib(PackedVector2Array([Vector2(3510,-570),Vector2(3570,-730),Vector2(3650,-790)]),18)

func _zone_10() -> void:
	# Long recesses establish shaft continuity, with light on the receiving mass.
	_rib(PackedVector2Array([Vector2(3620,-100),Vector2(3600,210),Vector2(3620,570),Vector2(3590,820)]),18)
	_rib(PackedVector2Array([Vector2(3850,30),Vector2(3870,400),Vector2(3860,700)]),24)
	_light(Vector2(3750,780),Vector2(180,240),Color("527887"))
	# Displaced fragments echo the suspension wheel far above without copying it.
	draw_arc(Vector2(3020,1000),110,3.3,4.8,12,STONE,22)
	_rib(PackedVector2Array([Vector2(2580,975),Vector2(2640,880),Vector2(2740,860)]),22)

func _zone_11() -> void:
	# A recessed drainage seam carries the eye up the eastern return, behind steps.
	_root(PackedVector2Array([Vector2(4560,830),Vector2(4510,700),Vector2(4550,550),Vector2(4490,320),Vector2(4340,210)]),10)
	_rib(PackedVector2Array([Vector2(4270,660),Vector2(4240,530),Vector2(4150,485)]),22)
	_light(Vector2(4470,460),Vector2(175,220),Color("60786c"))
	_chain(4330,225,397)

func _zone_12() -> void:
	# The transition corridor continues beyond the backdrop's painted bounds.
	draw_rect(Rect2(5000,-1770,384,270),SHADOW)
	# A high lintel and surviving stone jamb distinguish an exit from scenery.
	_rib(PackedVector2Array([Vector2(4880,-1500),Vector2(4880,-1680),Vector2(4930,-1750),Vector2(5020,-1750)]),28)
	_light(Vector2(4920,-1610),Vector2(180,190),Color("a99c72"))
	# Broken suspension bracket points down toward the heavy-return mouth.
	_rib(PackedVector2Array([Vector2(4270,-1490),Vector2(4300,-1430),Vector2(4380,-1410)]),20)

func _zone_13() -> void:
	# One continuous service mechanism, tied to the room's original winding wheel.
	_chain(4938,-1450,1600)
	for y in [-1020,-350,420,1190]:
		_rib(PackedVector2Array([Vector2(4710,y),Vector2(4740,y-36),Vector2(4948,y-36)]),14)
	_light(Vector2(4810,1510),Vector2(150,220),Color("6d7c72"))
	# Recessed conduit joins the shaft and entrance without repeated landmarks.
	_root(PackedVector2Array([Vector2(4920,1590),Vector2(4500,1550),Vector2(3550,1540),Vector2(2540,1560),Vector2(1700,1540),Vector2(850,1560)]),6)

func _zone_14() -> void:
	# Heavy compressed roof blocks and inward fractures imply DOWNWARD force.
	# No side-door framing: the floor above is this pocket's only future connection.
	_rib(PackedVector2Array([Vector2(3420,1005),Vector2(3500,1050),Vector2(3540,1110)]),24)
	_rib(PackedVector2Array([Vector2(3900,1005),Vector2(3830,1050),Vector2(3790,1110)]),24)
	_root(PackedVector2Array([Vector2(3300,1090),Vector2(3370,1140),Vector2(3360,1290),Vector2(3450,1380)]),8)
	_light(Vector2(3660,1130),Vector2(220,180),Color("495e62"))
