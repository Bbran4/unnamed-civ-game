shader_type spatial;

render_mode cull_front, unshaded, blend_add, depth_draw_never;

uniform vec4 atmosphere_color : source_color = vec4(0.18, 0.5, 1.0, 1.0);
uniform float atmosphere_density = 0.75;

void fragment() {
	float rim: float = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	float alpha = clamp(rim * atmosphere_density, 0.0, 0.9);

	ALBEDO = atmosphere_color.rgb;
	EMISSION = atmosphere_color.rgb * rim;
	ALPHA = alpha;
}
