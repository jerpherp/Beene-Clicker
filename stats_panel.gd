extends Control

@export var slide_duration := 0.4

@onready var bg_rect: ColorRect = $ColorRect
@onready var stats_container: VBoxContainer = $StatsPanel/ScrollContainer/StatsContainer
@onready var close_btn: TextureButton = $StatsPanel/CloseButton

var shown_x: float

func _ready() -> void:
	visible = false
	shown_x = position.x
	position.x = get_viewport_rect().size.x + 400
	
	if bg_rect:
		bg_rect.gui_input.connect(_on_bg_clicked)
		
	if close_btn:
		close_btn.pressed.connect(close)
		close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func open() -> void:
	update_stats_display()
	visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", shown_x, slide_duration)

func close() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", get_viewport_rect().size.x + 400, slide_duration)
	await tween.finished
	visible = false

func update_stats_display() -> void:
	if not stats_container:
		return

	for child in stats_container.get_children():
		child.queue_free()

	var total_beenes: int = Global.get("total_beenes") if "total_beenes" in Global else Global.click_count
	var total_clicks: int = Global.get("total_clicks") if "total_clicks" in Global else Global.click_count
	var fights_fought: int = Global.get("fights_fought") if "fights_fought" in Global else 0
	var fights_won: int = Global.get("fights_won") if "fights_won" in Global else 0
	var fights_lost: int = Global.get("fights_lost") if "fights_lost" in Global else 0

	var stats_data := [
		{"label": "Total Beenes Earned", "val": _format_number(total_beenes)},
		{"label": "Total Clicks", "val": _format_number(total_clicks)},
		{"label": "Battles Fought", "val": _format_number(fights_fought)},
		{"label": "Battles Won", "val": _format_number(fights_won)},
		{"label": "Battles Lost", "val": _format_number(fights_lost)}
	]

	for stat in stats_data:
		_create_stat_row(stat["label"], str(stat["val"]))

func _create_stat_row(stat_label: String, stat_val: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	row.add_theme_constant_override("separation", 120)
	
	var name_lbl := Label.new()
	name_lbl.text = stat_label
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	
	var val_lbl := Label.new()
	val_lbl.text = stat_val
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	
	row.add_child(name_lbl)
	row.add_child(val_lbl)
	stats_container.add_child(row)

func _format_number(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func _on_bg_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and event is InputEventMouseButton:
		close()
