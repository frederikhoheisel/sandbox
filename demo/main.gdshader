shader_type canvas_item;

uniform float max_depth_mm = 1000.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float depth = texture(TEXTURE, UV).r; // Read the red channel
	COLOR = vec4(vec3(depth / max_depth_mm), 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
