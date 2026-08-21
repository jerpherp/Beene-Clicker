extends AnimatedSprite2D

var animation_offsets = {
	"idle": Vector2(0, 0),
	"spook": Vector2(6, -140),
	"levelUp": Vector2(0, -15),
	"yippie": Vector2(-200, -340),
}

var animation_scales = {
	"idle": Vector2(0.86, 0.86),
	"spook": Vector2(0.86, 0.86),
	"levelUp": Vector2(0.86, 0.86),
	"yippie": Vector2(0.68, 0.68),
}

#FOR TESTING OFFSETS
#func _input(event):
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_1:
			#play_animation("idle")
		#if event.keycode == KEY_2:
			#play_animation("yippie")

func _ready():
	animation_changed.connect(_on_animation_changed)
	animation_finished.connect(_on_animation_finished)
	if Global.play_yippie:
		Global.play_yippie = false
		modulate.a = 0.0  # start invisible
		play("idle")  # set idle but invisible
		await get_tree().create_timer(0.5).timeout
		modulate.a = 1.0  # show
		play_animation("yippie")
	else:
		play("idle")


func _on_animation_changed():
	if animation_offsets.has(animation):
		offset = animation_offsets[animation]


func _on_animation_finished():
	if animation == "levelUp":
		await get_tree().create_timer(1.8).timeout
		play_animation("idle")
	elif animation == "yippie":
		play_animation("idle")
		
		
func play_animation(anim_name: String):
	play(anim_name)
	if animation_offsets.has(anim_name):
		offset = animation_offsets[anim_name]
	if animation_scales.has(anim_name):
		scale = animation_scales[anim_name]
