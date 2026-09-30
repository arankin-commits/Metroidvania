shader_type canvas_item;
render_mode unshaded;
uniform sampler2D sky_one : filter_nearest;
uniform sampler2D sky_two : filter_nearest;
uniform sampler2D sky_three : filter_nearest;
void fragment() {
	// Whole coherent paintings; supports use their own authoritative source registration.
	vec2 p=UV*vec2(5016.0,1873.0)-vec2(0.0,600.0);
	vec4 first=texture(sky_one,vec2(p.x/1672.0,(p.y-70.0+347.0)/1508.6));
	vec4 second=texture(sky_two,vec2((p.x-1672.0)/1672.0,(p.y-70.0+416.0)/1548.7));
	if(p.x>=3344.0) {
		COLOR=texture(sky_three,vec2((p.x-3344.0)/1672.0,(p.y+485.0)/1522.0));
	} else {
		COLOR=mix(first,second,smoothstep(1630.0,1714.0,p.x));
	}
}
