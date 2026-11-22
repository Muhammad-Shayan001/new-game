shader_type canvas_item;

// Post-Processing Reality Tear & Glitch Shader (Godot 4.3)
// Triggered dynamically during Reality Shift, Memory Vision, and Anomaly proximity

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.008;
uniform float scanline_density : hint_range(100.0, 1200.0) = 480.0;
uniform float block_threshold : hint_range(0.0, 1.0) = 0.7;

// Pseudo-random hash
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	if (glitch_intensity > 0.001) {
		// Digital block displacement
		vec2 block_grid = floor(uv * vec2(24.0, 48.0));
		float noise_val = hash(block_grid + vec2(floor(TIME * 12.0)));
		
		if (noise_val > block_threshold) {
			float offset = (hash(block_grid * 1.5) - 0.5) * 0.06 * glitch_intensity;
			uv.x += offset;
		}

		// Horizontal jitter line
		float line_noise = step(0.96, hash(vec2(floor(uv.y * 80.0), floor(TIME * 24.0))));
		uv.x += line_noise * 0.02 * glitch_intensity * (hash(vec2(TIME)) - 0.5);
	}

	// Chromatic Aberration (RGB split)
	float split = chromatic_aberration * (0.3 + glitch_intensity * 2.0);
	float r = texture(screen_texture, uv + vec2(split, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(split, 0.0)).b;

	vec3 scene_color = vec3(r, g, b);

	// Analog Scanlines
	float scanline = sin(uv.y * scanline_density) * 0.04 * (0.2 + glitch_intensity * 0.8);
	scene_color -= scanline;

	COLOR = vec4(scene_color, 1.0);
}
