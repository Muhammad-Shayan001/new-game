shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// PBR Wet Road & Rain Ripple Shader (Godot 4.3 Mobile / Clustered)
// Optimized for mobile: uses procedural normal synthesis without branching

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D orm_texture : hint_default_white, filter_linear_mipmap; // R: AO, G: Roughness, B: Metallic
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;

uniform float rain_intensity : hint_range(0.0, 1.0) = 0.8;
uniform float puddle_threshold : hint_range(0.0, 1.0) = 0.45;
uniform vec2 uv_scale = vec2(4.0, 4.0);
uniform float ripple_speed = 3.5;
uniform float wetness_darkening : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 base_uv = UV * uv_scale;
	vec4 base_color = texture(albedo_texture, base_uv);
	vec4 orm = texture(orm_texture, base_uv);
	vec3 base_normal = texture(normal_texture, base_uv).rgb * 2.0 - 1.0;

	// Procedural rain ripples
	float t = TIME * ripple_speed;
	vec2 ripple_uv = base_uv * 8.0;
	float ripple_wave1 = sin(length(fract(ripple_uv) - 0.5) * 20.0 - t);
	float ripple_wave2 = cos(length(fract(ripple_uv + 0.35) - 0.5) * 16.0 - t * 1.2);
	vec2 ripple_normal = vec2(ripple_wave1 + ripple_wave2) * 0.08 * rain_intensity;

	// Puddle mask based on surface height and roughness
	float puddle_mask = clamp((1.0 - orm.g) * rain_intensity * 1.5, 0.0, 1.0);

	// Wet surfaces are darker and more specular/reflective
	vec3 wet_albedo = base_color.rgb * mix(1.0, 1.0 - wetness_darkening, puddle_mask);
	float wet_roughness = mix(orm.g, 0.05, puddle_mask);

	ALBEDO = wet_albedo;
	ROUGHNESS = wet_roughness;
	METALLIC = orm.b;
	AO = orm.r;
	NORMAL = normalize(mix(base_normal, vec3(ripple_normal, 1.0), puddle_mask * 0.6));
}
