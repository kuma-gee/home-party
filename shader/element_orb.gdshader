shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Fill level: 0.0 = empty, 1.0 = full
uniform float fill_level : hint_range(0.0, 1.0) = 0.5;
// Base color of the object (unfilled part)
uniform vec4 base_color : source_color = vec4(0.1, 0.1, 0.15, 1.0);
// Color of the filled liquid
uniform vec4 fill_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
// Emission glow of the fill
uniform vec4 emission_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
// Soft edge at the fill boundary
uniform float edge_softness : hint_range(0.001, 0.2) = 0.05;
// Edge glow band width and intensity
uniform float edge_glow_width : hint_range(0.0, 0.3) = 0.08;
uniform float edge_glow_strength : hint_range(0.0, 20.0) = 5.0;
varying float local_y;

void vertex() {
    local_y = VERTEX.y; // VERTEX in vertex() is in local/model space
}

void fragment() {
    // local_y is passed from vertex shader in local space, so it's
    // unaffected by camera orientation.
    // Convert fill_level to the same -1..1 range as the mesh's local Y extents
    float mesh_min =  -1.0;
    float mesh_max =  1.0;
    float fill_y = mix(mesh_min, mesh_max, fill_level);
    // Signed distance from the fill line (positive = above fill, negative = below)
    float dist = local_y - fill_y;
    // Smooth step for the fill boundary
    float fill_mask = 1.0 - smoothstep(-edge_softness, edge_softness, dist);
    // Edge glow band centered on the fill line
    float edge_mask = smoothstep(edge_glow_width, 0.0, abs(dist));
    // Blend base and fill colors
    vec3 color = mix(base_color.rgb, fill_color.rgb, fill_mask);
    // Emission: fill area glows + extra bright at the edge
    vec3 emission = fill_mask * emission_color.rgb * emission_strength;
    emission += edge_mask * emission_color.rgb * edge_glow_strength;
    ALBEDO = color;
    EMISSION = emission;

    float alpha = mix(base_color.a, fill_color.a, fill_mask);
    ALPHA = alpha;
    //ROUGHNESS = 0.3;
    //METALLIC = 0.1;
}