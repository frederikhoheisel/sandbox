extends Window

## Creates a window on the second screen for the projection on the sand surface

@export var enable_projector: bool
@export var sandbox: AnimatableBody3D

var calibration_meshes: Array
var calibrating: bool = false

@onready var camera_3d: Camera3D = $SubViewport/Camera3D
@onready var callibration_mesh_container: Node = %CallibrationMeshContainer


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
	#_transform_projector_camera()
	if not enable_projector:
		self.queue_free()
	#sandbox_width = abs(sandbox_pos[0]) + abs(sandbox_pos[1])
	#sandbox_height = abs(sandbox_pos[2]) + abs(sandbox_pos[3])
	#sandbox_size = Vector2(sandbox_width, sandbox_height)
	#sandbox_center = Vector2((sandbox_pos[0] + sandbox_pos[1]) / 2.0, (sandbox_pos[2] + sandbox_pos[3]) / 2.0)
	#$"../MeshInstance3D".position = Vector3(sandbox_center.x, -10.0, sandbox_center.y)
	#$"../MeshInstance3D".mesh.size = Vector3(sandbox_width, 1.0, sandbox_height)
	calibration_meshes = callibration_mesh_container.get_children()


func _process(_delta: float) -> void:
	if calibrating:
		_position_corners()
	if Input.is_action_just_pressed("calibrate"):
		_start_callibration()


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

func _start_callibration() -> void:
	print("--- CALIBRATION STARTED ---")
	print("position the sqaures to the corners of the sandbox using the arrow keys")
	print("press 'tab' to select the next square")
	
	%MeshInstance3D.visible = false
	
	for corner in calibration_meshes:
		corner.visible = true
	
	calibration_meshes[0].position = Vector3(20.0, 0.0, 20.0)
	calibration_meshes[1].position = Vector3(-20.0, 0.0, 20.0)
	calibration_meshes[2].position = Vector3(20.0, 0.0, -20.0)
	calibration_meshes[3].position = Vector3(-20.0, 0.0, -20.0)
	
	current_callibration_mesh = 0
	calibration_meshes[current_callibration_mesh].mesh.material.albedo_color = Color.CYAN
	calibrating = true


var current_callibration_mesh: int = 0
func _position_corners() -> void:
	var direction = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up") * 0.05
	calibration_meshes[current_callibration_mesh].position += Vector3(direction.x, 0.0, direction.y)
	
	if Input.is_action_just_pressed("next_callibration_point"):
		calibration_meshes[current_callibration_mesh].mesh.material.albedo_color = Color.RED
		if current_callibration_mesh >= 3:
			calibrating = false
			_callibrate_projector()
			return
		current_callibration_mesh += 1
		calibration_meshes[current_callibration_mesh].mesh.material.albedo_color = Color.CYAN


func _callibrate_projector():
	var corners: Array[Vector3]
	for corner in calibration_meshes:
		corner.visible = false
		corners.append(corner.position)
	#print(corners)
	
	var center: Vector3 = (corners[0] + corners[1] + corners[2] + corners[3] + Vector3(5.2, 0.0, 14.56)) * 0.25
	
	printt("center:", center)
	sandbox.position = Vector3(center.x, sandbox.global_position.y, center.z)
	
	#camera_3d.position = Vector3(
		#center.x,
		#100.0,
		#center.z
	#)
	
	#print(sandbox.global_position)
	var scale = 20.0 * ((corners[0].z - corners[2].z + corners[1].z - corners[3].z) / 200.0)
	printt("scale:", scale)
	#camera_3d.size = (corners[0].z - corners[2].z + corners[1].z - corners[3].z) / 2.0
	#print(camera_3d.size)
	sandbox.SANDBOX_SCALE = scale
	#print(sandbox.SANDBOX_SCALE)
	sandbox.refresh_scale()
	
	%MeshInstance3D.visible = true


func print_cam_params():
	printt("position: ", pos)
	printt("fov_size: ", fov_size)
	printt("x rot: ", rotation_deg_x)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print_cam_params()
