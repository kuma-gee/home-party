shader_type spatial;
render_mode depth_test_disabled, skip_vertex_transform, unshaded, cull_disabled;

// GH-11: fullscreen TV-static overlay pinned in front of the VR camera.
// intensity 0 = invisible; GhostHunter drives it from the Haunt Glitch level.

uniform vec4 color : source_color = vec4(0.85, 0.9, 1.0, 1.0);
uniform float intensity = 0.0;
uniform float grain_scale = 260.0;
uniform float speed = 30.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	vec2 v = VERTEX.xy;
	// Project the quad to full screen, centered on the eye (same trick as the
	// vignette effect).
	vec4 eye = PROJECTION_MATRIX * vec4(0.0, 0.0, 100.0, 1.0);
	v += eye.xy / eye.w;
	float z = PROJECTION_MATRIX[2][2] < 0.0 ? 0.0 : 1.0;
	POSITION = vec4(v, z, 1.0);
}

void fragment() {
	vec2 cell = floor(UV * grain_scale) + floor(vec2(TIME * speed, TIME * speed * 1.31));
	float n = hash(cell);
	ALBEDO = mix(color.rgb * 0.15, color.rgb, step(0.5, n));
	ALPHA = intensity * (0.25 + 0.75 * n);
}
