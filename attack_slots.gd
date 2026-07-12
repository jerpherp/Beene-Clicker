extends HBoxContainer

@onready var slots = [$AttackSlot1, $AttackSlot2, $AttackSlot3]
@onready var picker = get_tree().get_root().get_node("Main/CanvasLayer/AttackPicker")
@export var empty_texture : Texture2D

func _ready():
	for i in slots.size():
		var slot = slots[i]
		slot.pressed.connect(_on_slot_pressed.bind(i))
		slot.mouse_entered.connect(_on_slot_hover.bind(i))
		slot.mouse_exited.connect(_on_slot_exit.bind(i))
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	update_slots()

func _on_slot_hover(index: int):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slots[index], "scale", Vector2(1.05, 1.05), 0.15)
	
func _on_slot_exit(index: int):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slots[index], "scale", Vector2.ONE, 0.15)

func update_slots():
	for i in slots.size():
		var attack_id = Global.equipped_attacks[i]
		if attack_id != "":
			slots[i].texture_normal = load("res://attacks/" + attack_id + ".png")
		else:
			slots[i].texture_normal = empty_texture

func _on_slot_pressed(index: int):
	picker.open(index)
