#[compute]
#version 450

// Specify the local work group size
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input texture (FORMAT_RG8) - binding 0
layout(set = 0, binding = 0, rg8) uniform readonly image2D input_texture;

// previous texture (FORMAT_RF) - binding 1
layout(set = 0, binding = 1, r32f) uniform readonly image2D previous_frame;

// Output texture (FORMAT_RF) - binding 2
layout(set = 0, binding = 2, r32f) uniform writeonly image2D output_texture;

// DISTORTION CORRECTION PARAMETERS as uniform buffer - binding 3
layout(set = 0, binding = 3, std430) restrict readonly buffer UniformBuffer {
    // focal length
    float fx;
    float fy;
    // principal point
    float cx;
    float cy;
    // radial distortion
    float k1;
    float k2;
    float k3;
    float k4;
    float k5;
    float k6;
    // tangential distortion
    float p1;
    float p2;
} uniforms;

// Constants
// bilateral filter
const float sigma_spatial = 2.0;
const float sigma_intensity = 0.05;
const int kernel_size = 9;

// exponential filter
const float alpha = 0.1;

const float min_depth = 0.45;
const float max_depth = 9.0;

// edge detection
const float edge_threshold = 0.05;

// trapezoid correction
const float top_width_ratio = 1.05;
const float bottom_width_ratio = 1.0;
const float perspective_strength = 0.1;
// for cutting the edges (left, right, top, bottom) (in uv space)
const vec4 cut_box = vec4(0.097, 0.881, 0.196, 0.753);
const vec2 resolution = vec2(640.0, 576.0);

/**
* corrects the lens distortion using the Brown-Conrady model of the kinect
* also uses perspective correction to turn a trapezoid into a rectangle
*/
vec2 undistort_pixel(vec2 distorted_uv) {
    // Brown–Conrady model distortion
    // vec2 center_offset = vec2(0.5, 0.5);
    vec2 center_offset = vec2(uniforms.cx / resolution.x, uniforms.cy / resolution.y);
    vec2 focal_scale = vec2(uniforms.fx / resolution.x, uniforms.fy / resolution.y);

    vec2 norm = (distorted_uv - center_offset) / focal_scale;
    float x = norm.x;
    float y = norm.y;
    float r2 = x * x + y * y;
    float r4 = r2 * r2;
    float r6 = r4 * r2;

    // Radial distortion correction
    float radial_distortion = 1.0 + uniforms.k1 * r2 + uniforms.k2 * r4 + uniforms.k3 * r6;
    float radial_distortion_denom = 1.0 + uniforms.k4 * r2 + uniforms.k5 * r4 + uniforms.k6 * r6;

    // radial_distortion_denom = max(radial_distortion_denom, 1e-6);
    float radial_factor = radial_distortion / radial_distortion_denom;

    // Tangential distortion correction
    float tangential_x = 2.0 * uniforms.p1 * x * y + uniforms.p2 * (r2 + 2.0 * x * x);
    float tangential_y = 2.0 * uniforms.p2 * x * y + uniforms.p1 * (r2 + 2.0 * y * y);

    // Apply corrections
    vec2 undistorted_norm = vec2(
            x * radial_factor + tangential_x,
            y * radial_factor + tangential_y);
            
    vec2 undistorted_uv = undistorted_norm * focal_scale + center_offset;
    return undistorted_uv;
    
    // Trapezoid distortion
    vec2 center_uv = undistorted_uv - 0.5;
    float width_scale = mix(bottom_width_ratio, top_width_ratio, (center_uv.y + 0.5));
    //width_scale = max(abs(width_scale), 1e-6) * sign(width_scale);
    
    float perspective_factor = 1.0 + perspective_strength * center_uv.y;
    perspective_factor = max(abs(perspective_factor), 1e-6) * sign(perspective_factor);

    vec2 corrected_uv = vec2(
            (center_uv.x / width_scale) / perspective_factor,
            center_uv.y / perspective_factor);
    
    return corrected_uv + 0.5;
}
    
/** 
* gaussian distribution function 
*/
float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma));
}

