shader_type canvas_item;

// Generated extraction supplied an RGB neutral matte; remove only that matte.
// Cool foliage/crystal pixels retain their source colors. This is scenery, not occlusion.
void fragment() {
	vec4 pixel=texture(TEXTURE,UV);
	// Include pale matte-contaminated silhouette edges, not only neutral interiors.
	if (pixel.r>0.34 && pixel.g>0.45 && pixel.b>0.48) pixel.a=0.0;
	COLOR=pixel;
}
