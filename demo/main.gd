extends Node3D

@onready var kinect : Kinect = $Kinect
var running : bool = false
var depth_texture : ImageTexture

func _ready() -> void:
	kinect.initialize_kinect(0)
	kinect.start_cameras()
	depth_texture = kinect.get_depth_texture()
	#print($MeshInstance3D.surface_material_override)
	# Ensure material_override is a ShaderMaterial
	if $MeshInstance3D.material_override == null:
		var shader = Shader.new()
		shader.code = preload("res://terrain.gdshader").get_code()
		var material = ShaderMaterial.new()
		material.shader = shader
		$MeshInstance3D.material_override = material

	# Debug print to confirm material assignment
	print("Material override assigned:", $MeshInstance3D.material_override)

	# Set the depth texture
	var material = $MeshInstance3D.material_override
	if material is ShaderMaterial:
		material.set_shader_param("depth_texture", depth_texture)
	else:
		print("Material override is not a ShaderMaterial!")

func _process(_delta) -> void:
	if Input.is_action_just_pressed("take_image"):
		running = false if running else true
	if running:
		depth_texture = kinect.get_depth_texture()
		$Sprite2D.texture = depth_texture

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kinect.close_kinect()
		get_tree().quit()
