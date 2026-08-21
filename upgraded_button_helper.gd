extends TextureButton

@export var hover_scale := Vector2(1.1, 1.1)
@export var scale_duration := 0.15
@export var title := "Helper Beene"
@export var description := "A mini Beene that orbits and clicks for you!"
@export var base_price := 50
@export var exponent := 1.5

var level := 1

@onready var tooltip = $Tooltip
@onready var counter = get_tree().get_root().get_node("Main/ClickCounter")
var original_scale: Vector2

func _ready():
	var upgrade_name = name
	if Global.upgrade_levels.has(upgrade_name):
		level = int(Global.upgrade_levels[upgrade_name])
	
	original_scale = scale
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip.visible = false
	$Tooltip.position = Vector2(0, -45)
	$Tooltip/UpgradeDesc.text = "[b]" + title + "[/b]\nLevel " + str(level) + "\n" + description + "\n[b]Cost:[/b] " + str(get_price()) + " Beenes"
	pressed.connect(_on_pressed)

func get_price() -> int:
	return int(floor(base_price * pow(exponent, level - 1)))

func _on_mouse_entered():
	_animate_scale(hover_scale)
	tooltip.visible = true

func _on_mouse_exited():
	_animate_scale(original_scale)
	tooltip.visible = false

func _animate_scale(target: Vector2):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target, scale_duration)

func _on_pressed():
	var c = get_tree().get_root().get_node("Main/ClickCounter")
	if Global.click_count >= get_price():
		Global.click_count -= get_price()
		level += 1
		Global.helper_beene_count += 1
		Global.upgrade_levels[name] = level  # save level
		Global.save_data()
		# recompute beene bot rate after purchasing helper
		if Global.has_method("update_upgrade_effects"):
			Global.update_upgrade_effects()
		c.update_display()
		var helper_scene = load("res://helper_beene.tscn")
		var new_helper = helper_scene.instantiate()
		new_helper.angle = (level - 2) * (TAU / 3.0)
		get_tree().get_root().get_node("Main/Area2D").add_child(new_helper)
		new_helper.activate()
		$Tooltip/UpgradeDesc.text = "[b]" + title + "[/b]\nLevel " + str(level) + "\n" + description + "\n[b]Cost:[/b] " + str(get_price()) + " Beenes"
