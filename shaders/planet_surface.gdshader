shader_type spatial;

uniform float generation_seed = 1.0;
uniform float noise_scale = 2.0;
uniform float noise_strength = 0.75;
uniform float surface_contrast = 1.25;

uniform vec4 surface_color_a : source_color = vec4(0.08, 0.24, 0.12, 1.0);
uniform vec4 surface_color_b : source_color = vec4(0.55, 0.38, 0.18, 1.0);
uniform vec4 ocean_color : source_color = vec4(0.025, 0.11, 0.3, 1.0);

float hash_value(vec3 position) {
	float value = dot(position, vec3(127.1, 311.7, 74.7) + generation_seed);
	return fract(sin(value) * 43758.5453);
}

float noise_value(vec3 position) {
	vec3 cell = floor(position);
	vec3 local = fract(position);
	local = local * local * (3.0 - 2.0 * local);

	float n000 = hash_value(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash_value(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash_value(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash_value(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash_value(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash_value(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash_value(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash_value(cell + vec3(1.0, 1.0, 1.0));

	float x00 = mix(n000, n100, local.x);
	float x10 = mix(n010, n110, local.x);
	float x01 = mix(n001, n101, local.x);
	float x11 = mix(n011, n111, local.x);

	float y0 = mix(x00, x10, local.y);
	float y1 = mix(x01, x11, local.y);

	return mix(y0, y1, local.z);
}

float fractal_noise(vec3 position) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int octave = 0; octave < 4; octave++) {
		value += noise_value(position * frequency) * amplitude;
		frequency *= 2.0;
		amplitude *= 0.5;
	}

	return value;
}

void fragment() {
	vec3 position = NORMAL * noise_scale;
	float terrain = fractal_noise(position);
	terrain = clamp(pow(terrain, surface_contrast), 0.0, 1.0);

	float land_mask = smoothstep(0.43, 0.53, terrain);
	vec3 land_color = mix(surface_color_a.rgb, surface_color_b.rgb, terrain * noise_strength);
	vec3 final_color = mix(ocean_color.rgb, land_color, land_mask);

	ALBEDO = final_color;
	ROUGHNESS = 0.82;
	METALLIC = 0.0;
}
