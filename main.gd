extends Control

const Data = preload("res://game_data.gd")
const Poker = preload("res://poker_rules.gd")
const UI = preload("res://main_ui.gd")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var opponents: Array[Dictionary] = []
var upgrades: Dictionary = {}

var chips: int = 100
var encounter: int = 0
var pot: int = 0
var ante: int = 0
var street: int = 0
var amount_to_call: int = 0
var base_raise: int = 10
var visible_community: int = 0
var hand_over: bool = false
var insurance_used: bool = false
var escape_pod_used: bool = false
var cheats_remaining: int = 0
var cheats_used_this_hand: int = 0
var bluff_wins: int = 0
var intimidation_bonus: float = 0.0

var deck: Array[Dictionary] = []
var player_hole: Array[Dictionary] = []
var opponent_hole: Array[Dictionary] = []
var community: Array[Dictionary] = []
var owned_upgrades: Array[String] = []
var current_upgrade_choices: Array[String] = []
var current_opponent: Dictionary = {}

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
var all_in_button: Button
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
	opponents = Data.opponents()
	upgrades = Data.upgrades()
	_build_ui()
	_refresh_owned_list()
	_set_actions_enabled(false)

func _build_ui() -> void:
	var refs: Dictionary = UI.build(self, {
		"start": Callable(self, "_start_run"),
		"call": Callable(self, "_on_check_call"),
		"raise": Callable(self, "_on_raise"),
		"all_in": Callable(self, "_on_all_in"),
		"fold": Callable(self, "_on_fold"),
		"cheat": Callable(self, "_on_cheat"),
		"upgrade": Callable(self, "_on_upgrade_chosen")
	})
	chip_label = refs["chip_label"] as Label
	encounter_label = refs["encounter_label"] as Label
	pot_label = refs["pot_label"] as Label
	opponent_name = refs["opponent_name"] as Label
	opponent_subtitle = refs["opponent_subtitle"] as Label
	opponent_quote = refs["opponent_quote"] as Label
	opponent_cards = refs["opponent_cards"] as HBoxContainer
	community_cards = refs["community_cards"] as HBoxContainer
	player_cards = refs["player_cards"] as HBoxContainer
	status_label = refs["status_label"] as Label
	log_box = refs["log_box"] as RichTextLabel
	call_button = refs["call_button"] as Button
	raise_button = refs["raise_button"] as Button
	all_in_button = refs["all_in_button"] as Button
	fold_button = refs["fold_button"] as Button
	cheat_button = refs["cheat_button"] as Button
	upgrade_overlay = refs["upgrade_overlay"] as Control
	upgrade_title = refs["upgrade_title"] as Label
	end_overlay = refs["end_overlay"] as Control
	end_title = refs["end_title"] as Label
	end_body = refs["end_body"] as Label
	begin_overlay = refs["begin_overlay"] as Control
	owned_list_box = refs["owned_list_box"] as RichTextLabel
	var raw_buttons: Array = refs["upgrade_buttons"]
	for raw_button in raw_buttons:
		upgrade_buttons.append(raw_button as Button)

func _start_run() -> void:
	begin_overlay.visible = false
	end_overlay.visible = false
	upgrade_overlay.visible = false
	chips = 100
	encounter = 0
	owned_upgrades.clear()
	insurance_used = false
	escape_pod_used = false
	bluff_wins = 0
	intimidation_bonus = 0.0
	log_box.clear()
	_log("New run. One ship. One stack. Terrible judgment.")
	_refresh_owned_list()
	_start_next_encounter()

