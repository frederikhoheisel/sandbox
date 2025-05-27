extends AnimatableBody3D


@export var kinect: Kinect
@export var image_conversion: Node
@export var filtered_texture: Sprite2D

@onready var collision_shape := %CollisionShape3D

var heightmap_shape := HeightMapShape3D.new()

var running := false
var depth_texture : ImageTexture

const WIDTH := 10.0
const DEPTH := 9.0
const PIXEL_WIDTH := 640
const PIXEL_DEPTH := 576

const sandbox_scale := .5

func _ready() -> void:
	## setup of the plane mesh
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(WIDTH, DEPTH)
	mesh.subdivide_width = PIXEL_WIDTH
	mesh.subdivide_depth = PIXEL_DEPTH
	%MeshInstance3D.mesh = mesh
	%MeshInstance3D.scale *= sandbox_scale
	
	## no culling for the terrain mesh
	## solved by increasing extra cull margin on %MeshInstance3D
	# var id = %MeshInstance3D.get_instance_id()
	# RenderingServer.instance_set_ignore_culling(id, true)
	
	## setup of the material and corresponding shader for the FilteredTexture
	## directly done in the editor
	#var filter_shader := load("res://texture_filter.gdshader")
	#var filter_material := ShaderMaterial.new()
	#filter_material.shader = filter_shader
	
	## setup of the material and corresponding shader for the terrain
	var terrain_shader := load("res://terrain.gdshader")
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	
	## setup of the collision shape
	heightmap_shape.map_width = 2
	heightmap_shape.map_depth = 2
	collision_shape.shape = heightmap_shape
	collision_shape.scale = Vector3(WIDTH / PIXEL_WIDTH, -10.0, DEPTH / PIXEL_DEPTH)
	collision_shape.scale *= sandbox_scale
	
	## start the kinect and cameras
	kinect.initialize_kinect(0)
	kinect.start_cameras()
	
	## do everything once
	depth_texture = kinect.get_depth_texture_rf()
	var modified_texture := await filter_texture(depth_texture)
	%MeshInstance3D.material_override = terrain_material
	%MeshInstance3D.material_override.set("shader_parameter/depth_texture", modified_texture)
	set_heightmap(modified_texture)

## filters a texture with a shader and returns it
func filter_texture(texture: Texture2D) -> Texture2D:
	filtered_texture.texture = texture
	filtered_texture.material.set("shader_parameter/depth_texture", texture)
	await get_tree().process_frame
	return %SubViewport.get_texture()

## converts texture to image and applies it to the heightmapshape
func set_heightmap(texture: Texture2D) -> void:
	var image = texture.get_image()
	image.convert(Image.FORMAT_RF)
	heightmap_shape.update_map_data_from_image(image, 0.0, 1.0)

func _process(_delta) -> void:
	if Input.is_action_just_pressed("take_image"):
		running = false if running else true
		print("toggle recording to: " + str(running))
	if running:
		var texture = kinect.get_depth_texture_rf()
		var modified_texture = await filter_texture(texture)
		%MeshInstance3D.material_override.set("shader_parameter/depth_texture", modified_texture)
		set_heightmap(modified_texture)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kinect.close_kinect()
		get_tree().quit()
