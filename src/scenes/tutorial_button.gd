extends Button

func _pressed() -> void:
	get_tree().paused = false
	Sound.get_node("Prayer/AnimationPlayer").play("Sound_FadeOut")
	%Tutorial.queue_free()
