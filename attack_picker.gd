extends Panel

@onready var grid = $PickerPanel/AttackGrid
@onready var close_btn = $PickerPanel/CloseButton
var selected_slot := -1
var slots_node : Node
var tooltip_label : Label

@export var locked_texture : Texture2D
@export var total_attacks := 10
@export var attacks_per_source := 2

var attack_sources := ["base", "boss1", "boss2", "boss3", "boss4"]

func _ready():
	visible = false
	slots_node = get_tree().get_root().get_node("Main/CanvasLayer/Panel/EquippedAttacks")
	close_btn.pressed.connect(close)

	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 20)
	tooltip_label.visible = false
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tooltip_label.custom_minimum_size = Vector2(900, 50)
	$PickerPanel.add_child(tooltip_label)

func open(slot_index: int):
	selected_slot = slot_index
	visible = true
	_populate_grid()

func close():
	visible = false
	selected_slot = -1

func _populate_grid():
	for child in grid.get_children():
		child.queue_free()
	
	var all_buttons = []
	for source in attack_sources:
		var source_attacks = Global.unlocked_attacks.filter(func(id): 
			return Global.attack_data.get(id, {}).get("source", "") == source
		)
		var source_btns = []
		for i in attacks_per_source:
			var btn = TextureButton.new()
			btn.custom_minimum_size = Vector2(80, 80)
			if i < source_attacks.size():
				var attack_id = source_attacks[i]
				btn.texture_normal = load("res://attacks/" + attack_id + ".png")
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				if Global.attack_data.has(attack_id):
					var data = Global.attack_data[attack_id]
					var display_text = data["name"] + "\n" + data["desc"] + "\nDamage: " + str(data["damage"])
					btn.mouse_entered.connect(_show_tooltip.bind(display_text, btn))
					btn.mouse_exited.connect(_hide_tooltip)
				if attack_id in Global.equipped_attacks:
					btn.modulate = Color(0.4, 0.4, 0.4, 1.0)
					btn.mouse_filter = Control.MOUSE_FILTER_STOP
				else:
					btn.pressed.connect(_on_attack_picked.bind(attack_id))
			else:
				btn.texture_normal = locked_texture if locked_texture else load("res://attacks/locked.png")
				btn.disabled = true
				btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
			source_btns.append(btn)
		all_buttons.append(source_btns)
	
	for row in attacks_per_source:
		for source_btns in all_buttons:
			grid.add_child(source_btns[row])

func _on_attack_picked(attack_id: String):
	Global.equipped_attacks[selected_slot] = attack_id
	Global.save_data()
	slots_node.update_slots()
	close()

func _show_tooltip(text: String, btn: TextureButton):
	tooltip_label.text = text
	tooltip_label.visible = true
	tooltip_label.position = Vector2(20, $PickerPanel.size.y - 110)

func _hide_tooltip():
	tooltip_label.visible = false
