extends Node

@onready var sub_viewport_a: SubViewport = %SubViewportA
@onready var sub_viewport_b: SubViewport = %SubViewportB
@onready var sprite_a: Sprite2D = $SubViewportA/SpriteA
@onready var sprite_b: Sprite2D = $SubViewportB/SpriteB

var current_buffer = 0 # 0 = A, 1 = B

func _ready() -> void:
	# creating a blank texture for the first update
	#var blank_image = Image.create(640, 576, false, Image.FORMAT_RF)
	#blank_image.fill(Color.RED)
	#var blank_texture = ImageTexture.create_from_image(blank_image)
	#
	#sprite_a.material.set("shader_parameter/previous_frame", blank_texture)
	#sprite_b.material.set("shader_parameter/previous_frame", blank_texture)
	pass

func filter_texture(new_texture: Texture2D) -> Texture2D:
	if current_buffer == 0:
		sprite_a.texture = new_texture
		var prev_texture = sub_viewport_b.get_texture()
		$"../Sprite3D3".texture = prev_texture
		sprite_a.material.set("shader_parameter/previous_frame", prev_texture)
		
		sub_viewport_a.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		current_buffer = 1
		$"../Sprite3D".texture = sub_viewport_a.get_texture()
		return sub_viewport_a.get_texture()
	else:
		sprite_b.texture = new_texture
		var prev_texture = sub_viewport_a.get_texture()
		$"../Sprite3D4".texture = prev_texture
		sprite_b.material.set("shader_parameter/previous_frame", prev_texture)
		
		sub_viewport_b.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		current_buffer = 0
		$"../Sprite3D2".texture = sub_viewport_b.get_texture()
		return sub_viewport_b.get_texture()

func set_lens_distortion_params(depth_params: Array) -> void:
	sprite_a.material.set("shader_parameter/fx", depth_params[0])
	sprite_a.material.set("shader_parameter/fy", depth_params[1])
	sprite_a.material.set("shader_parameter/cx", depth_params[2])
	sprite_a.material.set("shader_parameter/cy", depth_params[3])
	sprite_a.material.set("shader_parameter/k1", depth_params[4])
	sprite_a.material.set("shader_parameter/k2", depth_params[5])
	sprite_a.material.set("shader_parameter/k3", depth_params[6])
	sprite_a.material.set("shader_parameter/k4", depth_params[7])
	sprite_a.material.set("shader_parameter/k5", depth_params[8])
	sprite_a.material.set("shader_parameter/k6", depth_params[9])
	sprite_a.material.set("shader_parameter/p1", depth_params[10])
	sprite_a.material.set("shader_parameter/p2", depth_params[11])
	
	sprite_b.material.set("shader_parameter/fx", depth_params[0])
	sprite_b.material.set("shader_parameter/fy", depth_params[1])
	sprite_b.material.set("shader_parameter/cx", depth_params[2])
	sprite_b.material.set("shader_parameter/cy", depth_params[3])
	sprite_b.material.set("shader_parameter/k1", depth_params[4])
	sprite_b.material.set("shader_parameter/k2", depth_params[5])
	sprite_b.material.set("shader_parameter/k3", depth_params[6])
	sprite_b.material.set("shader_parameter/k4", depth_params[7])
	sprite_b.material.set("shader_parameter/k5", depth_params[8])
	sprite_b.material.set("shader_parameter/k6", depth_params[9])
	sprite_b.material.set("shader_parameter/p1", depth_params[10])
	sprite_b.material.set("shader_parameter/p2", depth_params[11])

func set_boundary_box(cut_box: Vector4) -> void:
	sprite_a.material.set("shader_parameter/cut_box", cut_box)
	sprite_b.material.set("shader_parameter/cut_box", cut_box)
