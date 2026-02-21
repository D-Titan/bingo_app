class_name BingoSlot
extends TextureButton
@onready var btn_text: Label = $btn_text


var grid_pos : Vector2 = Vector2.ZERO
var val : int :
	set(value):
		val = value
		if value == 0:
			if self.get_parent():
				btn_text.text = ""
		else:
			if self.get_parent():
				btn_text.text = str(val)

signal interacted(slot_node: BingoSlot)

func setup(vals : int, pos: Vector2) -> void:
	grid_pos = pos
	val = vals
	button_pressed = false
	disabled = false

func _ready() -> void:
	toggle_mode = true
	toggled.connect(on_toggle)
	update_without_signal(false)


func on_toggle(_btn_pressed : bool) -> void:
	if button_pressed: 
		interacted.emit(self)

func update_without_signal(state : bool) -> void:
	set_block_signals(state)
	button_pressed = state
	disabled = state
	set_block_signals(false)
