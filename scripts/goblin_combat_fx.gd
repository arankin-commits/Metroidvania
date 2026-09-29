extends RefCounted
const CHARGE_WAKE=preload("res://assets/effects/goblin_charge_wake.png")
# Transient combat art: positions are measured from the actor/feet, never hitboxes.
var ghosts: Array[Dictionary]=[]
var wakes: Array[Dictionary]=[]
var motes: Array[Dictionary]=[]
var clock:=0.0
var ghost_timer:=0.0
var serial:=0

func clear() -> void:
	ghosts.clear(); wakes.clear(); motes.clear()

func release(boss: Node2D) -> void:
	serial+=1
	var style:=str(boss.phase.get("style",boss.state))
	if boss.state!="slam" and boss.state!="jump":
		wakes.append({"position":boss.global_position,"age":0.0,"duration":.30 if style!="spin" else .38,"style":style,"direction":boss.facing,"serial":serial,"reverse":int(boss.phase.get("sprite_pose",0))==7,"heavy":boss.state=="charge"})
	var count:=30 if boss.state=="slam" else 14
	for i in count:
		var spread:=float(i)/float(count-1)
		var side:=-1.0 if i%2==0 else 1.0
		var impact: bool=boss.state=="slam"
		var launch:=fposmod(sin((i+1)*12.9898)*43758.5453,1.0)
		var velocity:=Vector2(side*lerpf(100,360,spread),-lerpf(120,360,launch)) if impact else Vector2(-boss.facing*lerpf(35,120,spread),-lerpf(12,45,launch))
		motes.append({"position":boss.global_position+Vector2(side*(8+spread*(56 if impact else 36)),46),"velocity":velocity,"age":0.0,"duration":.35+spread*.23,"size":2.0+spread*4,"stone":impact and i%3==0,"hot":impact and i%4==0})
	while wakes.size()>6: wakes.pop_front()
	while motes.size()>60: motes.pop_front()

func tick(boss: Node2D,delta: float) -> void:
	clock+=delta
	for collection in [ghosts,wakes,motes]:
		for item in collection: item.age+=delta
		for i in range(collection.size()-1,-1,-1):
			if collection[i].age>=collection[i].duration: collection.remove_at(i)
	for wake in wakes:
		if wake.serial==serial and boss.phase.has("hit"): wake.position=boss.global_position
	for mote in motes:
		mote.position+=mote.velocity*delta
		mote.velocity.y+=310*delta
		# Ground debris stays above its landing plane; nothing acquires collision.
		if mote.position.y>boss.home_y+47: mote.position.y=boss.home_y+47; mote.velocity.y=0
	ghost_timer-=delta
	if (boss.phase.has("hit") or boss.state=="jump") and boss.state!="slam" and ghost_timer<=0:
		ghost_timer=.035
		ghosts.append({"position":boss.global_position,"pose":boss.visual_pose(),"direction":boss.facing,"age":0.0,"duration":.17})
		while ghosts.size()>4: ghosts.pop_front()

func draw_behind(boss: Node2D) -> void:
	for ghost in ghosts:
		var index: int=ghost.pose
		var rect: Rect2=boss.FRAME_RECT
		rect.position+=ghost.position-boss.global_position
		var source:=Rect2((index%4)*boss.FRAME_SIZE,(index/4)*boss.FRAME_SIZE,boss.FRAME_SIZE,boss.FRAME_SIZE)
		boss.draw_texture_rect_region(boss.LEFT_ATLAS if ghost.direction<0 else boss.ATLAS,rect,source,Color(.64,.55,.52,.20*(1-ghost.age/ghost.duration)))
	for wake in wakes: draw_wake(boss,wake)
	for mote in motes:
		var p: Vector2=mote.position-boss.global_position
		var fade: float=1.0-mote.age/mote.duration
		var size: float=mote.size*(1.0 if mote.stone else 1.0+mote.age*3)
		var color:=Color(.66,.63,.58,.48*fade)
		if mote.hot: color=Color(.94,.34,.22,.65*fade)
		if mote.stone:
			boss.draw_colored_polygon(PackedVector2Array([p+Vector2(-size,0),p+Vector2(-1,-size),p+Vector2(size,-1),p+Vector2(1,size*.6)]),Color(.46,.49,.51,.9*fade))
		else:
			if mote.hot:
				var streak: Vector2=mote.velocity.normalized()*size*2.5
				boss.draw_colored_polygon(PackedVector2Array([p+streak,p+Vector2(-2,2),p-streak*.5,p+Vector2(2,2)]),Color(1,.43,.30,.72*fade))
			p=p.round()
			boss.draw_colored_polygon(PackedVector2Array([p+Vector2(-size,0),p+Vector2(-size*.7,-size*.65),p+Vector2(0,-size),p+Vector2(size*.8,-size*.4),p+Vector2(size,size*.4),p+Vector2(0,size*.6)]),color)
			boss.draw_rect(Rect2(p+Vector2(-size*.4,-size*.5),Vector2(size,size*.7)),Color(.79,.74,.66,.22*fade))

