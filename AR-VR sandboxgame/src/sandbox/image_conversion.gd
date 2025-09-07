extends Node

# RD variables
var rd: RenderingDevice
var shader: RID
var pipeline: RID

# Input and output textures
var input_texture_rid: RID
var output_texture_rid: RID

# Uniform set
var uniform_set: RID
var uniform_buffer: RID
var previous_frame_texture: RID

func _ready():
	# Initialize the rendering device
	rd = RenderingServer.create_local_rendering_device()

	# Load GLSL shader
	var shader_file := load("res://src/sandbox/combined_compute_shader.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)

	# Create compute pipeline
	pipeline = rd.compute_pipeline_create(shader)
	
	setup_uniform_buffer()

func setup_uniform_buffer() -> void:
	# Create uniform data struct matching the shader
	var uniform_data = PackedFloat32Array()
	# Camera parameters
	uniform_data.append(503.014038085938) # fx
	uniform_data.append(503.003509521484) # fy
	uniform_data.append(323.092102050781) # cx
	uniform_data.append(336.343688964844) # cy

	# Distortion coefficients
	uniform_data.append(0.7217835187912) # k1
	uniform_data.append(0.30027222633362) # k2
	uniform_data.append(0.01698642224073) # k3
	uniform_data.append(1.05875504016876) # k4
	uniform_data.append(0.47951143980026) # k5
	uniform_data.append(0.0855306237936) # k6
	uniform_data.append(0.00005971607243) # p1
	uniform_data.append(0.00005871869143) # p2

	# Create buffer
	var buffer_data = uniform_data.to_byte_array()
	uniform_buffer = rd.storage_buffer_create(buffer_data.size())
	rd.buffer_update(uniform_buffer, 0, buffer_data.size(), buffer_data)


func create_texture_from_image(image: Image, format: RenderingDevice.DataFormat) -> RID:
	var texture_format = RDTextureFormat.new()
	texture_format.format = format
	texture_format.width = image.get_width()
	texture_format.height = image.get_height()
	texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

	var texture_view = RDTextureView.new()
	return rd.texture_create(texture_format, texture_view, [image.get_data()])


func process_image(input_image: Image, previous_frame: Image = null) -> Image:
	# Make sure the input image is in FORMAT_RG8
	if input_image.get_format() != Image.FORMAT_RG8:
		print("wrong image format")
		input_image.convert(Image.FORMAT_RG8)

	var width = input_image.get_width()
	var height = input_image.get_height()
	
	# Create or update previous frame texture
	if previous_frame == null:
		# Create empty previous frame texture (R32F format)
		var empty_image = Image.create(width, height, false, Image.FORMAT_RF)
		empty_image.fill(Color(0.0, 0.0, 0.0, 1.0))
		previous_frame_texture = create_texture_from_image(empty_image, RenderingDevice.DATA_FORMAT_R32_SFLOAT)
	else:
		previous_frame_texture = create_texture_from_image(previous_frame, RenderingDevice.DATA_FORMAT_R32_SFLOAT)

	# Create input texture
	input_texture_rid = create_texture_from_image(input_image, RenderingDevice.DATA_FORMAT_R8G8_UNORM)

	# Create output texture
	var output_format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	var output_texture_format = RDTextureFormat.new()
	output_texture_format.width = width
	output_texture_format.height = height
	output_texture_format.depth = 1
	output_texture_format.format = output_format
	output_texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var output_view = RDTextureView.new()
	output_texture_rid = rd.texture_create(output_texture_format, output_view)

	# Create uniform set
	var input_uniform := RDUniform.new()
	input_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	input_uniform.binding = 0
	input_uniform.add_id(input_texture_rid)

	var previous_uniform := RDUniform.new()
	previous_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	previous_uniform.binding = 1
	previous_uniform.add_id(previous_frame_texture)

	var output_uniform := RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 2
	output_uniform.add_id(output_texture_rid)

	var buffer_uniform := RDUniform.new()
	buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_uniform.binding = 3
	buffer_uniform.add_id(uniform_buffer)

	uniform_set = rd.uniform_set_create([
		input_uniform,
		previous_uniform,
		output_uniform,
		buffer_uniform
	], shader, 0)

	# Dispatch compute shader
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	# Calculate dispatch size - make sure to cover the entire image
	var dispatch_x = (width + 7.0) / 8.0
	var dispatch_y = (height + 7.0) / 8.0
	rd.compute_list_dispatch(compute_list, dispatch_x, dispatch_y, 1)
	rd.compute_list_end()

	# Submit computation and wait for completion
	rd.submit()
	rd.sync()

	# Create output image
	var output_image = Image.create(width, height, false, Image.FORMAT_RF)

	# Read back the result
	var output_data = rd.texture_get_data(output_texture_rid, 0)
	output_image.set_data(width, height, false, Image.FORMAT_RF, output_data)

	# Clean up
	rd.free_rid(input_texture_rid)
	input_texture_rid = RID()
	rd.free_rid(output_texture_rid)
	output_texture_rid = RID()
	rd.free_rid(previous_frame_texture)
	previous_frame_texture = RID()

	return output_image

func _exit_tree():
	if rd:
		rd.free_rid(pipeline)
		rd.free_rid(shader)
		rd.free_rid(uniform_buffer)
		rd.free_rid(previous_frame_texture)
		rd.free()
