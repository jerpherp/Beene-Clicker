extends HBoxContainer

@onready var active_upgrades_hbox = $CanvasLayer/Panel/ActiveUpgrades

var shop_item_info := {
	"beene_armor": {
		"title": "Beene Armor",
		"desc": "+10% Armor",
		"icon": "res://store/armor1.png"
	},
	"bronze_armor": {
		"title": "Bronze Armor",
		"desc": "+25% Armor",
		"icon": "res://store/armor2.png"
	},
	"gold_armor": {
		"title": "Gold Armor",
		"desc": "+50% Armor",
		"icon": "res://store/armor3.png"
	},
	"strength_1": {
		"title": "Strength Boost",
		"desc": "+15% Damage",
		"icon": "res://store/strength.png"
	},
	"health_potion": {
		"title": "Health Potion",
		"desc": "Consumable",
		"icon": "res://store/healthPotion.png"
	}
}

func _ready():
	refresh_active_items()

func refresh_active_items():
	if not active_upgrades_hbox:
		return

	for child in active_upgrades_hbox.get_children():
		child.queue_free()

	for item_key in shop_item_info.keys():
		if Global.owned_items.has(item_key):
			var value = Global.owned_items[item_key]
			
			if (typeof(value) == TYPE_BOOL and value == true) or (typeof(value) == TYPE_INT and value > 0):
				_add_item_badge(item_key, value)

func _add_item_badge(item_key: String, item_value):
	var data = shop_item_info[item_key]
	
	var badge = PanelContainer.new()
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	
	var item_hbox = HBoxContainer.new()
	item_hbox.add_theme_constant_override("separation", 6)
	
	if ResourceLoader.exists(data["icon"]):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(data["icon"])
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(24, 24)
		item_hbox.add_child(tex_rect)

	var vbox = VBoxContainer.new()
	
	var title_label = Label.new()
	if typeof(item_value) == TYPE_INT:
		title_label.text = data["title"] + " x" + str(item_value)
	else:
		title_label.text = data["title"]
		
	title_label.add_theme_font_size_override("font_size", 12)
	
	var desc_label = Label.new()
	desc_label.text = data["desc"]
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.modulate = Color(0.8, 0.8, 0.8)

	vbox.add_child(title_label)
	vbox.add_child(desc_label)
	item_hbox.add_child(vbox)
	
	margin.add_child(item_hbox)
	badge.add_child(margin)
	
	active_upgrades_hbox.add_child(badge)
