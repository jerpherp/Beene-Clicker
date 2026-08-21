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
	"attack": 1.0,
	"hit": 1.0,
	"idle": 0.0,
	"knockout": 0.0,
}

func _ready():
	animation_finished.connect(_on_animation_finished)
	play("idle")


# Cleaned: removed commented testing handlers to declutter file

func _on_animation_finished():
	if animation == "knockout":
		frame = loop_start_frame
		play("knockout")
	if animation != "idle" and animation != "knockout" and animation != "attack":
		var linger = animation_linger.get(animation, 0.0)
		if linger > 0.0:
			await get_tree().create_timer(linger).timeout
		play_animation("idle")

func play_animation(anim_name: String):
	play(anim_name)
	if animation_offsets.has(anim_name):
		offset = animation_offsets[anim_name]
		
func trigger_attack_feathers():
	attack_bubbles.speed_scale = 8.0
	attack_bubbles.restart()
	attack_bubbles.emitting = true
