extends Control

@export var slide_duration := 1.5
@export var hidden_x := -335.0
@export var shown_x := 0.0

@onready var tab = $Button
@onready var slideSFX = $slideInWood

var is_open := false

func _ready():
	position.x = shown_x
	is_open = true
	tab.pressed.connect(_on_tab_pressed)

func toggle():
	slideSFX.pitch_scale = randf_range(0.6, 1.2)
	slideSFX.play()
	is_open = !is_open
	var target_x = shown_x if is_open else hidden_x
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", target_x, slide_duration)

func _on_tab_pressed():
	toggle()
