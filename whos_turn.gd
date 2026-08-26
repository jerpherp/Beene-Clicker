extends Node

enum Turn { PLAYER, ENEMY }

var current_turn : Turn = Turn.PLAYER
var pause_cooldown: bool = false
var loop_from_frame: int = -1
var enemy_turn_id: int = 0
var fight_timer: float = 0.0

var is_qte_active: bool = false

@onready var apple_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/appleFight")
@onready var boss2_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/scubaFight")
@onready var boss3_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/peeperFight")
@onready var boss4_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/fezantFight")
@onready var enemy_icon = get_tree().get_root().get_node("Fight/HUD/enemyIcon")
@onready var enemy_health_bar = get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar")
@onready var armorIcon = get_tree().get_root().get_node("Fight/HUD/ArmorIcon")

@onready var beach_bg = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer/beachBG")
@onready var palm = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Palm")
@onready var sandcastle = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Sandcastle")

@onready var snow = get_tree().get_root().get_node("Fight/ParallaxBackground/Snow")
@onready var mountains_bg = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer8/mountainsBG")
@onready var far_mountains = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer7/FarMountains")
@onready var mountains = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer6/Mountains")
@onready var ground = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer5/Ground")
@onready var snowman = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Snowman")
@onready var close_mountain = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/CloseMountain")

var qte_queue: Array = []
var qte_damage_reduction: int = 0
var total_qtes: int = 0
var base_damage: int = 20

@onready var camera = get_parent().get_node("Camera2D")
@onready var player_health = get_tree().get_root().get_node("Fight/HUD/BeeneHealthBar")
@onready var enemy_health = get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar")
@onready var pause_screen = get_tree().get_root().get_node("Fight/HUD/PauseScreen")
@onready var qte = get_tree().get_root().get_node("Fight/HUD/QTE")
@onready var player_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer3/beeneFight")
@onready var enemy_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/appleFight")
@onready var scuba_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/scubaFight")
@onready var peeper_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/peeperFight")
@onready var fezant_sprite = get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/fezantFight")
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

func _ready():
	Global.in_fight = true
	Global.reset_fight_stats()
	Global.fight_config = Global.boss_data[Global.current_boss - 1]["config"]
	_apply_fight_background()
	base_damage = Global.fight_config["base_damage"]
	dodge_sfx.stream = load(Global.fight_config["dodge_sound"])
	
	var bonus_hp = 25 if Global.owned_items.get("health_potion", false) else 0
	player_health.setup(100 + bonus_hp)
	
	_apply_armor_icon()
	
	Global.fights_fought += 1
	
	if Global.current_boss == 1:
		enemy_sprite = apple_sprite
		apple_sprite.visible = true
		boss2_sprite.visible = false
		boss3_sprite.visible = false
		boss4_sprite.visible = false
		enemy_health_bar.hurt_animation = "hurt_apple"
		enemy_health_bar.normal_animation = "normal_apple"
	elif Global.current_boss == 2:
		enemy_sprite = boss2_sprite
		apple_sprite.visible = false
		boss2_sprite.visible = true
		boss3_sprite.visible = false
		boss4_sprite.visible = false
		enemy_health_bar.hurt_animation = "hurt_scuba"
		enemy_health_bar.normal_animation = "normal_scuba"
	elif Global.current_boss == 3:
		enemy_sprite = boss3_sprite
		apple_sprite.visible = false
		boss2_sprite.visible = false
		boss3_sprite.visible = true
		boss4_sprite.visible = false
		enemy_health_bar.hurt_animation = "hurt_peeper"
		enemy_health_bar.normal_animation = "normal_peeper"
	elif Global.current_boss == 4:
		enemy_sprite = boss4_sprite
		apple_sprite.visible = false
		boss2_sprite.visible = false
		boss3_sprite.visible = false
		boss4_sprite.visible = true
		enemy_health_bar.hurt_animation = "hurt_fezant"
		enemy_health_bar.normal_animation = "normal_fezant"
	
	await get_tree().create_timer(0.0).timeout
	enemy_health.setup(Global.fight_config["enemy_health"])
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

func _apply_fight_background():
	if Global.current_boss == 1 || Global.current_boss == 2:
		beach_bg.visible = true
		palm.visible = true
		sandcastle.visible = true
		snow.visible = false
		mountains_bg.visible = false
		far_mountains.visible = false
		mountains.visible = false
		ground.visible = false
		snowman.visible = false
		close_mountain.visible = false
	elif Global.current_boss == 3 || Global.current_boss == 4:
		beach_bg.visible = false
		palm.visible = false
		sandcastle.visible = false
		snow.visible = true
		mountains_bg.visible = true
		far_mountains.visible = true
		mountains.visible = true
		ground.visible = true
		snowman.visible = true
		close_mountain.visible = true

