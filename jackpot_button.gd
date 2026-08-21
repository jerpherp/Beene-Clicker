extends TextureButton

@export var hover_scale := Vector2(1.1, 1.1)
@export var scale_duration := 0.15

@export var title := "Lucky Jackpot"
@export var description := "Grants a chance for clicks to hit a massive multiplier."

@export var base_price := 3000
@export var exponent := 2.5
var level := 1

@export var multiplier_increase := 1
@onready var counter = get_tree().get_root().get_node("Main/ClickCounter")
@onready var tooltip = $Tooltip

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
	_update_tooltip_text()
	update_price_display()
	
	pressed.connect(_on_pressed)

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

func get_price():
	return int(floor(base_price * pow(exponent, level - 1)))

func update_price_display():
	if has_node("PriceLabel"):
		$PriceLabel.text = str(get_price())

func _update_tooltip_text():
	$Tooltip/UpgradeDesc.text = "[b]" + title + "[/b]\n Level " + str(level) + "\n" + description + "\n[b]Cost:[/b] " + str(get_price()) + " Beenes"

func _on_pressed():
	if Global.click_count >= get_price():
		Global.click_count -= get_price()
		Global.has_jackpot = true
		level += 1
		Global.upgrade_levels[name] = level
		Global.save_data()
		if Global.has_method("update_upgrade_effects"):
			Global.update_upgrade_effects()
		
		if counter and counter.has_method("update_display"):
			counter.update_display()
			
		_update_tooltip_text()
		update_price_display()