func _start_next_encounter() -> void:
	encounter += 1
	if encounter > Data.MAX_ENCOUNTERS:
		_show_run_end(true)
		return

	if _has_upgrade("hot_hand"):
		chips += 6
		_log("Hot Hand pays +6 chips before the deal.")
	if _has_upgrade("death_wish") and chips < 40:
		chips += 15
		_log("Death Wish kicks in: +15 chips for arriving nearly broke.")

	var ante_discount: int = 3 if _has_upgrade("cheap_ante") else 0
	ante = maxi(2, 5 + (encounter - 1) * 2 - ante_discount)
	if chips < ante:
		_show_run_end(false)
		return

	current_opponent = opponents[encounter - 1]
	pot = 0
	street = 0
	amount_to_call = 0
	visible_community = 0
	hand_over = false
	cheats_used_this_hand = 0
	cheats_remaining = 1 + (1 if _has_upgrade("greased_dealer") else 0)
	base_raise = 8 + encounter * 2

	deck = Poker.build_deck()
	player_hole = [Poker.draw_card(deck), Poker.draw_card(deck)]
	opponent_hole = [Poker.draw_card(deck), Poker.draw_card(deck)]
	community = [Poker.draw_card(deck), Poker.draw_card(deck), Poker.draw_card(deck), Poker.draw_card(deck), Poker.draw_card(deck)]
	_apply_sleeve_ace()

	chips -= ante
	pot = ante * 2
	_log("\n=== %s ===" % str(current_opponent["name"]))
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
	var strength: float = Poker.estimate_strength(opponent_hole + _visible_board())
	var aggression: float = float(current_opponent["aggression"])
	var bluff: float = float(current_opponent["bluff"])
	var bet_chance: float = aggression * (0.35 + strength * 0.95)
	var is_bluff: bool = rng.randf() < bluff * 0.35
	if rng.randf() < bet_chance or is_bluff:
		amount_to_call = base_raise
		pot += amount_to_call
		_log("%s bets %d." % [str(current_opponent["name"]), amount_to_call])
	else:
		amount_to_call = 0
		_log("%s checks." % str(current_opponent["name"]))
	_refresh_header()

func _on_check_call() -> void:
	if hand_over or amount_to_call > chips:
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
	var total_cost: int = amount_to_call + base_raise
	if chips < total_cost:
		return
	chips -= total_cost
	pot += total_cost
	_log("You raise by %d." % base_raise)

	var strength: float = Poker.estimate_strength(opponent_hole + _visible_board())
	var fold_chance: float = 0.58 - strength * 0.52 + _current_fold_bonus()
	fold_chance = clampf(fold_chance, 0.05, 0.92)
	if rng.randf() < fold_chance:
		_log("%s folds." % str(current_opponent["name"]))
		_finish_hand(true, "They folded under pressure.", false, "bluff")
		return

	pot += base_raise
	_log("%s calls the raise." % str(current_opponent["name"]))
	_refresh_header()
	_advance_street()

func _on_all_in() -> void:
	if hand_over or chips <= 0:
		return
	var shove: int = chips
	var fold_bonus: float = _current_fold_bonus()
	chips = 0
	pot += shove
	_log("You shove ALL-IN for %d." % shove)

	var strength: float = Poker.estimate_strength(opponent_hole + _visible_board())
	var fold_chance: float = 0.42 - strength * 0.36 + fold_bonus
	if _has_upgrade("redline_reactor"):
		fold_chance += 0.15
	if _has_upgrade("double_down"):
		fold_chance -= 0.12
	if _has_upgrade("death_wish") and shove <= 55:
		fold_chance += 0.10
	fold_chance = clampf(fold_chance, 0.04, 0.90)

	if rng.randf() < fold_chance:
		_log("%s refuses the shove and folds." % str(current_opponent["name"]))
		_finish_hand(true, "Your shove scares them off.", false, "all_in_bluff")
		return

	pot += shove
	_log("%s calls. No more hiding." % str(current_opponent["name"]))
	visible_community = 5
	_refresh_header()
	_showdown(true)

func _on_fold() -> void:
	if hand_over:
		return
	_log("You fold. Space piracy remains temporarily legal.")
	_finish_hand(false, "You folded the hand.")

func _on_cheat() -> void:
	if hand_over or cheats_remaining <= 0:
		return
	if street == 0 and _has_upgrade("second_deal"):
		var redraw_index: int = 0 if int(player_hole[0]["rank"]) <= int(player_hole[1]["rank"]) else 1
		var old_hole: Dictionary = player_hole[redraw_index]
		player_hole[redraw_index] = Poker.draw_card(deck)
		deck.append(old_hole)
		deck.shuffle()
		cheats_remaining -= 1
		cheats_used_this_hand += 1
		_log("Second Deal replaces your lower hole card.")
	elif street > 0 and visible_community > 0 and _has_upgrade("loaded_river"):
		var index: int = visible_community - 1
		var old_card: Dictionary = community[index]
		community[index] = Poker.draw_card(deck)
		deck.append(old_card)
		deck.shuffle()
		cheats_remaining -= 1
		cheats_used_this_hand += 1
		_log("Loaded River swaps the newest community card. Nobody notices. Probably.")
	else:
		return
	_refresh_cards()
	_refresh_buttons()

