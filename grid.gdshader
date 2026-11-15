shader_type spatial;

uniform vec3 bg_color : source_color = vec3(0.18, 0.21, 0.28);
uniform vec3 line_color : source_color = vec3(0.35, 0.42, 0.55);
uniform float grid_size = 2.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_pos.xz / grid_size;
	vec2 f = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = min(f.x, f.y);
	float c = 1.0 - min(line, 1.0);
	ALBEDO = mix(bg_color, line_color, c * 0.7);
	ROUGHNESS = 0.8;
}
