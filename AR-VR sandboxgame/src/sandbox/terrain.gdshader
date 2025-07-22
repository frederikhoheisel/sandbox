shader_type spatial;

uniform sampler2D depth_texture; // The depth texture
uniform bool use_real_colors = false;
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

uniform vec3 shallow_color: source_color = vec3(0.0, 0.0, 1.0); // blue for low areas
uniform vec3 mid_color: source_color = vec3(0.0, 1.0, 0.0); // green for mid-range
uniform vec3 high_color: source_color = vec3(1.0, 0.0, 0.0); // red for peaks

void vertex() {
	float depth = texture(depth_texture, UV).r * height_scale;
	VERTEX.y -= depth;

	vec2 texel_size = 1.0 / vec2(textureSize(depth_texture, 0));

	float up = texture(depth_texture, UV + texel_size * vec2(0.0, 1.0)).r;
	float right = texture(depth_texture, UV + texel_size * vec2(1.0, 0.0)).r;
	float left = texture(depth_texture, UV + texel_size * vec2(-1.0, 0.0)).r;
	float down = texture(depth_texture, UV + texel_size * vec2(0.0, -1.0)).r;

	vec3 a = vec3(2.0 * texel_size.x, 0.0, right - left);
	vec3 b = vec3( 0.0, 2.0 * texel_size.y, up - down);

	//vec3 a = vec3(2.0 * texel_size.x, right - left, 0.0);
	//vec3 b = vec3( 0.0, up - down, 2.0 * texel_size.y);

	NORMAL = -normalize(cross(a, b));
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
		//ROUGHNESS = 0.3 + normalized_height * 0.4; // Higher areas are less rough
		//METALLIC = normalized_height * 0.2; // Higher areas have slight metallic sheen
//
		//SPECULAR = normalized_height * 0.5;
	}
}