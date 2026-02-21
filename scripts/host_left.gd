extends PanelContainer

func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/home_page.tscn")
