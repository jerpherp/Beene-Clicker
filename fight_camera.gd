extends Camera2D

@export var pan_duration := 1.2
@export var player_position := Vector2(630.0, 390.0)
@export var enemy_position := Vector2(468.0, 320.0)

@export var knockout_position := Vector2(930.0, 390.0)

@export var player_zoom := Vector2(1.3, 1.3)
@export var enemy_zoom := Vector2(0.7, 0.7)

func _ready():
	position = player_position

func pan_to_player():
	_pan_to(player_position)

func pan_to_enemy():
	_pan_to(enemy_position)
	
func pan_to_knockout():
	await get_tree().create_timer(0.5).timeout
	_pan_to(knockout_position)

func _pan_to(target: Vector2):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target, pan_duration)
