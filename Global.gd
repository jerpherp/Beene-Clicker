extends Node

# THE TOTAL NUMBER OF BEENES CLICKED!
var click_count := 999911
# CLICK MULTIPLIER
var click_multiplier := 1

var equipped_attacks := ["", "", ""]
var unlocked_attacks := []

var music_volume := -10.0
var sfx_volume := -10.0

var play_yippie := false
var show_fight_results := false

var helper_beene_active := false
var helper_beene_count := 0

var current_boss := 3

var boss1_unlocked := false

var current_background := 1

var new_attacks := [] 

var attack_data := {
	"attack1": {"name": "Beene Bash", "desc": "A simple strike. Basic, but gets the job done", "source": "base", "damage": 4, "cooldown": false},
	"attack2": {"name": "Beene Rage", "desc": "Hits hard but slow. Cools down after one use.", "source": "base", "damage": 8, "cooldown": true},
	"boss1_attack1": {"name": "Seed Shrapnel", "desc": "Throws sharp seeds that do a good amount of damage.", "source": "boss1", "damage": 8, "cooldown": false},
	"boss1_attack2": {"name": "Newton's Downfall", "desc": "A high-gravity slam that does crushing damage to your opponent. Cools down after one use.", "source": "boss1", "damage": 15, "cooldown": true},
	"boss2_attack1": {"name": "Bubble Burst", "desc": "Blows a myriad of bubbles at your opponent. Sounds harmless, but packs a punch.", "source": "boss2", "damage": 18, "cooldown": false},
	"boss2_attack2": {"name": "Tidal Wave", "desc": "Creates a massive wave that crashes on your enemy. Cools down after one use.", "source": "boss2", "damage": 25, "cooldown": true},
	"boss3_attack1": {"name": "???", "desc": "???", "source": "boss3"},
	"boss3_attack2": {"name": "???", "desc": "???", "source": "boss3"},
}

var fight_config := {
	"enemy_health": 100,
	"base_damage": 20,
	"qte_speed": 1.5,
	"qte_count_min": 1,
	"qte_count_max": 2,
	"enemy_scene": "res://fight.tscn",
	"qte_time_limit": 2.2,
	"dodge_sound": "res://SFX/appleDodge.mp3",
}

var fight_stats := {
	"damage_taken": 0,
	"hits_dealt": 0,
	"attacks_used": 0,
	"fight_time": 0.0,
}
var fight_rank := ""
var fight_beene_reward := 0

func reset_fight_stats():
	fight_stats = {
		"damage_taken": 0,
		"hits_dealt": 0,
		"attacks_used": 0,
		"fight_time": 0.0,
	}
	
var upgrade_levels := {
	"x2": 1,
	"beeneHelper1": 1,
	"auto1": 1,
}

var bosses_unlocked := [true, false, false, false, false]

var boss_data := [
	{
		"name": "Apple Beene", 
		"desc": "A sour apple with a bad attitude.", 
		"scene": "res://fight.tscn",
		"image": "res://bosses/apple.png",
		"config": {
			"enemy_health": 100,
			"base_damage": randf_range(8, 15),
			"qte_speed": 1,
			"qte_count_min": 1,
			"qte_count_max": 2,
			"qte_time_limit": 2,
			"dodge_sound": "res://SFX/appleDodge.mp3",
		}
	},
	{
		"name": "Scuba Beene", 
		"desc": "A Beene from the depths...", 
		"scene": "res://fight.tscn",
		"image": "res://bosses/boss2.png",
		"config": {
			"enemy_health": 275,
			"base_damage": randf_range(16, 30),
			"qte_speed": 1.5,
			"qte_count_min": 2,
			"qte_count_max": 4,
			"qte_time_limit": 1.3,
			"dodge_sound": "res://SFX/scubaAttack.mp3",
		}
	},
	{
		"name": "Peeper", 
		"desc": "Got one eye and is always watching. Always.", 
		"scene": "res://fight.tscn",
		"image": "res://bosses/boss2.png",
		"config": {
			"enemy_health": 650,
			"base_damage": randf_range(32, 45),
			"qte_speed": 1.8,
			"qte_count_min": 2,
			"qte_count_max": 4,
			"qte_time_limit": 1.2,
			"dodge_sound": "res://SFX/scubaAttack.mp3",
		}
	},
	{
		"name": "Fezant", 
		"desc": "Just a bird. Doesn't know where they are most of the time.", 
		"scene": "res://fight.tscn",
		"image": "res://bosses/boss2.png",
		"config": {
			"enemy_health": 1000,
			"base_damage": randf_range(50, 68),
			"qte_speed": 2.2,
			"qte_count_min": 3,
			"qte_count_max": 5,
			"qte_time_limit": 1.1,
			"dodge_sound": "res://SFX/scubaAttack.mp3",
		}
	},
]

const SAVE_PATH = "user://save.dat"

func _ready():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	load_data()
	bosses_unlocked[3] = true
	# temp: unlock all attacks for testing
	unlocked_attacks = ["attack1", "attack2", "boss1_attack1", "boss1_attack2", "boss2_attack1", "boss2_attack2"]
	equipped_attacks = ["boss2_attack1", "boss2_attack2", "attack1"]
	if unlocked_attacks.is_empty():
		save_data()


func apply_volumes():
	# find all AudioStreamPlayers and apply sfx volume
	# music buses handled separately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume)


func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(click_count)
	file.store_var(click_multiplier)
	file.store_var(equipped_attacks)
	file.store_var(unlocked_attacks)
	file.store_var(music_volume)
	file.store_var(sfx_volume)
	file.store_var(helper_beene_count)
	file.store_var(boss1_unlocked)
	file.store_var(current_boss)
	file.store_var(upgrade_levels)
	file.store_var(bosses_unlocked)


func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		click_count = file.get_var() if not file.eof_reached() else 0
		click_multiplier = file.get_var() if not file.eof_reached() else 1
		equipped_attacks = file.get_var() if not file.eof_reached() else ["", "", ""]
		unlocked_attacks = file.get_var() if not file.eof_reached() else []
		music_volume = file.get_var() if not file.eof_reached() else -10.0
		sfx_volume = file.get_var() if not file.eof_reached() else -10.0
		helper_beene_count = file.get_var() if not file.eof_reached() else 0
		boss1_unlocked = file.get_var() if not file.eof_reached() else false
		current_boss = file.get_var() if not file.eof_reached() else 1
		upgrade_levels = file.get_var() if not file.eof_reached() else {"x2": 1, "beeneHelper1": 1, "auto1": 1}
		bosses_unlocked = file.get_var() if not file.eof_reached() else [true, false, false, false, false]
		owned_items = file.get_var() if not file.eof_reached() else {
			"beene_armor": false,
			"bronze_armor": false, 
			"gold_armor": false,
			"health_potion": false,
			"strength_1": false,
		}

var owned_items := {
	"beene_armor": false,
	"bronze_armor": false,
	"gold_armor": false,
	"health_potion": 0,
	"strength_1": false,
}

func get_damage_reduction() -> float:
	var reduction := 0.0
	if owned_items["gold_armor"]:
		reduction += 0.5
	elif owned_items["bronze_armor"]:
		reduction += 0.25
	elif owned_items["beene_armor"]:
		reduction += 0.1
	return reduction

func get_damage_bonus() -> float:
	var bonus := 0.0
	if owned_items["strength_1"]:
		bonus += 0.15
	return bonus
