extends Node2D


func _ready() -> void:
	transition()

func transition():
	$AnimationPlayer.play("fade")
	await get_tree().create_timer(3.5).timeout
	get_tree().change_scene_to_file("res://main.tscn")
