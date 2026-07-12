extends AnimatedSprite2D

var animation_offsets = {
	"attack": Vector2(50, 10),   # tune these
	"hit": Vector2(0, 0),
	"idle": Vector2(0, 0),
	"knockout": Vector2(-500, -40),
}

#FOR TESTING OFFSETS
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			play_animation("attack")
		if event.keycode == KEY_2:
			play_animation("hit")
		if event.keycode == KEY_3:
			play_animation("idle")
		if event.keycode == KEY_4:
			play_animation("knockout")

var animation_linger = {
	"attack": 0.0,
	"hit": 3.0,
	"idle": 0.0,
	"knockout": 0.0,
}

func _ready():
	animation_finished.connect(_on_animation_finished)
	play("idle")

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
