extends AnimatableBody3D

## Creates an 3D mesh with corresponding collision shape from the kinect.
## Handles communicating the Kinect and starting the game.

@export var image_conversion: Node

@export var use_kinect: bool = true
@export var use_color_image: bool = true

@onready var kinect: Kinect = %Kinect
@onready var collision_shape := %CollisionShape3D
@onready var depth_test_ray_cast_3d: RayCast3D = %DepthTestRayCast3D

var heightmap_shape := HeightMapShape3D.new()

var running := false
var game_running: bool = false

const WIDTH := 10.0
const DEPTH := 9.0
const PIXEL_WIDTH := 640
const PIXEL_DEPTH := 576

const SANDBOX_SCALE := 20.0
var down_scale_factor: float = 8.0 # for downscaling the collision shape
var thread: Thread

var sandbox_rect: Rect2
var mesh: PlaneMesh


func _ready() -> void:
	sandbox_rect = Rect2(cut_box.x * PIXEL_WIDTH, cut_box.z * PIXEL_DEPTH, (cut_box.y - cut_box.x) * PIXEL_WIDTH, (cut_box.w - cut_box.z) * PIXEL_DEPTH)
	## setup of the plane mesh
	mesh = PlaneMesh.new()
	mesh.size = Vector2(WIDTH, DEPTH)
	mesh.subdivide_width = PIXEL_WIDTH
	mesh.subdivide_depth = PIXEL_DEPTH
	%MeshInstance3D.mesh = mesh
	%MeshInstance3D.scale *= SANDBOX_SCALE
	
	## setup of the material and corresponding shader for the terrain
	var terrain_shader := load("res://src/sandbox/terrain.gdshader")
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	mesh.material = terrain_material
	
	## setup of the collision shape
	heightmap_shape.map_width = 2
	heightmap_shape.map_depth = 2
	collision_shape.shape = heightmap_shape
	collision_shape.scale = Vector3(WIDTH / PIXEL_WIDTH, -10.0, DEPTH / PIXEL_DEPTH)
	collision_shape.scale *= SANDBOX_SCALE
	collision_shape.scale *= Vector3(down_scale_factor, 1.0, down_scale_factor)
	
	## enable or disable the color image in the shader
	mesh.material.set("shader_parameter/use_real_colors", use_color_image)
	
	## start the kinect and cameras if enabled
	if use_kinect:
		kinect.initialize_kinect(0)
		kinect.start_cameras()
	
		## do everything a bit
		var image_rg8
		for _i in 20:
			if use_color_image:
				image_rg8 = kinect.get_depth_and_color_image_rg8()
			else:
				image_rg8 = kinect.get_depth_image_rg8()
			await get_tree().process_frame # for some reason needs to wait 2 frames to work properly
			
			finish_update_depth(image_rg8)
		
		# extract the camera intrinsics and apply them to the shader
		# currently broken
		#var depth_params: Array = kinect.extract_camera_parameters(false)
		#if not depth_params.is_empty():
			#filter_texture.set_lens_distortion_params(depth_params)
	
	adjust_position_of_sandbox()
	
	## initialise thred
	thread = Thread.new()

## moves the sandbox so the center is positioned 5 meters below the VR user
func adjust_position_of_sandbox() -> void:
	depth_test_ray_cast_3d.force_raycast_update()
	var depth = depth_test_ray_cast_3d.get_collision_point().y
	#print(depth)
	self.position.y = -5.0 - depth


## downsamples the filtered depth image and applies it to the heightmapshape to update the collision shape
func set_heightmap(image: Image) -> void:
	var heightmap_image = image.duplicate()
	# the actual resizing
	heightmap_image.resize(
			image.get_width() / down_scale_factor,
			image.get_height() / down_scale_factor, 
			Image.INTERPOLATE_BILINEAR)
	heightmap_shape.update_map_data_from_image(heightmap_image, 0.0, 1.0)
	#printt(heightmap_shape.get_max_height(), heightmap_shape.get_min_height())

## helper function to adjust the color image and fit it to the depth data
## it can only be used when the kinect streams color images as well
## currently not working
var color_img_scale: Vector2 = Vector2(0.455, 0.791)
var color_img_offset: Vector2 = Vector2(-0.017, 0.016)
func fit_color_image() -> void:
	# scale
	if Input.is_action_just_pressed("scale_x_up"):
		color_img_scale.x += 0.001
		print("scale_x_up to " + str(color_img_scale.x))
	if Input.is_action_just_pressed("scale_x_down"):
		color_img_scale.x -= 0.001
		print("scale_x_down to " + str(color_img_scale.x))
	if Input.is_action_just_pressed("scale_y_up"):
		color_img_scale.y += 0.001
		print("scale_y_up to " + str(color_img_scale.y))
	if Input.is_action_just_pressed("scale_y_down"):
		color_img_scale.y -= 0.001
		print("scale_x_down to " + str(color_img_scale.y))
	
	# offset
	if Input.is_action_just_pressed("offset_x_up"):
		color_img_offset.x += 0.001
		print("offset_x_up to " + str(color_img_offset.x))
	if Input.is_action_just_pressed("offset_x_down"):
		color_img_offset.x -= 0.001
		print("offset_x_down to " + str(color_img_offset.x))
	if Input.is_action_just_pressed("offset_y_up"):
		color_img_offset.y += 0.001
		print("offset_y_up to " + str(color_img_offset.y))
	if Input.is_action_just_pressed("offset_y_down"):
		color_img_offset.y -= 0.001
		print("offset_x_down to " + str(color_img_offset.y))
	
	# apply the changed values to the shader
	%MeshInstance3D.material_override.set("shader_parameter/color_scale", color_img_scale)
	%MeshInstance3D.material_override.set("shader_parameter/color_offset", color_img_offset)

