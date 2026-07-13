extends Node

# ============================================================
# TURN SYSTEM
# ============================================================

enum Turn { PLAYER, ENEMY }

var current_turn : Turn = Turn.PLAYER
var pause_cooldown := false
var loop_from_frame := -1
var enemy_turn_id := 0
var fight_timer := 0.0
@onready var apple_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/appleFight")
@onready var boss2_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/scubaFight")
@onready var enemy_icon = get_tree().get_root().get_node("Fight/HUD/enemyIcon")
@onready var enemy_health_bar = get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar")

func _ready():	
	Global.reset_fight_stats()
	base_damage = Global.fight_config["base_damage"]
	enemy_health.setup(Global.fight_config["enemy_health"])
	
	dodge_sfx.stream = load(Global.fight_config["dodge_sound"])
	
	# show correct enemy
	if Global.current_boss == 1:
		enemy_sprite = apple_sprite
		boss2_sprite.visible = false
		apple_sprite.visible = true
		enemy_health_bar.hurt_animation = "hurt_apple"
		enemy_health_bar.normal_animation = "normal_apple"
	elif Global.current_boss == 2:
		enemy_sprite = boss2_sprite
		apple_sprite.visible = false
		boss2_sprite.visible = true
		enemy_health_bar.hurt_animation = "hurt_scuba"
		enemy_health_bar.normal_animation = "normal_scuba"
	
	enemy_health.max_health = Global.fight_config["enemy_health"]
	enemy_health.current_health = Global.fight_config["enemy_health"]
	enemy_health.update_bar()
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

# ============================================================
# QTE STATE
# ============================================================

var qte_queue := []
var qte_damage_reduction := 0
var total_qtes := 0
var base_damage := 20

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var camera = get_parent().get_node("Camera2D")
@onready var player_health = get_tree().get_root().get_node("Fight/HUD/BeeneHealthBar")
@onready var enemy_health = get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar")
@onready var pause_screen = get_tree().get_root().get_node("Fight/HUD/PauseScreen")
@onready var qte = get_tree().get_root().get_node("Fight/HUD/QTE")
@onready var player_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer3/beeneFight")
@onready var enemy_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/appleFight")
@onready var scuba_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/scubaFight")
@onready var attack_hud = get_tree().get_root().get_node("Fight/HUD/EquippedAttacksHUD")
@onready var music = get_tree().get_root().get_node("Fight/BackgroundMusic")
@onready var transition_overlay = get_tree().get_root().get_node("Fight/HUD/TransitionOverlay")
@onready var dodge_sfx = get_tree().get_root().get_node("Fight/HUD/DodgeSFX")
@onready var beene_hit_sfx = get_tree().get_root().get_node("Fight/HUD/BeeneHitSFX")
@onready var get_hit_sfx = get_tree().get_root().get_node("Fight/HUD/GetHitSFX")
@onready var speed_lines = get_tree().get_root().get_node("Fight/HUD/SpeedLines")
@onready var great_label = get_tree().get_root().get_node("Fight/HUD/GreatLabel")
@onready var hit_label = get_tree().get_root().get_node("Fight/HUD/HitLabel")
@onready var miss_label = get_tree().get_root().get_node("Fight/HUD/MissLabel")

# ============================================================
# HELPERS
# ============================================================

func _enemy_anim(anim_name: String) -> void:
	enemy_sprite.animation_finished.disconnect(enemy_sprite._on_animation_finished)
	enemy_sprite.play_animation(anim_name)
	await enemy_sprite.animation_finished
	enemy_sprite.animation_finished.connect(enemy_sprite._on_animation_finished)

func _show_label(label: Node):
	label.visible = true
	label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.visible = false

# ============================================================
# INPUT
# ============================================================

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if get_tree().paused:
				pause_screen.unpause()
			else:
				if pause_cooldown:
					return
				pause_cooldown = true
				get_tree().create_timer(0.5, false, false, true).timeout.connect(
					func(): pause_cooldown = false
				)
				pause_screen.pause()
		if event.keycode == KEY_ALT:
			switch_turn()

# ============================================================
# TURN MANAGEMENT
# ============================================================

func switch_turn():
	if current_turn == Turn.PLAYER:
		current_turn = Turn.ENEMY
		start_enemy_turn()
	else:
		current_turn = Turn.PLAYER
		start_player_turn()

func start_player_turn():
	camera.pan_to_player()
	await get_tree().create_timer(1.0).timeout
	attack_hud.show_attacks()
	attack_hud.update_slots()

