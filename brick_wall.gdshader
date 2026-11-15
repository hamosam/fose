shader_type spatial;

uniform vec3 brick_color : source_color = vec3(0.38, 0.20, 0.17);
uniform vec3 brick_color_alt : source_color = vec3(0.26, 0.14, 0.12);
uniform vec3 mortar_color : source_color = vec3(0.12, 0.12, 0.13);
uniform vec2 brick_size = vec2(0.5, 0.22);
uniform float mortar_size = 0.025;
uniform float roughness = 0.88;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 get_brick(vec2 uv) {
	vec2 grid_uv = uv / brick_size;
	
	// 가로 줄마다 지그재그(staggered) 오프셋
	float row = floor(grid_uv.y);
	if (mod(row, 2.0) > 0.5) {
		grid_uv.x += 0.5;
	}
	
	vec2 f = fract(grid_uv);
	vec2 cell = floor(grid_uv);
	
	// 줄눈(Mortar) 여부 계산
	vec2 m = mortar_size / brick_size;
	float is_mortar = step(f.x, m.x) + step(f.y, m.y);
	
	if (is_mortar > 0.0) {
		return mortar_color;
	}
	
	// 벽돌마다 약간씩 다른 색상 변형
	float rnd = hash21(cell);
	vec3 base = mix(brick_color, brick_color_alt, rnd);
	
	// 표면 미세 노이즈
	float surface_noise = hash21(uv * 18.0) * 0.08 - 0.04;
	return clamp(base + surface_noise, 0.0, 1.0);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec3 col;
	if (n.x > n.z) {
		col = get_brick(world_pos.zy);
	} else {
		col = get_brick(world_pos.xy);
	}
	
	ALBEDO = col;
	ROUGHNESS = roughness;
}
