extends TextureButton

@export var hover_scale := Vector2(1.05, 1.05)
@export var scale_duration := 0.15

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	pressed.connect(func(): get_parent().get_node("BossSelect").open())

func _on_hover():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", hover_scale, scale_duration)
	
func _on_exit():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, scale_duration)
