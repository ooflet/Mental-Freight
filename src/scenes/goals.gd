extends Node3D

signal point_hit(data)

func _ready():
	# Loop through all children
	for child in %CollectionPoints.get_children():
		print(child)
		if child is Area3D:
			print("OK!")
			# Connect the signal dynamically
			child.body_entered.connect(func(body): _on_area_body_entered(child.name))

# This will handle all area signals
func _on_area_body_entered(point):
	print("point!")
	emit_signal("point_hit", point)
