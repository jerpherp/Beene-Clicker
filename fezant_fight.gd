extends AnimatedSprite2D

@export var loop_start_frame := 62

@onready var attack_bubbles = $AttackFeathers

var animation_offsets = {
	"attack": Vector2(-10, 0),
	"hit": Vector2(-80, 0),
	"idle": Vector2(0, 0),
	"knockout": Vector2(-78, -192),
}

var animation_linger = {
	"attack": 0.0,
	"hit": 1.0,
	"idle": 0.0,
	"knockout": 0.0,
}

func _ready():
	animation_finished.connect(_on_animation_finished)
	play("idle")

func _on_animation_finished():
	var fight_node = get_node_or_null("/root/Fight/whos_turn")
	if fight_node and fight_node.is_qte_active:
		return

	if animation != "idle" and animation != "knockout" and animation != "attack":
		var linger = animation_linger.get(animation, 0.0)
		if linger > 0.0:
			await get_tree().create_timer(linger).timeout

func play_animation(anim_name: String):
	speed_scale = 1.0
	play(anim_name)
	if animation_offsets.has(anim_name):
		offset = animation_offsets[anim_name]
		
func trigger_attack_feathers():
	attack_bubbles.speed_scale = 8.0
	attack_bubbles.restart()
	attack_bubbles.emitting = true
