shader_type canvas_item;

uniform sampler2D depth_texture; // The depth texture

const float edge_threshold = 0.1;
const float min_depth = 0.4;
const float max_depth = 3.0;

// for cutting the edges (left, right, top, bottom)
uniform vec4 cut_box = vec4(0.097, 0.881, 0.196, 0.753);

/**DISTORTION CORRECTION PARAMETERS*/
// focal length
uniform float fx = 503.014038085938;
uniform float fy = 503.003509521484;
// principal point
uniform float cx = 323.092102050781;
uniform float cy = 336.343688964844;
// radial distortion
uniform float k1 = 0.7217835187912;
uniform float k2 = 0.30027222633362;
uniform float k3 = 0.01698642224073;
uniform float k4 = 1.05875504016876;
uniform float k5 = 0.47951143980026;
uniform float k6 = 0.0855306237936;
// tangential distortion
uniform float p1 = 0.00005971607243;
uniform float p2 = 0.00005871869143;

/**TRAPEZOID CORRECTION*/
const float top_width_ratio = 1.05;
const float bottom_width_ratio = 1.0;
const float perspective_strength = 0.1;

const vec2 resolution = vec2(640, 576);

vec2 undistort_pixel(vec2 distorted_uv) {
	// Brown–Conrady model distortion
	// Normalize to camera coordinates
	vec2 center_offset = vec2(cx / resolution.x, cy / resolution.y);
	vec2 norm = (distorted_uv - center_offset) / vec2(fx / resolution.x, fy / resolution.y);
	// vec2 norm = (distorted_uv - vec2(0.5, 0.5)) * aspect_ratio;

	float x = norm.x;
	float y = norm.y;
	float r2 = x * x + y * y;
	float r4 = r2 * r2;
	float r6 = r4 * r2;

	// Radial distortion correction
	float radial_distortion = 1.0 + k1 * r2 + k2 * r4 + k3 * r6;
	float radial_distortion_denom = 1.0 + k4 * r2 + k5 * r4 + k6 * r6;
	float radial_factor = radial_distortion / radial_distortion_denom;

	// Tangential distortion correction
	float tangential_x = 2.0 * p1 * x * y + p2 * (r2 + 2.0 * x * x);
	float tangential_y = 2.0 * p2 * x * y + p1 * (r2 + 2.0 * y * y);

	// Apply corrections
	vec2 undistorted_norm = vec2(
		x * radial_factor + tangential_x,
		y * radial_factor + tangential_y
	);

	// Convert back to pixel coordinates
	// vec2 result = undistorted_norm + vec2(cx / resolution.x, cy / resolution.y);
	vec2 undistorted_uv = undistorted_norm * vec2(fx / resolution.x, fy / resolution.y) + vec2(cx / resolution.x, cy / resolution.y);
	
	// Trapezoid distortion
	vec2 center_uv = undistorted_uv - 0.5; // + center_offset;
	
	float width_scale = mix(bottom_width_ratio, top_width_ratio, (center_uv.y + 0.5));
	
	float perspective_factor = 1.0 + perspective_strength * center_uv.y;
	
	vec2 corrected_uv = vec2(
		(center_uv.x / width_scale) / perspective_factor,
		center_uv.y / perspective_factor
	);
	
	return corrected_uv + 0.5; // - center_offset;
}

void fragment() {
	vec2 undistorted_uv = undistort_pixel(UV);
	float center_depth = texture(depth_texture, undistorted_uv).r / max_depth;
	center_depth -= undistorted_uv.y * 0.091;
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
		float neighbor_depth = texture(depth_texture, undistorted_uv + offset).r / max_depth;

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
		COLOR.r = max_depth;
	}

	/* // for debugging the uv distortion
	if(undistorted_uv.x <= 0.0 || undistorted_uv.x >= 1.0 || undistorted_uv.y <= 0.0 || undistorted_uv.y >= 1.0) {
		COLOR.g = 255.0;
	}*/

	if(UV.x < cut_box.x || UV.x > cut_box.y || UV.y < cut_box.z || UV.y > cut_box.w) {
		COLOR.r = max_depth;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
