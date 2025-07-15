shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_opaque, depth_test_disabled, blend_mix;

uniform float transparency = 0.5;
uniform vec4 edge_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 base_color: source_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform float edge_width = 0.1;
uniform float dot_scale = 10.0;
uniform float dot_speed = 1.0;
uniform float dot_spacing = 0.2;

varying vec3 world_normal;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 normal = normalize(world_normal);
	
	//vec3 view_dir = normalize(world_pos - CAMERA_POSITION_WORLD);
	//float edge_factor = 1.0 - abs(dot(normal, view_dir));
	vec2 uv_edge = min(UV, 1.0 - UV);
	float uv_edge_factor =1.0 - smoothstep(0.0, edge_width, min(uv_edge.x, uv_edge.y));
	//uv_edge_factor = smoothstep(0.5 - edge_width, 0.5, uv_edge_factor);
	
	float edge_factor = max(uv_edge_factor, 0.0);
	
	vec2 world_uv = world_pos.xy + world_pos.xz + world_pos.yz;
	float dot_pattern = sin(world_uv.x * dot_scale + TIME * dot_speed) * 
						sin(world_uv.y * dot_scale + TIME * dot_speed);
	dot_pattern = smoothstep(0.0, 0.5, dot_pattern);
	
	float edge_mask = smoothstep(1.0 - edge_width, 1.0, edge_factor);
	float final_edge = edge_mask * dot_pattern;
	
	vec4 final_color = mix(base_color, edge_color, final_edge);
	final_color.a = transparency + final_edge * (1.0 - transparency);
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
