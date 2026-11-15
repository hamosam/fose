shader_type spatial;

uniform vec3 ground_color : source_color = vec3(0.07, 0.08, 0.09);
uniform vec3 dirt_color : source_color = vec3(0.04, 0.045, 0.05);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float n = noise(world_pos.xz * 0.3) * 0.7 + noise(world_pos.xz * 1.2) * 0.3;
	vec3 col = mix(ground_color, dirt_color, n);
	ALBEDO = col;
	ROUGHNESS = 0.92;
}
