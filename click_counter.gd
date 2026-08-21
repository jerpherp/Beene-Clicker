extends Node2D

var digit_width := 45 

func _ready():
	update_display()


func increment():
	update_display()


func update_display():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	var digits = str(int(Global.click_count))
	for i in digits.length():
		var sprite = Sprite2D.new()
		sprite.texture = load("res://numbers/" + digits[i] + ".png")
		sprite.position.x = (i - digits.length()) * digit_width + 10
		add_child(sprite)
