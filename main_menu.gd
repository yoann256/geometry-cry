extends Node2D

func _on_play_button_pressed() -> void:
	print("testing!")
	get_tree().change_scene_to_file("res://play_scene.tscn")
	pass # Replace with function body.
