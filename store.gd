extends Control

@export var parallax_strength := 20.0

@onready var bg = $Background
@onready var floor_node = $Floor
@onready var counter = $Counter
@onready var shades = $Shades
@onready var hand = $Hand
@onready var light = $light
@onready var upgrades = $Area2D

@onready var animation_player = $AnimationPlayer

@onready var info_panel = $InfoPanel
@onready var item_name_label = $InfoPanel/VBoxContainer/ItemName
@onready var item_desc_label = $InfoPanel/VBoxContainer/ItemDesc
@onready var item_price_label = $InfoPanel/VBoxContainer/ItemPrice

@onready var beenes_amount = $BeenesAmount

var base_bg : Vector2
var base_floor : Vector2
var base_counter : Vector2
var base_shades : Vector2
var base_hand : Vector2
var base_light : Vector2
var base_upgrades : Vector2

var panel_shown_x : float
var panel_hidden_x : float
var current_item : Dictionary = {}

func _ready():
	_update_beenes_amount()
	animation_player.play("fade_out")
	base_bg = bg.position
	base_floor = floor_node.position
	base_counter = counter.position
	base_shades = shades.position
	base_hand = hand.position
	base_light = light.position
	base_upgrades = upgrades.position
	
	panel_shown_x = get_viewport_rect().size.x - info_panel.size.x - 400
	panel_hidden_x = get_viewport_rect().size.x + 100
	info_panel.position.x = panel_hidden_x
	info_panel.position.y = get_viewport_rect().size.y - info_panel.size.y - 300
	item_name_label.add_theme_font_size_override("font_size", 32)
	item_desc_label.add_theme_font_size_override("font_size", 20)
	item_price_label.add_theme_font_size_override("font_size", 24)
	item_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	item_price_label.autowrap_mode = TextServer.AUTOWRAP_WORD

func _process(delta):
	var viewport_size = get_viewport_rect().size
	var mouse = get_viewport().get_mouse_position()
	
	var offset = Vector2(
		(mouse.x / viewport_size.x - 0.5) * 2.0,
		(mouse.y / viewport_size.y - 0.5) * 2.0
	)
	
	bg.position = bg.position.lerp(base_bg + offset * parallax_strength * 0.1, delta * 5.0)
	floor_node.position = floor_node.position.lerp(base_floor + offset * parallax_strength * 0.15, delta * 5.0)
	shades.position = shades.position.lerp(base_shades + offset * parallax_strength * 0.3, delta * 5.0)
	hand.position = hand.position.lerp(base_hand + offset * parallax_strength * 0.45, delta * 5.0)
	counter.position = counter.position.lerp(base_counter + offset * parallax_strength * 0.5, delta * 5.0)
	upgrades.position = upgrades.position.lerp(base_upgrades + offset * parallax_strength * 0.5, delta * 4.5)
	light.position = light.position.lerp(base_light + offset * parallax_strength * 0.8, delta * 5.0)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			animation_player.play_backwards("fade_out")
			await get_tree().create_timer(1.5).timeout
			_on_back()

func _on_back():
	get_tree().change_scene_to_file("res://main.tscn")

func _populate_grid(grid: GridContainer, category: String):
	for child in grid.get_children():
		child.queue_free()
	
	for item in Global.store_items[category]:
		var btn = TextureButton.new()
		btn.texture_normal = load(item["image"])
		btn.custom_minimum_size = Vector2(100, 100)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = item["name"] + "\n" + item["desc"] + "\nPrice: " + str(item["price"]) + " Beenes"
		
		if item["owned"]:
			btn.modulate = Color.WHITE
			btn.pressed.connect(_on_item_selected.bind(item, category))
		elif Global.click_count >= item["price"]:
			btn.pressed.connect(_on_item_purchase.bind(item, category, grid))
		else:
			btn.modulate = Color(0.4, 0.4, 0.4)
			btn.disabled = true
		
		grid.add_child(btn)

func _on_item_selected(item: Dictionary, category: String):
	if category == "backgrounds":
		Global.equipped_background = Global.store_items["backgrounds"].find(item)
		Global.current_background = Global.equipped_background
		Global.save_data()

func _on_item_purchase(item: Dictionary, category: String, grid: GridContainer):
	if Global.click_count >= item["price"]:
		Global.click_count -= item["price"]
		item["owned"] = true
		Global.owned_cosmetics.append(item["id"])
		Global.save_data()
		_update_beenes_amount()
		_populate_grid(grid, category)

func _update_beenes_amount():
	beenes_amount.text = str(int(Global.click_count)) + " Beenes"

func _on_hover(btn):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)

func _on_exit(btn):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.15)

func _show_info(item: Dictionary):
	current_item = item
	item_name_label.text = item["name"]
	item_desc_label.text = item["desc"]
	
	if item.get("owned", false):
		item_price_label.text = "Owned"
	else:
		item_price_label.text = str(item["price"]) + " Beenes"
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(info_panel, "position:x", panel_shown_x, 0.3)

func _hide_info():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(info_panel, "position:x", panel_hidden_x, 0.2)

func _on_buy_pressed():
	if current_item.is_empty():
		return
	if Global.click_count >= current_item["price"]:
		Global.click_count -= current_item["price"]
		current_item["owned"] = true
		Global.owned_cosmetics.append(current_item["id"])
		Global.save_data()
		_update_beenes_amount()
		_show_info(current_item)
		
func show_item_info(name: String, desc: String, price: int, id: String):
	_show_info({"name": name, "desc": desc, "price": price, "id": id})

func hide_item_info():
	_hide_info()
