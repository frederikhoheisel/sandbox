extends Window

## Creates a window on the second screen for the projection on the sand surface

@export var enable_projector: bool

@onready var camera_3d: Camera3D = $SubViewport/Camera3D

var sandbox_pos: Array = [
		-40.3,	#left
		38.05,	#right
		-27.2,	#top -27.2
		22.75]	#bottom 22.75

var sandbox_center: Vector2
var sandbox_size: Vector2
var sandbox_width: float
var sandbox_height: float

func _ready() -> void:
	_transform_projector_camera()
	if not enable_projector:
		self.queue_free()
	sandbox_width = abs(sandbox_pos[0]) + abs(sandbox_pos[1])
	sandbox_height = abs(sandbox_pos[2]) + abs(sandbox_pos[3])
	sandbox_size = Vector2(sandbox_width, sandbox_height)
	sandbox_center = Vector2((sandbox_pos[0] + sandbox_pos[1]) / 2.0, (sandbox_pos[2] + sandbox_pos[3]) / 2.0)
	#$"../MeshInstance3D".position = Vector3(sandbox_center.x, -10.0, sandbox_center.y)
	#$"../MeshInstance3D".mesh.size = Vector3(sandbox_width, 1.0, sandbox_height)


## depricated
var tex_scale = Vector2(3.15, 3.52)
var tex_pos = Vector2(153.0, -48.0)
func scale_terrain_texture() -> void:
	if Input.is_action_just_pressed("scale_x_down"):
		print("scale_x_down")
		tex_scale.x += 0.01
		print(tex_scale)
	if Input.is_action_just_pressed("scale_x_up"):
		print("scale_x_up")
		tex_scale.x -= 0.01
		print(tex_scale)
	if Input.is_action_just_pressed("scale_y_down"):
		print("scale_y_down")
		tex_scale.y += 0.01
		print(tex_scale)
	if Input.is_action_just_pressed("scale_y_up"):
		print("scale_y_up")
		tex_scale.y -= 0.01
		print(tex_scale)
	$TerrainSprite2D.scale = tex_scale
	
	if Input.is_action_just_pressed("offset_x_up"):
		print("offset_x_up")
		tex_pos.x += 1.0
		print(tex_pos)
	if Input.is_action_just_pressed("offset_x_down"):
		print("offset_x_down")
		tex_pos.x -= 1.0
		print(tex_pos)
	if Input.is_action_just_pressed("offset_y_down"):
		print("offset_y_down")
		tex_pos.y += 1.0
		print(tex_pos)
	if Input.is_action_just_pressed("offset_y_up"):
		print("offset_y_up")
		tex_pos.y -= 1.0
		print(tex_pos)
	$TerrainSprite2D.position = tex_pos


var fov_size: float = 52.0 * 2.0
var pos: Vector3 = Vector3(0.0, 32.0, -2.6)
var rotation_deg_x: float = -90.0
func _transform_projector_camera() -> void:
	var dz := Input.get_axis("cam_back", "cam_for")
	var dy := Input.get_axis("cam_down", "cam_up")
	var dfov := Input.get_axis("cam_fov_down", "cam_fov_up")
	var drotx := Input.get_axis("cam_look_down", "cam_look_up")
	
	pos += Vector3(0.0, dy, dz) * 0.1
	fov_size += dfov * 0.1
	rotation_deg_x += drotx * 0.1
	
	camera_3d.position = pos
	camera_3d.size = fov_size
	camera_3d.rotation_degrees.x = rotation_deg_x

func print_cam_params():
	printt("position: ", pos)
	printt("fov_size: ", fov_size)
	printt("x rot: ", rotation_deg_x)
