shader_type spatial;

render_mode cull_back, blend_mix;

uniform float cloud_density = 0.35;
uniform float cloud_speed = 0.003;

float hash_value(vec2 position) {
	return fract(sin(dot(position, vec2(127.1, 311.7))) * 43758.5453);
}

float noise_value(vec2 position) {
	vec2 cell = floor(position);
	vec2 local = fract(position);
	local = local * local * (3.0 - 2.0 * local);

	float a = hash_value(cell);
	float b = hash_value(cell + vec2(1.0, 0.0));
	float c = hash_value(cell + vec2(0.0, 1.0));
	float d = hash_value(cell + vec2(1.0, 1.0));

	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void fragment() {
	vec2 uv = UV;
	uv.x += TIME * cloud_speed;

	float cloud_noise = noise_value(uv * 7.0);
	float cloud_mask = smoothstep(
		1.0 - cloud_density,
		1.0 - cloud_density + 0.12,
		cloud_noise
	);

	float limb = clamp(dot(NORMAL, VIEW), 0.0, 1.0);

	ALBEDO = vec3(0.92, 0.95, 1.0);
	ROUGHNESS = 1.0;
	ALPHA = cloud_mask * limb * 0.55;
}
