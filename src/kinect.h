#ifndef KINECT_H
#define KINECT_H

#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node.hpp>
#include <k4a/k4a.h>

namespace godot {

class Kinect : public Node {
    GDCLASS(Kinect, Node)

private:
    k4a_device_t kinect_device; // Handle for the Kinect device
    k4a_device_configuration_t config; // Store the configuration
    bool cameras_running = false; // Flag to check if cameras are running
    Ref<ImageTexture> depth_texture; // Texture for storing the depth image
    PackedByteArray depth_data; // Buffer for storing the depth image data

protected:
    static void _bind_methods();

public:
    Kinect();
    ~Kinect();

    static void kinect_log_callback(void *context, k4a_log_level_t level, const char *file, const int line, const char *message);
    Array extract_camera_parameters();
    bool initialize_kinect(int device_index = 0);
    void close_kinect();
    bool start_cameras();
    bool stop_cameras();
    int get_connected_device_count();
    Ref<Image> get_depth_image_rf();
    Ref<Image> get_depth_image_rg8();
    Array get_depth_and_color_image_rg8();
    Ref<ImageTexture> Kinect::get_depth_texture_rg8();
    Ref<ImageTexture> Kinect::get_depth_texture_rf();
    Ref<ImageTexture> Kinect::get_placeholder_texture();
    Array playback_mkv(const String &file_path);
    void Kinect::undistort_depth_image(k4a_calibration_t &camera_calibration, k4a_image_t depth_image, Ref<Image> &undistorted_image);
};

}

#endif