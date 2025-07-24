extends Node3D

var check_time: float = 1.0
var cur_time: float = 0.0


func snap_to_ground() -> void:
	$RayCast3D.force_raycast_update()
	var depth = $RayCast3D.get_collision_point().y
	self.global_position.y = depth
	#print("tree pos after: " + str(self.global_position))

func _process(delta: float) -> void:
	cur_time += delta
	if cur_time > check_time:
		self.global_position.y += 10.0
		snap_to_ground()
		cur_time = 0.0
