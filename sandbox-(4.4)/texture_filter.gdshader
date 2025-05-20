shader_type canvas_item;

uniform sampler2D depth_texture; // The depth texture
uniform float edge_threshold = 0.1;
uniform float min_depth = 0.3;
uniform float max_depth = 3.0;

void fragment() {
	float center_depth = texture(depth_texture, UV).r / max_depth;
	//float center_depth = COLOR.r / max_depth;
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
		float neighbor_depth = texture(depth_texture, UV + offset).r / max_depth;
		
		min_neighbor = min(min_neighbor, neighbor_depth);
		max_neighbor = max(max_neighbor, neighbor_depth);
	}
	
	// If depth difference is too large, this is an edge
	if(max_neighbor - min_neighbor > edge_threshold) {
		is_edge = true;
	}
	
	if(is_edge) {
		COLOR.r = max_neighbor;
	} else {
		COLOR.r = center_depth;
	}
	if(center_depth < min_depth){
		COLOR.r += 1.5;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