func draw_wake(boss: Node2D,wake: Dictionary) -> void:
	var alpha:=1.0 if wake.age<.12 else pow(1.0-(wake.age-.12)/(wake.duration-.12),1.4)
	var origin: Vector2=wake.position-boss.global_position
	var growth:=clampf(wake.age/.10,.12,1)
	if wake.heavy:
		boss.draw_set_transform(origin,0,Vector2(wake.direction,1))
		boss.draw_texture_rect(CHARGE_WAKE,Rect2(-93,-105,242,152),false,Color(1,1,1,alpha))
		boss.draw_set_transform(Vector2.ZERO)
		return
	if wake.style=="thrust":
		for layer in 3:
			var y: float=-17+(layer-1)*7
			var points:=PackedVector2Array([Vector2(-45,y+3),Vector2(75,y-2),Vector2(145,y),Vector2(40,y+5)])
			for i in points.size(): points[i]=origin+Vector2(points[i].x*wake.direction,points[i].y)
			boss.draw_colored_polygon(points,Color(.8,.78,.73,.25*alpha))
		return
	for layer in 3:
		var outer:=PackedVector2Array()
		var inner:=PackedVector2Array()
		var center:=Vector2(25,-22)
		var radii:=Vector2(100-layer*7,65-layer*5)
		var start:=-2.45
		var finish:=1.15
		if wake.reverse: start=1.35; finish=-1.4
		if wake.style=="overhead": center=Vector2(7,-30); radii=Vector2(112-layer*7,105-layer*5); start=-2.0; finish=.72
		if wake.style=="spin": center=Vector2(0,-9); radii=Vector2(135-layer*8,34-layer*3); start=-PI; finish=PI-.03
		if wake.heavy: radii+=Vector2(8,8)
		for i in 33:
			var t:=float(i)/32
			var angle:=lerpf(start,lerpf(start,finish,growth),t)
			var radial:=Vector2(cos(angle)*radii.x,sin(angle)*radii.y)
			var roughness:=1.0+.014*sin(i*2.3+layer*1.7)
			var p:=center+radial*roughness
			var width:=(30.0 if layer==0 else 12.0)*sin(t*PI)*(.35+.65*t)
			outer.append(origin+Vector2(p.x*wake.direction,p.y))
			if i>0 and i<32:
				var inside:=center+radial*roughness-radial.normalized()*width
				inner.insert(0,origin+Vector2(inside.x*wake.direction,inside.y))
		var color:=Color(1,.87,.75,.95*alpha) if layer==0 else Color(.92,.20,.13,.42*alpha/float(layer))
		boss.draw_colored_polygon(outer+inner,color)
		# Interrupted highlights and frayed flecks replace a uniform geometric line.
		if layer==0:
			for i in range(3,31,3):
				boss.draw_line(outer[i],outer[i+1],Color(1,.91,.78,.75*alpha),1)
				boss.draw_rect(Rect2(outer[i]+Vector2(-3,2),Vector2(2,1)),Color(.94,.46,.29,.45*alpha))



