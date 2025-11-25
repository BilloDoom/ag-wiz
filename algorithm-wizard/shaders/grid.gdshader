shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_always;

uniform float grid_spacing : hint_range(0.1, 10.0) = 1.0;
uniform float line_width : hint_range(0.001, 0.1) = 0.02;  // World-space width
uniform vec4 grid_color : source_color = vec4(0.5, 0.5, 0.5, 0.3);
uniform vec4 axis_x_color : source_color = vec4(1.0, 0.0, 0.0, 0.5);
uniform vec4 axis_z_color : source_color = vec4(0.0, 0.0, 1.0, 0.5);
uniform bool show_axes = true;
uniform float fade_distance = 100.0;

void fragment() {
    // Get world position (not UV)
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Use XZ plane coordinates
    vec2 coord = world_pos.xz / grid_spacing;

    // Calculate grid lines using derivatives (world-space)
    vec2 derivative = fwidth(coord);
    vec2 grid = abs(fract(coord - 0.5) - 0.5) / derivative;

    // Apply world-space line width
    float line = min(grid.x, grid.y);
    float grid_alpha = 1.0 - min(line * (line_width / grid_spacing), 1.0);

    // Fade based on distance from origin
    float dist = length(world_pos.xz);
    float fade = 1.0 - smoothstep(fade_distance * 0.7, fade_distance, dist);

    vec3 color = grid_color.rgb;
    float alpha = grid_alpha * grid_color.a * fade;

    // Draw axes with world-space width
    if (show_axes) {
        float axis_width_world = line_width * 3.0;  // Axes are thicker

        // X axis (red) - along X, near Z=0
        if (abs(world_pos.z) < axis_width_world) {
            color = axis_x_color.rgb;
            alpha = max(alpha, axis_x_color.a * fade);
        }

        // Z axis (blue) - along Z, near X=0
        if (abs(world_pos.x) < axis_width_world) {
            color = axis_z_color.rgb;
            alpha = max(alpha, axis_z_color.a * fade);
        }
    }

    ALBEDO = color;
    ALPHA = alpha;
}