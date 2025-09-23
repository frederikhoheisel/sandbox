shader_type spatial;
render_mode blend_mix, cull_back, diffuse_toon, specular_toon;

uniform sampler2D depth_texture; // The depth texture
uniform bool use_real_colors = false; // if the kinect provides
uniform float height_scale = 10.0; // Scale factor

uniform float min_depth = 0.5;
uniform float max_depth = 0.57;

const float min_depth_depth = 4.5;
const float max_depth_depth = 10.5;

uniform sampler2D color_texture;
// for scaling and positioning the color texture
uniform vec2 color_scale = vec2(0.455, 0.791);
uniform vec2 color_offset = vec2(-0.017, 0.016);
uniform float aspect_correction : hint_range(0.5, 2.0) = 1.0;

uniform vec3 shallow_color: source_color = vec3(0.2, 0.2, 0.0); // for low areas
uniform vec3 mid_color: source_color = vec3(0.5, 0.5, 0.0); // for mid-range
uniform vec3 high_color: source_color = vec3(1.0, 1.0, 0.0); // for peaks

uniform bool show_normals = false;
uniform bool WorldSpace = true; // toggle between world and local space
uniform bool RemapRange = true; // remap from -1..1 to 0..1

group_uniforms grass_spawning;
	uniform int tree_count : hint_range(0, 1024) = 0;
	uniform vec3 tree_positions[1024];
	uniform int tree_spawn_times[1024];
	
	uniform float grass_spot_radius : hint_range(0.1, 20.0) = 2.0;
	uniform float grass_spot_softness : hint_range(0.01, 5.0) = 1.0;
	uniform float grass_intensity : hint_range(0.0, 2.0) = 1.0;
	
	uniform int growth_pattern : hint_range(0, 2) = 0;
	uniform float start_time = 0.0;
	uniform float grow_duration : hint_range(0.0, 10000.0, 0.1) = 1000.0;

group_uniforms grass_texture;
	uniform vec4 grass_albedo : source_color;
	uniform sampler2D grass_texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

	uniform float grass_roughness : hint_range(0.0, 1.0);
	uniform sampler2D grass_texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
	uniform sampler2D grass_texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

	uniform float grass_specular : hint_range(0.0, 1.0, 0.01);
	uniform float grass_metallic : hint_range(0.0, 1.0, 0.01);

	uniform sampler2D grass_texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
	uniform float grass_normal_scale : hint_range(-16.0, 16.0);

	uniform sampler2D grass_texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
	uniform float grass_ao_light_affect : hint_range(0.0, 1.0, 0.01);

	uniform sampler2D grass_texture_heightmap : hint_default_black, filter_linear_mipmap, repeat_enable;
	uniform float grass_heightmap_scale : hint_range(-16.0, 16.0, 0.001);
	uniform int grass_heightmap_min_layers : hint_range(1, 64);
	uniform int grass_heightmap_max_layers : hint_range(1, 64);
	uniform vec2 grass_heightmap_flip;

	uniform vec3 grass_uv1_scale;

varying vec3 world_position;
varying vec2 uv;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	uv = UV;
	
	float depth = texture(depth_texture, UV).r * height_scale;
	VERTEX.y -= depth;

	vec2 texel_size = 1.0 / vec2(textureSize(depth_texture, 0));

	float up = texture(depth_texture, UV + texel_size * vec2(0.0, 1.0)).r * height_scale;
	float right = texture(depth_texture, UV + texel_size * vec2(1.0, 0.0)).r * height_scale;
	float left = texture(depth_texture, UV + texel_size * vec2(-1.0, 0.0)).r * height_scale;
	float down = texture(depth_texture, UV + texel_size * vec2(0.0, -1.0)).r * height_scale;

	//vec3 a = vec3(2.0 * texel_size.x, 0.0, right - left);
	//vec3 b = vec3( 0.0, 2.0 * texel_size.y, up - down);
	vec3 a = vec3(2.0 * texel_size.x, -(right - left), 0.0);  // Negate height difference
	vec3 b = vec3(0.0, -(up - down), 2.0 * texel_size.y); 
	//vec3 a = vec3(2.0 * texel_size.x, right - left, 0.0);
	//vec3 b = vec3(0.0, up - down, 2.0 * texel_size.y);

	NORMAL = -normalize(cross(a, b));
}

float calculate_grass_influence(vec3 world_pos) {
	float total_influence = 0.0;

	// Check influence from each tree position
	for (int i = 0; i < tree_count; i++) {
		vec3 tree_pos = tree_positions[i];
		float spawn_time = float(tree_spawn_times[i]);

		// Calculate 2D distance from tree
		float tree_distance = length(vec2(world_pos.x - tree_pos.x, world_pos.z - tree_pos.z));

		// Basic circular influence
		float spatial_influence = 1.0 - smoothstep(0.0, grass_spot_radius, tree_distance);

		// Time-based growth animation
		float time_influence = smoothstep(spawn_time, spawn_time + grow_duration, start_time - 1000.0 + TIME * 1000.0);

		float influence = 0.0;

		// Circular growth - radius expands over time
		float current_radius = grass_spot_radius * time_influence;
		influence = 1.0 - smoothstep(0.0, current_radius, tree_distance);

		// Apply softness
		influence = pow(influence, 1.0 / grass_spot_softness);

		total_influence = max(total_influence, influence);

		// Early exit if we're already at max influence
		if (total_influence >= 1.0) break;
	}

	return clamp(total_influence, 0.0, 1.0);
}


