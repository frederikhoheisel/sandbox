shader_type canvas_item;

uniform float depth_scale = 1.0; // Scale factor for visualization

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Combine the R and G channels into a 16-bit value
	//float depth = (texture(TEXTURE, UV).r + texture(TEXTURE, UV).g * 256.0) * depth_scale;
	
	// Visualize the depth as grayscale
	//COLOR = vec4(vec3(depth), 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
