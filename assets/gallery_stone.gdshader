shader_type canvas_item;
render_mode unshaded;
varying vec2 stone_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { stone_position = VERTEX; }
void fragment() {
	vec4 ink = COLOR;
	// Only the geology fill is shaded. Collision caps, gate cues and drop marks
	// preserve their authored values. Coordinates are shared across every polygon.
	if (distance(ink.rgb,vec3(0.14,0.20,0.24)) < 0.015) {
		vec2 p=floor(stone_position/4.0)*4.0;
		float bend=floor((sin(p.x*0.0021)*22.0+sin(p.x*0.008)*8.0)/4.0)*4.0;
		float band=floor((p.y+bend)/64.0);
		float seam=mod(p.y+bend,64.0);
		float broad=hash(vec2(floor((p.x+band*43.0)/180.0),band));
		float grain=hash(floor(p/vec2(16.0,8.0)));
		vec3 rock=mix(vec3(0.065,0.100,0.128),vec3(0.115,0.160,0.185),broad);
		if(seam<4.0) rock*=0.67;
		if(seam>=4.0 && seam<8.0) rock+=vec3(0.013,0.019,0.021);
		if(grain>0.94) rock+=vec3(0.018,0.021,0.021);
		if(grain<0.08) rock*=0.88;
		ink.rgb=rock;
	}
	COLOR=ink;
}
