shader_type spatial;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D opacity_gradient : hint_default_white, filter_linear;
uniform float opacity_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// NORMAL faces the camera (dot == 1) at the visible center of the sphere
	// and is perpendicular to the view (dot == 0) at the silhouette edge.
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float radial = 1.0 - facing + 0.01;

	vec4 sampled = texture(opacity_gradient, vec2(radial, 0.5));
	float gradient_value = sampled.a;

	vec4 tex = texture(albedo_texture, UV);

	ALBEDO = base_color.rgb;
	ALPHA = base_color.a * gradient_value * opacity_strength * tex.r;
}