func _enemy_anim(anim_name: String) -> void:
	enemy_sprite.speed_scale = 1.0
	enemy_sprite.play_animation(anim_name)
	await enemy_sprite.animation_finished

func _show_label(label: Node):
	label.visible = true
	label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.visible = false

func _get_max_frame(sprite: AnimatedSprite2D, anim_name: String) -> int:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		return max(0, sprite.sprite_frames.get_frame_count(anim_name) - 1)
	return 0

func _set_world_pause_state(paused: bool):
	if paused:
		enemy_sprite.speed_scale = 0.0
		player_sprite.speed_scale = 0.0
		
		if snow and snow.has_method("pause"):
			snow.pause()
	else:
		enemy_sprite.speed_scale = 1.0
		player_sprite.speed_scale = 1.0
		
		if snow and snow.has_method("play"):
			snow.play()

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

	is_qte_active = true

	enemy_sprite.speed_scale = 1.0
	enemy_sprite.play_animation("attack")
	enemy_sprite.frame = 0

	var max_frame = _get_max_frame(enemy_sprite, "attack")
	var target_pause_frame = min(19, max_frame)

	while enemy_sprite.animation == "attack" and enemy_sprite.frame < target_pause_frame and enemy_sprite.is_playing():
		await get_tree().process_frame

	_set_world_pause_state(true)

	if this_turn != enemy_turn_id:
		return

	_next_qte()

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

	if qte_queue.is_empty():
		_apply_damage()
		return

	await get_tree().create_timer(0.3).timeout
	if this_turn != enemy_turn_id:
		return
	_next_qte()

func _apply_damage():
	var this_turn = enemy_turn_id
	
	var reduction = float(qte_damage_reduction) / float(total_qtes)
	var final_damage = int(base_damage * (1.0 - reduction))
	final_damage = int(final_damage * (1.0 - Global.get_damage_reduction()))

	_set_world_pause_state(false)

	if enemy_sprite.animation == "attack" and enemy_sprite.is_playing():
		await enemy_sprite.animation_finished

	is_qte_active = false
	enemy_sprite.play_animation("idle")

	camera.pan_to_player()
	
	if Global.current_boss == 2:
		scuba_sprite.trigger_attack_bubbles()
	elif Global.current_boss == 3:
		peeper_sprite.trigger_eye_beam(player_sprite.global_position)
	elif Global.current_boss == 4:
		fezant_sprite.trigger_attack_feathers()

	if final_damage == 0:
		_show_label(great_label)
		if Global.current_boss == 1:
			speed_lines.trigger()
		dodge_sfx.pitch_scale = randf_range(0.9, 1.1)
		dodge_sfx.play()
		player_sprite.play_animation("dodge")
		
		if player_sprite.is_playing():
			await player_sprite.animation_finished
			
		current_turn = Turn.PLAYER
		start_player_turn()
		return

	dodge_sfx.pitch_scale = randf_range(0.9, 1.1)
	dodge_sfx.play()

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
		await get_tree().create_timer(1.0).timeout
		var player_ko_max = _get_max_frame(player_sprite, "knockout")
		player_sprite.frame = min(45, player_ko_max)
		loop_from_frame = player_sprite.frame
		return
	elif final_damage > 0:
		_show_label(miss_label)
		get_hit_sfx.pitch_scale = randf_range(0.9, 1.1)
		get_hit_sfx.play()
		player_sprite.play_animation("getHit")
		await player_sprite.animation_finished

	current_turn = Turn.PLAYER
	start_player_turn()

func player_attack(attack_id: String):
	attack_hud.hide_attacks()
	Global.fight_stats["attacks_used"] += 1
	beene_hit_sfx.pitch_scale = randf_range(0.9, 1.1)
	beene_hit_sfx.play()
	player_sprite.speed_scale = 1.0
	player_sprite.play_animation("attack")
	await get_tree().create_timer(0.85).timeout
	_show_label(hit_label)
	await _enemy_anim("hit")

	var damage = 20
	if Global.attack_data.has(attack_id):
		damage = Global.attack_data[attack_id]["damage"]
		
	damage = int(damage * (1.0 + Global.get_damage_bonus()))

	enemy_health.take_damage(damage)
	Global.fight_stats["hits_dealt"] += 1

	if enemy_health.current_health <= 0:
		await _enemy_anim("knockout")
		player_sprite.play_animation("finish")
		await player_sprite.animation_finished
		await _transition_to_main()
		return

	enemy_sprite.play_animation("idle")
	current_turn = Turn.ENEMY
	start_enemy_turn()

