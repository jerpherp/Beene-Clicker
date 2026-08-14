extends Node

# --- Save File Configuration ---
const SAVE_PATH := "user://savegame.save"

# --- Primary Game Stats ---
var click_count: int = 100000
var click_multiplier: int = 1

var music_volume: float = -10.0
var sfx_volume: float = -10.0

var play_yippie: bool = false
var show_fight_results: bool = false
var current_background: int = 0

# --- Upgrade Flags & Buffs ---
var frenzy_active: bool = false
var click_frenzy_active: bool = false
var click_frenzy_cooldown: bool = false
var golden_click_counter: int = 0
var jackpot_chance: float = 0.02  # 2% chance per click

var has_auto_collect: bool = false
var has_golden_click: bool = false
var has_click_frenzy: bool = false
var has_jackpot: bool = false

var helper_beene_active: bool = false
var helper_beene_count: int = 0

var golden_click_level: int = 1

# Upgrade level dictionary used by buttons
var upgrade_levels: Dictionary = {
	"x2": 1,
	"beeneHelper1": 1,
	"auto1": 1,
}

# --- Offline / Beene Bot Systems ---
var beene_bot_rate: int = 10      # Beenes earned per second while game is closed
var last_exit_time: int = 0      # Unix timestamp recorded when exiting

# --- Items & Equipment ---
var owned_items: Dictionary = {
	"beene_armor": false,
	"bronze_armor": false,
	"gold_armor": false,
	"health_potion": 0,
	"strength_1": false,
}

var equipped_attacks: Array = ["attack1", "attack2", ""]
var unlocked_attacks: Array = ["attack1", "attack2"]
var new_attacks: Array = []

var attack_data: Dictionary = {
	"attack1": {"name": "Beene Bash", "desc": "A simple strike. Basic, but gets the job done", "source": "base", "damage": 4, "cooldown": false},
	"attack2": {"name": "Beene Rage", "desc": "Hits hard but slow. Cools down after one use.", "source": "base", "damage": 8, "cooldown": true},
	"boss1_attack1": {"name": "Seed Shrapnel", "desc": "Throws sharp seeds that do a good amount of damage.", "source": "boss1", "damage": 8, "cooldown": false},
	"boss1_attack2": {"name": "Newton's Downfall", "desc": "A high-gravity slam that does crushing damage to your opponent. Cools down after one use.", "source": "boss1", "damage": 15, "cooldown": true},
	"boss2_attack1": {"name": "Bubble Burst", "desc": "Blows a myriad of bubbles at your opponent. Sounds harmless, but packs a punch.", "source": "boss2", "damage": 18, "cooldown": false},
	"boss2_attack2": {"name": "Tidal Wave", "desc": "Creates a massive wave that crashes on your enemy. Cools down after one use.", "source": "boss2", "damage": 25, "cooldown": true},
	"boss3_attack1": {"name": "Laser Vision", "desc": "Creates a high-powered beam pointed at your enemy. Watch the eyes! Or anything, really...", "source": "boss3", "damage": 27, "cooldown": false},
	"boss3_attack2": {"name": "Echolocation", "desc": "Sends out powerful sound waves that does massive amounts of damage.", "source": "boss3", "damage": 36, "cooldown": true},
}

# --- Boss & Combat Systems ---
var current_boss: int = 0
var boss1_unlocked: bool = false
var bosses_unlocked: Array = [true, false, false, false, false]

var fight_config: Dictionary = {
	"enemy_health": 100,
	"base_damage": 20,
	"qte_speed": 1.5,
	"qte_count_min": 1,
	"qte_count_max": 2,
	"enemy_scene": "res://fight.tscn",
	"qte_time_limit": 2.2,
	"dodge_sound": "res://SFX/appleDodge.mp3",
}

var fight_stats: Dictionary = {
	"damage_taken": 0,
	"hits_dealt": 0,
	"attacks_used": 0,
	"fight_time": 0.0,
}
var fight_rank: String = ""
var fight_beene_reward: int = 0

