extends Control

@export var slide_duration := 0.4

@onready var left_btn = $LeftButton
@onready var right_btn = $RightButton
@onready var info_btn = $InfoButton
@onready var boss_image = $BossPanel/BossImage
@onready var boss_name = $BossPanel/BossName
@onready var boss_desc = $BossPanel/BossDesc
@onready var boss_panel = $BossPanel
@onready var bg_rect = $ColorRect
@onready var fade_overlay = get_tree().get_root().get_node("Main/CanvasLayer/TransitionOverlay")
@onready var panel_btn = $BossPanelButton
@onready var music = get_tree().get_root().get_node("Main/BackgroundMusic")

var current_index := 0
var shown_x : float

func _ready():
	visible = false
	shown_x = position.x
	position.x = get_viewport_rect().size.x + 400
	
	panel_btn.pressed.connect(_on_fight)
	panel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	left_btn.pressed.connect(_on_left)
	right_btn.pressed.connect(_on_right)
	
	# add hover to all buttons
	for btn in [left_btn, right_btn, info_btn]:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.mouse_entered.connect(_on_hover.bind(btn))
		btn.mouse_exited.connect(_on_exit.bind(btn))
		
	bg_rect.gui_input.connect(_on_bg_clicked)
		
	update_display()

func _on_hover(btn: TextureButton):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15)

func _on_exit(btn: TextureButton):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.15)

func open():
	visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", shown_x, slide_duration)

func close():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", get_viewport_rect().size.x + 400, slide_duration)
	await tween.finished
	visible = false

func _on_left():
	current_index = (current_index - 1 + 5) % 5
	update_display()

func _on_right():
	current_index = (current_index + 1) % 5
	update_display()

func update_display():
	var data = Global.boss_data[current_index]
	var unlocked = Global.bosses_unlocked[current_index]
	
	boss_name.text = data["name"]
	boss_desc.text = data["desc"]
	boss_image.texture = load(data["image"])

	if unlocked:
		boss_image.modulate = Color.WHITE
		boss_name.modulate = Color.WHITE
	else:
		boss_image.modulate = Color(0.3, 0.3, 0.3)
		boss_name.modulate = Color(0.3, 0.3, 0.3)

func _on_fight():
	if Global.bosses_unlocked[current_index]:
		Global.current_boss = current_index + 1
		Global.fight_config = Global.boss_data[current_index]["config"]
		await _fade_and_go()

func _on_bg_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		close()

func _on_panel_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		_on_fight()

func _input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close()
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_fight()

func _fade_and_go():
	var music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", -30.0, 0.8)
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.75)
	await tween.finished
	get_tree().change_scene_to_file(Global.boss_data[current_index]["scene"])
