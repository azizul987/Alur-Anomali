shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float effect_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	if (effect_strength <= 0.001) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		// 1. Distorsi lengkungan gelombang kejut dari pusat layar
		vec2 center = vec2(0.5, 0.5);
		vec2 dir = SCREEN_UV - center;
		float dist = length(dir);
		vec2 distorted_uv = SCREEN_UV - dir * sin(dist * 20.0) * (effect_strength * 0.05);
		
		// 2. Efek Chromatic Aberration (Pemisahan warna Merah & Biru)
		float offset = effect_strength * 0.015;
		float r = texture(screen_texture, distorted_uv + vec2(offset, 0.0)).r;
		float g = texture(screen_texture, distorted_uv).g;
		float b = texture(screen_texture, distorted_uv - vec2(offset, 0.0)).b;
		
		COLOR = vec4(r, g, b, 1.0);
	}
}
