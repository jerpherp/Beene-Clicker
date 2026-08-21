extends Node2D

@export var orbit_radius := 200.0
@export var orbit_speed := 1.5
@export var click_interval := 6.0

var angle := 0.0
var click_timer := 0.0
var active := false

@onready var sprite = $MiniBeene

func _ready():
	if Global.helper_beene_active:
		activate()

func activate():
	visible = true
	active = true
	Global.helper_beene_active = true
	Global.save_data()

func _process(delta):
	if not active:
		return
	
	angle += orbit_speed * delta
	position = Vector2(
		cos(angle) * orbit_radius + 100,
		sin(angle) * orbit_speed * orbit_radius * 1.1 + 180
	)
	
	click_timer += delta
	if click_timer >= click_interval:
		click_timer = 0.0
		_auto_click()

func _auto_click():
	var notify := not Global.in_fight
	var newly := Global.add_clicks(Global.click_multiplier, notify)
	get_tree().get_root().get_node("Main/ClickCounter").update_display()
	if newly.size() > 0:
		var boss_idx = newly[newly.size() - 1]
		var boss_select = get_tree().get_root().get_node("Main/CanvasLayer/BossSelect")
		boss_select.current_index = boss_idx
		boss_select.open()
