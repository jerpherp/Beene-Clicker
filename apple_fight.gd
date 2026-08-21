extends AnimatedSprite2D

# Offset for Apple animations
var animation_offsets = {
	"attack": Vector2(190, 0),
	"hit": Vector2(40, 0),
	"idle": Vector2(0, 0),
	"knockout": Vector2(15, 0),
}

# How long should the last frame play for when done?
var animation_linger = {
	"attack": 0.0,
	"hit": 3.0,
	"idle": 0.0,
	"knockout": 0.0,
}

func _ready():
	animation_finished.connect(_on_animation_finished)
	play("idle")


# Cleaned: removed commented testing handlers to declutter file

func _on_animation_finished():
	if animation != "idle" and animation != "knockout" and animation != "attack":
		var linger = animation_linger.get(animation, 0.0)
		if linger > 0.0:
			await get_tree().create_timer(linger).timeout
		play_animation("idle")

func play_animation(anim_name: String):
	play(anim_name)
	if animation_offsets.has(anim_name):
		offset = animation_offsets[anim_name]
