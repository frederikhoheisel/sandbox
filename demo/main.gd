extends Node

@onready var kinect = $Kinect

func _ready():
	if kinect.initialize_kinect(0):
		#print("Kinect initialized!")
		if kinect.start_cameras():
			#print("Cameras started!")
			var depth_image = kinect.get_depth_image()
			if depth_image.size() > 0:
				print("Depth image captured, size:", depth_image.size())
			else:
				print("Failed to capture depth image.")
		else:
			pass
			#print("Failed to start cameras.")
	else:
		pass
		#print("Failed to initialize Kinect.")
