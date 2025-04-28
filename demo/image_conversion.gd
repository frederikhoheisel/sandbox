extends Node

# RD variables
var rd: RenderingDevice
var shader: RID
var pipeline: RID

# Input and output textures
var input_texture: RID
var output_texture: RID

# Uniform set
var uniform_set: RID

func _ready():
	# Initialize the rendering device
	rd = RenderingServer.create_local_rendering_device()

	# Load GLSL shader
	var shader_file := load("res://convert_image.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)

	# Create compute pipeline
	pipeline = rd.compute_pipeline_create(shader)

func process_image(input_image: Image) -> Image:
	# Make sure the input image is in FORMAT_RG8
	if input_image.get_format() != Image.FORMAT_RG8:
		input_image.convert(Image.FORMAT_RG8)

	var width = input_image.get_width()
	var height = input_image.get_height()

	# Create input texture
	var input_format = RenderingDevice.DATA_FORMAT_R8G8_UNORM
	var input_texture_format = RDTextureFormat.new()
	input_texture_format.width = width
	input_texture_format.height = height
	input_texture_format.depth = 1
	input_texture_format.format = input_format
	input_texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

	var input_view = RDTextureView.new()
	input_texture = rd.texture_create(input_texture_format, input_view)

	# Create output texture
	var output_format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	var output_texture_format = RDTextureFormat.new()
	output_texture_format.width = width
	output_texture_format.height = height
	output_texture_format.depth = 1
	output_texture_format.format = output_format
	output_texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var output_view = RDTextureView.new()
	output_texture = rd.texture_create(output_texture_format, output_view)

	# Upload input image data to the input texture
	var input_data = input_image.get_data()
	rd.texture_update(input_texture, 0, input_data)

	# Setup uniform bindings
	var input_uniform = RDUniform.new()
	input_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	input_uniform.binding = 0
	input_uniform.texture = input_texture

	var output_uniform = RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 1
	output_uniform.texture = output_texture

	# Create uniform set
	var uniform_bindings = [input_uniform, output_uniform]
	uniform_set = rd.uniform_set_create(uniform_bindings, shader, 0)

	# Dispatch compute shader
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	# Calculate dispatch size - make sure to cover the entire image
	var dispatch_x = (width + 7) / 8
	var dispatch_y = (height + 7) / 8
	rd.compute_list_dispatch(compute_list, dispatch_x, dispatch_y, 1)
	rd.compute_list_end()

	# Submit computation and wait for completion
	rd.submit()
	rd.sync()

	# Create output image
	var output_image = Image.create(width, height, false, Image.FORMAT_RF)

	# Read back the result
	var output_data = rd.texture_get_data(output_texture, 0)
	output_image.set_data(width, height, false, Image.FORMAT_RF, output_data)

	# Clean up
	rd.free_rid(input_texture)
	rd.free_rid(output_texture)
	rd.free_rid(uniform_set)

	return output_image

func _exit_tree():
	# Clean up resources when the node exits the tree
	if rd:
		rd.free_rid(pipeline)
		rd.free_rid(shader)
		rd.free()
