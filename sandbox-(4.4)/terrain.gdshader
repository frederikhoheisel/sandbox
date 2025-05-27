shader_type spatial;

uniform sampler2D depth_texture; // The depth texture
uniform float height_scale = 10.0; // Scale factor
uniform float min_depth = 0.66;
uniform float max_depth = 1.0;

uniform vec3 shallow_color: source_color = vec3(0.0, 0.0, 1.0); // blue for low areas
uniform vec3 mid_color: source_color = vec3(0.0, 1.0, 0.0);     // green for mid-range
uniform vec3 high_color: source_color = vec3(1.0, 0.0, 0.0);    // red for peaks

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
	VERTEX -= texture(depth_texture, UV).r * height_scale * NORMAL;
}

void fragment() {
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
	ROUGHNESS = 0.3 + normalized_height * 0.4;		// Higher areas are less rough
	METALLIC = normalized_height * 0.2;		// Higher areas have slight metallic sheen
	
	SPECULAR = normalized_height * 0.5;
}