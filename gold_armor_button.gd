extends TextureButton

@export var hover_scale := Vector2(1.05, 1.05)
@export var scale_duration := 0.15
@export var item_name := "Gold Armor"
@export var item_desc := "Only the best armor for a fightin' Beene. Gives you 50% protection during the toughest of battles."
@export var item_price := 150000
@export var item_id := ""

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

func _on_hover():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", hover_scale, scale_duration)
	# tell the store to show info
	get_parent().get_parent().show_item_info(item_name, item_desc, item_price, item_id)

func _on_exit():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, scale_duration)
	get_parent().get_parent().hide_item_info()
