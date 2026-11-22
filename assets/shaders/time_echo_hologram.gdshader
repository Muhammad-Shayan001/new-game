shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

// Time Echo Hologram Spatial Shader (Godot 4.3)
// Translucent wireframe/fresnel recording with horizontal scan-bands and digital jitter

uniform vec4 hologram_color : source_color = vec4(0.0, 0.94, 1.0, 0.7); // Cyan Phosphor
uniform float scan_speed : hint_range(0.1, 10.0) = 2.0;
uniform float scan_density : hint_range(5.0, 80.0) = 30.0;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.5;
uniform float flicker_amount : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	// Fresnel Rim Calculation
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	// Moving scanline bands
	float scan = sin((VERTEX.y + TIME * scan_speed) * scan_density) * 0.5 + 0.5;
	scan = smoothstep(0.3, 0.7, scan);

	// Noise flicker
	float flicker = 1.0 - (fract(sin(dot(vec2(TIME, VERTEX.y), vec2(12.9898, 78.233))) * 43758.5453) * flicker_amount);

	float alpha = (fresnel * 0.8 + scan * 0.4) * hologram_color.a * flicker;

	ALBEDO = hologram_color.rgb * (1.2 + fresnel * 0.8);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