void fragment() {
	//if (use_real_colors) { // use the color camera and scale it accordingly
		//// Convert to normalized device coordinates (-1 to 1)
		//vec2 ndc = (UV - 0.5) * 2.0;
//
		//// Azure Kinect NFOV unbinned depth FOV: ~75° horizontal, ~65° vertical
		//// Azure Kinect color camera FOV: ~90° horizontal, ~59° vertical
		//float depth_fov_h = 75.0;
		//float depth_fov_v = 65.0;
		//float color_fov_h = 90.0;
		//float color_fov_v = 59.0;
//
		//// Calculate FOV scaling factors
		//float fov_scale_x = tan(radians(depth_fov_h * 0.5)) / tan(radians(color_fov_h * 0.5));
		//float fov_scale_y = tan(radians(depth_fov_v * 0.5)) / tan(radians(color_fov_v * 0.5));
//
		//// Resolution-based aspect ratio correction
		//// Depth: 640x576, Color: 1280x720
		//float depth_aspect = 640.0 / 576.0;
		//float color_aspect = 1280.0 / 720.0;
		//float auto_aspect = color_aspect / depth_aspect;
//
		//// Apply transformations
		//ndc.x *= fov_scale_x * color_scale.x * auto_aspect * aspect_correction;
		//ndc.y *= fov_scale_y * color_scale.y;
//
		//// Convert back to UV coordinates
		//vec2 adjusted_uv = (ndc * 0.5) + 0.5;
//
		//// Apply manual offset
		//adjusted_uv += color_offset;
//
		//// Sample the color texture
		//if (adjusted_uv.x >= 0.0 && adjusted_uv.x <= 1.0 && adjusted_uv.y >= 0.0 && adjusted_uv.y <= 1.0) {
			//ALBEDO = texture(color_texture, adjusted_uv).rgb;
		//} else {
			//ALBEDO = vec3(0.0, 0.0, 0.0);
		//}
	//} else {
	vec3 base_color;
	float base_roughness;
	float base_metallic;
	float base_specular;
	//if (show_normals) {
		//// World space normal
		//vec4 Wn = INV_VIEW_MATRIX * vec4( NORMAL, 0.0 );
		//if ( WorldSpace == false ) {
			//Wn = inverse( MODEL_MATRIX ) * Wn;
		//} if ( RemapRange == true ) {
			//ALBEDO = ( Wn.rgb + 1.0 )/2.0;
		//} else {
			//ALBEDO = Wn.rgb;
		//}
	//} else {
	float depth = texture(depth_texture, UV).r;
	float normalized_height = 1.0 - clamp((depth - min_depth) / (max_depth - min_depth), 0.0, 1.0);

	if(normalized_height < 0.5) {
		// Interpolate between mid and high colors for upper half
		base_color = mix(shallow_color, mid_color, normalized_height * 2.0);
	} else {
		// Interpolate between shallow and mid colors for lower half
		base_color = mix(mid_color, high_color, (normalized_height - 0.5) * 2.0);
	}

	// Add some material properties based on height
	base_roughness = 0.3 + normalized_height * 0.4; // Higher areas are less rough
	base_metallic = normalized_height * 0.2; // Higher areas have slight metallic sheen
	base_specular = normalized_height * 0.5; // speculars for high areas

	vec2 grass_uv = uv * grass_uv1_scale.xy;
	float grass_influence = calculate_grass_influence(world_position);
	grass_influence *= grass_intensity;
	
	/* //Height things; performance intensive
	{
		// Height: Enabled
		vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT * grass_heightmap_flip.x, -BINORMAL * grass_heightmap_flip.y, NORMAL));

		// Height Deep Parallax: Enabled
		float num_layers = mix(float(grass_heightmap_max_layers), float(grass_heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		float layer_depth = 1.0 / num_layers;
		float current_layer_depth = 0.0;
		vec2 p = view_dir.xy * grass_heightmap_scale * 0.01;
		vec2 delta = p / num_layers;
		vec2 ofs = grass_uv;
		float depth = 1.0 - texture(grass_texture_heightmap, ofs).r;

		float current_depth = 0.0;
		while (current_depth < depth) {
			ofs -= delta;
			depth = 1.0 - texture(grass_texture_heightmap, ofs).r;

			current_depth += layer_depth;
		}

		vec2 prev_ofs = ofs + delta;
		float after_depth = depth - current_depth;
		float before_depth = (1.0 - texture(grass_texture_heightmap, prev_ofs).r) - current_depth + layer_depth;

		float weight = after_depth / (after_depth - before_depth);
		ofs = mix(ofs, prev_ofs, weight);
		grass_uv = ofs;
	} */
	
	
	vec3 grass_color = grass_albedo.rgb * texture(grass_texture_albedo, grass_uv).rgb;
	
	float final_grass_metallic = texture(grass_texture_metallic, grass_uv).r * grass_metallic;
	
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float final_grass_roughness = texture(grass_texture_roughness, grass_uv).r * grass_roughness;
	
	
	vec3 final_color = mix(base_color, grass_color, grass_influence);
	float final_roughness = mix(base_roughness, final_grass_roughness, grass_influence);
	float final_metallic = mix(base_metallic, final_grass_metallic, grass_influence);
	float final_specular = mix(base_specular, grass_specular, grass_influence);
	
	
	NORMAL_MAP = mix(NORMAL_MAP, texture(grass_texture_normal, grass_uv).rgb, grass_influence);
	NORMAL_MAP_DEPTH = grass_normal_scale;
	
	AO = mix(AO, texture(grass_texture_ambient_occlusion, grass_uv).r, grass_influence);
	AO_LIGHT_AFFECT = grass_ao_light_affect;
	
	ALBEDO = final_color;
	ROUGHNESS = final_roughness;
	METALLIC = final_metallic;
	SPECULAR = final_specular;
}