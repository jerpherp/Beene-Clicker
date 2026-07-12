extends Control

@export var slide_duration := 0.8

@onready var left_graphic = $Pause
@onready var right_graphic = $BeeneAtTable
@onready var dimmer = $Dimmer

@onready var continue_btn = $ButtonContainer/ContinueButton
@onready var leave_btn = $ButtonContainer/LeaveFightButton
@onready var button_container = $ButtonContainer

@onready var music = get_tree().get_root().get_node("Fight/BackgroundMusic")

var left_shown_x : float
var right_shown_x : float
var buttons_shown_x : float

func _ready():
	visible = false
	
	# store the final positions
	left_shown_x = left_graphic.position.x
	right_shown_x = right_graphic.position.x
	buttons_shown_x = button_container.position.x
	
	# buttons
	continue_btn.pressed.connect(unpause)
	leave_btn.pressed.connect(_on_leave_fight)

func pause():
	visible = true
	get_tree().paused = true
	
	# for music
	var music_tween = create_tween()
	music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.tween_property(music, "volume_db", -20.0, 0.5)
	
	# start offscreen
	left_graphic.position.x = -400
	right_graphic.position.x = get_viewport_rect().size.x + 400
	button_container.position.x = -400
	dimmer.modulate.a = 0.0
	
	# animate in
	var tween = create_tween().set_parallel(true)
	tween.tween_property(left_graphic, "position:x", left_shown_x, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(right_graphic, "position:x", right_shown_x, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button_container, "position:x", buttons_shown_x, slide_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.2)
	tween.tween_property(dimmer, "modulate:a", 1.0, slide_duration)

func unpause():
	# for music
	var music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", 0.0, 0.5)
	
	get_tree().paused = false
	visible = false

func _on_leave_fight():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
