extends TextureButton

func _pressed():
	%PauseMenu.visible = true
	get_tree().paused = true
