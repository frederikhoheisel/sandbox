shader_type canvas_item;

<<<<<<< HEAD
=======
uniform float depth_scale = 1.0; // Scale factor for visualization

>>>>>>> 7f964950910e4c52801eb79b4a5e9c1da272d002
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
<<<<<<< HEAD
=======
	// Combine the R and G channels into a 16-bit value
	//float depth = (texture(TEXTURE, UV).r + texture(TEXTURE, UV).g * 256.0) * depth_scale;
	
	// Visualize the depth as grayscale
	//COLOR = vec4(vec3(depth), 1.0);
>>>>>>> 7f964950910e4c52801eb79b4a5e9c1da272d002
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
