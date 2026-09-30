shader_type canvas_item;
uniform float rune_glow = 0.0;
uniform float hurt_flash = 0.0;
uniform float protected = 0.0;

void fragment() {
	vec3 ink = COLOR.rgb;
	float cyan = step(ink.r * 1.6 + 0.05, ink.g) * step(ink.r * 1.6 + 0.05, ink.b);
	ink = mix(ink, min(vec3(1.0), ink * 1.35 + vec3(0.04,0.12,0.12)), cyan * rune_glow);
	ink = mix(ink, ink + vec3(0.02,0.11,0.13), protected * 0.5);
	COLOR.rgb = mix(ink, vec3(1.0), hurt_flash * 0.8);
}
