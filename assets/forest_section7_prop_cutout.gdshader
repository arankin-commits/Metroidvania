shader_type canvas_item;

void fragment() {
	vec4 pixel=texture(TEXTURE,UV);
	// The registered RGB extraction contains a neutral matte and desaturated
	// shadow residue. Its intended foliage/crystals are consistently cool colored.
	bool colored_growth=pixel.g>pixel.r*1.6 && pixel.b>pixel.r*1.6;
	if (!colored_growth) pixel.a=0.0;
	COLOR=pixel;
}
