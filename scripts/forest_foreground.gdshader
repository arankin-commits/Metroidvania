shader_type canvas_item;
render_mode unshaded;
void fragment() {
	COLOR=texture(TEXTURE,UV);
	// Solid bark must hide the player completely; preserve soft cutout edges only.
	if(COLOR.a>=0.8) COLOR.a=1.0;
}