## helper function to adjust the edges of the sandbox which are cut off
## currently not working
var cut_box: Vector4 = Vector4(0.097, 0.881, 0.196, 0.753) # for cutting the edges (left, right, top, bottom)
func set_cut_box() -> void:
	# left
	if Input.is_action_just_pressed("cut_left_up"):
		cut_box.x += 0.001
		print("cut_left_up to " + str(cut_box))
	if Input.is_action_just_pressed("cut_left_down"):
		cut_box.x -= 0.001
		print("cut_left_down to " + str(cut_box))
	# right
	if Input.is_action_just_pressed("cut_right_up"):
		cut_box.y += 0.001
		print("cut_right_up to " + str(cut_box))
	if Input.is_action_just_pressed("cut_right_down"):
		cut_box.y -= 0.001
		print("cut_right_down to " + str(cut_box))
	# top
	if Input.is_action_just_pressed("cut_top_up"):
		cut_box.z += 0.001
		print("cut_top_up to " + str(cut_box))
	if Input.is_action_just_pressed("cut_top_down"):
		cut_box.z -= 0.001
		print("cut_top_down to " + str(cut_box))
	# bottom
	if Input.is_action_just_pressed("cut_bottom_up"):
		cut_box.w += 0.001
		print("cut_bottom_up to " + str(cut_box))
	if Input.is_action_just_pressed("cut_bottom_down"):
		cut_box.w -= 0.001
		print("cut_bottom_down to " + str(cut_box))

## function is called every physics frame
var recording: bool = false
func _physics_process(_delta: float) -> void:
	# play a recording (has to be in filesystem) (key is currently "r")
	if Input.is_action_just_pressed("get_recording"):
		get_recording()
		recording = not recording
		print("toggle recording to: " + str(recording))
	# start/ stop the terrain updates and game by pressing space
	if Input.is_action_just_pressed("take_image"):
		if !recording:
			running = not running
			print("toggle running to: " + str(running))
			if !thread.is_started():
				if not game_running:
					# starts the marker placement
					# once a marker is placed, they recursively call the placement of another
					# -> cant be stopped
					$"../Game".place_objective()
					game_running = true
				# start continuous terrain updates
				thread.start(update_sandbox)
			else:
				# stop the terrain updates
				thread.wait_to_finish()
		else:
			play_recording()

## take a single depth image and stoe it in the filesystem
func take_image() -> void:
	var img = kinect.get_depth_texture_rf().get_image()
	img.save_png("res://img.png")

## get an array of depth images from a file in: "recordings/output.mkv"
var recording_images: Array
func get_recording() -> void:
	recording_images = kinect.playback_mkv("recordings/output.mkv")
	if recording_images.size() > 0:
		print("Successfully extracted images.")
	else:
		print("Failed to extract images.")

## plays the recording
## requires get_recording() to be previously called
func play_recording() -> void:
	if recording_images.size() <= 0:
		print("unable to play, images are empty")
	for frame : Dictionary in recording_images:
		var depth = frame["depth"]
		var depth_image_rf = image_conversion.process_image(depth)
		var _depth_texture = ImageTexture.create_from_image(depth_image_rf)
		#$"../Sprite3D2".texture = depth_texture # only for debugging
		if frame.get("color") != null:
			var color = frame["color"]
			var color_texture = ImageTexture.create_from_image(color)
			#$"../Sprite3D".texture = color_texture # only for debugging
			%MeshInstance3D.material_override.set("shader_parameter/color_texture", color_texture)
		#finish_update(depth_texture)
		await get_tree().create_timer(.1).timeout

## is in thread
## continuously updates the sandbox terrain
func update_sandbox() -> void:
	while running:
		var image_rg8 # either only depth image or both depth and color image
		if use_color_image:
			image_rg8 = kinect.get_depth_and_color_image_rg8()
			#call_deferred("finish_update", image_rg8)
		else:
			image_rg8 = kinect.get_depth_image_rg8()
			## deferred because thread cant make changes to resources 
			call_deferred("finish_update_depth", image_rg8)

## actual environment update logic
## applies chenges of one new depth image
var prev_image: Image = null # texture buffer used for exponential smoothing
func finish_update_depth(depth_image_rg8) -> void:
	if depth_image_rg8 != null:
		# convert the depth image to format rf and apply the compute shader on it
		var image_rf = image_conversion.process_image(depth_image_rg8, prev_image)
		
		# store the filtered image for the next pass
		prev_image = image_rf
		
		# create texture with the filtered image
		var texture = ImageTexture.create_from_image(image_rf)
		
		# pass texture to terrain mesh for vertice displacement, normal calculation and fragment coloring
		mesh.material.set("shader_parameter/depth_texture", texture)
		
		# use the filtered depth image to change the collision shape
		set_heightmap(image_rf)
		
		# sprites for debugging
		#$"../Sprite3D2".texture = ImageTexture.create_from_image(prev_image)
		#$"../Sprite3D".texture = ImageTexture.create_from_image(depth_image_rg8)

## stop the thread and close the kinect when exiting
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		running = false
		kinect.close_kinect()
		get_tree().quit()
		if thread.is_alive():
			thread.wait_to_finish()
		%ProjectorWindow.print_cam_params()

## catch the VR player when he falls through the ground and resets his vertical position
func _on_fall_throughprotection_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		body.get_parent().global_position.y = 0.0
