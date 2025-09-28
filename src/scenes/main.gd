extends Node3D

@export var packages = 0
@export var quota = 10

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout # setup camera first
	get_tree().paused = true
	$Map.point_hit.connect(point_hit)
	
func point_hit(point):
	print(point)
	packages += 1
	$GUI/Quota.text = "Quota: "+str(packages)+"/"+str(quota)
