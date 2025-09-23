extends Node


@export var model: Node3D
@export var check_interval: float = 0.1

var cur_time: float = 0.0

@onready var ray_cast_3d: RayCast3D = $RayCast3D


func _process(delta: float) -> void:
	cur_time += delta
	if cur_time > check_interval:
		ray_cast_3d.global_position.y += 10.0
		model.global_position.y += 10.0
		snap_to_ground()
		cur_time = 0.0


func snap_to_ground() -> void:
	ray_cast_3d.force_raycast_update()
	if ray_cast_3d.is_colliding():
		var depth = ray_cast_3d.get_collision_point().y
		model.global_position.y = depth
		ray_cast_3d.global_position.y = depth
	else:
		model.queue_free()
		self.queue_free()