func _advance_street() -> void:
	street += 1
	if street > 3:
		_showdown(false)
	else:
		_begin_street()

func _showdown(from_all_in: bool) -> void:
	visible_community = 5
	_refresh_cards(true)
	var player_score: Array[int] = Poker.evaluate_best(player_hole + community)
	var opponent_score: Array[int] = Poker.evaluate_best(opponent_hole + community)
	var comparison: int = Poker.compare_scores(player_score, opponent_score)
	var player_hand: String = Poker.hand_name(player_score[0])
	var opponent_hand: String = Poker.hand_name(opponent_score[0])
	_log("SHOWDOWN — You: %s | %s: %s" % [player_hand, str(current_opponent["name"]), opponent_hand])
	var method: String = "all_in" if from_all_in else "showdown"
	if comparison > 0:
		_finish_hand(true, "%s beats %s." % [player_hand, opponent_hand], false, method)
	elif comparison < 0:
		_finish_hand(false, "%s beats your %s." % [opponent_hand, player_hand], false, method)
	else:
		var split: int = int(floor(float(pot) / 2.0))
		chips += split
		_log("Split pot. You recover %d chips." % split)
		_finish_hand(false, "The hand ends in a tie.", true, method)

func _finish_hand(player_won: bool, reason: String, tie: bool = false, win_method: String = "showdown") -> void:
	if hand_over:
		return
	hand_over = true
	_set_actions_enabled(false)

	if player_won:
		var payout: int = pot
		if _has_upgrade("pirates_cut"):
			var cut_bonus: int = int(round(float(pot) * 0.15))
			payout += cut_bonus
			_log("Pirate's Cut skims +%d bonus chips." % cut_bonus)
		chips += payout

		var is_bluff_win: bool = win_method == "bluff" or win_method == "all_in_bluff"
		var is_all_in_win: bool = win_method == "all_in" or win_method == "all_in_bluff"
		if is_bluff_win:
			_apply_bluff_rewards()
		if is_all_in_win:
			if _has_upgrade("blood_money"):
				chips += 18
				_log("Blood Money pays +18 chips.")
			if win_method == "all_in" and _has_upgrade("double_down"):
				chips += 30
				_log("Double Down pays +30 chips for surviving the call.")
		elif win_method == "showdown" and _has_upgrade("salvage_rights"):
			chips += 10
			_log("Salvage Rights pays +10 chips for the showdown win.")
		if cheats_used_this_hand > 0 and _has_upgrade("inside_man"):
			chips += 12
			_log("Inside Man pays +12 chips because the fix worked.")
		status_label.text = "WIN — %s" % reason
		_log("You take the pot: %d chips." % payout)
	else:
		status_label.text = "LOSS — %s" % reason
		if not tie and win_method == "all_in" and _has_upgrade("escape_pod") and not escape_pod_used:
			escape_pod_used = true
			chips = maxi(chips, 20)
			_log("Escape Pod fires. You crawl back into the run with 20 chips.")
		elif not tie and win_method != "all_in" and _has_upgrade("insurance") and not insurance_used:
			insurance_used = true
			chips += 15
			_log("Insurance Fraud refunds 15 chips.")

	_refresh_header()
	_refresh_owned_list()
	await get_tree().create_timer(0.8).timeout
	if chips <= 0:
		_show_run_end(false)
		return
	if encounter >= Data.MAX_ENCOUNTERS:
		_show_run_end(player_won)
		return
	_show_upgrade_choices(player_won)

func _apply_bluff_rewards() -> void:
	if _has_upgrade("shark_smile"):
		chips += 10
		_log("Shark Smile pays +10 chips for the fold.")
	if _has_upgrade("no_witnesses"):
		var witness_bonus: int = bluff_wins * 4
		if witness_bonus > 0:
			chips += witness_bonus
			_log("No Witnesses pays +%d chips." % witness_bonus)
	bluff_wins += 1
	if _has_upgrade("terror_engine"):
		intimidation_bonus = minf(0.20, intimidation_bonus + 0.04)
		_log("Terror Engine grows: permanent fold pressure is now +%d%%." % int(round(intimidation_bonus * 100.0)))

