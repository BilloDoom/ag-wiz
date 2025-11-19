shader_type sky;

uniform vec3 background_color : source_color = vec3(0.15, 0.15, 0.15);
uniform float ambient_intensity : hint_range(0.0, 1.0) = 0.3;

void sky() {
	COLOR = background_color;
	COLOR *= ambient_intensity;
}