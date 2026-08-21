extends Control

@export var slide_duration := 0.4
@onready var bg = $Background
@onready var close_btn = $CloseButton
@onready var music_slider = $MusicSlider
@onready var sfx_slider = $SFXSlider
@onready var screen_options = $ScreenOptions

var shown_x : float

func _ready():
	visible = false
	shown_x = position.x
	position.x = get_viewport_rect().size.x + 400
	
	close_btn.pressed.connect(close)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	screen_options.item_selected.connect(_on_screen_size_changed)
	
	music_slider.min_value = -80.0
	music_slider.max_value = 0.0
	music_slider.value = Global.music_volume
	
	sfx_slider.min_value = -80.0
	sfx_slider.max_value = 0.0
	sfx_slider.value = Global.sfx_volume
	
	screen_options.clear()
	screen_options.add_item("1280x720")
	screen_options.add_item("1920x1080")
	screen_options.add_item("Fullscreen")
	
	if Global.screen_size_index >= 0 and Global.screen_size_index < screen_options.item_count:
		screen_options.selected = Global.screen_size_index

func open():
	visible = true
	screen_options.selected = Global.screen_size_index
	
	position.x = get_viewport_rect().size.x + 400
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", shown_x, slide_duration)

func close():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", get_viewport_rect().size.x + 400, slide_duration)
	await tween.finished
	visible = false

func _on_music_changed(value: float):
	Global.music_volume = value
	Global.apply_volumes()
	Global.save_data()

func _on_sfx_changed(value: float):
	Global.sfx_volume = value
	Global.apply_volumes()
	Global.save_data()

func _on_screen_size_changed(index: int):
	Global.screen_size_index = index
	Global.apply_screen_size()
	Global.save_data()
