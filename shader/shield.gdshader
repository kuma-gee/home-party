shader_type spatial;

render_mode cull_disabled, unshaded, shadows_disabled, fog_disabled;

uniform float fresnel_power: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform sampler2D gradient_color: source_color;
uniform sampler2D alpha_gradient: source_color;
uniform float opacity: hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms Overlay;
uniform sampler2D overlay_texture: source_color;
uniform vec2 overlay_scale = vec2(1.0, 1.0);
uniform vec2 overlay_speed = vec2(0.0, 0.0);
uniform float overlay_strength: hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms Fade;
uniform float fade_value: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float fade_texture_divider: hint_range(1.0, 10.0, 0.01) = 1.0;
uniform float fade_smooth: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform sampler2D fade_mask: source_color;
uniform sampler2D fade_texture: source_color;
uniform vec2 fade_texture_scale = vec2(1.0, 1.0);

group_uniforms Proximity;
uniform float proximity_fade_distance: hint_range(0.0, 4.0) = 1.0;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void fragment() {
	// Fade
	vec4 fade_tex = texture(fade_texture, UV * fade_texture_scale);
	vec2 fade_uv = UV + fade_tex.r / fade_texture_divider;
	vec4 mask = texture(fade_mask, fade_uv);
	float fade = step(mask.r, fade_value);

	float mask_pow = pow(mask.r, 0.5);
	float alpha_fade = smoothstep(fade_value, fade_value + fade_smooth, mask_pow);

	// Overlay
	vec2 overlay_uv = UV * overlay_scale + TIME * overlay_speed;
	vec4 overlay = texture(overlay_texture, overlay_uv);
	float overlay_factor = overlay.r * overlay_strength;

	// Alpha
	float fresnel = pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)), fresnel_power);
	float alpha_uv = clamp(fresnel + alpha_fade + overlay_factor, 0.0, 1.0);
	vec4 alpha_tex = texture(alpha_gradient, vec2(alpha_uv));

	// Color
	vec2 color_uv = vec2(alpha_fade);
	vec4 color = texture(gradient_color, color_uv);
	ALBEDO = color.rgb + alpha_tex.rgb;

	// Proximity Fade
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float prox_fade = clamp(1.0 - smoothstep(view.z + proximity_fade_distance, view.z, VERTEX.z), 0.0, 1.0);

	ALPHA = alpha_tex.a * fade * prox_fade * opacity;
}
