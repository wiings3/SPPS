extends Control

const MAX_ENCOUNTERS := 5
const SUITS := ["♠", "♥", "♦", "♣"]
const RANK_TEXT := {
	11: "J",
	12: "Q",
	13: "K",
	14: "A"
}

var rng := RandomNumberGenerator.new()

var chips := 100
var encounter := 0
var pot := 0
var ante := 0
var street := 0
var amount_to_call := 0
var base_raise := 10
var visible_community := 0
var hand_over := false
var cheat_used := false
var insurance_used := false

var deck: Array = []
var player_hole: Array = []
var opponent_hole: Array = []
var community: Array = []
var owned_upgrades: Array[String] = []
var current_upgrade_choices: Array[String] = []
var current_opponent: Dictionary = {}

var opponents := [
	{"name":"Deckhand Dax", "subtitle":"Dockside card shark", "aggression":0.24, "bluff":0.12, "quote":"Try not to cry on the cards."},
	{"name":"Smuggler Vexa", "subtitle":"Contraband broker", "aggression":0.34, "bluff":0.24, "quote":"Everything is legal if nobody logs it."},
	{"name":"Rustjaw Rell", "subtitle":"Scrap-fleet raider", "aggression":0.46, "bluff":0.10, "quote":"I don't bluff. I threaten mathematically."},
	{"name":"Lady Void", "subtitle":"Wanted in seven systems", "aggression":0.45, "bluff":0.34, "quote":"You brought money. How optimistic."},
	{"name":"Admiral Ash", "subtitle":"The Black Orbit", "aggression":0.58, "bluff":0.20, "quote":"Your ship will look excellent in my hangar."}
]

var upgrades := {
	"marked_deck": {
		"name":"Marked Deck",
		"desc":"Reveal one of your opponent's hole cards every encounter."
	},
	"sleeve_ace": {
		"name":"Sleeve Ace",
		"desc":"If your starting hand has no Ace, secretly replace one card with an Ace."
	},
	"loaded_river": {
		"name":"Loaded River",
		"desc":"Once per encounter, redraw the newest visible community card."
	},
	"dead_eye": {
		"name":"Dead-Eye Stare",
		"desc":"Opponents are 18% more likely to fold when you raise."
	},
	"blood_money": {
		"name":"Blood Money",
		"desc":"Gain 8 bonus chips whenever you win an encounter."
	},
	"pirates_cut": {
		"name":"Pirate's Cut",
		"desc":"Winning pays 15% extra chips from the house."
	},
	"insurance": {
		"name":"Insurance Fraud",
		"desc":"The first encounter you lose each run refunds 15 chips."
	},
	"cheap_ante": {
		"name":"Forged Buy-In",
		"desc":"Antes cost 3 fewer chips."
	},
	"cold_reader": {
		"name":"Cold Reader",
		"desc":"Your scanner gives a vague read on the opponent each street."
	},
	"hot_hand": {
		"name":"Hot Hand",
		"desc":"Gain 5 chips at the start of every encounter."
	}
}

# UI references
var chip_label: Label
var encounter_label: Label
var pot_label: Label
var opponent_name: Label
var opponent_subtitle: Label
var opponent_quote: Label
var opponent_cards: HBoxContainer
var community_cards: HBoxContainer
var player_cards: HBoxContainer
var status_label: Label
var log_box: RichTextLabel
var call_button: Button
var raise_button: Button
var fold_button: Button
var cheat_button: Button
var upgrade_overlay: Control
var upgrade_title: Label
var upgrade_buttons: Array[Button] = []
var end_overlay: Control
var end_title: Label
var end_body: Label
var begin_overlay: Control
var owned_list_box: RichTextLabel

