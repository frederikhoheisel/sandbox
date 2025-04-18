extends Node3D

@onready var kinect : Kinect = $Kinect
var running : bool = false
var depth_texture : ImageTexture

func _ready() -> void:
	kinect.initialize_kinect(0)
	kinect.start_cameras()
	depth_texture = kinect.get_depth_texture()

func _process(_delta) -> void:
	if Input.is_action_just_pressed("take_image"):
		running = false if running else true
		print("toggle recording to: " + str(running))
	if running:
		depth_texture = kinect.get_depth_texture()
		$Sprite2D.texture = depth_texture

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kinect.close_kinect()
		get_tree().quit()
