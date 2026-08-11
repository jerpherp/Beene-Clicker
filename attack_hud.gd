extends HBoxContainer

@onready var slots = [$AttackSlot1, $AttackSlot2, $AttackSlot3]
@export var empty_texture : Texture2D
@export var cooldown_turn_count := 3
@export var hover_scale := Vector2(1.05, 1.05)
@export var scale_duration := 0.15

@onready var hover_sfx = get_tree().get_root().get_node("Fight/HUD/HoverSFX")
@export var hover_volume_db := -15.0
@export var pitch_min := 0.8
@export var pitch_max := 1.2

var cooldown_turns := [0, 0, 0]

func _ready():
	visible = true
	update_slots()
	for i in slots.size():
		slots[i].custom_minimum_size = Vector2(80, 80)
		slots[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slots[i].pressed.connect(_on_slot_pressed.bind(i))
		slots[i].mouse_entered.connect(_on_slot_hover.bind(i))
		slots[i].mouse_exited.connect(_on_slot_exit.bind(i))
		
func _on_slot_hover(index: int):
	if not slots[index].disabled:
		hover_sfx.volume_db = hover_volume_db
		hover_sfx.pitch_scale = randf_range(pitch_min, pitch_max)
		hover_sfx.play()
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(slots[index], "scale", hover_scale, scale_duration)
		
func _on_slot_exit(index: int):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slots[index], "scale", Vector2.ONE, scale_duration)

func show_attacks():
	visible = true
	for i in slots.size():
		if cooldown_turns[i] > 0:
			cooldown_turns[i] -= 1
			slots[i].modulate = Color(0.4, 0.4, 0.4)
			slots[i].disabled = true
		else:
			slots[i].modulate = Color.WHITE
			slots[i].disabled = false

func hide_attacks():
	visible = false

func update_slots():
	for i in slots.size():
		var attack_id = Global.equipped_attacks[i]
		if attack_id != "":
			slots[i].texture_normal = load("res://attacks/" + attack_id + ".png")
			if Global.attack_data.has(attack_id):
				var data = Global.attack_data[attack_id]
				var base_dmg = data["damage"]
				var actual_dmg = int(base_dmg * (1.0 + Global.get_damage_bonus()))
				var tooltip = data["name"] + "\n" + data["desc"] + "\nDamage: " + str(actual_dmg)
				if Global.owned_items.get("strength_1", false):
					tooltip += " -" + str(actual_dmg - base_dmg) + " bonus-"
				slots[i].tooltip_text = tooltip
		else:
			slots[i].texture_normal = empty_texture

func _on_slot_pressed(index: int):
	print("slot pressed: ", index)
	var attack_id = Global.equipped_attacks[index]
	if attack_id != "" and cooldown_turns[index] <= 0:
		get_tree().get_root().get_node("Fight/whosTurn").player_attack(attack_id)
		if Global.attack_data.has(attack_id) and Global.attack_data[attack_id].get("cooldown", false):
			cooldown_turns[index] = cooldown_turn_count
		hide_attacks()
