extends Node2D
@export var max_health := 100
@export var bar_width := 300
@export var hurt_threshold_percent := 0.2
@export var icon : AnimatedSprite2D

var current_health := 100

@onready var fill = $healthBarTop
@onready var bonus_label = get_tree().get_root().get_node("Fight/HUD/BonusHP")

@export var hurt_animation := "hurt"
@export var normal_animation := "normal"

func _resolve_icon_animation(animation_name: String) -> String:
	if icon == null or icon.sprite_frames == null:
		return ""
	if icon.sprite_frames.has_animation(animation_name):
		return animation_name
	if animation_name == "hurt" and icon.sprite_frames.has_animation("hurt_apple"):
		return "hurt_apple"
	if animation_name == "normal" and icon.sprite_frames.has_animation("normal_apple"):
		return "normal_apple"
	if animation_name == "hurt_apple" and icon.sprite_frames.has_animation("hurt"):
		return "hurt"
	if animation_name == "normal_apple" and icon.sprite_frames.has_animation("normal"):
		return "normal"
	return ""

func _ready():
	_update_bonus_label()
	update_bar()
	
func _update_bonus_label():
	bonus_label.visible = Global.owned_items.get("health_potion", false)
	
func setup(new_max_health: int):
	max_health = new_max_health
	current_health = new_max_health
	update_bar()

func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	update_bar()

func heal(amount: int):
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	update_bar()

func update_bar():
	var percent = float(current_health) / float(max_health)
	var tween = create_tween()
	tween.tween_property(fill, "size:x", bar_width * percent, 0.2)
	
	if icon:
		var desired_anim = hurt_animation if percent <= hurt_threshold_percent else normal_animation
		var resolved_anim = _resolve_icon_animation(desired_anim)
		if resolved_anim != "" and icon.animation != resolved_anim:
			icon.play(resolved_anim)
