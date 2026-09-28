extends Node2D
# Each room supplies a unique painting and measured floor registration.
const RECT=preload("res://scripts/forest_dash_galleries_layout.gd")
var art: Texture2D
var bounds:=Vector2.ZERO
var source_floor:=600.0
var close_left:=false
var close_right:=false
var chair: Sprite2D

func _ready() -> void:
	var size:=Vector2(art.get_width(),art.get_height())
	var origin:=Vector2(bounds.x,-60)
	var scale:=Vector2((bounds.y-bounds.x)/size.x,660/source_floor)
	var scenery:=Sprite2D.new()
	scenery.texture=art
	scenery.centered=false
	scenery.position=origin
	scenery.scale=scale
	scenery.z_index=-95
	scenery.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(scenery)
	var shells: Array[Rect2]=[Rect2(bounds.x,600,bounds.y-bounds.x,180),Rect2(bounds.x,-60,bounds.y-bounds.x,50)]
	if close_left: shells.append(Rect2(bounds.x,-60,32,660))
	if close_right: shells.append(Rect2(bounds.y-32,-60,32,660))
	for r in shells:
		var p:=RECT.rectangle(r)
		var body:=StaticBody2D.new()
		var collision:=CollisionPolygon2D.new()
		collision.polygon=p
		body.add_child(collision)
		add_child(body)
		var terrain:=Polygon2D.new()
		terrain.polygon=p
		terrain.texture=art
		terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index=-85
		var uv:=PackedVector2Array()
		for v in p: uv.append((v-origin)/scale)
		terrain.uv=uv
		add_child(terrain)
