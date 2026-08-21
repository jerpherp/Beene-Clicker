extends Control

@export var slide_duration := 0.4

# Node References
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

# Sprite Textures for Stars - Adjust file paths to match your assets!
const STAR_FULL_TEX = preload("res://hud/star.png")   
const STAR_EMPTY_TEX = preload("res://hud/starFull.png") 

# Container generated dynamically via code
var stars_container: HBoxContainer
var star_rects: Array[TextureRect] = []

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
	
	# Add hover to all buttons
	for btn in [left_btn, right_btn, info_btn]:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.mouse_entered.connect(_on_hover.bind(btn))
		btn.mouse_exited.connect(_on_exit.bind(btn))
		
	bg_rect.gui_input.connect(_on_bg_clicked)
	
	# Dynamically build the 5-star container and texture rects
	_setup_stars_ui()
		
	update_display()

# Creates the 5 stars via code
func _setup_stars_ui():
	stars_container = HBoxContainer.new()
	stars_container.name = "StarsContainer"
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_container.add_theme_constant_override("separation", 6)
	
	boss_panel.add_child(stars_container)
	
	stars_container.position = Vector2(-185, 220) 
	stars_container.size = Vector2(200, 30)
	
	for i in range(5):
		var star = TextureRect.new()
		star.custom_minimum_size = Vector2(70, 70)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stars_container.add_child(star)
		star_rects.append(star)

# Updates star textures dynamically
func _update_star_sprites(rating: int, unlocked: bool):
	for i in range(star_rects.size()):
		var star = star_rects[i]
		if unlocked and i < rating:
			star.texture = STAR_FULL_TEX
			star.modulate = Color.WHITE
		else:
			star.texture = STAR_EMPTY_TEX
			# Dim empty stars slightly when locked
			star.modulate = Color.WHITE if unlocked else Color(0.4, 0.4, 0.4, 0.5)

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
	current_index = (current_index - 1 + Global.boss_data.size()) % Global.boss_data.size()
	update_display()

func _on_right():
	current_index = (current_index + 1) % Global.boss_data.size()
	update_display()

func update_display():
	Global.refresh_boss_unlocks()
	var data = Global.boss_data[current_index]
	var unlocked = Global.bosses_unlocked[current_index]
	
	# Default rating: Boss 1 = 1 star, Boss 2 = 2 stars, etc.
	# If defined in dictionary as data["difficulty"], it uses that instead
	var difficulty_stars = data.get("difficulty", current_index + 1)
	
	if unlocked:
		boss_name.text = data["name"]
		boss_desc.text = data["desc"]
		boss_image.texture = load(data["image"])
		boss_image.modulate = Color.WHITE
		boss_name.modulate = Color.WHITE
		
		_update_star_sprites(difficulty_stars, true)
		panel_btn.disabled = false
	else:
		# Mask locked boss details
		boss_name.text = "???"
		boss_desc.text = "???"
		boss_image.texture = load(data["image"])
		boss_image.modulate = Color(0.15, 0.15, 0.15, 0.8) # Dark silhouette
		boss_name.modulate = Color(0.6, 0.6, 0.6)
		
		_update_star_sprites(0, false) # Show all empty stars for locked boss
		panel_btn.disabled = true

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
