shader_type canvas_item;

uniform float min_depth = 0.5;
uniform float max_depth = 0.57;

uniform vec3 shallow_color: source_color = vec3(0.0, 0.0, 1.0); // blue for low areas
uniform vec3 mid_color: source_color = vec3(0.0, 1.0, 0.0); // green for mid-range
uniform vec3 high_color: source_color = vec3(1.0, 0.0, 0.0); // red for peaks

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float depth = texture(TEXTURE, UV).r;
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
	COLOR = vec4(color, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
