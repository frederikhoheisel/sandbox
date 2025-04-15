#ifndef KINECT_H
#define KINECT_H

#include <godot_cpp/classes/sprite2d.hpp>
#include <k4a/k4a.h>

namespace godot {

class Kinect : public Node {
	GDCLASS(Kinect, Node)

	private:
    k4a_device_t kinect_device; // Handle for the Kinect device
    k4a_device_configuration_t config; // Store the configuration
    bool cameras_running = false; // Flag to check if cameras are running

protected:
    static void _bind_methods();

public:
    Kinect();
    ~Kinect();

    static void kinect_log_callback(void *context, k4a_log_level_t level, const char *file, const int line, const char *message);
    bool initialize_kinect(int device_index = 0);
    void close_kinect();
    bool start_cameras();
    bool stop_cameras();
    int get_connected_device_count();
    PackedByteArray get_depth_image();
};

}

#endif