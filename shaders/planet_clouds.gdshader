shader_type spatial;

render_mode cull_back, blend_mix, depth_draw_alpha_prepass;

uniform sampler2D cloud_texture : source_color, filter_linear, repeat_enable;
uniform float cloud_speed = 0.003;

void fragment() {
	float longitude_offset: float = TIME * cloud_speed;
	vec2 cloud_uv: vec2 = vec2(
		fract(UV.x + longitude_offset),
		UV.y
	);

	vec4 cloud_sample: vec4 = texture(cloud_texture, cloud_uv);

	ALBEDO = cloud_sample.rgb;
	ROUGHNESS = 1.0;
	ALPHA = cloud_sample.a;
}
