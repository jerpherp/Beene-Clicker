extends Node2D

@onready var fight_results = $CanvasLayer/FightResults
@onready var beene_main = $Area2D/BeeneMain

@onready var bg_ground = $BeachGround
@onready var bg_water = $BeachWater
@onready var bg_sky = $BeachSky
@onready var bg_foreground = $Foreground
@onready var snow = $Snow

@onready var bg_music = $BackgroundMusic

@onready var animation_player = $CanvasLayer/AnimationPlayer

var backgrounds := [
	{
		"ground": "res://mainGame/backgrounds/beach/beachGround.png",
		"water": "res://mainGame/backgrounds/beach/water.png", 
		"sky": "res://mainGame/backgrounds/beach/sky.png",
		"foreground": "",
		"music": "res://music/Seaside_Shuffle.ogg",
	},
	{
		"ground": "res://mainGame/backgrounds/mountains/mountains.png",
		"water": "res://mainGame/backgrounds/mountains/farMountains.png",
		"sky": "res://mainGame/backgrounds/mountains/sky.png",
		"foreground": "res://mainGame/backgrounds/mountains/foreground.png",
		"music": "res://music/Moonlit_Mountain.ogg",
	},
]

func _apply_background():
	var bg = backgrounds[Global.current_background]
	bg_ground.texture = load(bg["ground"])
	bg_water.texture = load(bg["water"])
	bg_sky.texture = load(bg["sky"])
	bg_foreground.texture = load(bg["foreground"])
	snow.visible = Global.current_background == 1
	
	var new_music = load(bg["music"])
	if bg_music.stream != new_music:
		bg_music.stream = new_music
		bg_music.play()

func _ready():
	animation_player.play("fade_out")
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

	if Global.last_unlocked_bosses and Global.last_unlocked_bosses.size() > 0:
		var boss_idx = Global.last_unlocked_bosses[Global.last_unlocked_bosses.size() - 1]
		Global.last_unlocked_bosses = []
		beene_main.play_animation("spook")
		await beene_main.animation_finished
		var boss_select = get_tree().get_root().get_node("Main/CanvasLayer/BossSelect")
		boss_select.current_index = boss_idx
		boss_select.open()
		
	if Global.show_fight_results:
		Global.show_fight_results = false
		await get_tree().create_timer(2.0).timeout
		fight_results.show_results()
