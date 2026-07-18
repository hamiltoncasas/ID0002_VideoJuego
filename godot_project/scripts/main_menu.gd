extends Control

func _ready():
	$StartBtn.connect("pressed", Callable(self, "_on_start_pressed"))
	# Auto-transition to battle after screenshot
	await get_tree().create_timer(1.0).timeout
	take_screenshot()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

func take_screenshot():
	var image = get_viewport().get_texture().get_image()
	if image:
		image.save_png("user://screenshot_menu.png")
		print("✅ Menu screenshot saved")