func _process(delta):
	fight_timer += delta
	Global.fight_stats["fight_time"] = fight_timer
	if loop_from_frame >= 0:
		if not player_sprite.is_playing():
			player_sprite.frame = loop_from_frame
			player_sprite.play("knockout")

func _player_death():
	camera.pan_to_knockout()
	attack_hud.hide_attacks()

	var music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", -80.0, 1.5)
	
	Global.fights_lost += 1
	Global.save_data()
	
	var bg_layer_path = ""
	if Global.current_boss == 1 || Global.current_boss == 2:
		bg_layer_path = "Fight/ParallaxBackground/ParallaxLayer"
	elif Global.current_boss == 3 || Global.current_boss == 4:
		bg_layer_path = "Fight/ParallaxBackground/ParallaxLayer8"

	var bg_layer = get_tree().get_root().get_node(bg_layer_path)
	var black_rect = ColorRect.new()
	black_rect.size = Vector2(3000, 3000)
	black_rect.position = Vector2(-1500, -1500)
	black_rect.color = Color(0, 0, 0, 0)
	bg_layer.add_child(black_rect)
	var beach_tween = create_tween()
	beach_tween.tween_property(black_rect, "color", Color(0, 0, 0, 1), 1.0)

	var nodes_to_darken = [
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/appleFight"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/scubaFight"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/peeperFight"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer2/fezantFight"),
	]
	var nodes_to_fade = [
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Palm"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Sandcastle"),
		get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar"),
		get_tree().get_root().get_node("Fight/HUD/BeeneHealthBar"),
		get_tree().get_root().get_node("Fight/HUD/beeneIcon"),
		get_tree().get_root().get_node("Fight/HUD/enemyIcon"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer8/mountainsBG"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer7/FarMountains"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer6/Mountains"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer5/Ground"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/Snowman"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/ParallaxLayer4/CloseMountain"),
		get_tree().get_root().get_node("Fight/HUD/EnemyHealthBar"),
		get_tree().get_root().get_node("Fight/HUD/BeeneHealthBar"),
		get_tree().get_root().get_node("Fight/HUD/beeneIcon"),
		get_tree().get_root().get_node("Fight/HUD/enemyIcon"),
		get_tree().get_root().get_node("Fight/ParallaxBackground/Snow"),
		get_tree().get_root().get_node("Fight/HUD/BonusHP"),
		get_tree().get_root().get_node("Fight/HUD/ArmorIcon"),
	]

	for node in nodes_to_darken:
		var t = create_tween()
		t.tween_property(node, "modulate", Color.BLACK, 1.0)

	for node in nodes_to_fade:
		var t = create_tween()
		t.tween_property(node, "modulate", Color(1, 1, 1, 0), 1.0)

	var player_tween = create_tween()
	player_tween.tween_property(player_sprite, "modulate", Color.WHITE, 1.0)
	
	await beach_tween.finished
	await get_tree().create_timer(1).timeout
	_show_death_options()

func _show_death_options() -> void:
	var hud = get_tree().get_root().get_node("Fight/HUD")
	
	var options_container: HBoxContainer = HBoxContainer.new()
	options_container.name = "DeathOptionsContainer"
	options_container.anchor_left = 0.42
	options_container.anchor_top = 0.75
	options_container.anchor_right = 0.5
	options_container.anchor_bottom = 0.35
	options_container.offset_left = -250.0
	options_container.offset_top = -30.0
	options_container.offset_right = 250.0
	options_container.offset_bottom = 30.0
	options_container.add_theme_constant_override("separation", 240)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_container.modulate.a = 0.0
	
	var flat_style: StyleBoxEmpty = StyleBoxEmpty.new()
	
	var handle_choice: Callable = func(action: Callable):
		options_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fade_out = create_tween()
		fade_out.tween_property(options_container, "modulate:a", 0.0, 0.5)
		await fade_out.finished
		action.call()

	var try_again_btn: Button = Button.new()
	try_again_btn.text = "Try Again?"
	try_again_btn.pivot_offset = Vector2(100, 25)
	try_again_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	try_again_btn.add_theme_font_size_override("font_size", 42)
	try_again_btn.add_theme_color_override("font_color", Color.WHITE)
	try_again_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	try_again_btn.add_theme_color_override("font_focus_color", Color.WHITE)
	try_again_btn.add_theme_stylebox_override("normal", flat_style)
	try_again_btn.add_theme_stylebox_override("hover", flat_style)
	try_again_btn.add_theme_stylebox_override("pressed", flat_style)
	try_again_btn.add_theme_stylebox_override("focus", flat_style)
	try_again_btn.pressed.connect(func(): 
		handle_choice.call(func(): get_tree().reload_current_scene())
	)
	_apply_float_effects(try_again_btn)
	
	var give_up_btn: Button = Button.new()
	give_up_btn.text = "Give Up..."
	give_up_btn.pivot_offset = Vector2(100, 25)
	give_up_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	give_up_btn.add_theme_font_size_override("font_size", 42)
	give_up_btn.add_theme_color_override("font_color", Color.WHITE)
	give_up_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	give_up_btn.add_theme_color_override("font_focus_color", Color.WHITE)
	give_up_btn.add_theme_stylebox_override("normal", flat_style)
	give_up_btn.add_theme_stylebox_override("hover", flat_style)
	give_up_btn.add_theme_stylebox_override("pressed", flat_style)
	give_up_btn.add_theme_stylebox_override("focus", flat_style)
	give_up_btn.pressed.connect(func(): 
		handle_choice.call(func():
			Global.in_fight = false
			get_tree().change_scene_to_file("res://main.tscn")
		)
	)
	_apply_float_effects(give_up_btn)
	
	options_container.add_child(try_again_btn)
	options_container.add_child(give_up_btn)
	hud.add_child(options_container)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(options_container, "modulate:a", 1.0, 0.8)
	fade_tween.tween_property(player_sprite, "modulate:a", 1.0, 0.8)

