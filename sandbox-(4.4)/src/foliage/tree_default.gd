extends Node3D

func snap_to_ground() -> void:
	$RayCast3D.force_raycast_update()
	var depth = $RayCast3D.get_collision_point().y
	self.global_position.y = depth
	#print("tree pos after: " + str(self.global_position))
