extends Node3D

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout # setup camera first
	get_tree().paused = true
	$Map.point_hit.connect(point_hit)
	
func point_hit(point):
	print(point)
