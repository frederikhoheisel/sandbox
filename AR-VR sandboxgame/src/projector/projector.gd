extends Window

@onready var sprite_2d: Sprite2D = $Sprite2D
@export var track_obj: Node3D
@export var cut_depth_texture: Texture2D
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
	if not enable_projector:
		self.queue_free()
	sandbox_width = abs(sandbox_pos[0]) + abs(sandbox_pos[1])
	sandbox_height = abs(sandbox_pos[2]) + abs(sandbox_pos[3])
	sandbox_size = Vector2(sandbox_width, sandbox_height)
	sandbox_center = Vector2((sandbox_pos[0] + sandbox_pos[1]) / 2.0, (sandbox_pos[2] + sandbox_pos[3]) / 2.0)
	#$"../MeshInstance3D".position = Vector3(sandbox_center.x, -10.0, sandbox_center.y)
	#$"../MeshInstance3D".mesh.size = Vector3(sandbox_width, 1.0, sandbox_height)
	
	## XROrigin is not moving, need to get the plyer body to track
	if track_obj is XROrigin3D:
		track_obj = track_obj.get_child(3)

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

func _process(_delta: float) -> void:
	var track_pos_2d = Vector2(track_obj.position.x, track_obj.position.z) * Vector2(0.85, 0.95) + sandbox_size / 2.0
	var track_pos_2d_normalized = track_pos_2d / sandbox_size * Vector2(1920.0, 1080.0)
	sprite_2d.position = track_pos_2d_normalized + Vector2(0.0, 50.0)
	sprite_2d.rotation = -track_obj.rotation.y

func _physics_process(_delta: float) -> void:
	#$TerrainSprite2D.texture = cut_depth_texture
	#scale_terrain_texture()
	#print(sprite_2d.position)
	#print(str(track_obj.position.x) + "  " + str(track_obj.position.z))
	_transform_projector_camera()

var fov: float = 69.0
var pos: Vector3 = Vector3(0.0, 25.0, 0.0)
var rotation_deg_x: float = -90.0
func _transform_projector_camera() -> void:
	var dx := Input.get_axis("cam_left", "cam_right")
	var dz := Input.get_axis("cam_back", "cam_for")
	var dy := Input.get_axis("cam_down", "cam_up")
	var dfov := Input.get_axis("cam_fov_down", "cam_fov_up")
	var drotx := Input.get_axis("cam_look_down", "cam_look_up")
	
	pos += Vector3(0.0, dy, dz) * 0.1
	fov += dfov * 0.1
	rotation_deg_x += drotx * 0.1
	
	camera_3d.position = pos
	camera_3d.fov = fov
	camera_3d.rotation_degrees.x = rotation_deg_x

func print_cam_params():
	printt("position: ", pos)
	printt("fov: ", fov)
	printt("x rot: ", rotation_deg_x)
