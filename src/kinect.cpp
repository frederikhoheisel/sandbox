#include "kinect.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/image.hpp>
#include <k4a/k4a.h>
#include <k4arecord/playback.h>
#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

using namespace godot;

// bind the methods of this class to 
void Kinect::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize_kinect", "device_index"), &Kinect::initialize_kinect);
    ClassDB::bind_method(D_METHOD("extract_camera_parameters"), &Kinect::extract_camera_parameters);
    ClassDB::bind_method(D_METHOD("close_kinect"), &Kinect::close_kinect);
    ClassDB::bind_method(D_METHOD("get_connected_device_count"), &Kinect::get_connected_device_count);
    ClassDB::bind_method(D_METHOD("get_depth_image_rf"), &Kinect::get_depth_image_rf);
    ClassDB::bind_method(D_METHOD("get_depth_image_rg8"), &Kinect::get_depth_image_rg8);
    ClassDB::bind_method(D_METHOD("get_depth_and_color_image_rg8"), &Kinect::get_depth_and_color_image_rg8);
    ClassDB::bind_method(D_METHOD("start_cameras"), &Kinect::start_cameras);
    ClassDB::bind_method(D_METHOD("stop_cameras"), &Kinect::stop_cameras);
    ClassDB::bind_method(D_METHOD("get_depth_texture_rg8"), &Kinect::get_depth_texture_rg8);
    ClassDB::bind_method(D_METHOD("get_depth_texture_rf"), &Kinect::get_depth_texture_rf);
    ClassDB::bind_method(D_METHOD("get_placeholder_texture"), &Kinect::get_placeholder_texture);
    ClassDB::bind_method(D_METHOD("playback_mkv", "file_path"), &Kinect::playback_mkv);
    //ClassDB::bind_method(D_METHOD("undistort_depth_image"), &Kinect::undistort_depth_image); // uses internal data types unknown to godot-cpp
}

Kinect::Kinect() {
    kinect_device = nullptr; // Initialize Kinect device handle
}

Kinect::~Kinect() {
    close_kinect(); // Ensure the Kinect device is closed
}

// function to pass log messages to the Godot Engine
void Kinect::kinect_log_callback(void *context, k4a_log_level_t level, const char *file, const int line, const char *message) {
    UtilityFunctions::print(String("[Kinect SDK] {0}:{1} - {2}").format(Array::make(file, line, message)));
}

bool Kinect::initialize_kinect(int device_index) {
    /** Enable SDK logging
     * K4A_LOG_LEVEL_CRITICAL: critical errors
     * K4A_LOG_LEVEL_ERROR: errors
     * K4A_LOG_LEVEL_WARNING: warnings
     * K4A_LOG_LEVEL_INFO: informational messages
     * K4A_LOG_LEVEL_TRACE: detailed trace messages
     */ 
    k4a_set_debug_message_handler(kinect_log_callback, nullptr, K4A_LOG_LEVEL_WARNING);

    if (k4a_device_open(device_index, &kinect_device) == K4A_RESULT_SUCCEEDED) {
        config = K4A_DEVICE_CONFIG_INIT_DISABLE_ALL;
        config.depth_mode = K4A_DEPTH_MODE_NFOV_UNBINNED; // Set depth mode
        config.color_resolution = K4A_COLOR_RESOLUTION_720P; // Enable color camera
        config.color_format = K4A_IMAGE_FORMAT_COLOR_BGRA32; // Set color format
        config.camera_fps = K4A_FRAMES_PER_SECOND_30; // Set frame rate

        UtilityFunctions::print("Kinect device initialized successfully.");
        return true;

    } else {
        UtilityFunctions::print("Failed to initialize Kinect device.");
    }

    return false;
}

