extends Control

signal qte_completed(success: bool)

enum QTEType { TIMING_BAR, RANDOM_KEY, TIMING_CIRCLE, RAPID_TAP, HOLD }

@export var sweet_spot_size := 0.15
@export var bar_width := 400.0

var current_type : QTEType
var active := false
var marker_pos := 0.0
var marker_dir := 1.0
var circle_scale := 0.0
var target_key := KEY_NONE
var sweet_x_ratio := 0.5
var timeout_timer : SceneTreeTimer = null

var tap_progress := 0.0
var tap_decay := 0.3
var tap_required := 0.8

var hold_marker := 0.0
var hold_zone_start := 0.3
var hold_zone_end := 0.7
var is_holding := false

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

var tap_border : ColorRect
var tap_bg : ColorRect
var tap_fill : ColorRect
var tap_label : Label

var hold_border : ColorRect
var hold_bg : ColorRect
var hold_zone : ColorRect
var hold_marker_rect : ColorRect
var hold_label : Label

func _ready():
	visible = false
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()

func _build_ui():
	var center = get_viewport_rect().size / 2

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

	key_label = Label.new()
	key_label.add_theme_font_size_override("font_size", 80)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.position = Vector2(center.x - 100, center.y - 60)
	key_label.size = Vector2(200, 120)
	add_child(key_label)

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

	tap_label = Label.new()
	tap_label.text = "MASH SPACE!"
	tap_label.add_theme_font_size_override("font_size", 50)
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.position = Vector2(center.x - 200, center.y - 80)
	tap_label.size = Vector2(400, 60)
	add_child(tap_label)

	tap_border = ColorRect.new()
	tap_border.size = Vector2(bar_width + 6, 36)
	tap_border.position = Vector2(center.x - bar_width / 2 - 3, center.y + 97)
	tap_border.color = Color.WHITE
	add_child(tap_border)

	tap_bg = ColorRect.new()
	tap_bg.size = Vector2(bar_width, 30)
	tap_bg.position = Vector2(center.x - bar_width / 2, center.y + 100)
	tap_bg.color = Color(0.2, 0.2, 0.2)
	add_child(tap_bg)

	tap_fill = ColorRect.new()
	tap_fill.size = Vector2(0, 30)
	tap_fill.color = Color(0.2, 0.6, 1.0)
	tap_bg.add_child(tap_fill)

	hold_label = Label.new()
	hold_label.text = "HOLD SPACE!"
	hold_label.add_theme_font_size_override("font_size", 50)
	hold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hold_label.position = Vector2(center.x - 200, center.y - 80)
	hold_label.size = Vector2(400, 60)
	add_child(hold_label)

	hold_border = ColorRect.new()
	hold_border.size = Vector2(bar_width + 6, 36)
	hold_border.position = Vector2(center.x - bar_width / 2 - 3, center.y + 97)
	hold_border.color = Color.WHITE
	add_child(hold_border)

	hold_bg = ColorRect.new()
	hold_bg.size = Vector2(bar_width, 30)
	hold_bg.position = Vector2(center.x - bar_width / 2, center.y + 100)
	hold_bg.color = Color(0.2, 0.2, 0.2)
	add_child(hold_bg)

	hold_zone = ColorRect.new()
	hold_zone.size = Vector2((hold_zone_end - hold_zone_start) * bar_width, 30)
	hold_zone.position.x = hold_zone_start * bar_width
	hold_zone.color = Color(0.0, 0.9, 0.3)
	hold_bg.add_child(hold_zone)

	hold_marker_rect = ColorRect.new()
	hold_marker_rect.size = Vector2(6, 30)
	hold_marker_rect.color = Color(1.0, 0.2, 0.2)
	hold_bg.add_child(hold_marker_rect)

func _hide_all():
	bar_border.visible = false
	bar_bg.visible = false
	key_label.visible = false
	outer_border.visible = false
	outer_circle.visible = false
	inner_circle.visible = false
	tap_border.visible = false
	tap_bg.visible = false
	tap_label.visible = false
	hold_border.visible = false
	hold_bg.visible = false
	hold_label.visible = false

