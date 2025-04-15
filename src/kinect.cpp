#include "kinect.h"
#include <godot_cpp/core/class_db.hpp>
#include <k4a/k4a.h>

using namespace godot;

void Kinect::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize_kinect", "device_index"), &Kinect::initialize_kinect);
    ClassDB::bind_method(D_METHOD("close_kinect"), &Kinect::close_kinect);
    ClassDB::bind_method(D_METHOD("get_connected_device_count"), &Kinect::get_connected_device_count);
    ClassDB::bind_method(D_METHOD("get_depth_image"), &Kinect::get_depth_image);
    ClassDB::bind_method(D_METHOD("start_cameras"), &Kinect::start_cameras);
    ClassDB::bind_method(D_METHOD("stop_cameras"), &Kinect::stop_cameras);
}

Kinect::Kinect() {
    kinect_device = nullptr; // Initialize Kinect device handle
}

Kinect::~Kinect() {
    close_kinect(); // Ensure the Kinect device is closed
}

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
        config.camera_fps = K4A_FRAMES_PER_SECOND_5; // Set frame rate

        UtilityFunctions::print("Kinect device initialized successfully.");
        return true;

    } else {
        UtilityFunctions::print("Failed to initialize Kinect device.");
    }

    return false;
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

PackedByteArray Kinect::get_depth_image() {
    PackedByteArray depth_data;

    if (kinect_device == nullptr) {
        UtilityFunctions::print("Kinect device is not initialized.");
        return depth_data;
    }

    k4a_capture_t capture = nullptr;
    if (k4a_device_get_capture(kinect_device, &capture, 3000) == K4A_WAIT_RESULT_SUCCEEDED) {
        k4a_image_t depth_image = k4a_capture_get_depth_image(capture);
        if (depth_image != nullptr) {
            uint8_t *buffer = k4a_image_get_buffer(depth_image);
            size_t buffer_size = k4a_image_get_size(depth_image);

            depth_data.resize(buffer_size);
            memcpy(depth_data.ptrw(), buffer, buffer_size);

            k4a_image_release(depth_image);
        } else {
            UtilityFunctions::print("Failed to get depth image.");
        }

        k4a_capture_release(capture);
    } else {
        UtilityFunctions::print("Failed to capture frame.");
    }

    return depth_data;
}