// function to return to print camera parameters for use in shader to counter distortion
Array Kinect::extract_camera_parameters(bool print) {
    k4a_calibration_t calibration;
    Array depth_params_array;
    if (k4a_device_get_calibration(kinect_device, config.depth_mode, config.color_resolution, &calibration) == K4A_RESULT_SUCCEEDED) {
        auto depth_params = calibration.depth_camera_calibration.intrinsics.parameters.param;
        if (print) {
            UtilityFunctions::print("DEPTH CAMERA INTRINSICS:");
            // for direct copy to the shader
            UtilityFunctions::print("// focal length");
            UtilityFunctions::print(String("uniform float fx = {0};").format(Array::make(depth_params.fx)));
            UtilityFunctions::print(String("uniform float fy = {0};").format(Array::make(depth_params.fy)));
            UtilityFunctions::print("// principal point");
            UtilityFunctions::print(String("uniform float cx = {0};").format(Array::make(depth_params.cx)));
            UtilityFunctions::print(String("uniform float cy = {0};").format(Array::make(depth_params.cy)));
            UtilityFunctions::print("// radial distortion");
            UtilityFunctions::print(String("uniform float k1 = {0};").format(Array::make(depth_params.k1)));
            UtilityFunctions::print(String("uniform float k2 = {0};").format(Array::make(depth_params.k2)));
            UtilityFunctions::print(String("uniform float k3 = {0};").format(Array::make(depth_params.k3)));
            UtilityFunctions::print(String("uniform float k4 = {0};").format(Array::make(depth_params.k4)));
            UtilityFunctions::print(String("uniform float k5 = {0};").format(Array::make(depth_params.k5)));
            UtilityFunctions::print(String("uniform float k6 = {0};").format(Array::make(depth_params.k6)));
            UtilityFunctions::print("// tangential distortion");
            UtilityFunctions::print(String("uniform float p1 = {0};").format(Array::make(depth_params.p1)));
            UtilityFunctions::print(String("uniform float p2 = {0};").format(Array::make(depth_params.p2)));
        }
        depth_params_array.push_back(depth_params.fx);
        depth_params_array.push_back(depth_params.fy);
        depth_params_array.push_back(depth_params.cx);
        depth_params_array.push_back(depth_params.cy);
        depth_params_array.push_back(depth_params.k1);
        depth_params_array.push_back(depth_params.k2);
        depth_params_array.push_back(depth_params.k3);
        depth_params_array.push_back(depth_params.k4);
        depth_params_array.push_back(depth_params.k5);
        depth_params_array.push_back(depth_params.k6);
        depth_params_array.push_back(depth_params.p1);
        depth_params_array.push_back(depth_params.p2);
    } else {
        UtilityFunctions::print("Failed to get calibration data from the Kinect");
    }
    return depth_params_array;
}

bool Kinect::start_cameras() {
    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return false;
    }

    if (cameras_running) {
        UtilityFunctions::print("Cameras are already running.");
        return true; // Cameras are already running, no need to start them again
    }

    // start cameras
    if (k4a_device_start_cameras(kinect_device, &config) == K4A_RESULT_SUCCEEDED) {
        cameras_running = true;
        UtilityFunctions::print("Kinect cameras started successfully.");
        return true;
    } 
    UtilityFunctions::print("Failed to start Kinect cameras.");
    k4a_device_close(kinect_device);
    kinect_device = nullptr;
    return false;
}

bool Kinect::stop_cameras() {
    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return false;
    }

    if (!cameras_running) {
        UtilityFunctions::print("Cameras are not running.");
        return true; // Cameras are already stopped
    }

    k4a_device_stop_cameras(kinect_device);
    cameras_running = false;
    UtilityFunctions::print("Kinect cameras stopped successfully.");
    return true;
}

void Kinect::close_kinect() {
    if (kinect_device != nullptr) {
        if (cameras_running) {
            stop_cameras(); // Stop cameras before closing the device
        }
        k4a_device_close(kinect_device);
        kinect_device = nullptr;
        UtilityFunctions::print("Kinect device closed.");
    }
}

int Kinect::get_connected_device_count() {
    return k4a_device_get_installed_count();
}

Ref<Image> Kinect::get_depth_image_rf() {
    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return nullptr;
    }

    k4a_capture_t capture = nullptr;
    if (k4a_device_get_capture(kinect_device, &capture, 5000) != K4A_WAIT_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to capture frame.");
        return nullptr;
    }

    k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
    if (depth_image == nullptr) {
        UtilityFunctions::print("Failed to get depth image.");
        k4a_capture_release(capture);
        return nullptr;
    }

    uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));
    int width = k4a_image_get_width_pixels(depth_image);
    int height = k4a_image_get_height_pixels(depth_image);

    Ref<Image> image = Image::create(width, height, false, Image::FORMAT_RF);

    float *image_data = reinterpret_cast<float *>(image->ptrw());
    const float max_depth_mm = 512.0f; // Maximum depth range in millimeters
    for (size_t i = 0; i < width * height; i++) {
        image_data[i] = static_cast<float>(buffer[i]) / max_depth_mm; // Normalize depth to [0.0, 1.0]
    }

    k4a_image_release(depth_image);
    k4a_capture_release(capture);

    return image;
}

