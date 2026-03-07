shader_type spatial;
render_mode unshaded, wireframe, cull_disabled, shadows_disabled;

uniform vec4 wireframe_color : source_color = vec4(0.0, 1.0, 0.3, 1.0);

void fragment() {
    ALBEDO = wireframe_color.rgb;
    ALPHA = wireframe_color.a;
}
