extends Node

@onready var kinect : Kinect = $Kinect

func _ready() -> void:
	kinect.initialize_kinect(0)
	kinect.start_cameras()

func _process(_delta) -> void:
	var depth_texture = kinect.get_depth_texture()
	$Sprite2D.texture = depth_texture
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kinect.close_kinect()
		get_tree().quit()