Ref<ImageTexture> Kinect::get_depth_texture_rf() {
    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return nullptr;
    }

    k4a_capture_t capture = nullptr;
    if (k4a_device_get_capture(kinect_device, &capture, 5000) != K4A_WAIT_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to capture frame.");
        return nullptr;
    }

    k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
    if (depth_image == nullptr) {
        UtilityFunctions::print("Failed to get depth image.");
        k4a_capture_release(capture);
        return nullptr;
    }

    uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));
    int width = k4a_image_get_width_pixels(depth_image);
    int height = k4a_image_get_height_pixels(depth_image);

    Ref<Image> image = Image::create(width, height, false, Image::FORMAT_RF);

    float *image_data = reinterpret_cast<float *>(image->ptrw());
    const float max_depth_mm = 1400.0f; // Maximum depth range in millimeters
    for (size_t i = 0; i < width * height; i++) {
        image_data[i] = static_cast<float>(buffer[i]) / max_depth_mm; // Normalize depth to [0.0, 1.0]
    }

    depth_texture = ImageTexture::create_from_image(image);

    k4a_image_release(depth_image);
    k4a_capture_release(capture);

    return depth_texture;
}

// get one Godot Image from the kinect in format FORMAT_RG8
Ref<Image> Kinect::get_depth_image_rg8() {
    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return nullptr;
    }

    // get a capture from the Kinect
    k4a_capture_t capture = nullptr;
    if (k4a_device_get_capture(kinect_device, &capture, 1000) != K4A_WAIT_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to capture frame.");
        return nullptr;
    }

    // get the depth image from the capture
    k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
    if (depth_image == nullptr) {
        UtilityFunctions::print("Failed to get depth image.");
        k4a_capture_release(capture);
        return nullptr;
    }

    // get the buffer location where the depth image is located
    uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));
    int width = k4a_image_get_width_pixels(depth_image); // width of depth image in pixels (640)
    int height = k4a_image_get_height_pixels(depth_image); // height of depth image in pixels (576)

    // create a Godot Image with the dimensions of the depth image and the format FORMAT_RG8 (8bit red channel + 8bit green channel)
    Ref<Image> depth = Image::create(width, height, false, Image::FORMAT_RG8);
    // copy the buffer containing the depth image into the Godot Image
    memcpy(depth->ptrw(), buffer, width * height * sizeof(uint16_t));
    
    // free memory of depth image and capture
    k4a_image_release(depth_image);
    k4a_capture_release(capture);

    return depth;
}

Array Kinect::get_depth_and_color_image_rg8() {
    Array frame_data;

    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return frame_data;
    }

    k4a_capture_t capture = nullptr;
    if (k4a_device_get_capture(kinect_device, &capture, 5000) != K4A_WAIT_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to capture frame.");
        return frame_data;
    }

    // get the depth image
    k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
    if (depth_image == nullptr) {
        UtilityFunctions::print("Failed to get depth image.");
        k4a_image_release(depth_image);
    } else {
        uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));
        int width = k4a_image_get_width_pixels(depth_image);
        int height = k4a_image_get_height_pixels(depth_image);

        Ref<Image> depth = Image::create(width, height, false, Image::FORMAT_RG8);
        memcpy(depth->ptrw(), buffer, width * height * sizeof(uint16_t));

        frame_data.append(depth);
        k4a_image_release(depth_image);
    }

    // get the color image
    k4a_image_t color_image = k4a_capture_get_color_image(capture);
    //UtilityFunctions::print(k4a_image_get_format(color_image));
    if (color_image == nullptr) {
        UtilityFunctions::print("Failed to get color image.");
        k4a_image_release(color_image);
    } else {
        uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(color_image));
        int width = k4a_image_get_width_pixels(color_image);
        int height = k4a_image_get_height_pixels(color_image);

        Ref<Image> color = Image::create(width, height, false, Image::FORMAT_RGBA8);
        memcpy(color->ptrw(), buffer, width * height * 4);

        frame_data.append(color);
        k4a_image_release(color_image);
    }

    k4a_capture_release(capture);

    return frame_data;
}

