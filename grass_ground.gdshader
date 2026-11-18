shader_type spatial;

uniform vec3 grass_color_dark : source_color = vec3(0.08, 0.16, 0.08);
uniform vec3 grass_color_mid : source_color = vec3(0.12, 0.22, 0.10);
uniform vec3 grass_color_dry : source_color = vec3(0.16, 0.18, 0.11);
uniform vec3 soil_color : source_color = vec3(0.10, 0.08, 0.07);
uniform float roughness = 0.88;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 2; i++) {
		v += a * noise(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = world_pos.xz;
	
	// 큰 스케일 군락 노이즈 (2회 루프)
	float n_macro = fbm(uv * 0.12);
	// 중간/미세 잔디 질감 (단일 noise 호출로 경량화)
	float n_mid = noise(uv * 0.8);
	float n_micro = noise(uv * 3.5);
	
	vec3 base_grass = mix(grass_color_dark, grass_color_mid, n_micro * 0.8 + n_mid * 0.2);
	vec3 patch_grass = mix(base_grass, grass_color_dry, n_macro);
	
	// 간간이 보이는 어두운 흙 패치 (단일 noise 호출)
	float dirt_patch = smoothstep(0.68, 0.85, noise(uv * 0.25 + 5.0));
	vec3 final_color = mix(patch_grass, soil_color, dirt_patch * 0.6);
	
	ALBEDO = final_color;
	ROUGHNESS = roughness;
	SPECULAR = 0.15;
}
