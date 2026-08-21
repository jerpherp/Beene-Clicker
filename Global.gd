"""
Global shared state and helpers.
Cleaned: clarified comments; removed test-only constants elsewhere.
No gameplay changes intended.
"""

extends Node

# --- Save File Configuration ---
const SAVE_PATH := "user://savegame.save"

# --- Primary Game Stats ---
var click_count: int = 0
var click_multiplier: int = 1

var screen_size_index: int = 0

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
var jackpot_multiplier: int = 100

var has_auto_collect: bool = false
var has_golden_click: bool = false
var has_click_frenzy: bool = false
var has_jackpot: bool = false

var total_beenes: int = 0
var total_clicks: int = 0
var fights_fought: int = 0
var fights_won: int = 0
var fights_lost: int = 0

# Whether the player is currently in a fight scene
var in_fight: bool = false

var helper_beene_active: bool = false
var helper_beene_count: int = 0

var golden_click_level: int = 1

var window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED

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
	"attack1": {"name": "Beene Bash", "desc": "A simple strike. Basic, but gets the job done", "source": "base", "damage": 9999, "cooldown": false},
	"attack2": {"name": "Beene Rage", "desc": "Hits hard but slow. Cools down after one use.", "source": "base", "damage": 8, "cooldown": true},
	"boss1_attack1": {"name": "Seed Shrapnel", "desc": "Throws sharp seeds that do a good amount of damage.", "source": "boss1", "damage": 8, "cooldown": false},
	"boss1_attack2": {"name": "Newton's Downfall", "desc": "A high-gravity slam that does crushing damage to your opponent. Cools down after one use.", "source": "boss1", "damage": 15, "cooldown": true},
	"boss2_attack1": {"name": "Bubble Burst", "desc": "Blows a myriad of bubbles at your opponent. Sounds harmless, but packs a punch.", "source": "boss2", "damage": 18, "cooldown": false},
	"boss2_attack2": {"name": "Tidal Wave", "desc": "Creates a massive wave that crashes on your enemy. Cools down after one use.", "source": "boss2", "damage": 25, "cooldown": true},
	"boss3_attack1": {"name": "Laser Vision", "desc": "Creates a high-powered beam pointed at your enemy. Watch the eyes! Or anything, really...", "source": "boss3", "damage": 27, "cooldown": false},
	"boss3_attack2": {"name": "Echolocation", "desc": "Sends out powerful sound waves that does massive amounts of damage. Cools down after one use.", "source": "boss3", "damage": 36, "cooldown": true},
	"boss4_attack1": {"name": "Feather Barrage", "desc": "Throws countless sharp feathers at your target!", "source": "boss4", "damage": 39, "cooldown": false},
	"boss4_attack2": {"name": "The Hardest Peck", "desc": "Delivers an extremely powerful and piercing peck. Watch your head! Cools down after one use.", "source": "boss4", "damage": 45, "cooldown": true},
}

# --- Boss & Combat Systems ---
const BOSS_UNLOCK_THRESHOLDS: Array = [10, 1000, 5000, 10000, 15000]

var current_boss: int = 1
var boss1_unlocked: bool = false
var bosses_unlocked: Array = [false, false, false, false, false]
var last_unlocked_bosses: Array = []
var bosses_beaten: Array = [false, false, false, false, false]

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
			"base_damage": randf_range(10, 18),
			"qte_speed": 1.4,
			"qte_count_min": 1,
			"qte_count_max": 2,
			"qte_time_limit": 2.1,
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
			"qte_speed": 1.2,
			"qte_count_min": 2,
			"qte_count_max": 4,
			"qte_time_limit": 1.5,
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
			"enemy_health": 900,
			"base_damage": randf_range(50, 68),
			"qte_speed": 2.2,
			"qte_count_min": 3,
			"qte_count_max": 5,
			"qte_time_limit": 1.1,
			"dodge_sound": "res://SFX/fezantAttack.mp3",
		}
	},
]