Ref<ImageTexture> Kinect::get_depth_texture_rg8() {
    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return nullptr;
    }

    k4a_capture_t capture = nullptr;
    if (k4a_device_get_capture(kinect_device, &capture, 5000) != K4A_WAIT_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to capture frame.");
        return nullptr;
    }

    k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
    if (depth_image == nullptr) {
        UtilityFunctions::print("Failed to get depth image.");
        k4a_capture_release(capture);
        return nullptr;
    }

    uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));
    int width = k4a_image_get_width_pixels(depth_image);
    int height = k4a_image_get_height_pixels(depth_image);

    Ref<Image> image = Image::create(width, height, false, Image::FORMAT_RG8);
    memcpy(image->ptrw(), buffer, width * height * sizeof(uint16_t));

    depth_texture = ImageTexture::create_from_image(image);

    k4a_image_release(depth_image);
    k4a_capture_release(capture);

    return depth_texture;
}

Ref<ImageTexture> Kinect::get_placeholder_texture() {
    Ref<ImageTexture> depth_texture;
    Ref<Image> test_image;

    test_image = Image::create(256, 256, false, Image::FORMAT_L8);
    test_image->fill(Color(1, 1, 1)); // Fill with white

    depth_texture = ImageTexture::create_from_image(test_image);

    if (depth_texture->get_size() == Vector2(0, 0)) {
        UtilityFunctions::print("Failed to create ImageTexture from placeholder.");
    } else {
        UtilityFunctions::print(String("Placeholder ImageTexture created successfully with size: {0}")
            .format(Array::make(depth_texture->get_size())));
    }

    return depth_texture;
}

// function to playback mkv files and return an array of Dictionaries containing depth and color images
Array Kinect::playback_mkv(const String &file_path) {
    k4a_playback_t playback_handle = nullptr;
    Array images;

    // Convert Godot String to a standard C string
    std::string file_path_std = file_path.utf8().get_data();
    UtilityFunctions::print(file_path_std.c_str());

    // Open the MKV file
    if (k4a_playback_open(file_path_std.c_str(), &playback_handle) != K4A_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to open MKV file.");
        return images;
    }

    UtilityFunctions::print("MKV file opened successfully.");

    // Retrieve recording length
    uint64_t recording_length_usec = k4a_playback_get_recording_length_usec(playback_handle);
    UtilityFunctions::print(String("Recording length: {0} microseconds").format(Array::make(recording_length_usec)));

    // Read the recording configuration
    k4a_record_configuration_t config;
    if (k4a_playback_get_record_configuration(playback_handle, &config) != K4A_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to get recording configuration.");
        k4a_playback_close(playback_handle);
        return images;
    }

    UtilityFunctions::print(String("Playback configuration: Depth mode: {0}, Color resolution: {1}, FPS: {2}")
        .format(Array::make(config.depth_mode, config.color_resolution, config.camera_fps)));

    // Seek to the beginning of the recording
    if (k4a_playback_seek_timestamp(playback_handle, 0, K4A_PLAYBACK_SEEK_BEGIN) != K4A_RESULT_SUCCEEDED) {
        UtilityFunctions::print("Failed to seek to the beginning of the recording.");
        k4a_playback_close(playback_handle);
        return images;
    }

    // Read frames from the MKV file
    k4a_capture_t capture = nullptr;
    while (true) {
        k4a_stream_result_t result = k4a_playback_get_next_capture(playback_handle, &capture);
        if (result == K4A_STREAM_RESULT_FAILED) {
            UtilityFunctions::print("Failed to get next capture.");
            break;
        } else if (result == K4A_STREAM_RESULT_EOF) {
            UtilityFunctions::print("End of file reached.");
            break;
        }
        Dictionary frame_data;

        // Process the depth data
        k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
        if (depth_image != nullptr) {
            uint16_t *buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));
            int width = k4a_image_get_width_pixels(depth_image);
            int height = k4a_image_get_height_pixels(depth_image);

            // Create a Godot Image
            Ref<Image> image = Image::create(width, height, false, Image::FORMAT_RG8);

            // Undistort the depth image
            k4a_calibration_t camera_calibration;
            if (k4a_device_get_calibration(kinect_device, config.depth_mode, config.color_resolution, &camera_calibration) != K4A_RESULT_SUCCEEDED) {
                UtilityFunctions::print("Failed to get camera calibration.");
                return images;
            }
            undistort_depth_image(camera_calibration, depth_image, image);
            
            //memcpy(image->ptrw(), buffer, width * height * sizeof(uint16_t));

            // Add the image to the array
            frame_data["depth"] = image;

            k4a_image_release(depth_image);
        }

        // Process the color data
        k4a_image_t color_image = k4a_capture_get_color_image(capture);
        if (color_image != nullptr) {
            //UtilityFunctions::print(k4a_image_get_format(color_image));

            uint8_t *buffer = k4a_image_get_buffer(color_image);
            size_t buffer_size = k4a_image_get_size(color_image);

            int width, height, channels;
            // use of stb_image for the conversion from jpg
            unsigned char *decoded_data = stbi_load_from_memory(buffer, buffer_size, &width, &height, &channels, 3); // Decode as RGB

            UtilityFunctions::print("width: " + String::num_int64(width) + ", height: " + String::num_int64(height) + ", channels: " + String::num_int64(channels));

            if (decoded_data != nullptr) {
                Ref<Image> image = Image::create(width, height, false, Image::FORMAT_RGB8);
                memcpy(image->ptrw(), decoded_data, width * height * 3);
                frame_data["color"] = image;
            } else {
                UtilityFunctions::print("Invalid color image data.");
            }

            k4a_image_release(color_image);
        }
        images.append(frame_data);

        k4a_capture_release(capture);
    }

    // Close the playback handle
    k4a_playback_close(playback_handle);
    UtilityFunctions::print("MKV playback finished.");

    return images;
}

