shader_type canvas_item;

uniform sampler2D foundation : filter_nearest, repeat_disable;
uniform vec2 foundation_origin=vec2(5000.0,-950.0);
uniform vec2 foundation_size=vec2(11200.0,2250.0);
uniform bool preserve_growth=true;
uniform float growth_green_ratio=0.65;
uniform bool future_seal=false;
varying vec2 terrain_position;

float stone_hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

vec4 masonry(vec2 p, vec4 field) {
	// World-sized stone detail is independent of the panorama's pixel count.
	// This continuous native material adds no repeated image plates or landmarks.
	float row=floor(p.y/22.0);
	float stagger=mod(row,2.0)*19.0;
	vec2 cell=vec2(floor((p.x+stagger)/42.0),row);
	vec2 inside=vec2(mod(p.x+stagger,42.0),mod(p.y,22.0));
	float seed=stone_hash(cell);
	vec3 color=mix(vec3(0.105,0.125,0.135),field.rgb*0.52,0.22)*(0.78+seed*0.44);
	if (inside.x<1.4 || inside.y<1.3) color*=0.38;
	else if (inside.x<2.8 || inside.y<2.7) color+=vec3(0.023,0.026,0.027);
	float grain=stone_hash(floor(p/2.0));
	color+=(grain-0.5)*0.016;
	float fissure=abs(inside.x-(8.0+seed*23.0+inside.y*0.21));
	if (seed>0.82 && fissure<0.9 && inside.y>5.0) color*=0.66;
	return vec4(color,1.0);
}

void vertex() {
	terrain_position=VERTEX;
}

void fragment() {
	vec4 source=texture(TEXTURE,UV);
	vec4 stone=masonry(terrain_position,texture(foundation,(terrain_position-foundation_origin)/foundation_size));
	// Preserve registered moss/vines and the distinct sealed floor; all masonry
	// shares one world-space fill, with no crossfade or section-local texture reset.
	bool attached_growth=preserve_growth && UV.y>=0.0 && UV.y<=1.0 && source.g>source.r*1.25 && source.b>source.r*1.2 && source.g>source.b*growth_green_ratio;
	bool amber_patch=future_seal && terrain_position.y<222.202;
	COLOR=attached_growth || amber_patch ? source : stone;
}
