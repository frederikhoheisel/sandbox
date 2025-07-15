extends AnimatableBody3D


@export var image_conversion: Node
@export var filter_texture: Node

@export var use_kinect: bool = true
@export var use_color_image: bool = true

@onready var kinect: Kinect = %Kinect
@onready var collision_shape := %CollisionShape3D
@onready var depth_test_ray_cast_3d: RayCast3D = %DepthTestRayCast3D

var heightmap_shape := HeightMapShape3D.new()

var running := false
#var depth_texture : ImageTexture

const WIDTH := 10.0
const DEPTH := 9.0
const PIXEL_WIDTH := 640
const PIXEL_DEPTH := 576

const SANDBOX_SCALE := 10.0
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
	var terrain_shader := load("res://src/sandbox/terrain.gdshader")
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	mesh.material = terrain_material
	
	## setup of the collision shape
	heightmap_shape.map_width = 2
	heightmap_shape.map_depth = 2
	collision_shape.shape = heightmap_shape
	collision_shape.scale = Vector3(WIDTH / PIXEL_WIDTH, -30.0, DEPTH / PIXEL_DEPTH)
	collision_shape.scale *= SANDBOX_SCALE
	
	## enable or disable the color image in the shader
	mesh.material.set("shader_parameter/use_real_colors", use_color_image)
	
	## start the kinect and cameras if enabled
	if use_kinect:
		kinect.initialize_kinect(0)
		kinect.start_cameras()
	
		## do everything a bit
		var image_rg8
		for _i in 8:
			if use_color_image:
				image_rg8 = kinect.get_depth_and_color_image_rg8()
			else:
				image_rg8 = kinect.get_depth_image_rg8()
			await get_tree().process_frame # for some reason needs to wait 2 frames to work properly
			
			finish_update_depth(image_rg8)
		
		# extract the camera intrinsics and apply them to the shader
		var depth_params: Array = kinect.extract_camera_parameters(false)
		if not depth_params.is_empty():
			filter_texture.set_lens_distortion_params(depth_params)
	
	adjust_position_of_sandbox()
	
	## initialise thred
	thread = Thread.new()

func adjust_position_of_sandbox() -> void:
	depth_test_ray_cast_3d.force_raycast_update()
	var depth = depth_test_ray_cast_3d.get_collision_point().y
	#print(depth)
	self.position.y = -5.0 - depth

## filters a texture with a shader and returns it
#var previous_depth_texture: Texture2D = null # frame buffer
#func filter_texture(texture: Texture2D) -> Texture2D:
	#filtered_texture.texture = texture
	##filtered_texture.material.set("shader_parameter/depth_texture", texture)
	#filtered_texture.material.set("shader_parameter/previous_frame", previous_depth_texture)
	#%SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	#await get_tree().process_frame
	#var new_texture = %SubViewport.get_texture()
	#previous_depth_texture = new_texture
	#return new_texture

## converts texture to image and applies it to the heightmapshape
func set_heightmap(texture: Texture2D) -> void:
	var image = image_conversion.process_image(texture.get_image())
	#var image = texture.get_image()
	#image.convert(Image.FORMAT_RF)
	heightmap_shape.update_map_data_from_image(image, 0.0, 1.0)

## helper function to adjust the color image and fit it to the depth data
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
	
	%MeshInstance3D.material_override.set("shader_parameter/color_scale", color_img_scale)
	%MeshInstance3D.material_override.set("shader_parameter/color_offset", color_img_offset)

## helper function to adjust the edges of the sandbox
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
	
	filter_texture.set_boundary_box(cut_box)

var recording: bool = false
func _physics_process(_delta: float) -> void:
	# fit_color_image()
	# set_cut_box()
	if Input.is_action_just_pressed("get_recording"):
		get_recording()
		recording = not recording
		print("toggle recording to: " + str(recording))
	if Input.is_action_just_pressed("take_image"):
		if !recording:
			running = not running
			print("toggle running to: " + str(running))
			if !thread.is_started():
				$"../Game".place_objective()
				thread.start(update_sandbox)
			else:
				thread.wait_to_finish()
		else:
			play_recording()

