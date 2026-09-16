extends RefCounted

const Poker = preload("res://poker_rules.gd")

static func build(host: Control, callbacks: Dictionary) -> Dictionary:
	var refs: Dictionary = {}

	var background: ColorRect = ColorRect.new()
	background.color = Color("07101b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	host.add_child(margin)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_vbox)

	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	main_vbox.add_child(top)

	var title: Label = label("SPACE PIRATE POKER SIMULATOR", 26, Color("e8edf4"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var chip_label: Label = pill_label("CHIPS 100")
	var encounter_label: Label = pill_label("ENCOUNTER 0/7")
	var pot_label: Label = pill_label("POT 0")
	refs["chip_label"] = chip_label
	refs["encounter_label"] = encounter_label
	refs["pot_label"] = pot_label
	top.add_child(chip_label)
	top.add_child(encounter_label)
	top.add_child(pot_label)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	main_vbox.add_child(body)

	var table_panel: PanelContainer = PanelContainer.new()
	table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_panel.size_flags_stretch_ratio = 2.2
	table_panel.add_theme_stylebox_override("panel", panel_style(Color("0d1825"), Color("25364a"), 12))
	body.add_child(table_panel)

	var table_margin: MarginContainer = MarginContainer.new()
	table_margin.add_theme_constant_override("margin_left", 24)
	table_margin.add_theme_constant_override("margin_right", 24)
	table_margin.add_theme_constant_override("margin_top", 20)
	table_margin.add_theme_constant_override("margin_bottom", 20)
	table_panel.add_child(table_margin)

	var table_vbox: VBoxContainer = VBoxContainer.new()
	table_vbox.add_theme_constant_override("separation", 12)
	table_margin.add_child(table_vbox)

	var opponent_name: Label = label("OPPONENT", 27, Color("ffca78"))
	var opponent_subtitle: Label = label("", 14, Color("9aabba"))
	var opponent_quote: Label = label("", 15, Color("c7d0d9"))
	refs["opponent_name"] = opponent_name
	refs["opponent_subtitle"] = opponent_subtitle
	refs["opponent_quote"] = opponent_quote
	var opponent_labels: Array[Label] = [opponent_name, opponent_subtitle, opponent_quote]
	for opponent_label in opponent_labels:
		opponent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		table_vbox.add_child(opponent_label)

	var opponent_cards: HBoxContainer = HBoxContainer.new()
	refs["opponent_cards"] = opponent_cards
	configure_card_row(opponent_cards)
	table_vbox.add_child(opponent_cards)
	table_vbox.add_child(HSeparator.new())

	var community_title: Label = label("COMMUNITY", 12, Color("6f8799"))
	community_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(community_title)
	var community_cards: HBoxContainer = HBoxContainer.new()
	refs["community_cards"] = community_cards
	configure_card_row(community_cards)
	table_vbox.add_child(community_cards)

	var status: Label = label("Awaiting deal...", 17, Color("8ee3c0"))
	refs["status_label"] = status
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 34
	table_vbox.add_child(status)
	table_vbox.add_child(HSeparator.new())

	var you_title: Label = label("YOUR HAND", 12, Color("6f8799"))
	you_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_vbox.add_child(you_title)
	var player_cards: HBoxContainer = HBoxContainer.new()
	refs["player_cards"] = player_cards
	configure_card_row(player_cards)
	table_vbox.add_child(player_cards)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	table_vbox.add_child(actions)
	var call_button: Button = action_button("CHECK")
	var raise_button: Button = action_button("RAISE")
	var all_in_button: Button = action_button("ALL-IN")
	var fold_button: Button = action_button("FOLD")
	var cheat_button: Button = action_button("CHEAT")
	refs["call_button"] = call_button
	refs["raise_button"] = raise_button
	refs["all_in_button"] = all_in_button
	refs["fold_button"] = fold_button
	refs["cheat_button"] = cheat_button
	var action_buttons: Array[Button] = [call_button, raise_button, all_in_button, fold_button, cheat_button]
	for button in action_buttons:
		actions.add_child(button)

	var call_callback: Callable = callbacks["call"]
	var raise_callback: Callable = callbacks["raise"]
	var all_in_callback: Callable = callbacks["all_in"]
	var fold_callback: Callable = callbacks["fold"]
	var cheat_callback: Callable = callbacks["cheat"]
	call_button.pressed.connect(call_callback)
	raise_button.pressed.connect(raise_callback)
	all_in_button.pressed.connect(all_in_callback)
	fold_button.pressed.connect(fold_callback)
	cheat_button.pressed.connect(cheat_callback)

	var side: VBoxContainer = VBoxContainer.new()
	side.custom_minimum_size.x = 300
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 0.8
	side.add_theme_constant_override("separation", 12)
	body.add_child(side)
	side.add_child(label("CAPTAIN'S LOG", 16, Color("e8edf4")))

	var log_box: RichTextLabel = RichTextLabel.new()
	refs["log_box"] = log_box
	log_box.bbcode_enabled = false
	log_box.scroll_active = true
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.custom_minimum_size.y = 290
	log_box.add_theme_font_size_override("normal_font_size", 14)
	side.add_child(log_box)

	side.add_child(label("INSTALLED CONTRABAND", 16, Color("e8edf4")))
	var owned: RichTextLabel = RichTextLabel.new()
	refs["owned_list_box"] = owned
	owned.bbcode_enabled = false
	owned.custom_minimum_size.y = 150
	owned.add_theme_font_size_override("normal_font_size", 13)
	side.add_child(owned)

	build_upgrade_overlay(host, refs, callbacks)
	build_end_overlay(host, refs, callbacks)
	build_begin_overlay(host, refs, callbacks)
	return refs

static func build_upgrade_overlay(host: Control, refs: Dictionary, callbacks: Dictionary) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.05, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	host.add_child(overlay)
	refs["upgrade_overlay"] = overlay

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size.x = 900
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var upgrade_title: Label = label("SALVAGE: PICK ONE", 28, Color("ffca78"))
	refs["upgrade_title"] = upgrade_title
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(upgrade_title)
	var hint: Label = label("Build a machine. Don't collect bonuses.", 15, Color("9aabba"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var upgrade_buttons: Array[Button] = []
	var choose_callback: Callable = callbacks["upgrade"]
	for i in range(3):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(285, 210)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(choose_callback.bind(i))
		row.add_child(button)
		upgrade_buttons.append(button)
	refs["upgrade_buttons"] = upgrade_buttons

static func build_end_overlay(host: Control, refs: Dictionary, callbacks: Dictionary) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.05, 0.97)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	host.add_child(overlay)
	refs["end_overlay"] = overlay
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size.x = 600
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var end_title: Label = label("RUN OVER", 34, Color("ffca78"))
	var end_body: Label = label("", 17, Color("c7d0d9"))
	refs["end_title"] = end_title
	refs["end_body"] = end_body
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(end_title)
	box.add_child(end_body)
	var restart: Button = action_button("START NEW RUN")
	restart.custom_minimum_size = Vector2(240, 52)
	var restart_callback: Callable = callbacks["start"]
	restart.pressed.connect(restart_callback)
	var restart_center: CenterContainer = CenterContainer.new()
	restart_center.add_child(restart)
	box.add_child(restart_center)

static func build_begin_overlay(host: Control, refs: Dictionary, callbacks: Dictionary) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.05, 0.98)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(overlay)
	refs["begin_overlay"] = overlay
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size.x = 700
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title: Label = label("SPACE PIRATE\nPOKER SIMULATOR", 42, Color("ffca78"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var body: Label = label("Seven captains. Build a broken contraband engine from bluffing, cheating, all-ins, and economy upgrades.", 18, Color("c7d0d9"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var start: Button = action_button("BEGIN RUN")
	start.custom_minimum_size = Vector2(220, 56)
	var start_callback: Callable = callbacks["start"]
	start.pressed.connect(start_callback)
	var start_center: CenterContainer = CenterContainer.new()
	start_center.add_child(start)
	box.add_child(start_center)

static func configure_card_row(row: HBoxContainer) -> void:
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

static func card_widget(card: Dictionary, hidden: bool, empty_slot: bool = false) -> Label:
	var result: Label = Label.new()
	result.custom_minimum_size = Vector2(74, 92)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 25)
	var style: StyleBoxFlat = StyleBoxFlat.new()
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
		result.text = "✦" if not empty_slot else "—"
		result.add_theme_color_override("font_color", Color("607b96"))
	else:
		style.bg_color = Color("e9edf0")
		style.border_color = Color("b7c1ca")
		result.text = Poker.card_text(card)
		var suit: String = str(card.get("suit", ""))
		var red: bool = suit == "♥" or suit == "♦"
		result.add_theme_color_override("font_color", Color("b73b4c") if red else Color("1b2530"))
	result.add_theme_stylebox_override("normal", style)
	return result

static func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

static func label(text: String, font_size: int, color: Color) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result

static func pill_label(text: String) -> Label:
	var result: Label = label(text, 14, Color("dce6ef"))
	result.custom_minimum_size = Vector2(126, 38)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_stylebox_override("normal", panel_style(Color("111f2e"), Color("2e4358"), 8))
	return result

static func action_button(text: String) -> Button:
	var result: Button = Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(122, 46)
	result.add_theme_font_size_override("font_size", 14)
	return result

static func panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var result: StyleBoxFlat = StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = border
	result.border_width_left = 1
	result.border_width_top = 1
	result.border_width_right = 1
	result.border_width_bottom = 1
	result.corner_radius_top_left = radius
	result.corner_radius_top_right = radius
	result.corner_radius_bottom_left = radius
	result.corner_radius_bottom_right = radius
	return result
