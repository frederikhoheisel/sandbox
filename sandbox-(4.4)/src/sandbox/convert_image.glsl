#[compute]
#version 450

// Specify the local work group size
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input texture (FORMAT_RG8) - binding 0
layout(set = 0, binding = 0, rg8) uniform readonly image2D input_texture;

// Output texture (FORMAT_RF) - binding 1
layout(set = 0, binding = 1, r32f) uniform writeonly image2D output_texture;

void main() {
    // Get the current pixel coordinates
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
    
    // Get dimensions of the input texture
    ivec2 texture_size = imageSize(input_texture);
    
    // Check if the pixel is within the texture bounds
    if(pixel_coords.x < texture_size.x && pixel_coords.y < texture_size.y) {
        // Read the RG values from the input texture
        vec4 pixel_data = imageLoad(input_texture, pixel_coords);
        
        // Apply the conversion
        float result = ( pixel_data.r + pixel_data.g * 256.0) / 3.0;
        
        // Store the result in the output texture
        imageStore(output_texture, pixel_coords, vec4(result, 0.0, 0.0, 0.0));
    }
}