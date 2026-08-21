extends TextureButton

@export var hover_scale := Vector2(1.05, 1.05)
@export var scale_duration := 0.15
@export var item_name := ""
@export var item_desc := ""
@export var item_price := 0
@export var item_id := ""

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_buy)
	_update_state()

func _update_state():
	if item_id == "health_potion":
		var owned = Global.owned_items.get("health_potion", false)
		modulate = Color(0.5, 0.5, 0.5) if owned else Color.WHITE
		disabled = owned
	else:
		var owned = Global.owned_items.get(item_id, false)
		modulate = Color(0.5, 0.5, 0.5) if owned else Color.WHITE
		disabled = owned

func _on_hover():
	if not disabled:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", hover_scale, scale_duration)
	get_parent().get_parent().show_item_info(item_name, item_desc, item_price, item_id)

func _on_exit():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, scale_duration)
	get_parent().get_parent().hide_item_info()

func _on_buy():
	if Global.click_count < item_price:
		return
	Global.click_count -= item_price
	if item_id == "health_potion":
		Global.owned_items["health_potion"] = true
	else:
		Global.owned_items[item_id] = true
	Global.save_data()
	_update_state()
	get_parent().get_parent()._update_beenes_amount()
	get_parent().get_parent().show_item_info(item_name, item_desc, item_price, item_id)
