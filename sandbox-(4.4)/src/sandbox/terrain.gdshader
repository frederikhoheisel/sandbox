shader_type spatial;

uniform sampler2D depth_texture; // The depth texture
uniform bool use_real_colors = false;
uniform float height_scale = 10.0; // Scale factor
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 304a027 (distortion correction and color camera use)
uniform float min_depth = 0.5;
uniform float max_depth = 0.56;

uniform sampler2D color_texture;
// for scaling and positioning the color texture
uniform vec2 color_scale = vec2(0.455, 0.791);
uniform vec2 color_offset = vec2(-0.017, 0.016);
uniform float aspect_correction : hint_range(0.5, 2.0) = 1.0;
<<<<<<< HEAD
=======
uniform float min_depth = 0.3;
uniform float max_depth = 1.0;
>>>>>>> 88e57b7 (recording feature)
=======
>>>>>>> 304a027 (distortion correction and color camera use)

uniform vec3 shallow_color: source_color = vec3(0.0, 0.0, 1.0); // blue for low areas
uniform vec3 mid_color: source_color = vec3(0.0, 1.0, 0.0); // green for mid-range
uniform vec3 high_color: source_color = vec3(1.0, 0.0, 0.0); // red for peaks

void vertex() {
	/*
	float center_depth = texture(depth_texture, UV).r;
	vec2 texel_size = 1.0 / vec2(textureSize(depth_texture, 0));

	// Check if this pixel is near a depth discontinuity
	bool is_edge = false;
	float min_neighbor = 99999.0;
	float max_neighbor = 0.0;

	// Sample in cardinal directions (up, down, left, right) and combinations
	vec2 directions[8] = {
		vec2(0.0, 1.0),
		vec2(0.0, -1.0),
		vec2(1.0, 0.0),
		vec2(-1.0, 0.0),
		vec2(1.0, 1.0),
		vec2(-1.0, 1.0),
		vec2(1.0, -1.0),
		vec2(-1.0, -1.0)
	};

	for(int i = 0; i < directions.length(); i++) {
		vec2 offset = directions[i] * texel_size;
		float neighbor_depth = texture(depth_texture, UV + offset).r + texture(depth_texture, UV + offset).g * 256.0;

		min_neighbor = min(min_neighbor, neighbor_depth);
		max_neighbor = max(max_neighbor, neighbor_depth);
	}

	// If depth difference is too large, this is an edge
	if(max_neighbor - min_neighbor > edge_threshold) {
		is_edge = true;
	}

	// Apply displacement, but not on edges
	if(!is_edge && center_depth > min_depth) {
		VERTEX -= NORMAL * center_depth * height_scale;
	} else {
		VERTEX.y -= 10.0;
	}*/
	VERTEX.y -= texture(depth_texture, UV).r * height_scale;
}

void fragment() {
	if (use_real_colors) { // use the color camera and scale it accordingly
		// Convert to normalized device coordinates (-1 to 1)
		vec2 ndc = (UV - 0.5) * 2.0;

		// Azure Kinect NFOV unbinned depth FOV: ~75° horizontal, ~65° vertical
		// Azure Kinect color camera FOV: ~90° horizontal, ~59° vertical
		float depth_fov_h = 75.0;
		float depth_fov_v = 65.0;
		float color_fov_h = 90.0;
		float color_fov_v = 59.0;

		// Calculate FOV scaling factors
		float fov_scale_x = tan(radians(depth_fov_h * 0.5)) / tan(radians(color_fov_h * 0.5));
		float fov_scale_y = tan(radians(depth_fov_v * 0.5)) / tan(radians(color_fov_v * 0.5));

		// Resolution-based aspect ratio correction
		// Depth: 640x576, Color: 1280x720
		float depth_aspect = 640.0 / 576.0;
		float color_aspect = 1280.0 / 720.0;
		float auto_aspect = color_aspect / depth_aspect;

		// Apply transformations
		ndc.x *= fov_scale_x * color_scale.x * auto_aspect * aspect_correction;
		ndc.y *= fov_scale_y * color_scale.y;

		// Convert back to UV coordinates
		vec2 adjusted_uv = (ndc * 0.5) + 0.5;

		// Apply manual offset
		adjusted_uv += color_offset;

		// Sample the color texture
		if (adjusted_uv.x >= 0.0 && adjusted_uv.x <= 1.0 && adjusted_uv.y >= 0.0 && adjusted_uv.y <= 1.0) {
			ALBEDO = texture(color_texture, adjusted_uv).rgb;
		} else {
			ALBEDO = vec3(0.0, 0.0, 0.0);
		}
	} else {
		float depth = texture(depth_texture, UV).r;
		float normalized_height = 1.0 - clamp((depth - min_depth) / (max_depth - min_depth), 0.0, 1.0);

		vec3 color;
		if(normalized_height < 0.5) {
			// Interpolate between mid and high colors for upper half
			color = mix(shallow_color, mid_color, normalized_height * 2.0);
		} else {
			// Interpolate between shallow and mid colors for lower half
			color = mix(mid_color, high_color, (normalized_height - 0.5) * 2.0);
		}

		// Apply the color
		ALBEDO = color;

		// Add some material properties based on height
		ROUGHNESS = 0.3 + normalized_height * 0.4; // Higher areas are less rough
		METALLIC = normalized_height * 0.2; // Higher areas have slight metallic sheen

		SPECULAR = normalized_height * 0.5;
	}
}