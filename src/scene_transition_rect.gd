extends ColorRect

# Path to the next scene to transition to
@export var next_scene_path: String

# Reference to the _AnimationPlayer_ node
@onready var _anim_player := %AnimationPlayer

func _ready() -> void:
	# Plays the animation backward to fade in
	_anim_player.play_backwards("Fade")

func transition_to(_next_scene := next_scene_path) -> void:
	# Plays the Fade animation and wait until it finishes
	_anim_player.play("Fade")
	await get_tree().create_timer(0.75).timeout
	# Changes the scene
	get_tree().change_scene_to_file(_next_scene)