func start_enemy_turn():
	var count = randi_range(
		Global.fight_config["qte_count_min"],
		Global.fight_config["qte_count_max"]
	)
	enemy_turn_id += 1
	var this_turn = enemy_turn_id

	attack_hud.hide_attacks()
	camera.pan_to_enemy()
	await get_tree().create_timer(0.5).timeout
	if this_turn != enemy_turn_id:
		return

	total_qtes = count
	qte_queue.clear()
	qte_damage_reduction = 0
	for i in count:
		qte_queue.append(i)

	enemy_sprite.animation_finished.disconnect(enemy_sprite._on_animation_finished)
	enemy_sprite.play_animation("attack")
	while enemy_sprite.frame < 19:
		await get_tree().process_frame
	enemy_sprite.pause()

	if this_turn != enemy_turn_id:
		return

	_next_qte()

# ============================================================
# QTE CHAIN
# ============================================================

func _next_qte():
	if qte_queue.is_empty():
		_apply_damage()
		return
	qte_queue.pop_back()
	qte.qte_completed.connect(_on_qte_done, CONNECT_ONE_SHOT)
	qte.start()

func _on_qte_done(success: bool):
	var this_turn = enemy_turn_id
	if success:
		qte_damage_reduction += 1

	if qte_queue.is_empty() and qte_damage_reduction == total_qtes:
		_next_qte()
		return

	await get_tree().create_timer(0.3).timeout
	if this_turn != enemy_turn_id:
		return
	_next_qte()

# ============================================================
# APPLY DAMAGE
# ============================================================

func _apply_damage():
	var this_turn = enemy_turn_id
	var reduction = float(qte_damage_reduction) / float(total_qtes)
	var final_damage = int(base_damage * (1.0 - reduction))
	
	if Global.current_boss == 2:
		scuba_sprite.trigger_attack_bubbles()

	if final_damage == 0:
		_show_label(great_label)
		if Global.current_boss == 1:
			speed_lines.trigger()
		dodge_sfx.pitch_scale = randf_range(0.9, 1.1)
		dodge_sfx.play()
		enemy_sprite.animation_finished.connect(enemy_sprite._on_animation_finished)
		player_sprite.play_animation("dodge")
		enemy_sprite.play_animation("idle")
		await player_sprite.animation_finished
		current_turn = Turn.PLAYER
		start_player_turn()
		return

	dodge_sfx.pitch_scale = randf_range(0.9, 1.1)
	dodge_sfx.play()
	enemy_sprite.play()
	await enemy_sprite.animation_finished
	enemy_sprite.animation_finished.connect(enemy_sprite._on_animation_finished)

	player_health.take_damage(final_damage)
	Global.fight_stats["damage_taken"] += final_damage
	if this_turn != enemy_turn_id:
		return

	if Global.current_boss == 1:
		speed_lines.trigger()
	if player_health.current_health <= 0:
		player_sprite.play_animation("knockout")
		enemy_sprite.play_animation("idle")
		_player_death()
		await player_sprite.animation_finished
		player_sprite.frame = 45
		loop_from_frame = 45
		return
	elif final_damage > 0:
		_show_label(miss_label)
		get_hit_sfx.pitch_scale = randf_range(0.9, 1.1)
		get_hit_sfx.play()
		player_sprite.play_animation("getHit")
		enemy_sprite.play_animation("idle")
		await player_sprite.animation_finished

	current_turn = Turn.PLAYER
	start_player_turn()

# ============================================================
# PLAYER ATTACK
# ============================================================

func player_attack(attack_id: String):
	attack_hud.hide_attacks()
	Global.fight_stats["attacks_used"] += 1
	beene_hit_sfx.pitch_scale = randf_range(0.9, 1.1)
	beene_hit_sfx.play()
	player_sprite.play_animation("attack")
	await get_tree().create_timer(0.8).timeout
	_show_label(hit_label)
	await _enemy_anim("hit")

	var damage = 20
	if Global.attack_data.has(attack_id):
		damage = Global.attack_data[attack_id]["damage"]

	enemy_health.take_damage(damage)
	Global.fight_stats["hits_dealt"] += 1

	if enemy_health.current_health <= 0:
		await _enemy_anim("knockout")
		player_sprite.play_animation("finish")
		await player_sprite.animation_finished
		await _transition_to_main()
		return

	enemy_sprite.play_animation("idle")
	await player_sprite.animation_finished

	current_turn = Turn.ENEMY
	start_enemy_turn()

# ============================================================
# PROCESS — fight timer + knockout loop
# ============================================================

func _process(delta):
	fight_timer += delta
	Global.fight_stats["fight_time"] = fight_timer
	if loop_from_frame >= 0:
		if not player_sprite.is_playing():
			player_sprite.frame = loop_from_frame
			player_sprite.play("knockout")

