extends Button

func _pressed():
	%PauseMenu.visible = false
	get_tree().paused = false
