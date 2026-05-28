shader_type canvas_item;

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform vec4 empty_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);
uniform float glyph_start : hint_range(0.0, 1.0) = 0.0;
uniform float glyph_end : hint_range(0.0, 1.0) = 1.0;
uniform bool circle_shape = false;
uniform float circle_radius : hint_range(0.0, 1.0) = 0.5;
uniform bool merge_empty_color = true;

void fragment() {
	if (circle_shape) {
		float dist = distance(UV, vec2(0.5));
		if (dist > circle_radius) {
			discard;
		}
	}

	float glyph_uv = (UV.y - glyph_start) / (glyph_end - glyph_start);
	if (glyph_uv < (1.0 - fill)) {
		if (merge_empty_color) {
			COLOR.rgb = mix(COLOR.rgb, empty_color.rgb, empty_color.a);
		} else {
			COLOR = empty_color;
		}
	}
}
