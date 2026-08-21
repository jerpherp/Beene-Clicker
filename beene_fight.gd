extends AnimatedSprite2D

var animation_offsets = {
	"attack": Vector2(-140, -10),
	"dodge": Vector2(0, -150),
	"finish": Vector2(0, -20),
	"getHit": Vector2(40, -20),
	"idle": Vector2(0, 0),
	"knockout": Vector2(-160, -15),
}

var animation_linger = {
	"attack": 0.0,
	"dodge": 0.8,
	"finish": 5.0,
	"getHit": 1.0,
	"idle": 0.0,
	"knockout": 0.0,
}

func _ready():
	animation_finished.connect(_on_animation_finished)
	play("idle")

func _on_animation_finished():
	if animation != "idle" and animation != "knockout":
		var linger = animation_linger.get(animation, 0.0)
		if linger > 0.0:
			await get_tree().create_timer(linger).timeout
		play_animation("idle")

func play_animation(anim_name: String):
	play(anim_name)
	if animation_offsets.has(anim_name):
		offset = animation_offsets[anim_name]