func _ready() -> void:
	rng.randomize()
	_build_ui()
	_show_begin_screen()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("07101b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_vbox)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	main_vbox.add_child(top)

	var title := _label("SPACE PIRATE POKER SIMULATOR", 26, Color("e8edf4"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	chip_label = _pill_label("CHIPS 100")
	encounter_label = _pill_label("ENCOUNTER 0/5")
	pot_label = _pill_label("POT 0")
	top.add_child(chip_label)
	top.add_child(encounter_label)
	top.add_child(pot_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	main_vbox.add_child(body)

	var table_panel := PanelContainer.new()
	table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_panel.size_flags_stretch_ratio = 2.2
	table_panel.add_theme_stylebox_override("panel", _panel_style(Color("0d1825"), Color("25364a"), 12))
	body.add_child(table_panel)

	var table_margin := MarginContainer.new()
	table_margin.add_theme_constant_override("margin_left", 24)
	table_margin.add_theme_constant_override("margin_right", 24)
	table_margin.add_theme_constant_override("margin_top", 20)
	table_margin.add_theme_constant_override("margin_bottom", 20)
	table_panel.add_child(table_margin)

	var table_vbox := VBoxContainer.new()
	table_vbox.add_theme_constant_override("separation", 12)
	table_margin.add_child(table_vbox)

	opponent_name = _label("OPPONENT", 27, Color("ffca78"))
	opponent_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(opponent_name)

	opponent_subtitle = _label("", 14, Color("9aabba"))
	opponent_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(opponent_subtitle)

	opponent_quote = _label("", 15, Color("c7d0d9"))
	opponent_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(opponent_quote)

	opponent_cards = HBoxContainer.new()
	opponent_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	opponent_cards.add_theme_constant_override("separation", 10)
	table_vbox.add_child(opponent_cards)

	var divider1 := HSeparator.new()
	table_vbox.add_child(divider1)

	var comm_title := _label("COMMUNITY", 12, Color("6f8799"))
	comm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(comm_title)

	community_cards = HBoxContainer.new()
	community_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	community_cards.add_theme_constant_override("separation", 9)
	table_vbox.add_child(community_cards)

	status_label = _label("Awaiting deal...", 17, Color("8ee3c0"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 34
	table_vbox.add_child(status_label)

	var divider2 := HSeparator.new()
	table_vbox.add_child(divider2)

	var you_title := _label("YOUR HAND", 12, Color("6f8799"))
	you_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(you_title)

	player_cards = HBoxContainer.new()
	player_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	player_cards.add_theme_constant_override("separation", 10)
	table_vbox.add_child(player_cards)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	table_vbox.add_child(actions)

	call_button = _action_button("CHECK")
	raise_button = _action_button("RAISE")
	fold_button = _action_button("FOLD")
	cheat_button = _action_button("CHEAT")
	actions.add_child(call_button)
	actions.add_child(raise_button)
	actions.add_child(fold_button)
	actions.add_child(cheat_button)
	call_button.pressed.connect(_on_check_call)
	raise_button.pressed.connect(_on_raise)
	fold_button.pressed.connect(_on_fold)
	cheat_button.pressed.connect(_on_cheat)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 300
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 0.8
	side.add_theme_constant_override("separation", 12)
	body.add_child(side)

	var log_title := _label("CAPTAIN'S LOG", 16, Color("e8edf4"))
	side.add_child(log_title)
	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = false
	log_box.fit_content = false
	log_box.scroll_active = true
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.custom_minimum_size.y = 290
	log_box.add_theme_font_size_override("normal_font_size", 14)
	side.add_child(log_box)

	var upgrades_title := _label("INSTALLED CONTRABAND", 16, Color("e8edf4"))
	side.add_child(upgrades_title)
	owned_list_box = RichTextLabel.new()
	owned_list_box.name = "OwnedList"
	owned_list_box.bbcode_enabled = false
	owned_list_box.fit_content = false
	owned_list_box.custom_minimum_size.y = 150
	owned_list_box.add_theme_font_size_override("normal_font_size", 13)
	side.add_child(owned_list_box)

	_build_upgrade_overlay()
	_build_end_overlay()
	_build_begin_overlay()
	_refresh_owned_list()

func _build_upgrade_overlay() -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.color = Color(0.02, 0.03, 0.05, 0.96)
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.visible = false
	add_child(upgrade_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(center)

	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 860
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)

	upgrade_title = _label("SALVAGE: PICK ONE", 28, Color("ffca78"))
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(upgrade_title)

	var hint := _label("Bolt one piece of questionable technology onto your run.", 15, Color("9aabba"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)

	for i in range(3):
		var b := Button.new()
		b.custom_minimum_size = Vector2(270, 190)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_upgrade_chosen.bind(i))
		row.add_child(b)
		upgrade_buttons.append(b)

func _build_end_overlay() -> void:
	end_overlay = ColorRect.new()
	end_overlay.color = Color(0.02, 0.03, 0.05, 0.97)
	end_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_overlay.visible = false
	add_child(end_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_overlay.add_child(center)
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 600
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)
	end_title = _label("RUN OVER", 34, Color("ffca78"))
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(end_title)
	end_body = _label("", 17, Color("c7d0d9"))
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(end_body)
	var restart := _action_button("START NEW RUN")
	restart.custom_minimum_size = Vector2(240, 52)
	restart.pressed.connect(_start_run)
	var rc := CenterContainer.new()
	rc.add_child(restart)
	v.add_child(rc)

func _build_begin_overlay() -> void:
	begin_overlay = ColorRect.new()
	begin_overlay.color = Color(0.02, 0.03, 0.05, 0.98)
	begin_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(begin_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	begin_overlay.add_child(center)
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 700
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)
	var t := _label("SPACE PIRATE\nPOKER SIMULATOR", 42, Color("ffca78"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var body := _label("Prototype loop: survive five high-stakes Hold'em encounters. After every hand, salvage one of three upgrades and make your pirate poker build increasingly unfair.", 18, Color("c7d0d9"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	var start := _action_button("BEGIN RUN")
	start.custom_minimum_size = Vector2(220, 56)
	start.pressed.connect(_start_run)
	var cc := CenterContainer.new()
	cc.add_child(start)
	v.add_child(cc)

func _show_begin_screen() -> void:
	begin_overlay.visible = true
	_set_actions_enabled(false)

func _start_run() -> void:
	begin_overlay.visible = false
	end_overlay.visible = false
	upgrade_overlay.visible = false
	chips = 100
	encounter = 0
	owned_upgrades.clear()
	insurance_used = false
	log_box.clear()
	_log("New run. One ship. One stack. Terrible judgment.")
	_refresh_owned_list()
	_start_next_encounter()

func _start_next_encounter() -> void:
	encounter += 1
	if encounter > MAX_ENCOUNTERS:
		_show_run_end(true)
		return

	if _has_upgrade("hot_hand"):
		chips += 5
		_log("Hot Hand pays +5 chips before the deal.")

	ante = maxi(2, 5 + (encounter - 1) * 2 - (3 if _has_upgrade("cheap_ante") else 0))
	if chips < ante:
		_show_run_end(false)
		return

	current_opponent = opponents[encounter - 1]
	pot = 0
	street = 0
	amount_to_call = 0
	visible_community = 0
	hand_over = false
	cheat_used = false
	base_raise = 8 + encounter * 2

	_build_deck()
	player_hole = [_draw_card(), _draw_card()]
	opponent_hole = [_draw_card(), _draw_card()]
	community = [_draw_card(), _draw_card(), _draw_card(), _draw_card(), _draw_card()]
	_apply_sleeve_ace()

	chips -= ante
	pot = ante * 2
	_log("\n=== %s ===" % current_opponent["name"])
	_log("Both captains ante %d chips." % ante)
	_refresh_table()
	_refresh_header()
	_set_actions_enabled(true)
	_begin_street()

func _begin_street() -> void:
	amount_to_call = 0
	match street:
		0:
			visible_community = 0
			status_label.text = "PRE-FLOP"
		1:
			visible_community = 3
			status_label.text = "FLOP"
		2:
			visible_community = 4
			status_label.text = "TURN"
		3:
			visible_community = 5
			status_label.text = "RIVER"
	_refresh_cards()
	_offer_read_if_owned()
	_opponent_open_action()
	_refresh_buttons()

func _opponent_open_action() -> void:
	var strength := _estimate_strength(opponent_hole + _visible_board())
	var aggression: float = current_opponent["aggression"]
	var bluff: float = current_opponent["bluff"]
	var bet_chance := aggression * (0.35 + strength * 0.95)
	var is_bluff := rng.randf() < bluff * 0.35

	if rng.randf() < bet_chance or is_bluff:
		amount_to_call = base_raise
		pot += amount_to_call
		_log("%s bets %d." % [current_opponent["name"], amount_to_call])
	else:
		amount_to_call = 0
		_log("%s checks." % current_opponent["name"])
	_refresh_header()

func _on_check_call() -> void:
	if hand_over:
		return
	if amount_to_call > chips:
		return
	if amount_to_call > 0:
		chips -= amount_to_call
		pot += amount_to_call
		_log("You call %d." % amount_to_call)
	else:
		_log("You check.")
	_refresh_header()
	_advance_street()

func _on_raise() -> void:
	if hand_over:
		return
	var raise_by := base_raise
	var total_cost := amount_to_call + raise_by
	if chips < total_cost:
		return

	chips -= total_cost
	pot += total_cost
	_log("You raise by %d." % raise_by)

	var strength := _estimate_strength(opponent_hole + _visible_board())
	var fold_bonus := 0.18 if _has_upgrade("dead_eye") else 0.0
	var fold_chance: float = clampf(0.58 - strength * 0.52 + fold_bonus, 0.05, 0.88)
	if rng.randf() < fold_chance:
		_log("%s folds." % current_opponent["name"])
		_finish_hand(true, "They folded under pressure.")
		return

	pot += raise_by
	_log("%s calls the raise." % current_opponent["name"])
	_refresh_header()
	_advance_street()

func _on_fold() -> void:
	if hand_over:
		return
	_log("You fold. Space piracy remains temporarily legal.")
	_finish_hand(false, "You folded the hand.")

func _on_cheat() -> void:
	if hand_over or cheat_used or not _has_upgrade("loaded_river") or visible_community <= 0:
		return
	var index := visible_community - 1
	var old_card: Dictionary = community[index]
	community[index] = _draw_card()
	deck.append(old_card)
	deck.shuffle()
	cheat_used = true
	_log("Loaded River swaps the newest community card. Nobody notices. Probably.")
	_refresh_cards()
	_refresh_buttons()

func _advance_street() -> void:
	street += 1
	if street > 3:
		_showdown()
	else:
		_begin_street()

func _showdown() -> void:
	visible_community = 5
	_refresh_cards(true)
	var pscore := _evaluate_best(player_hole + community)
	var oscore := _evaluate_best(opponent_hole + community)
	var cmp := _compare_scores(pscore, oscore)
	var player_name := _hand_name(pscore[0])
	var opp_name := _hand_name(oscore[0])
	_log("SHOWDOWN — You: %s | %s: %s" % [player_name, current_opponent["name"], opp_name])

	if cmp > 0:
		_finish_hand(true, "%s beats %s." % [player_name, opp_name])
	elif cmp < 0:
		_finish_hand(false, "%s beats your %s." % [opp_name, player_name])
	else:
		if _has_upgrade("lucky_coin"):
			_finish_hand(true, "A tie somehow becomes your win.")
		else:
			var split := int(floor(pot / 2.0))
			chips += split
			_log("Split pot. You recover %d chips." % split)
			_finish_hand(false, "The hand ends in a tie.", true)

func _finish_hand(player_won: bool, reason: String, tie := false) -> void:
	if hand_over:
		return
	hand_over = true
	_set_actions_enabled(false)

	if player_won:
		var payout := pot
		if _has_upgrade("pirates_cut"):
			var bonus := int(round(pot * 0.15))
			payout += bonus
			_log("Pirate's Cut skims +%d bonus chips." % bonus)
		chips += payout
		if _has_upgrade("blood_money"):
			chips += 8
			_log("Blood Money pays +8 chips.")
		status_label.text = "WIN — %s" % reason
		_log("You take the pot: %d chips." % payout)
	else:
		status_label.text = "LOSS — %s" % reason
		if not tie and _has_upgrade("insurance") and not insurance_used:
			insurance_used = true
			chips += 15
			_log("Insurance Fraud refunds 15 chips.")

	_refresh_header()
	_refresh_owned_list()
	await get_tree().create_timer(1.0).timeout

	if chips <= 0:
		_show_run_end(false)
		return
	_show_upgrade_choices(player_won)

func _show_upgrade_choices(won: bool) -> void:
	upgrade_title.text = "VICTORY SALVAGE — PICK ONE" if won else "CONSOLATION SALVAGE — PICK ONE"
	current_upgrade_choices.clear()
	var available: Array[String] = []
	for key in upgrades.keys():
		if not owned_upgrades.has(key):
			available.append(key)
	available.shuffle()

	if available.is_empty():
		if encounter >= MAX_ENCOUNTERS:
			_show_run_end(true)
		else:
			_start_next_encounter()
		return

	for i in range(3):
		var button := upgrade_buttons[i]
		if i < available.size():
			var key := available[i]
			current_upgrade_choices.append(key)
			button.visible = true
			button.text = "%s\n\n%s" % [upgrades[key]["name"], upgrades[key]["desc"]]
		else:
			button.visible = false
	upgrade_overlay.visible = true

func _on_upgrade_chosen(index: int) -> void:
	if index >= current_upgrade_choices.size():
		return
	var key := current_upgrade_choices[index]
	owned_upgrades.append(key)
	_log("Installed: %s." % upgrades[key]["name"])
	upgrade_overlay.visible = false
	_refresh_owned_list()
	if encounter >= MAX_ENCOUNTERS:
		_show_run_end(true)
	else:
		_start_next_encounter()

func _show_run_end(victory: bool) -> void:
	upgrade_overlay.visible = false
	end_overlay.visible = true
	if victory:
		end_title.text = "SECTOR CLEARED"
		end_body.text = "You survived all five captains with %d chips and %d pieces of contraband installed. The prototype run is complete." % [chips, owned_upgrades.size()]
	else:
		end_title.text = "SHIP REPOSSESSED"
		end_body.text = "You ran out of chips before clearing the sector. Final stack: %d. Try a different upgrade build and bluff with more irresponsible confidence." % chips

func _refresh_table() -> void:
	opponent_name.text = current_opponent.get("name", "OPPONENT")
	opponent_subtitle.text = current_opponent.get("subtitle", "")
	opponent_quote.text = "“%s”" % current_opponent.get("quote", "")
	_refresh_cards()

func _refresh_header() -> void:
	chip_label.text = "CHIPS %d" % chips
	encounter_label.text = "ENCOUNTER %d/%d" % [encounter, MAX_ENCOUNTERS]
	pot_label.text = "POT %d" % pot
	_refresh_buttons()

func _refresh_cards(show_opponent := false) -> void:
	_clear_children(opponent_cards)
	for i in range(2):
		var reveal := show_opponent or (_has_upgrade("marked_deck") and i == 0)
		opponent_cards.add_child(_card_widget(opponent_hole[i] if reveal and opponent_hole.size() > i else {}, not reveal))

	_clear_children(community_cards)
	for i in range(5):
		if i < visible_community and community.size() > i:
			community_cards.add_child(_card_widget(community[i], false))
		else:
			community_cards.add_child(_card_widget({}, true, true))

	_clear_children(player_cards)
	for c in player_hole:
		player_cards.add_child(_card_widget(c, false))

func _refresh_buttons() -> void:
	if hand_over:
		_set_actions_enabled(false)
		return
	call_button.text = "CALL %d" % amount_to_call if amount_to_call > 0 else "CHECK"
	call_button.disabled = amount_to_call > chips
	var total_raise := amount_to_call + base_raise
	raise_button.text = "RAISE +%d" % base_raise
	raise_button.disabled = chips < total_raise
	fold_button.disabled = false
	cheat_button.visible = _has_upgrade("loaded_river")
	cheat_button.text = "CHEAT: REDRAW"
	cheat_button.disabled = cheat_used or visible_community <= 0

func _set_actions_enabled(enabled: bool) -> void:
	call_button.disabled = not enabled
	raise_button.disabled = not enabled
	fold_button.disabled = not enabled
	cheat_button.disabled = not enabled

func _refresh_owned_list() -> void:
	if owned_list_box == null:
		return
	if owned_upgrades.is_empty():
		owned_list_box.text = "No contraband installed yet."
		return
	var lines: Array[String] = []
	for key in owned_upgrades:
		lines.append("• %s" % upgrades[key]["name"])
	owned_list_box.text = "\n".join(lines)

func _visible_board() -> Array:
	var result: Array = []
	for i in range(visible_community):
		result.append(community[i])
	return result

func _offer_read_if_owned() -> void:
	if not _has_upgrade("cold_reader"):
		return
	var strength := _estimate_strength(opponent_hole + _visible_board())
	var read := "WEAK"
	if strength > 0.68:
		read = "DANGEROUS"
	elif strength > 0.43:
		read = "STEADY"
	_log("Cold Reader scan: %s." % read)

func _apply_sleeve_ace() -> void:
	if not _has_upgrade("sleeve_ace"):
		return
	if player_hole[0]["rank"] == 14 or player_hole[1]["rank"] == 14:
		return
	for i in range(deck.size()):
		if deck[i]["rank"] == 14:
			var old: Dictionary = player_hole[0]
			player_hole[0] = deck[i]
			deck[i] = old
			deck.shuffle()
			_log("Sleeve Ace quietly improves your opening hand.")
			return

func _has_upgrade(key: String) -> bool:
	return owned_upgrades.has(key)

func _build_deck() -> void:
	deck.clear()
	for suit in SUITS:
		for rank in range(2, 15):
			deck.append({"rank": rank, "suit": suit})
	deck.shuffle()

func _draw_card() -> Dictionary:
	if deck.is_empty():
		_build_deck()
	return deck.pop_back()

func _card_text(card: Dictionary) -> String:
	if card.is_empty():
		return "?"
	var rank: int = card["rank"]
	var rt: String = str(rank) if rank <= 10 else str(RANK_TEXT[rank])
	return "%s%s" % [rt, card["suit"]]

func _card_widget(card: Dictionary, hidden: bool, empty_slot := false) -> Label:
	var l := Label.new()
	l.custom_minimum_size = Vector2(74, 92)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 25)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	if hidden:
		style.bg_color = Color("16263a") if not empty_slot else Color("0b1420")
		style.border_color = Color("314863") if not empty_slot else Color("1a2938")
		l.text = "✦" if not empty_slot else "—"
		l.add_theme_color_override("font_color", Color("607b96"))
	else:
		style.bg_color = Color("e9edf0")
		style.border_color = Color("b7c1ca")
		l.text = _card_text(card)
		var suit: String = str(card.get("suit", ""))
		var red: bool = suit == "♥" or suit == "♦"
		l.add_theme_color_override("font_color", Color("b73b4c") if red else Color("1b2530"))
	l.add_theme_stylebox_override("normal", style)
	return l

func _estimate_strength(cards: Array) -> float:
	if cards.size() < 5:
		var r1: int = cards[0]["rank"]
		var r2: int = cards[1]["rank"]
		if r1 == r2:
			return clamp(0.48 + float(r1) / 28.0, 0.0, 1.0)
		var high: int = maxi(r1, r2)
		var suited_bonus := 0.07 if cards[0]["suit"] == cards[1]["suit"] else 0.0
		var connected := 0.06 if abs(r1 - r2) <= 2 else 0.0
		return clamp(0.12 + float(high) / 22.0 + suited_bonus + connected, 0.0, 0.78)
	var score := _evaluate_best(cards)
	var category: int = score[0]
	var kicker: int = score[1] if score.size() > 1 else 2
	return clamp(float(category) / 8.0 * 0.82 + float(kicker) / 14.0 * 0.18, 0.0, 1.0)

func _evaluate_best(cards: Array) -> Array:
	var best: Array = []
	var n := cards.size()
	if n < 5:
		return [0, 0]
	for a in range(n - 4):
		for b in range(a + 1, n - 3):
			for c in range(b + 1, n - 2):
				for d in range(c + 1, n - 1):
					for e in range(d + 1, n):
						var score := _evaluate_five([cards[a], cards[b], cards[c], cards[d], cards[e]])
						if best.is_empty() or _compare_scores(score, best) > 0:
							best = score
	return best

func _evaluate_five(cards: Array) -> Array:
	var ranks: Array[int] = []
	var suits: Array[String] = []
	var counts := {}
	for c in cards:
		var r: int = c["rank"]
		ranks.append(r)
		suits.append(c["suit"])
		counts[r] = counts.get(r, 0) + 1
	ranks.sort()
	ranks.reverse()

	var flush := true
	for s in suits:
		if s != suits[0]:
			flush = false
			break

	var unique := ranks.duplicate()
	var dedup: Array[int] = []
	for r in unique:
		if not dedup.has(r):
			dedup.append(r)
	var straight_high := 0
	if dedup.size() == 5:
		if dedup == [14, 5, 4, 3, 2]:
			straight_high = 5
		elif dedup[0] - dedup[4] == 4:
			straight_high = dedup[0]

	if flush and straight_high > 0:
		return [8, straight_high]

	var fours: Array[int] = []
	var threes: Array[int] = []
	var pairs: Array[int] = []
	var singles: Array[int] = []
	for r in counts.keys():
		match counts[r]:
			4: fours.append(r)
			3: threes.append(r)
			2: pairs.append(r)
			1: singles.append(r)
	fours.sort(); fours.reverse()
	threes.sort(); threes.reverse()
	pairs.sort(); pairs.reverse()
	singles.sort(); singles.reverse()

	if not fours.is_empty():
		return [7, fours[0], singles[0]]
	if not threes.is_empty() and not pairs.is_empty():
		return [6, threes[0], pairs[0]]
	if flush:
		return [5] + ranks
	if straight_high > 0:
		return [4, straight_high]
	if not threes.is_empty():
		return [3, threes[0]] + singles
	if pairs.size() >= 2:
		return [2, pairs[0], pairs[1], singles[0]]
	if pairs.size() == 1:
		return [1, pairs[0]] + singles
	return [0] + ranks

func _compare_scores(a: Array, b: Array) -> int:
	var length: int = maxi(a.size(), b.size())
	for i in range(length):
		var av: int = a[i] if i < a.size() else 0
		var bv: int = b[i] if i < b.size() else 0
		if av > bv:
			return 1
		if av < bv:
			return -1
	return 0

func _hand_name(category: int) -> String:
	match category:
		8: return "Straight Flush"
		7: return "Four of a Kind"
		6: return "Full House"
		5: return "Flush"
		4: return "Straight"
		3: return "Three of a Kind"
		2: return "Two Pair"
		1: return "Pair"
		_: return "High Card"

func _log(text: String) -> void:
	log_box.append_text(text + "\n")
	log_box.scroll_to_line(maxi(0, log_box.get_line_count() - 1))

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _pill_label(text: String) -> Label:
	var l := _label(text, 14, Color("dce6ef"))
	l.custom_minimum_size = Vector2(126, 38)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_stylebox_override("normal", _panel_style(Color("111f2e"), Color("2e4358"), 8))
	return l

func _action_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(135, 46)
	b.add_theme_font_size_override("font_size", 14)
	return b

func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s
