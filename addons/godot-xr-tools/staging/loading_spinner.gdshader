shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 spinner_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float ring_radius : hint_range(0.0, 1.0) = 0.38;
uniform float ring_width : hint_range(0.0, 0.4) = 0.07;
uniform float arc_fraction : hint_range(0.01, 1.0) = 0.75;
uniform float speed : hint_range(0.0, 10.0) = 1.5;
uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform float fade_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);

	// Ring mask — smooth inner and outer edges
	float inner = ring_radius - ring_width * 0.5;
	float outer = ring_radius + ring_width * 0.5;
	float ring = smoothstep(inner - 0.01, inner, dist)
			   * (1.0 - smoothstep(outer, outer + 0.01, dist));

	// Normalized angle in [0, 1), counter-clockwise from +X
	float angle = fract(atan(uv.y, uv.x) / (2.0 * PI));

	// Spinning head position
	float head = fract(TIME * speed);

	// "behind" = how far behind the head this pixel is (0 = at head, 1 = full lap behind)
	float behind = fract(head - angle);

	// Only light pixels within the arc tail
	float in_arc = step(behind, arc_fraction);

	// Comet fade: bright at head (behind=0), dark at tail (behind=arc_fraction)
	// `fade_amount` = 1.0 => full fade; 0.0 => no fade (uniform intensity)
	float full_fade = pow(1.0 - (behind / arc_fraction), 1.5) * in_arc;
	float no_fade = in_arc;
	float fade = mix(no_fade, full_fade, clamp(fade_amount, 0.0, 1.0));

	// Fill mask: only show arc within the filled fraction of the ring (clockwise from angle=0)
	float fill_mask = step(angle, fill);

	ALBEDO = spinner_color.rgb;
	ALPHA = ring * fade * spinner_color.a * fill_mask;
}
