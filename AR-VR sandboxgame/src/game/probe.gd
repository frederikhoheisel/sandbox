extends Node3D
class_name Probe

@export var shape_radius: float = 0.5

func _ready() -> void:
	$MeshInstance3D.mesh.radius = shape_radius
	$MeshInstance3D.mesh.height = shape_radius * 2.0

func detect_sand() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	
	var shape = SphereShape3D.new()
	shape.radius = 0.2
	
	query.shape = shape
	query.collide_with_bodies = true
	query.transform = self.global_transform
	
	var result = space_state.intersect_shape(query)
	if result.is_empty():
		$MeshInstance3D.mesh.material.albedo_color = Color.RED
		return false
	#print(result)
	$MeshInstance3D.mesh.material.albedo_color = Color.GREEN
	return true
