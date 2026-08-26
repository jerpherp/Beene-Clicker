extends AnimatedSprite2D

@onready var eye_beam_glow := $EyeBeamGlow
@onready var eye_beam := $EyeBeam

var animation_offsets = {
	"attack": Vector2(0, 10),
	"hit": Vector2(80, 0),
	"idle": Vector2(0, 0),
	"knockout": Vector2(0, 0),
}

var animation_linger = {
	"attack": 0.0,
	"hit": 0.5,
	"idle": 0.0,
	"knockout": 0.0,
}
func _ready():
	animation_finished.connect(_on_animation_finished)
	play("idle")
	_setup_eye_beam_visuals()

func _setup_eye_beam_visuals():
	eye_beam.width = 6
	eye_beam.default_color = Color(1, 1, 0.8, 1)
	eye_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	eye_beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	eye_beam.joint_mode = Line2D.LINE_JOINT_ROUND
	eye_beam.round_precision = 8
	eye_beam.visible = false

	eye_beam_glow.width = 24
	eye_beam_glow.default_color = Color(1, 0.9, 0.3, 0.35)
	eye_beam_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	eye_beam_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	eye_beam_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	eye_beam_glow.round_precision = 8
	eye_beam_glow.visible = false
	var glow_material = CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	eye_beam_glow.material = glow_material

func _on_animation_finished():
	var fight_node = get_node_or_null("/root/Fight/whos_turn")
	if fight_node and fight_node.is_qte_active:
		return

	if animation != "idle" and animation != "knockout" and animation != "attack":
		var linger = animation_linger.get(animation, 0.0)
		if linger > 0.0:
			await get_tree().create_timer(linger).timeout
		
func play_animation(anim_name: String):
	play(anim_name)
	if animation_offsets.has(anim_name):
		offset = animation_offsets[anim_name]

func trigger_eye_beam(target_global_pos: Vector2):
	eye_beam.visible = true
	eye_beam_glow.visible = true
	eye_beam.modulate.a = 1.0
	eye_beam_glow.modulate.a = 1.0
 
	var local_target = eye_beam.to_local(target_global_pos)
 
	var overshoot = 300.0
	local_target += local_target.normalized() * overshoot
 
	eye_beam.points = [Vector2.ZERO, Vector2.ZERO]
	eye_beam_glow.points = [Vector2.ZERO, Vector2.ZERO]
 
	var tween = create_tween()
	tween.tween_method(
		func(p):
			eye_beam.points = [Vector2.ZERO, p]
			eye_beam_glow.points = [Vector2.ZERO, p],
		Vector2.ZERO, local_target, 0.15
	)
	tween.tween_interval(0.2)
	tween.tween_property(eye_beam, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(eye_beam_glow, "modulate:a", 0.0, 0.25)
	await tween.finished
 
	eye_beam.visible = false
	eye_beam_glow.visible = false
