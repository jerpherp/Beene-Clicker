extends AnimatedSprite2D

@export var fade_in_duration := 1.0
@export var fade_out_duration := 0.5
@export var appear_threshold := randf_range(5, 10)
@export var timeout := 1.5
var base_multiplier: float = 1.0

var _timeout_timer : SceneTreeTimer = null
var _threshold_timer : SceneTreeTimer = null
var _is_visible := false

func _ready():
	modulate.a = 0.0
	stop()

func trigger():
	if _timeout_timer != null:
		_timeout_timer.time_left = timeout

	if _threshold_timer == null:
		_threshold_timer = get_tree().create_timer(appear_threshold)
		_threshold_timer.timeout.connect(_on_threshold_reached)

func _on_threshold_reached():
	if _is_visible:
		return
	_is_visible = true
	play()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	base_multiplier = Global.click_multiplier
	Global.click_multiplier = base_multiplier + 1.5
	_timeout_timer = get_tree().create_timer(timeout)
	_timeout_timer.timeout.connect(_on_idle)

func _on_idle():
	_threshold_timer = null
	_timeout_timer = null
	_is_visible = false
	Global.click_multiplier = base_multiplier
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	await tween.finished
	stop()
