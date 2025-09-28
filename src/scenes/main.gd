extends Node3D

@export var packages: int = 0
@export var quota: int = 10
@export var target_object: Area3D
@export var arrow: Node3D
@export var orientation_offset_deg: float = -90.0  # try 90 or -90

func _ready() -> void:
	$GUI/Tutorial.visible = true
	#$Prayer.play(Global.prayer_playbacktime.get_playback_time())
	await get_tree().create_timer(0.1).timeout # setup camera first
	get_tree().paused = true
	target_object = $Map/CollectionPoints/HospitalArea
	arrow = $Truck/VehicleBody3D/NavigationArrow
	$Map.point_hit.connect(point_hit)
	
func point_hit(point):
	print(point)
	packages += 1
	$GUI/Quota.text = "Quota: "+str(packages)+"/"+str(quota)
	# put near top so you can tweak in the editor

func _process(_delta):
	if target_object and arrow:
		var dir = target_object.global_transform.origin - arrow.global_transform.origin
		dir.y = 0
		if dir.length_squared() < 0.0001:
			return
		var angle = atan2(dir.x, dir.z)                      # global yaw to target
		var desired_global = angle + deg_to_rad(orientation_offset_deg)
		# If arrow is a child of the truck, you may want local yaw:
		var parent_yaw = 0.0
		var parent = arrow.get_parent()
		if parent and parent is Node3D:
			parent_yaw = parent.global_transform.basis.get_euler().y
		var desired_local = desired_global - parent_yaw
		arrow.rotation.y = desired_local                       # set local yaw directly
