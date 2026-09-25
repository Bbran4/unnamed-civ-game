shader_type spatial;

render_mode cull_back, blend_mix;

uniform float cloud_density = 0.35;
uniform float cloud_speed = 0.003;
uniform float cloud_scale = 4.5;
uniform float cloud_softness = 0.14;

float hash_value(vec3 position) {
	float value = dot(position, vec3(127.1, 311.7, 74.7));
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

float cloud_noise(vec3 position) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int octave = 0; octave < 3; octave++) {
		value += noise_value(position * frequency) * amplitude;
		frequency *= 2.0;
		amplitude *= 0.5;
	}

	return value;
}

vec3 rotate_cloud_position(vec3 position, float angle) {
	float sine = sin(angle);
	float cosine = cos(angle);

	return vec3(
		position.x * cosine - position.z * sine,
		position.y,
		position.x * sine + position.z * cosine
	);
}

void fragment() {
	vec3 sphere_position = normalize(NORMAL);
	float rotation_angle = TIME * cloud_speed;
	vec3 cloud_position = rotate_cloud_position(sphere_position, rotation_angle);

	float cloud_value = cloud_noise(cloud_position * cloud_scale);
	float cloud_edge = clamp(cloud_softness, 0.01, 0.49);
	float cloud_mask = smoothstep(
		1.0 - cloud_density - cloud_edge,
		1.0 - cloud_density + cloud_edge,
		cloud_value
	);

	float limb = clamp(dot(NORMAL, VIEW), 0.0, 1.0);

	ALBEDO = vec3(0.92, 0.95, 1.0);
	ROUGHNESS = 1.0;
	ALPHA = cloud_mask * limb * 0.5;
}
