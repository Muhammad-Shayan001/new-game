shader_type canvas_item;

// Memory Vision Post-Processing Shader (Godot 4.3)
// Converts world to atmospheric monochromatic cold slate, pulsing memory anomalies in electric vermilion

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vision_active : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cold_tint : source_color = vec3(0.12, 0.16, 0.24);
uniform vec3 pulse_color : source_color = vec3(1.0, 0.16, 0.33); // Electric Vermilion

void fragment() {
	vec4 base = texture(screen_texture, SCREEN_UV);

	if (vision_active <= 0.001) {
		COLOR = base;
	} else {
		// Calculate luminance
		float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
		vec3 mono = vec3(lum) * 0.85 + cold_tint * 0.35;

		// Contrast curve
		mono = pow(mono, vec3(1.25));

		// Vignette
		vec2 center_offset = SCREEN_UV - vec2(0.5);
		float dist = length(center_offset);
		float vignette = smoothstep(0.75, 0.25, dist);
		mono *= vignette;

		// Subtle pulse fringe at screen edge
		float pulse = sin(TIME * 3.0) * 0.5 + 0.5;
		vec3 edge_pulse = pulse_color * (1.0 - vignette) * 0.4 * pulse;

		vec3 final_color = mix(base.rgb, mono + edge_pulse, vision_active);
		COLOR = vec4(final_color, base.a);
	}
}