# --- Lifecycle Callbacks ---
func _ready():
	#if FileAccess.file_exists(SAVE_PATH):
		#DirAccess.remove_absolute(SAVE_PATH)
	load_data()
	apply_screen_size()
	_calculate_offline_gains()
	# apply any scaling from upgrades (jackpot chance/multiplier, beene bot rate)
	update_upgrade_effects()


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
			"bosses_beaten": bosses_beaten,
			"owned_items": owned_items,
			"has_auto_collect": has_auto_collect,
			"has_golden_click": has_golden_click,
			"has_click_frenzy": has_click_frenzy,
			"has_jackpot": has_jackpot,
			"beene_bot_rate": beene_bot_rate,
			"last_exit_time": last_exit_time,
			"total_beenes": total_beenes,
			"total_clicks": total_clicks,
			"fights_fought": fights_fought,
			"fights_won": fights_won,
			"fights_lost": fights_lost,
			"window_mode": window_mode,
			"screen_size_index": screen_size_index,
		}
		save_file.store_var(data)
		save_file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		# First run: default to beach (background index 0)
		current_background = 0
		return
		
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file:
		var data = save_file.get_var()
		save_file.close()
		
		if typeof(data) == TYPE_DICTIONARY:
			click_count = data.get("click_count", 0)
			click_multiplier = data.get("click_multiplier", 1)
			music_volume = data.get("music_volume", -10.0)
			sfx_volume = data.get("sfx_volume", -10.0)
			equipped_attacks = data.get("equipped_attacks", ["attack1", "attack2", ""])
			unlocked_attacks = data.get("unlocked_attacks", ["attack1", "attack2"])
			helper_beene_count = data.get("helper_beene_count", 0)
			boss1_unlocked = data.get("boss1_unlocked", false)
			current_boss = data.get("current_boss", 1)
			upgrade_levels = data.get("upgrade_levels", {"x2": 1, "beeneHelper1": 1, "auto1": 1})
			bosses_unlocked = data.get("bosses_unlocked", [true, false, false, false, false])
			bosses_beaten = data.get("bosses_beaten", [false, false, false, false, false])

			# Sanitize loaded unlocks: ensure no boss is unlocked unless the previous one was beaten
			for i in range(bosses_unlocked.size()):
				if bosses_unlocked[i] and i > 0 and not bosses_beaten[i - 1]:
					bosses_unlocked[i] = false
			owned_items = data.get("owned_items", {"beene_armor": false, "bronze_armor": false, "gold_armor": false, "health_potion": 0, "strength_1": false})
			has_auto_collect = data.get("has_auto_collect", false)
			has_golden_click = data.get("has_golden_click", false)
			has_click_frenzy = data.get("has_click_frenzy", false)
			has_jackpot = data.get("has_jackpot", false)
			beene_bot_rate = data.get("beene_bot_rate", 10)
			last_exit_time = data.get("last_exit_time", 0)
			total_beenes = data.get("total_beenes", click_count)
			total_clicks = data.get("total_clicks", 0)
			fights_fought = data.get("fights_fought", 0)
			fights_won = data.get("fights_won", 0)
			fights_lost = data.get("fights_lost", 0)
			window_mode = data.get("window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
			screen_size_index = data.get("screen_size_index", 0)
		# recompute derived values from upgrade levels
		update_upgrade_effects()

		# force the initial background to beach (overwrite any saved value)
		current_background = 0
		save_data()

func refresh_boss_unlocks() -> void:
	if bosses_unlocked.size() != BOSS_UNLOCK_THRESHOLDS.size():
		bosses_unlocked = []
		for i in range(BOSS_UNLOCK_THRESHOLDS.size()):
			bosses_unlocked.append(false)

	# Only mark bosses as unlocked once. Do not revert unlocks if click_count drops below threshold.
	# Additionally, require the previous boss to have been beaten before unlocking the next boss.
	for i in range(BOSS_UNLOCK_THRESHOLDS.size()):
		if not bosses_unlocked[i] and click_count >= BOSS_UNLOCK_THRESHOLDS[i]:
			# boss 0 (first boss) has no prerequisite; others require previous beaten
			if i == 0 or bosses_beaten[i - 1]:
				bosses_unlocked[i] = true

func add_clicks(amount: int, notify: bool = true) -> Array:
	# increment clicks and return list of newly unlocked boss indices (0-based)
	var previously_unlocked = bosses_unlocked.duplicate()
	var old = click_count
	click_count += amount
	refresh_boss_unlocks()
	save_data()
	var newly := []
	for i in range(BOSS_UNLOCK_THRESHOLDS.size()):
		# Only consider it newly unlocked if it was not unlocked before and is unlocked now
		if not previously_unlocked[i] and bosses_unlocked[i]:
			newly.append(i)
	# Only update last_unlocked_bosses when notifications are allowed
	if notify:
		last_unlocked_bosses = newly
	return newly

func _calculate_offline_gains():
	if has_auto_collect and beene_bot_rate > 0 and last_exit_time > 0:
		var current_time = int(Time.get_unix_time_from_system())
		var seconds_away = current_time - last_exit_time
		
		if seconds_away > 0:
			var offline_earned = seconds_away * beene_bot_rate
			click_count += offline_earned
			refresh_boss_unlocks()
			# ensure derived upgrade effects remain consistent after offline gains
			update_upgrade_effects()
			
#func _input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed and not event.echo:
		#if event.keycode == KEY_R:
			#reset_everything()
		#elif event.keycode == KEY_F1 or event.keycode == KEY_K:
			#unlock_all_bosses()
#
#func unlock_all_bosses() -> void:
	#for i in range(bosses_unlocked.size()):
		#bosses_unlocked[i] = true
	## set click_count to the highest defined unlock threshold rather than a magic number
	#click_count = BOSS_UNLOCK_THRESHOLDS[BOSS_UNLOCK_THRESHOLDS.size() - 1]
	#
	#for attack_id in attack_data.keys():
		#if not attack_id in unlocked_attacks:
			#unlocked_attacks.append(attack_id)
		#
	#save_data()

#func reset_everything() -> void:
	#click_count = 0
	#click_multiplier = 1
	#refresh_boss_unlocks()
	#has_golden_click = false
	#golden_click_level = 1
	#golden_click_counter = 0
	#upgrade_levels = {
		#"x2": 1,
		#"beeneHelper1": 1,
		#"auto1": 1,
	#}
	#
	#frenzy_active = false
	#click_frenzy_active = false
	#click_frenzy_cooldown = false
	#jackpot_chance = 0.02
	#has_auto_collect = false
	#has_click_frenzy = false
	#has_jackpot = false
	#helper_beene_active = false
	#helper_beene_count = 0
	#beene_bot_rate = 10
	#
	#owned_items = {
		#"beene_armor": false,
		#"bronze_armor": false,
		#"gold_armor": false,
		#"health_potion": 0,
		#"strength_1": false,
	#}
	#equipped_attacks = ["attack1", "attack2", ""]
	#unlocked_attacks = ["attack1", "attack2"]
	#new_attacks = []
	#
	#current_boss = 1
	#boss1_unlocked = false
	#bosses_unlocked = [false, false, false, false, false]
	#current_background = 0
	#
	#total_beenes = 0
	#total_clicks = 0
	#fights_fought = 0
	#fights_won = 0
	#fights_lost = 0
	#
	#if FileAccess.file_exists(SAVE_PATH):
		#var err = DirAccess.remove_absolute(SAVE_PATH)
		#if err == OK:
			#pass
		#else:
			#pass
			#
	## Progress reset complete
	#get_tree().reload_current_scene()

func apply_screen_size() -> void:
	match screen_size_index:
		0:  # 720p windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1280, 720))
		1:  # 1080p windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		2:  # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## --- Upgrade effect helpers ---
const JACKPOT_BASE_CHANCE := 0.02
const JACKPOT_CHANCE_PER_LEVEL := 0.01
const JACKPOT_BASE_MULTIPLIER := 100
const JACKPOT_MULTIPLIER_PER_LEVEL := 50

const BEENEBOT_BASE_RATE_PER_HELPER := 10
const BEENEBOT_RATE_MULTIPLIER_PER_LEVEL := 0.5

func update_upgrade_effects() -> void:
	var jackpot_lvl := int(upgrade_levels.get("jackpot", 1))
	jackpot_chance = JACKPOT_BASE_CHANCE + max(0, jackpot_lvl - 1) * JACKPOT_CHANCE_PER_LEVEL
	jackpot_multiplier = JACKPOT_BASE_MULTIPLIER + max(0, jackpot_lvl - 1) * JACKPOT_MULTIPLIER_PER_LEVEL

	var helper_upgrade_lvl := int(upgrade_levels.get("beeneHelper1", 1))
	beene_bot_rate = int(helper_beene_count * BEENEBOT_BASE_RATE_PER_HELPER * (1.0 + max(0, helper_upgrade_lvl - 1) * BEENEBOT_RATE_MULTIPLIER_PER_LEVEL))

	# X2 upgrade: linear progression 1,2,4,6,8,... -> multiplier = max(1, 2*(level-1))
	var x2_lvl := int(upgrade_levels.get("x2", 1))
	if x2_lvl <= 1:
		click_multiplier = 1
	else:
		click_multiplier = int(2 * (x2_lvl - 1))
