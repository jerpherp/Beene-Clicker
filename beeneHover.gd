extends Area2D

@export var hover_scale := Vector2(1.3, 1.3)
@export var scale_duration := 0.4

@onready var counter = get_tree().get_root().get_node("Main/ClickCounter")
@onready var combo_sprite = get_parent().get_node("ComboSprite")
@onready var click_sfx = $ClickSFX

var original_scale: Vector2
var is_hovered := false

func _ready():
	original_scale = scale
	input_pickable = true
	mouse_exited.connect(_on_mouse_exited)
	
	var save_timer = Timer.new()
	save_timer.wait_time = 1.0
	save_timer.autostart = true
	save_timer.timeout.connect(func(): Global.save_data())
	add_child(save_timer)


func _input_event(_viewport, event, _shape_idx):
	
#	FOR WHEN YOU HOVER OVER THE BEENE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if event is InputEventMouseMotion:
		if not is_hovered:
			is_hovered = true
			_animate_scale(hover_scale)

#	FOR WHEN YOU CLICK THE BEENE
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			click_sfx.pitch_scale = randf_range(0.6, 1.2)
			click_sfx.play()
			Global.click_count += Global.click_multiplier
			counter.update_display()
			combo_sprite.trigger()
			Global.save_data()
			
			# check if we should trigger the fight
			if Global.click_count >= randi_range(1000, 1200) and not Global.boss1_unlocked:
				_trigger_fight()


func _on_mouse_exited():
	is_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_animate_scale(original_scale)
	
func _trigger_fight():
	# disable further clicking
	input_pickable = false
	
	# play spook animation
	var beene = $BeeneMain
	beene.play_animation("spook")
	await beene.animation_finished
	
	# fade to black and go to fight
	Global.boss1_unlocked = true
	Global.save_data()
	get_tree().change_scene_to_file("res://fight.tscn")


func _animate_scale(target: Vector2):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target, scale_duration)