func take_image() -> void:
	var img = kinect.get_depth_texture_rf().get_image()
	img.save_png("res://img.png")

var recording_images: Array
func get_recording() -> void:
	recording_images = kinect.playback_mkv("recordings/output.mkv")
	if recording_images.size() > 0:
		print("Successfully extracted images.")
	else:
		print("Failed to extract images.")

func play_recording() -> void:
	if recording_images.size() <= 0:
		print("unable to play, images are empty")
	for frame : Dictionary in recording_images:
		var depth = frame["depth"]
		var depth_image_rf = image_conversion.process_image(depth)
		var depth_texture = ImageTexture.create_from_image(depth_image_rf)
		#$"../Sprite3D2".texture = depth_texture # only for debugging
		if frame.get("color") != null:
			var color = frame["color"]
			var color_texture = ImageTexture.create_from_image(color)
			#$"../Sprite3D".texture = color_texture # only for debugging
			%MeshInstance3D.material_override.set("shader_parameter/color_texture", color_texture)
		finish_update(depth_texture)
		await get_tree().create_timer(.1).timeout

## is in thread
func update_sandbox() -> void:
	while running:
		OS.delay_msec(33)
		var image_rg8
		if use_color_image:
			image_rg8 = kinect.get_depth_and_color_image_rg8()
			call_deferred("finish_update", image_rg8)
		else:
			image_rg8 = kinect.get_depth_image_rg8()
			call_deferred("finish_update_depth", image_rg8)

## cant be in thread because modifying something
## very spaghetti :(
func finish_update(image_rg8) -> void:
	var depth: Image = null
	var color: Image = null
	if use_color_image:
		if not image_rg8.is_empty():
			depth = image_rg8.get(0)
			#print(depth)
			if image_rg8.size() == 2:
				color = image_rg8.get(1)
	else:
		depth = image_rg8
	
	if depth != null:
		#depth.convert(Image.FORMAT_RF)
		var image_rf = image_conversion.process_image(depth)
		var texture = ImageTexture.create_from_image(image_rf) #image_rf
		var modified_texture = await filter_texture.filter_texture(texture)
		%MeshInstance3D.material_override.set("shader_parameter/depth_texture", modified_texture)
		set_heightmap(modified_texture)
		#(0.097, 0.881, 0.196, 0.753) (left, right, top, bottom)
		var cut_image = modified_texture.get_image().get_region(Rect2(cut_box.x * PIXEL_WIDTH, cut_box.z * PIXEL_DEPTH, (cut_box.y - cut_box.x) * PIXEL_WIDTH, (cut_box.w - cut_box.z) * PIXEL_DEPTH))
		var cut_texture = ImageTexture.create_from_image(cut_image)
		%ProjectorWindow.cut_depth_texture = cut_texture
		#$"../Sprite3D2".texture = cut_texture
	if color != null:
		var color_texture = ImageTexture.create_from_image(color)
		%MeshInstance3D.material_override.set("shader_parameter/color_texture", color_texture)
		$"../Sprite3D".texture = color_texture

var i: int = 0
func finish_update_depth(depth_image_rg8) -> void:
	if depth_image_rg8 != null:
		#var image_rf = depth_image_rg8.convert(Image.FORMAT_RF)
		var image_rf = image_conversion.process_image(depth_image_rg8)
		var texture = ImageTexture.create_from_image(image_rf)
		var modified_texture = await filter_texture.filter_texture(texture)
		mesh.material.set("shader_parameter/depth_texture", modified_texture)
		i += 1
		if i % 5 == 0:
			set_heightmap(modified_texture)
			i = 0
		#(0.097, 0.881, 0.196, 0.753) (left, right, top, bottom)
		var cut_image = modified_texture.get_image().get_region(sandbox_rect)
		var cut_texture = ImageTexture.create_from_image(cut_image)
		%ProjectorWindow.cut_depth_texture = cut_texture
		#$"../Sprite3D2".texture = texture
		#$"../Sprite3D".texture = modified_texture

## stop the thread and close the kinect when exiting
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		running = false
		kinect.close_kinect()
		get_tree().quit()
		if thread.is_alive():
			thread.wait_to_finish()
		%ProjectorWindow.print_cam_params()
