extends Control

@export var slide_duration := 0.6
@onready var panel = $Panel
@onready var rank_label = $Panel/RankLabel
@onready var damage_label = $Panel/DamageTakenLabel
@onready var hits_label = $Panel/HitsDealtLabel
@onready var time_label = $Panel/FightTimeLabel
@onready var reward_label = $Panel/RewardLabel
@onready var close_btn = $Panel/CloseButton

var shown_y : float

func _ready():
	visible = false
	close_btn.pressed.connect(close)

func show_results():
	visible = true
	shown_y = panel.position.y
	panel.position.y = -600
	
	rank_label.text = Global.fight_rank
	damage_label.text = "Damage Taken: " + str(Global.fight_stats["damage_taken"])
	hits_label.text = "Hits Dealt: " + str(Global.fight_stats["hits_dealt"])
	var minutes = int(Global.fight_stats["fight_time"]) / 60
	var seconds = int(Global.fight_stats["fight_time"]) % 60
	time_label.text = "Fight Time: " + str(minutes) + ":" + "%02d" % seconds
	reward_label.text = "+" + str(Global.fight_beene_reward) + " Beenes!"
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", shown_y, slide_duration)

func close():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "position:y", -600, slide_duration)
	await tween.finished
	visible = false