# ============================================================
# PLAYER DEATH
# ============================================================

func _player_death():
	camera.pan_to_knockout()
	attack_hud.hide_attacks()

	var music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", -80.0, 1.5)

	var beach_layer = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer")
	var black_rect = ColorRect.new()
	black_rect.size = Vector2(3000, 3000)
	black_rect.position = Vector2(-1500, -1500)
	black_rect.color = Color(0, 0, 0, 0)
	beach_layer.add_child(black_rect)
	var beach_tween = create_tween()
	beach_tween.tween_property(black_rect, "color", Color(0, 0, 0, 1), 1.0)

	var nodes_to_darken = [
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/appleFight"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/scubaFight"),
	]
	var nodes_to_fade = [
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Palm"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Sandcastle"),
		get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar"),
		get_tree().get_root().get_node("Fight/HUD/BeeneHealthBar"),
		get_tree().get_root().get_node("Fight/HUD/beeneIcon"),
		get_tree().get_root().get_node("Fight/HUD/enemyIcon"),
	]

	for node in nodes_to_darken:
		var t = create_tween()
		t.tween_property(node, "modulate", Color.BLACK, 1.0)

	for node in nodes_to_fade:
		var t = create_tween()
		t.tween_property(node, "modulate", Color(1, 1, 1, 0), 1.0)

	var player_tween = create_tween()
	player_tween.tween_property(player_sprite, "modulate", Color.WHITE, 1.0)

# ============================================================
# RANK CALCULATION
# ============================================================

func _calculate_rank():
	var score := 0

	# damage taken (0 = perfect, 40pts max)
	if Global.fight_stats["damage_taken"] == 0:
		score += 40
	elif Global.fight_stats["damage_taken"] <= 10:
		score += 30
	elif Global.fight_stats["damage_taken"] <= 25:
		score += 20
	elif Global.fight_stats["damage_taken"] <= 50:
		score += 10

	# hits dealt (more = better, 30pts max)
	if Global.fight_stats["hits_dealt"] >= 15:
		score += 30
	elif Global.fight_stats["hits_dealt"] >= 10:
		score += 20
	elif Global.fight_stats["hits_dealt"] >= 5:
		score += 10

	# fight time (30pts max)
	if Global.fight_stats["fight_time"] <= 90.0:    # under 2:30
		score += 30
	elif Global.fight_stats["fight_time"] <= 150.0:  # under 3:30
		score += 20
	elif Global.fight_stats["fight_time"] <= 240.0:  # under 5:00
		score += 10

	# base rewards scale exponentially by boss
	var boss_multiplier = pow(9, Global.current_boss - 1)

	if score >= 95:
		Global.fight_rank = "S+"
		Global.fight_beene_reward = int(randi_range(1200, 1800) * boss_multiplier)
	elif score >= 80:
		Global.fight_rank = "S"
		Global.fight_beene_reward = int(randi_range(1000, 1200) * boss_multiplier)
	elif score >= 60:
		Global.fight_rank = "A"
		Global.fight_beene_reward = int(randi_range(750, 1000) * boss_multiplier)
	elif score >= 40:
		Global.fight_rank = "B"
		Global.fight_beene_reward = int(randi_range(500, 730) * boss_multiplier)
	elif score >= 20:
		Global.fight_rank = "C"
		Global.fight_beene_reward = int(randi_range(250, 400) * boss_multiplier)
	else:
		Global.fight_rank = "F"
		Global.fight_beene_reward = int(randi_range(35, 150) * boss_multiplier)

# ============================================================
# TRANSITION
# ============================================================

func _transition_to_main():
	if "boss1_attack1" not in Global.unlocked_attacks:
		Global.unlocked_attacks.append("boss1_attack1")
		Global.new_attacks.append("boss1_attack1")
	if "boss1_attack2" not in Global.unlocked_attacks:
		Global.unlocked_attacks.append("boss1_attack2")
		Global.new_attacks.append("boss1_attack2")

	_calculate_rank()
	Global.current_boss += 1
	Global.click_count += Global.fight_beene_reward
	Global.save_data()
	
	var next_boss = Global.current_boss  # current_boss already incremented
	if next_boss < 5:
		Global.bosses_unlocked[next_boss] = true
	if Global.current_boss >= 2:
		Global.current_background = 1
	Global.save_data()

	await get_tree().create_timer(1.0).timeout
	var music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", -80.0, 1.5)
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), 1.5)
	await tween.finished
	Global.play_yippie = true
	Global.show_fight_results = true
	get_tree().change_scene_to_file("res://main.tscn")
