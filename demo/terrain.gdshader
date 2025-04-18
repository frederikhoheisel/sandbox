shader_type spatial;

uniform sampler2D depth_texture; // The depth texture
uniform float max_depth_mm = 1000.0; // Maximum depth in millimeters
uniform float height_scale = 1.0; // Scale factor for height displacement

void vertex() {
    // Get the UV coordinates of the vertex
    vec2 uv = UV;

    // Sample the depth texture
    float depth = texture(depth_texture, uv).r;

    // Normalize the depth value (assuming depth is in millimeters)
    float normalized_depth = depth / max_depth_mm;

    // Displace the vertex along the Y-axis based on the depth value
    VERTEX.y += normalized_depth * height_scale;
}

void fragment() {
    // Simple shading based on the vertex height
    float height = VERTEX.y;
    ALBEDO = vec3(height);
}