func _apply_float_effects(btn: Button) -> void:
	var float_offset: float = -10.0
	
	var float_up = func():
		var tween = btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position:y", float_offset, 0.15)
	
	var float_down = func():
		var tween = btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position:y", 0.0, 0.15)
		
	btn.mouse_entered.connect(float_up)
	btn.focus_entered.connect(float_up)
	btn.mouse_exited.connect(float_down)
	btn.focus_exited.connect(float_down)

func _calculate_rank():
	var score: int = 0

	if Global.fight_stats["damage_taken"] == 0:
		score += 40
	elif Global.fight_stats["damage_taken"] <= 10:
		score += 30
	elif Global.fight_stats["damage_taken"] <= 25:
		score += 20
	elif Global.fight_stats["damage_taken"] <= 50:
		score += 10

	if Global.fight_stats["hits_dealt"] >= 15:
		score += 30
	elif Global.fight_stats["hits_dealt"] >= 10:
		score += 20
	elif Global.fight_stats["hits_dealt"] >= 5:
		score += 10

	if Global.fight_stats["fight_time"] <= 90.0:
		score += 30
	elif Global.fight_stats["fight_time"] <= 150.0:
		score += 20
	elif Global.fight_stats["fight_time"] <= 240.0:
		score += 10

	var boss_index: int = clamp(Global.current_boss - 1, 0, Global.boss_data.size() - 1)
	var boss_multiplier = pow(9, boss_index)

	var fight_time: float = Global.fight_stats["fight_time"]
	if fight_time < 60.0:
		Global.fight_rank = "S+"
		Global.fight_beene_reward = int(randi_range(1200, 1800) * boss_multiplier)
	elif fight_time < 120.0:
		Global.fight_rank = "S"
		Global.fight_beene_reward = int(randi_range(1000, 1200) * boss_multiplier)
	elif score >= 95:
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

func _transition_to_main():
	var beaten_index = Global.current_boss - 1
	var first_clear: bool = beaten_index >= 0 and beaten_index < Global.bosses_beaten.size() and not Global.bosses_beaten[beaten_index]
	if beaten_index >= 0 and beaten_index < Global.bosses_beaten.size():
		Global.bosses_beaten[beaten_index] = true

	var attack_source = "boss" + str(Global.current_boss)
	for attack_id in Global.attack_data:
		if Global.attack_data[attack_id]["source"] == attack_source and attack_id not in Global.unlocked_attacks:
			Global.unlocked_attacks.append(attack_id)
			Global.new_attacks.append(attack_id)

	_calculate_rank()
	if not first_clear:
		Global.fight_beene_reward = int(Global.fight_beene_reward * 0.1)
	else:
		Global.current_boss += 1
	Global.fights_won += 1
	var newly: Array = Global.add_clicks(Global.fight_beene_reward, true)
	Global.in_fight = false
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

func _apply_armor_icon():
	if Global.owned_items.get("gold_armor", false):
		armorIcon.frame = 2
	elif Global.owned_items.get("bronze_armor", false):
		armorIcon.frame = 1
	elif Global.owned_items.get("beene_armor", false):
		armorIcon.frame = 0
	else:
		armorIcon.visible = false
