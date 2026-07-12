extends Node2D

@export var max_health := 100
@export var bar_width := 300
@export var hurt_threshold := 20
@export var icon : AnimatedSprite2D

var current_health := 100

@onready var fill = $healthBarTop

@export var hurt_animation := "hurt_apple"
@export var normal_animation := "normal_apple"

func _ready():
	update_bar()
	
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
		if current_health <= hurt_threshold:
			icon.play(hurt_animation)
		else:
			icon.play(normal_animation)
