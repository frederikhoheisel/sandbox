extends Node3D

@onready var kinect : Kinect = $Kinect
@onready var collision_shape := %CollisionShape3D
@onready var heightmap_shape := HeightMapShape3D.new()
@onready var image_conversion := $ImageConversion
var running := false
var depth_texture : ImageTexture

const WIDTH := 10.0
const DEPTH := 9.0
const PIXEL_WIDTH := 640
const PIXEL_DEPTH := 576

func _ready() -> void:
	# setup of the plane mesh
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(WIDTH, DEPTH)
	mesh.subdivide_width = PIXEL_WIDTH
	mesh.subdivide_depth = PIXEL_DEPTH
	%MeshInstance3D.mesh = mesh
	
	# setup of the material and corresponding shader
	var shader := load("res://terrain.gdshader")
	var material := ShaderMaterial.new()
	material.shader = shader
	
	# start the kinect and take one depth image to give to the shader
	kinect.initialize_kinect(0)
	kinect.start_cameras()
	depth_texture = kinect.get_depth_texture()
	material.set("shader_parameter/depth_texture", depth_texture)
	
	var depth_image_rg8 : Image = kinect.get_depth_image()
	var depth_image_rf : Image = image_conversion.process_image(depth_image_rg8)
	
	# setup of the collision shape
	heightmap_shape.map_width = 2
	heightmap_shape.map_depth = 2
	heightmap_shape.update_map_data_from_image(depth_image_rf, 0.0, 1.0)
	collision_shape.shape = heightmap_shape
	collision_shape.scale = Vector3(WIDTH / PIXEL_WIDTH, -3.0, DEPTH / PIXEL_DEPTH)
	
	"""
	# Debugging of the detph texture
	var img = depth_texture.get_image()
	print("=== Depth Texture Analysis ===")
	print("Resolution: ", img.get_width(), " x ", img.get_height())
	
	var min_val = 999999
	var max_val = 0
	var sample_points = [
		Vector2(0, 0),
		Vector2(img.get_width()/2, img.get_height()/2),
		Vector2(img.get_width()-1, img.get_height()-1)
	]
	for i in range(50):
		var random_x = randi() % img.get_width()
		var random_y = randi() % img.get_height()
		sample_points.append(Vector2(random_x, random_y))
	for point in sample_points:
		var pixel = img.get_pixel(int(point.x), int(point.y))
		var depth_value = pixel.r + pixel.g * 256.0
		print("Pixel at (", point.x, ",", point.y, "): R=", pixel.r, " G=", pixel.g, " Combined=", depth_value)
		min_val = min(min_val, depth_value)
		max_val = max(max_val, depth_value)
	print("Estimated depth range: ", min_val, " to ", max_val)
	print("===========================")
	"""
	
	%MeshInstance3D.material_override = material

func _process(_delta) -> void:
	if Input.is_action_just_pressed("take_image"):
		running = false if running else true
		print("toggle recording to: " + str(running))
	if running:
		depth_texture = kinect.get_depth_texture()
		%MeshInstance3D.material_override.set("shader_parameter/depth_texture", depth_texture)
		var image = kinect.get_depth_image()
		heightmap_shape.update_map_data_from_image(image_conversion.process_image(image), 0.0, 1.0)
		#$Sprite2D.texture = ImageTexture.create_from_image(image)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kinect.close_kinect()
		get_tree().quit()
