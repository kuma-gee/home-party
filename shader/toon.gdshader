shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 base_color : source_color = vec4(0.8, 0.6, 0.35, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 shadow_color : source_color = vec3(0.35, 0.28, 0.22);
uniform float shadow_threshold : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float shadow_smoothness : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float ambient_strength : hint_range(0.0, 1.0, 0.01) = 0.15;
uniform float specular_strength : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float specular_threshold : hint_range(0.0, 1.0, 0.01) = 0.78;
uniform vec3 specular_color : source_color = vec3(1.0, 0.95, 0.8);

void fragment() {
	vec4 surface_color = texture(albedo_texture, UV);

	ALBEDO = surface_color.rgb;
	ROUGHNESS = 0.85;
	SPECULAR = 0.0;
	EMISSION = surface_color.rgb * ambient_strength;
}

void light() {
	float ndotl = max(dot(NORMAL, LIGHT), 0.0);
	float edge_start = shadow_threshold - shadow_smoothness;
	float edge_end = shadow_threshold + shadow_smoothness;
	float toon_light = smoothstep(edge_start, edge_end, ndotl);
	toon_light = clamp(toon_light, 0.0, 1.0);

	vec3 diffuse_color = mix(shadow_color, ALBEDO, toon_light);
	DIFFUSE_LIGHT += diffuse_color * LIGHT_COLOR * ATTENUATION;

	vec3 half_vector = normalize(LIGHT + VIEW);
	float specular_amount = pow(max(dot(NORMAL, half_vector), 0.0), 32.0);
	float specular_step = step(specular_threshold, specular_amount) * specular_strength;
	SPECULAR_LIGHT += specular_color * specular_step * LIGHT_COLOR * ATTENUATION;
}