func _show_upgrade_choices(won: bool) -> void:
	upgrade_title.text = "VICTORY SALVAGE — PICK ONE" if won else "CONSOLATION SALVAGE — PICK ONE"
	current_upgrade_choices.clear()
	var available: Array[String] = []
	for raw_key in upgrades.keys():
		var key: String = str(raw_key)
		if owned_upgrades.has(key) or not _requirements_met(key):
			continue
		available.append(key)
	if available.is_empty():
		_start_next_encounter()
		return

	var desired: int = mini(3, available.size())
	for _pick in range(desired):
		var chosen: String = _pick_weighted_upgrade(available)
		current_upgrade_choices.append(chosen)
		available.erase(chosen)

	for i in range(3):
		var button: Button = upgrade_buttons[i]
		if i >= current_upgrade_choices.size():
			button.visible = false
			continue
		var key: String = current_upgrade_choices[i]
		var data: Dictionary = upgrades[key]
		var tags: Array = data.get("tags", [])
		var tag_text: String = _join_tags(tags, " / ")
		var combo_count: int = _matching_tag_count(tags)
		var combo_line: String = "NEW DIRECTION" if combo_count == 0 else "SYNERGY x%d" % combo_count
		button.visible = true
		button.text = "%s\n[%s]  %s\n\n%s" % [str(data["name"]), tag_text, combo_line, str(data["desc"])]
	upgrade_overlay.visible = true

func _requirements_met(key: String) -> bool:
	var data: Dictionary = upgrades[key]
	var requirements: Array = data.get("requires_any", [])
	if requirements.is_empty():
		return true
	for raw_requirement in requirements:
		if owned_upgrades.has(str(raw_requirement)):
			return true
	return false

func _pick_weighted_upgrade(available: Array[String]) -> String:
	var weights: Array[float] = []
	var total: float = 0.0
	for key in available:
		var data: Dictionary = upgrades[key]
		var tags: Array = data.get("tags", [])
		var matches: int = _matching_tag_count(tags)
		var weight: float = 1.0 + float(matches) * 2.25
		weights.append(weight)
		total += weight
	var roll: float = rng.randf() * total
	var cursor: float = 0.0
	for i in range(available.size()):
		cursor += weights[i]
		if roll <= cursor:
			return available[i]
	return available.back()

func _matching_tag_count(tags: Array) -> int:
	var owned_tags: Array[String] = _owned_tags()
	var count: int = 0
	for raw_tag in tags:
		if owned_tags.has(str(raw_tag)):
			count += 1
	return count

func _owned_tags() -> Array[String]:
	var result: Array[String] = []
	for key in owned_upgrades:
		var data: Dictionary = upgrades[key]
		var tags: Array = data.get("tags", [])
		for raw_tag in tags:
			var tag: String = str(raw_tag)
			if not result.has(tag):
				result.append(tag)
	return result

func _on_upgrade_chosen(index: int) -> void:
	if index < 0 or index >= current_upgrade_choices.size():
		return
	var key: String = current_upgrade_choices[index]
	owned_upgrades.append(key)
	var data: Dictionary = upgrades[key]
	_log("Installed: %s." % str(data["name"]))
	upgrade_overlay.visible = false
	_refresh_owned_list()
	_start_next_encounter()

func _refresh_table() -> void:
	opponent_name.text = str(current_opponent.get("name", "OPPONENT"))
	opponent_subtitle.text = str(current_opponent.get("subtitle", ""))
	opponent_quote.text = "“%s”" % str(current_opponent.get("quote", ""))
	_refresh_cards(false)

func _refresh_header() -> void:
	chip_label.text = "CHIPS %d" % chips
	encounter_label.text = "ENCOUNTER %d/%d" % [encounter, Data.MAX_ENCOUNTERS]
	pot_label.text = "POT %d" % pot
	_refresh_buttons()