// for now internal function to undistort depth images
// bad code, maybe needs a compute shader later on or a way to save calibration and apply it fast to all depth images
void Kinect::undistort_depth_image(k4a_calibration_t &camera_calibration, k4a_image_t depth_image, Ref<Image> &undistorted_image) {
    //UtilityFunctions::print("calibration started");
    int width = k4a_image_get_width_pixels(depth_image);
    int height = k4a_image_get_height_pixels(depth_image);
    uint16_t *depth_buffer = reinterpret_cast<uint16_t *>(k4a_image_get_buffer(depth_image));

    // Create a Godot Image for the undistorted depth image
    undistorted_image = Image::create(width, height, false, Image::FORMAT_RG8);
    uint16_t *undistorted_buffer = reinterpret_cast<uint16_t *>(undistorted_image->ptrw());
    //UtilityFunctions::print("in front of loop");
    // Iterate over each pixel in the depth image
    for (int y = 0; y < height; y++) {
        //UtilityFunctions::print("y: " + String::num_int64(y));
        for (int x = 0; x < width; x++) {
            //UtilityFunctions::print("x: " + String::num_int64(x));
            k4a_float2_t pixel = {static_cast<float>(x), static_cast<float>(y)};
            k4a_float3_t ray;
            int valid;

            //UtilityFunctions::print("in front of 2d to 3d calibration");
            // Map the 2D pixel to a 3D ray in the camera's coordinate system
            k4a_calibration_2d_to_3d(&camera_calibration, &pixel, depth_buffer[y * width + x],
                                     K4A_CALIBRATION_TYPE_DEPTH, K4A_CALIBRATION_TYPE_DEPTH, &ray, &valid);
            //UtilityFunctions::print("after 2d to 3d calibration");
            if (valid) {
                // Map the 3D ray back to 2D undistorted pixel coordinates
                k4a_float2_t undistorted_pixel;
                k4a_calibration_3d_to_2d(&camera_calibration, &ray, K4A_CALIBRATION_TYPE_DEPTH, K4A_CALIBRATION_TYPE_DEPTH, &undistorted_pixel, &valid);

                if (valid) {
                    int undistorted_x = static_cast<int>(undistorted_pixel.xy.x + 0.5f);
                    int undistorted_y = static_cast<int>(undistorted_pixel.xy.y + 0.5f);

                    // Ensure the undistorted pixel is within bounds
                    if (undistorted_x >= 0 && undistorted_x < width && undistorted_y >= 0 && undistorted_y < height) {
                        undistorted_buffer[undistorted_y * width + undistorted_x] = depth_buffer[y * width + x];
                    }
                }
            }
        }
    }
}