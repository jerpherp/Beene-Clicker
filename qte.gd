extends Control

signal qte_completed(success: bool)

enum QTEType { TIMING_BAR, RANDOM_KEY, TIMING_CIRCLE }

@export var time_limit := 3.5
@export var sweet_spot_size := 0.15
@export var bar_width := 400.0
var timeout_timer : SceneTreeTimer = null

var current_type : QTEType
var active := false
var marker_pos := 0.0
var marker_dir := 1.0
var circle_scale := 0.0
var target_key := KEY_NONE
var sweet_x_ratio := 0.5

const RANDOM_KEYS = [KEY_A, KEY_S, KEY_D, KEY_F, KEY_J, KEY_K, KEY_L]
const KEY_NAMES = {
	KEY_A: "A", KEY_S: "S", KEY_D: "D", KEY_F: "F",
	KEY_J: "J", KEY_K: "K", KEY_L: "L"
}

var bar_border : ColorRect
var bar_bg : ColorRect
var bar_sweet : ColorRect
var bar_marker : ColorRect
var key_label : Label
var outer_circle : ColorRect
var inner_circle : ColorRect
var outer_border : ColorRect

func _ready():
	visible = false
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()

func _build_ui():
	var center = get_viewport_rect().size / 2

	# --- TIMING BAR ---
	bar_border = ColorRect.new()
	bar_border.size = Vector2(bar_width + 6, 36)
	bar_border.position = Vector2(center.x - bar_width / 2 - 3, center.y + 97)
	bar_border.color = Color.WHITE
	add_child(bar_border)

	bar_bg = ColorRect.new()
	bar_bg.size = Vector2(bar_width, 30)
	bar_bg.position = Vector2(center.x - bar_width / 2, center.y + 100)
	bar_bg.color = Color(0.2, 0.2, 0.2)
	add_child(bar_bg)

	bar_sweet = ColorRect.new()
	bar_sweet.size = Vector2(sweet_spot_size * bar_width, 30)
	bar_sweet.color = Color(0.0, 0.9, 0.3)
	bar_bg.add_child(bar_sweet)

	bar_marker = ColorRect.new()
	bar_marker.size = Vector2(6, 30)
	bar_marker.color = Color(1.0, 0.2, 0.2)
	bar_bg.add_child(bar_marker)

	# --- KEY PROMPT ---
	key_label = Label.new()
	key_label.add_theme_font_size_override("font_size", 80)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.position = Vector2(center.x - 100, center.y - 60)
	key_label.size = Vector2(200, 120)
	add_child(key_label)

	# --- TIMING CIRCLE ---
	outer_border = ColorRect.new()
	outer_border.size = Vector2(126, 126)
	outer_border.position = Vector2(center.x - 63, center.y - 63)
	outer_border.color = Color.WHITE
	add_child(outer_border)
	
	outer_circle = ColorRect.new()
	outer_circle.size = Vector2(120, 120)
	outer_circle.position = Vector2(center.x - 60, center.y - 60)
	outer_circle.color = Color(0.3, 0.3, 0.3)
	add_child(outer_circle)

	inner_circle = ColorRect.new()
	inner_circle.size = Vector2(120, 120) 
	inner_circle.color = Color(1.0, 0.8, 0.0)
	inner_circle.pivot_offset = Vector2(60, 60)
	inner_circle.position = Vector2(center.x - 60, center.y - 60)
	add_child(inner_circle)

func _hide_all():
	bar_border.visible = false
	bar_bg.visible = false
	key_label.visible = false
	outer_border.visible = false
	outer_circle.visible = false
	inner_circle.visible = false

func start():
	# cancel any existing timeout timer
	if timeout_timer != null:
		timeout_timer.timeout.disconnect(_on_timeout)
		timeout_timer = null
	
	visible = true
	active = true
	marker_pos = 0.0
	marker_dir = 1.0
	circle_scale = 0.1
	_hide_all()
	
	# pause all animations
	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer3/beeneFight").pause()
	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer/beachBG").pause()

	current_type = randi() % 3 as QTEType

	match current_type:
		QTEType.TIMING_BAR:
			bar_border.visible = true
			bar_bg.visible = true
			bar_marker.visible = true
			sweet_x_ratio = randf_range(0.2, 0.7)
			bar_sweet.position.x = sweet_x_ratio * bar_width - bar_sweet.size.x / 2
			timeout_timer = get_tree().create_timer(Global.fight_config["qte_time_limit"])
			timeout_timer.timeout.connect(_on_timeout)

		QTEType.RANDOM_KEY:
			key_label.visible = true
			var key_index = randi() % RANDOM_KEYS.size()
			target_key = RANDOM_KEYS[key_index]
			key_label.text = "Press  " + KEY_NAMES[target_key] + "!"
			timeout_timer = get_tree().create_timer(Global.fight_config["qte_time_limit"])
			timeout_timer.timeout.connect(_on_timeout)

		QTEType.TIMING_CIRCLE:
			outer_border.visible = true
			outer_circle.visible = true
			inner_circle.visible = true
			inner_circle.scale = Vector2(0.1, 0.1)

func _process(delta):
	if not active:
		return
	match current_type:
		QTEType.TIMING_BAR:
			marker_pos += delta * Global.fight_config["qte_speed"] * marker_dir
			if marker_pos >= 1.0 or marker_pos <= 0.0:
				marker_dir *= -1.0
			bar_marker.position.x = marker_pos * bar_width
		QTEType.TIMING_CIRCLE:
			circle_scale += delta * Global.fight_config["qte_speed"] * 0.4
			inner_circle.scale = Vector2(circle_scale, circle_scale)
			if circle_scale >= 1.4:
				_finish(false)

func _input(event):
	if not active:
		return
	if not event is InputEventKey or not event.pressed:
		return

	match current_type:
		QTEType.TIMING_BAR:
			if event.keycode == KEY_SPACE:
				var in_sweet = abs(marker_pos - sweet_x_ratio) < sweet_spot_size
				_finish(in_sweet)

		QTEType.RANDOM_KEY:
			if event.keycode == target_key:
				_finish(true)
			else:
				_finish(false)

		QTEType.TIMING_CIRCLE:
			if event.keycode == KEY_SPACE:
				var success = circle_scale >= 0.7 and circle_scale <= 1.1
				_finish(success)

func _on_timeout():
	if active:
		_finish(false)

func _finish(success: bool):
	active = false
	visible = false
	
	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer3/beeneFight").play()
	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer/beachBG").play()
	
	emit_signal("qte_completed", success)