func _refresh_cards(show_opponent: bool = false) -> void:
	UI.clear_children(opponent_cards)
	for i in range(2):
		var reveal: bool = show_opponent or (_has_upgrade("marked_deck") and i == 0)
		var opponent_card: Dictionary = opponent_hole[i] if reveal and opponent_hole.size() > i else {}
		opponent_cards.add_child(UI.card_widget(opponent_card, not reveal))
	UI.clear_children(community_cards)
	for i in range(5):
		if i < visible_community and community.size() > i:
			community_cards.add_child(UI.card_widget(community[i], false))
		else:
			community_cards.add_child(UI.card_widget({}, true, true))
	UI.clear_children(player_cards)
	for card in player_hole:
		player_cards.add_child(UI.card_widget(card, false))

func _refresh_buttons() -> void:
	if hand_over:
		_set_actions_enabled(false)
		return
	call_button.text = "CALL %d" % amount_to_call if amount_to_call > 0 else "CHECK"
	call_button.disabled = amount_to_call > chips
	var total_raise: int = amount_to_call + base_raise
	raise_button.text = "RAISE +%d" % base_raise
	raise_button.disabled = chips < total_raise
	all_in_button.text = "ALL-IN %d" % chips
	all_in_button.disabled = chips <= 0
	fold_button.disabled = false
	var can_second_deal: bool = street == 0 and _has_upgrade("second_deal")
	var can_loaded_river: bool = street > 0 and visible_community > 0 and _has_upgrade("loaded_river")
	cheat_button.visible = can_second_deal or can_loaded_river
	cheat_button.text = "CHEAT: SECOND DEAL (%d)" % cheats_remaining if can_second_deal else "CHEAT: REDRAW (%d)" % cheats_remaining
	cheat_button.disabled = cheats_remaining <= 0

func _set_actions_enabled(enabled: bool) -> void:
	call_button.disabled = not enabled
	raise_button.disabled = not enabled
	all_in_button.disabled = not enabled
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
		var data: Dictionary = upgrades[key]
		var tags: Array = data.get("tags", [])
		lines.append("• %s  [%s]" % [str(data["name"]), _join_tags(tags, "/")])
	owned_list_box.text = "\n".join(lines)

func _visible_board() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(visible_community):
		result.append(community[i])
	return result

func _offer_read_if_owned() -> void:
	if not _has_upgrade("cold_reader"):
		return
	var strength: float = Poker.estimate_strength(opponent_hole + _visible_board())
	var read: String = "WEAK"
	if strength > 0.68:
		read = "DANGEROUS"
	elif strength > 0.43:
		read = "STEADY"
	_log("Cold Reader scan: %s." % read)

func _apply_sleeve_ace() -> void:
	if not _has_upgrade("sleeve_ace"):
		return
	if int(player_hole[0]["rank"]) == 14 or int(player_hole[1]["rank"]) == 14:
		return
	var replace_index: int = 0 if int(player_hole[0]["rank"]) <= int(player_hole[1]["rank"]) else 1
	for i in range(deck.size()):
		if int(deck[i]["rank"]) == 14:
			var old: Dictionary = player_hole[replace_index]
			player_hole[replace_index] = deck[i]
			deck[i] = old
			deck.shuffle()
			_log("Sleeve Ace quietly improves your opening hand.")
			return

func _current_fold_bonus() -> float:
	var bonus: float = intimidation_bonus
	if _has_upgrade("dead_eye"):
		bonus += 0.18
	if _has_upgrade("cornered_rat") and chips <= 45:
		bonus += 0.22
	return bonus

func _has_upgrade(key: String) -> bool:
	return owned_upgrades.has(key)

func _join_tags(tags: Array, separator: String) -> String:
	var text_tags: PackedStringArray = PackedStringArray()
	for raw_tag in tags:
		text_tags.append(str(raw_tag))
	return separator.join(text_tags)

func _show_run_end(victory: bool) -> void:
	upgrade_overlay.visible = false
	end_overlay.visible = true
	if victory:
		end_title.text = "SECTOR CLEARED"
		end_body.text = "You beat all seven captains with %d chips and %d pieces of contraband. More importantly: did the build change how you played the hands?" % [chips, owned_upgrades.size()]
	else:
		end_title.text = "SHIP REPOSSESSED"
		end_body.text = "Run over. Final stack: %d. Try committing harder to a synergy instead of collecting individually useful upgrades." % chips

func _log(text: String) -> void:
	log_box.append_text(text + "\n")
	log_box.scroll_to_line(maxi(0, log_box.get_line_count() - 1))