func _get_qte_pool() -> Array:
	if Global.current_boss <= 2:
		return [QTEType.TIMING_BAR, QTEType.RANDOM_KEY, QTEType.TIMING_CIRCLE]
	else:
		return [QTEType.TIMING_BAR, QTEType.RANDOM_KEY, QTEType.TIMING_CIRCLE, QTEType.RAPID_TAP, QTEType.HOLD]

func start():
	visible = true
	active = true
	marker_pos = 0.0
	marker_dir = 1.0
	circle_scale = 0.1
	tap_progress = 0.0
	hold_marker = 0.0
	is_holding = false
	_hide_all()

	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer3/beeneFight").pause()
	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer/beachBG").pause()

	var pool = _get_qte_pool()
	current_type = pool[randi() % pool.size()]

	if timeout_timer != null:
		if timeout_timer.timeout.is_connected(_on_timeout):
			timeout_timer.timeout.disconnect(_on_timeout)
		timeout_timer = null

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
			timeout_timer = get_tree().create_timer(Global.fight_config["qte_time_limit"])
			timeout_timer.timeout.connect(_on_timeout)

		QTEType.RAPID_TAP:
			tap_border.visible = true
			tap_bg.visible = true
			tap_label.visible = true
			tap_fill.size.x = 0
			timeout_timer = get_tree().create_timer(Global.fight_config["qte_time_limit"])
			timeout_timer.timeout.connect(_on_rapid_tap_timeout)

		QTEType.HOLD:
			hold_border.visible = true
			hold_bg.visible = true
			hold_label.visible = true
			hold_marker = 0.0
			timeout_timer = get_tree().create_timer(Global.fight_config["qte_time_limit"] * 1.5)
			timeout_timer.timeout.connect(_on_timeout)

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

		QTEType.RAPID_TAP:
			tap_progress = max(0.0, tap_progress - tap_decay * delta)
			tap_fill.size.x = tap_progress * bar_width

		QTEType.HOLD:
			if is_holding:
				hold_marker = min(1.0, hold_marker + delta * Global.fight_config["qte_speed"])
			else:
				hold_marker = max(0.0, hold_marker - delta * Global.fight_config["qte_speed"] * 0.5)
			hold_marker_rect.position.x = hold_marker * bar_width

func _input(event):
	if not active:
		return
	if not event is InputEventKey:
		return

	match current_type:
		QTEType.TIMING_BAR:
			if event.pressed and event.keycode == KEY_SPACE:
				var in_sweet = abs(marker_pos - sweet_x_ratio) < sweet_spot_size
				_finish(in_sweet)

		QTEType.RANDOM_KEY:
			if event.pressed:
				if event.keycode == target_key:
					_finish(true)
				elif event.keycode in RANDOM_KEYS:
					_finish(false)

		QTEType.TIMING_CIRCLE:
			if event.pressed and event.keycode == KEY_SPACE:
				var success = circle_scale >= 0.7 and circle_scale <= 1.1
				_finish(success)

		QTEType.RAPID_TAP:
			if event.pressed and event.keycode == KEY_SPACE:
				tap_progress = min(1.0, tap_progress + 0.15)
				tap_fill.size.x = tap_progress * bar_width

		QTEType.HOLD:
			if event.keycode == KEY_SPACE:
				if event.pressed:
					is_holding = true
				else:
					var in_zone = hold_marker >= hold_zone_start and hold_marker <= hold_zone_end
					_finish(in_zone)

func _on_timeout():
	if active:
		_finish(false)

func _on_rapid_tap_timeout():
	if active:
		_finish(tap_progress >= tap_required)

func _finish(success: bool):
	active = false
	visible = false
	is_holding = false

	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer3/beeneFight").play()
	get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer/beachBG").play()

	emit_signal("qte_completed", success)
