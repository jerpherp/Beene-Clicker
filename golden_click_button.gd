extends TextureButton

@export var hover_scale := Vector2(1.1, 1.1)
@export var scale_duration := 0.15

@export var title := "Golden Click"
@export var description := "Increases Golden Click amount by +10 Beenes per level."

@export var base_price := 100
@export var exponent := 1.15
var level := 1

@onready var counter = get_tree().get_root().get_node("Main/ClickCounter")
@onready var tooltip = $Tooltip

var original_scale: Vector2

func _ready():
	var upgrade_name = name
	if Global.upgrade_levels.has(upgrade_name):
		level = int(Global.upgrade_levels[upgrade_name])
	
	# Sync level with Global script variable
	Global.golden_click_level = level
	
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

# Exponential cost formula based on current upgrade level
func get_price() -> int:
	return int(floor(base_price * pow(exponent, level - 1)))

# Calculates current payout bonus for tooltip preview
func get_current_payout() -> int:
	var base_payout = level * 10
	var mult = Global.global_multiplier if "global_multiplier" in Global else 1.0
	return int(base_payout * mult)

func update_price_display():
	if has_node("PriceLabel"):
		$PriceLabel.text = str(get_price())

func _update_tooltip_text():
	var current_payout = get_current_payout()
	$Tooltip/UpgradeDesc.text = "[b]" + title + "[/b]\nLevel " + str(level) + "\n" + description + "\nCurrent Bonus: +" + str(current_payout) + " Beenes\n[b]Cost:[/b] " + str(get_price()) + " Beenes"

func _on_pressed():
	var price = get_price()
	
	if Global.click_count >= price:
		Global.click_count -= price
		Global.has_golden_click = true
		
		# Upgrade Level
		level += 1
		Global.upgrade_levels[name] = level
		Global.golden_click_level = level
		
		# Save & Refresh UI
		Global.save_data()
		
		if counter and counter.has_method("update_display"):
			counter.update_display()
			
		_update_tooltip_text()
		update_price_display()
