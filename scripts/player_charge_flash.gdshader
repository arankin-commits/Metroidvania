shader_type canvas_item;

uniform float white_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Only atlas artwork flashes; untextured aura and combat cues keep their colors.
	if (TEXTURE_PIXEL_SIZE.x < 1.0 && TEXTURE_PIXEL_SIZE.y < 1.0) {
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0), white_flash);
	}
}
