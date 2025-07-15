shader_type canvas_item;

//uniform sampler2D depth_texture; // The depth texture, is currently the sprite itself

const float edge_threshold = 0.05; // controls edge detection, lower detects more

/** parameters for the bilateral filter */
uniform float sigma_spatial = 2.0; // controls spatial smoothing
uniform float sigma_intensity = 0.05; // controls edge preservation
uniform int kernel_size = 3;

/** parameters for exponential smoothing */
uniform sampler2D previous_frame : repeat_disable;
uniform float alpha = 0.3;

uniform float min_depth = 0.45;
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

/**
* corrects the lens distortion using the Brown-Conrady model of the kinect
* also uses perspective correction to turn a trapezoid into a rectangle
*/
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
			y * radial_factor + tangential_y);

	// Convert back to pixel coordinates
	// vec2 result = undistorted_norm + vec2(cx / resolution.x, cy / resolution.y);
	vec2 undistorted_uv = undistorted_norm * vec2(fx / resolution.x, fy / resolution.y) + vec2(cx / resolution.x, cy / resolution.y);
	
	// Trapezoid distortion
	vec2 center_uv = undistorted_uv - 0.5; // + center_offset;
	
	float width_scale = mix(bottom_width_ratio, top_width_ratio, (center_uv.y + 0.5));
	
	float perspective_factor = 1.0 + perspective_strength * center_uv.y;
	
	vec2 corrected_uv = vec2(
			(center_uv.x / width_scale) / perspective_factor,
			center_uv.y / perspective_factor);
	
	return corrected_uv + 0.5; // - center_offset;
}

/** 
* gaussian distribution function 
*/
float gaussian(float x, float sigma) {
	return exp(-(x * x) / (2.0 * sigma * sigma));
}

float bilateral_filter(sampler2D tex, vec2 uv, vec2 texel_size) {
	float center_depth = texture(tex, uv).r / max_depth;
	float filtered_depth = 0.0;
	float weight_sum = 0.0;
	
	int half_kernel = kernel_size / 2;
	for (int i = -half_kernel; i <= half_kernel; i++) {
		for (int j = -half_kernel; j <= half_kernel; j++) {
			vec2 offset = vec2(float(i), float(j)) * texel_size;
			vec2 sample_uv = uv + offset;
			
			float sample_depth = texture(tex, sample_uv).r / max_depth;
			
			float spatial_distance = length(vec2(float(i), float(j)));
			float spatial_weight = gaussian(spatial_distance, sigma_spatial);
			
			float intensity_distance = length(sample_depth - center_depth);
			float intensity_weight = gaussian(intensity_distance, sigma_intensity);
			
			float bilateral_weight = spatial_weight * intensity_weight;
			
			filtered_depth += sample_depth * bilateral_weight;
			weight_sum += bilateral_weight;
		}
	}
	
	return weight_sum > 0.0 ? filtered_depth / weight_sum : center_depth;
}

float exponential_smooth(float current, float previous) {
	return alpha * current + (1.0 - alpha) * previous;
}

/**
* like the exponential filter, but also takes movement into account
*/
float adaptive_exponential_smooth(float current, float previous, float motion_factor) {
	float adaptive_alpha = mix(alpha * 0.5, 1.0, motion_factor);
	return adaptive_alpha * current + (1.0 - adaptive_alpha) * previous;
}

/**
* Check if this pixel is near a depth discontinuity
*/
bool edge_detection(vec2 texel_size, sampler2D tex, vec2 uv) {
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
		float neighbor_depth = texture(tex, uv + offset).r;
		
		min_neighbor = min(min_neighbor, neighbor_depth);
		max_neighbor = max(max_neighbor, neighbor_depth);
	}
	
	// If depth difference is too large, this is an edge
	if(max_neighbor - min_neighbor > edge_threshold) {
		is_edge = true;
	}
	return is_edge;
}

void fragment() {
	vec2 undistorted_uv = undistort_pixel(UV); // undistort the lens distortion and angle
	vec2 texel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	float center_depth; // = texture(TEXTURE, undistorted_uv).r / max_depth;
	
	float center_depth_filtered = bilateral_filter(TEXTURE, undistorted_uv, texel_size);
	center_depth_filtered -= UV.y * 0.081; // to balance out tilt
	//center_depth_filtered -= undistorted_uv.y * 0.084;
	
	float previous_depth = texture(previous_frame, UV).r;
	
	//center_depth = center_depth_filtered;
	center_depth = exponential_smooth(center_depth_filtered, previous_depth);
	
	//float motion_factor = center_depth_filtered - previous_depth;
	//motion_factor = clamp(motion_factor * 5.0, 0.0, 1.0);
	//center_depth = adaptive_exponential_smooth(center_depth_filtered, previous_depth, motion_factor);
	
	//previous_depth = clamp(previous_depth, 1.0, 100.0);
	
	// with edge detection
	//if (previous_depth < min_depth) {
		if (edge_detection(texel_size, TEXTURE, undistorted_uv) || center_depth < min_depth) {
			COLOR.r = previous_depth;
		} else {
			COLOR.r = center_depth;
		}
	//} else {
		//COLOR.r = max_depth;
	//}
	
	// without edge detection
	//if (center_depth < min_depth) {
		//COLOR.r = previous_depth;
	//} else {
		//COLOR.r = center_depth;
	//}

	/* // for debugging the uv distortion
	if(undistorted_uv.x <= 0.0 || undistorted_uv.x >= 1.0 || undistorted_uv.y <= 0.0 || undistorted_uv.y >= 1.0) {
		COLOR.g = 255.0;
	}*/

	//if(UV.x < cut_box.x || UV.x > cut_box.y || UV.y < cut_box.z || UV.y > cut_box.w) {
		//COLOR.r = max_depth;
	//}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
