extends Node2D

@onready var fight_results = $CanvasLayer/FightResults
@onready var beene_main = $Area2D/BeeneMain

@onready var bg_ground = $BeachGround
@onready var bg_water = $BeachWater
@onready var bg_sky = $BeachSky
@onready var bg_foreground = $Foreground
@onready var snow = $Snow

var backgrounds := [
	{
		"ground": "res://mainGame/backgrounds/beach/beachGround.png",
		"water": "res://mainGame/backgrounds/beach/water.png", 
		"sky": "res://mainGame/backgrounds/beach/sky.png",
		"foreground": "",
	},
	{
		"ground": "res://mainGame/backgrounds/mountains/mountains.png",
		"water": "res://mainGame/backgrounds/mountains/farMountains.png",
		"sky": "res://mainGame/backgrounds/mountains/sky.png",
		"foreground": "res://mainGame/backgrounds/mountains/foreground.png",
	},
]

func _apply_background():
	var bg = backgrounds[Global.current_background]
	# only snow for the mountains!	
	if (Global.current_background == 1):
		snow.show()
	else:
		snow.hide()
	bg_ground.texture = load(bg["ground"])
	bg_water.texture = load(bg["water"])
	bg_sky.texture = load(bg["sky"])
	bg_foreground.texture = load(bg["foreground"])

func _ready():
	_apply_background()
	
	for i in Global.helper_beene_count:
		var new_helper = load("res://helper_beene.tscn").instantiate()
		new_helper.angle = i * (TAU / max(Global.helper_beene_count, 1))
		get_node("Area2D").add_child(new_helper)
		new_helper.activate()

	if Global.play_yippie:
		Global.play_yippie = false
		await get_tree().create_timer(0.5).timeout
		beene_main.play_animation("yippie")
		await beene_main.animation_finished
		await get_tree().create_timer(0.5).timeout
		
	if Global.show_fight_results:
		Global.show_fight_results = false
		await get_tree().create_timer(2.0).timeout
		fight_results.show_results()
