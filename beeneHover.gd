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
	
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if event is InputEventMouseMotion:
		if not is_hovered:
			is_hovered = true
			_animate_scale(hover_scale)

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			click_sfx.pitch_scale = randf_range(0.6, 1.2)
			click_sfx.play()
			
			var multiplier = Global.click_multiplier
			Global.total_clicks += 1
			
			if Global.click_frenzy_active:
				multiplier *= 3
			
			if Global.has_golden_click:
				Global.golden_click_counter += 1
				if Global.golden_click_counter >= 100:
					Global.golden_click_counter = 0
					multiplier *= 10
					_show_golden_click()
			
			if Global.has_jackpot:
				if randf() < Global.jackpot_chance:
					multiplier *= Global.jackpot_multiplier
					_show_jackpot()
			
			Global.total_beenes += multiplier

			var newly := Global.add_clicks(multiplier)

			counter.update_display()
			combo_sprite.trigger()
			if newly.size() > 0:
				var boss_idx = newly[newly.size() - 1]
				var beene = $BeeneMain
				beene.play_animation("spook")
				await beene.animation_finished
				Global.current_boss = boss_idx + 1
				Global.fight_config = Global.boss_data[boss_idx]["config"]
				var music = get_tree().get_root().get_node("Main/BackgroundMusic")
				var fade_overlay = get_tree().get_root().get_node("Main/CanvasLayer/TransitionOverlay")
				var music_tween = create_tween()
				music_tween.tween_property(music, "volume_db", -30.0, 0.8)
				var tween = create_tween()
				tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.75)
				await tween.finished
				Global.save_data()
				get_tree().change_scene_to_file("res://fight.tscn")

func _show_golden_click():
	var tween = create_tween()
	tween.tween_property($BeeneMain, "modulate", Color(1.5, 1.2, 0.0), 0.1)
	tween.tween_property($BeeneMain, "modulate", Color.WHITE, 0.3)
	
func _show_jackpot():
	var tween = create_tween()
	tween.tween_property($BeeneMain, "modulate", Color(2.0, 1.5, 0.0), 0.1)
	tween.tween_property($BeeneMain, "modulate", Color.WHITE, 0.5)

func _on_mouse_exited():
	is_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_animate_scale(original_scale)
	
func _trigger_fight():
	input_pickable = false
	
	var beene = $BeeneMain
	beene.play_animation("spook")
	await beene.animation_finished

	Global.current_boss = 1
	Global.fight_config = Global.boss_data[0]["config"]

	var music = get_tree().get_root().get_node("Main/BackgroundMusic")
	var fade_overlay = get_tree().get_root().get_node("Main/CanvasLayer/TransitionOverlay")
	var music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", -30.0, 0.8)
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.75)
	await tween.finished

	Global.save_data()
	get_tree().change_scene_to_file("res://fight.tscn")


func _animate_scale(target: Vector2):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target, scale_duration)