float bilateral_filter(ivec2 center_coords) {    
    // Convert RG to depth for center pixel
    vec4 center_pixel = imageLoad(input_texture, center_coords);
    float center_depth = (center_pixel.r + center_pixel.g * 256.0) / (max_depth);

    float filtered_depth = 0.0;
    float weight_sum = 0.0;
    
    int half_kernel = kernel_size / 2;
    ivec2 texture_size = imageSize(input_texture);
    
    for (int i = -half_kernel; i <= half_kernel; i++) {
        for (int j = -half_kernel; j <= half_kernel; j++) {
            ivec2 sample_coords = center_coords + ivec2(i, j);
            // Check bounds
            if (sample_coords.x < 0 || sample_coords.x >= texture_size.x ||
                sample_coords.y < 0 || sample_coords.y >= texture_size.y) {
                continue;
            }
            
            vec4 sample_pixel = imageLoad(input_texture, sample_coords);
            float sample_depth = (sample_pixel.r + sample_pixel.g * 256.0) / (max_depth);
            
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
* Check if this pixel is near a depth discontinuity
*/
bool edge_detection(ivec2 center_coords) {    
    float min_neighbor = 99999.0;    
    float max_neighbor = 0.0;        

    ivec2 directions[8] = {        
        ivec2(0, 1), ivec2(0, -1), ivec2(1, 0), ivec2(-1, 0),        
        ivec2(1, 1), ivec2(-1, 1), ivec2(1, -1), ivec2(-1, -1)    
        };        
    
    ivec2 texture_size = imageSize(input_texture);        
    
    for(int i = 0; i < 8; i++) {        
        ivec2 sample_coords = center_coords + directions[i];                
        // Check bounds        
        if (sample_coords.x < 0 || sample_coords.x >= texture_size.x ||             
            sample_coords.y < 0 || sample_coords.y >= texture_size.y) {            
                continue;        
        }                
        
        vec4 neighbor_pixel = imageLoad(input_texture, sample_coords);        
        float neighbor_depth = (neighbor_pixel.r + neighbor_pixel.g * 256.0) / max_depth;                

        min_neighbor = min(min_neighbor, neighbor_depth);        
        max_neighbor = max(max_neighbor, neighbor_depth);    
    }        
    
    return (max_neighbor - min_neighbor) > edge_threshold;
}

void main() {
    // Get the current pixel coordinates
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);

    // Get dimensions of the input texture
    ivec2 texture_size = imageSize(input_texture);

    // Check if the pixel is within the texture bounds
    if(pixel_coords.x >= texture_size.x || pixel_coords.y >= texture_size.y) {
        return;
    }

    // Convert pixel coordinates to uv coordinates
    vec2 uv = (vec2(pixel_coords) + 0.5) / vec2(texture_size);

    // Apply lens distortion correction
    vec2 undistorted_uv = undistort_pixel(uv);

    // Convert undistorted uv back to pixel coordinates for sampling
    ivec2 undistorted_coords = ivec2(undistorted_uv * vec2(texture_size));
    // ivec2 undistorted_coords = ivec2(uv * vec2(texture_size));


    // Apply bilateral filter
    float center_depth_filtered = bilateral_filter(undistorted_coords);

    // vec4 center_pixel = imageLoad(input_texture, undistorted_coords);
    // float center_depth_filtered = (center_pixel.r + center_pixel.g * 256.0) / (max_depth);

    // Apply tilt correction
    center_depth_filtered -= uv.y * 0.081;
    
    // Get previous depth
    float previous_depth = imageLoad(previous_frame, pixel_coords).r;
    
    // Apply exponential smoothing
    float center_depth_filtered_smoothed = exponential_smooth(center_depth_filtered, previous_depth);
    
    bool is_edge = edge_detection(undistorted_coords);

    // Apply edge detection and calamp depth
    float final_depth;
    if (is_edge) {
        final_depth = previous_depth;
    }
    final_depth = clamp(center_depth_filtered_smoothed, min_depth, max_depth);

    // cut of edges
    if(uv.x < cut_box.x || uv.x > cut_box.y || uv.y < cut_box.z || uv.y > cut_box.w) {
        final_depth = max_depth;
    }
    
    // Store the result in the output texture    
    imageStore(output_texture, pixel_coords, vec4(final_depth, 0.0, 0.0, 1.0));
}