var boss_data: Array = [
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
			"enemy_health": 300,
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
		"image": "res://bosses/boss3.png",
		"config": {
			"enemy_health": 650,
			"base_damage": randf_range(32, 45),
			"qte_speed": 1.8,
			"qte_count_min": 2,
			"qte_count_max": 4,
			"qte_time_limit": 1.2,
			"dodge_sound": "res://SFX/peeper_attack.mp3",
		}
	},
	{
		"name": "Fezant", 
		"desc": "Just a bird. Doesn't know where they are most of the time.", 
		"scene": "res://fight.tscn",
		"image": "res://bosses/boss4.png",
		"config": {
			"enemy_health": 1200,
			"base_damage": randf_range(50, 68),
			"qte_speed": 2.2,
			"qte_count_min": 3,
			"qte_count_max": 5,
			"qte_time_limit": 1.1,
			"dodge_sound": "res://SFX/scubaAttack.mp3",
		}
	},
]

# --- Lifecycle Callbacks ---
func _ready():
	load_data()
	_calculate_offline_gains()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_data()

# --- Helper Methods ---
func reset_fight_stats():
	fight_stats = {
		"damage_taken": 0,
		"hits_dealt": 0,
		"attacks_used": 0,
		"fight_time": 0.0,
	}

func apply_volumes():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume)

func get_damage_reduction() -> float:
	var reduction := 0.0
	if owned_items.get("gold_armor", false):
		reduction += 0.5
	elif owned_items.get("bronze_armor", false):
		reduction += 0.25
	elif owned_items.get("beene_armor", false):
		reduction += 0.1
	return reduction

func get_damage_bonus() -> float:
	var bonus := 0.0
	if owned_items.get("strength_1", false):
		bonus += 0.15
	return bonus

# --- Unified Save / Load Logic ---
func save_data():
	last_exit_time = int(Time.get_unix_time_from_system())
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		var data = {
			"click_count": click_count,
			"click_multiplier": click_multiplier,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"equipped_attacks": equipped_attacks,
			"unlocked_attacks": unlocked_attacks,
			"helper_beene_count": helper_beene_count,
			"boss1_unlocked": boss1_unlocked,
			"current_boss": current_boss,
			"upgrade_levels": upgrade_levels,
			"bosses_unlocked": bosses_unlocked,
			"owned_items": owned_items,
			"has_auto_collect": has_auto_collect,
			"has_golden_click": has_golden_click,
			"has_click_frenzy": has_click_frenzy,
			"has_jackpot": has_jackpot,
			"beene_bot_rate": beene_bot_rate,
			"last_exit_time": last_exit_time
		}
		save_file.store_var(data)
		save_file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file:
		var data = save_file.get_var()
		save_file.close()
		
		if typeof(data) == TYPE_DICTIONARY:
			click_count = data.get("click_count", 100000)
			click_multiplier = data.get("click_multiplier", 1)
			music_volume = data.get("music_volume", -10.0)
			sfx_volume = data.get("sfx_volume", -10.0)
			equipped_attacks = data.get("equipped_attacks", ["attack1", "attack2", ""])
			unlocked_attacks = data.get("unlocked_attacks", ["attack1", "attack2"])
			helper_beene_count = data.get("helper_beene_count", 0)
			boss1_unlocked = data.get("boss1_unlocked", false)
			current_boss = data.get("current_boss", 0)
			upgrade_levels = data.get("upgrade_levels", {"x2": 1, "beeneHelper1": 1, "auto1": 1})
			bosses_unlocked = data.get("bosses_unlocked", [true, false, false, false, false])
			owned_items = data.get("owned_items", {"beene_armor": false, "bronze_armor": false, "gold_armor": false, "health_potion": 0, "strength_1": false})
			has_auto_collect = data.get("has_auto_collect", false)
			has_golden_click = data.get("has_golden_click", false)
			has_click_frenzy = data.get("has_click_frenzy", false)
			has_jackpot = data.get("has_jackpot", false)
			beene_bot_rate = data.get("beene_bot_rate", 10)
			last_exit_time = data.get("last_exit_time", 0)

func _calculate_offline_gains():
	if has_auto_collect and beene_bot_rate > 0 and last_exit_time > 0:
		var current_time = int(Time.get_unix_time_from_system())
		var seconds_away = current_time - last_exit_time
		
		if seconds_away > 0:
			var offline_earned = seconds_away * beene_bot_rate
			click_count += offline_earned
			print("Welcome back! Beene Bot gathered ", offline_earned, " Beenes while away (", seconds_away, "s).")
