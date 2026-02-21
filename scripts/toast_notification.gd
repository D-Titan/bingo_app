extends Control

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $Label/AnimationPlayer
@onready var panel: PanelContainer = $"."

func msg(message : String, color: Color = Color(0.89, 0.14, 0.32, 1.0)) -> void:
	label.text = message
	label.add_theme_color_override("font_color", color)
