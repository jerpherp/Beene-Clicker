extends Node2D

var active := false
var trail_x := 0.0
var trail_y := 0.0
var trail_points := []
var speed := 2300.0
var trail_length := 25

@export var start_position := Vector2(250, 150)

func _ready():
	visible = false

func trigger():
	visible = true
	active = true
	trail_points.clear()
	trail_x = start_position.x
	trail_y = start_position.y
	
	await get_tree().create_timer(0.5).timeout
	active = false
	visible = false

func _process(delta):
	if not active:
		return
	
	trail_x += speed * delta
	trail_y += speed * 0.2 * delta
	trail_points.append(Vector2(trail_x, trail_y))
	
	if trail_points.size() > trail_length:
		trail_points.pop_front()
	
	if trail_x > 1400:
		trail_points.clear()
		trail_x = -200.0
		trail_y = -200.0
	
	queue_redraw()

func _draw():
	if not active or trail_points.size() < 2:
		return
	
	for i in trail_points.size() - 1:
		var alpha = float(i) / trail_points.size()
		var width = lerp(2.0, 15.0, alpha)
		draw_line(trail_points[i], trail_points[i + 1], Color(1, 1, 1, alpha), width)
