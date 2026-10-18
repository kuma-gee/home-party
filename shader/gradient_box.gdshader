shader_type spatial;
render_mode unshaded;

// Box variant of gradient_radial_opacity.gdshader with a symmetric linear ramp.
// Sphere version relies on NORMAL/VIEW silhouette falloff, which collapses to a
// flat per-face value on a box. Here opacity ramps linearly outwards from the
// center along a local-space axis, so the box center is transparent and both
// ends along that axis are more visible.

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D opacity_gradient : hint_default_white, filter_linear;
uniform float opacity_strength : hint_range(0.0, 1.0) = 1.0;

// Half extents of the box in local space (mesh size / 2).
uniform vec3 box_half_extents = vec3(0.5);
// Local-space direction of the ramp. Use a principal axis (e.g. (0,1,0)).
uniform vec3 gradient_axis = vec3(0.0, 1.0, 0.0);

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// Normalize each axis by the half extents so the box maps onto [-1, 1].
	vec3 normalized = local_pos / max(box_half_extents, vec3(0.0001));

	// Distance from the center plane along the axis: 0 at center, 1 at both ends.
	float radial = clamp(abs(dot(normalized, normalize(gradient_axis))), 0.0, 1.0) + 0.002;

	vec4 sampled = texture(opacity_gradient, vec2(radial, 0.5));
	float gradient_value = sampled.a;

	vec4 tex = texture(albedo_texture, UV);

	ALBEDO = base_color.rgb;
	ALPHA = base_color.a * gradient_value * opacity_strength * tex.r;
}
