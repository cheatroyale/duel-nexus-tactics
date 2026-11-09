class_name BattleView
extends Control

## Battle screen. Owns a Battle (pure rules) and renders it; every click is
## translated into one of Battle's player_* calls.

signal battle_finished(won: bool, encounter_index: int)
signal quit_requested

var battle: Battle
var encounter_index := 0

var enemy_row: HFlowContainer
var player_row: HFlowContainer
var round_label: Label
var energy_label: Label
var hint_label: Label
var action_box: HFlowContainer
var end_turn_button: Button
var log_label: RichTextLabel

var selected_card: CardInstance = null
var targeting := false
var busy := false
var finished := false


## Called before the view enters the tree, so the fight is already set up by
## the time _ready() builds the UI.
func start(squad: Array[CardInstance], index: int) -> void:
	encounter_index = index
	var encounter := DB.encounter(index)
	var enemies: Array[CardInstance] = []
	for entry in encounter.get("team", []):
		enemies.append(CardInstance.from_blueprint(entry))
	battle = Battle.new()
	battle.setup(squad, enemies)


func _ready() -> void:
	if battle == null:
		push_error("BattleView.start() must be called before adding it to the tree.")
		return
	_build()
	for line in battle.history:
		log_label.append_text(line + "\n")
	battle.log_added.connect(_on_log)
	_refresh()


# --- Structure --------------------------------------------------------------

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)

	# Scrolls instead of clipping when the screen is shorter than the board.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	scroll.add_child(root)

	# Top bar: the encounter and retreat on one line, the round/energy readout
	# on the next, so both stay readable on a phone.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var encounter_name := String(DB.encounter(encounter_index).get("name", "Battle"))
	top.add_child(Palette.label(encounter_name, 20, Palette.TEXT))
	top.add_child(Palette.spacer())
	var retreat := Palette.button("Retreat")
	retreat.pressed.connect(func() -> void: quit_requested.emit())
	top.add_child(retreat)

	var meters := HBoxContainer.new()
	meters.add_theme_constant_override("separation", 16)
	root.add_child(meters)
	round_label = Palette.label("", 16, Palette.MUTED)
	meters.add_child(round_label)
	energy_label = Palette.label("", 16, Palette.ACCENT_2)
	meters.add_child(energy_label)

	# Enemy row: flows into as many lines as the screen needs.
	root.add_child(Palette.label("ENEMY", 12, Palette.MUTED))
	enemy_row = HFlowContainer.new()
	enemy_row.add_theme_constant_override("h_separation", 8)
	enemy_row.add_theme_constant_override("v_separation", 8)
	root.add_child(enemy_row)

	# Player row.
	root.add_child(Palette.label("YOUR SQUAD", 12, Palette.MUTED))
	player_row = HFlowContainer.new()
	player_row.add_theme_constant_override("h_separation", 8)
	player_row.add_theme_constant_override("v_separation", 8)
	root.add_child(player_row)

	# Action bar: hint on top, touch-sized buttons below.
	var bar := PanelContainer.new()
	root.add_child(bar)
	var bar_box := VBoxContainer.new()
	bar_box.add_theme_constant_override("separation", 8)
	bar.add_child(bar_box)
	hint_label = Palette.label("", 13, Palette.MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bar_box.add_child(hint_label)
	var bar_line := HBoxContainer.new()
	bar_line.add_theme_constant_override("separation", 8)
	bar_box.add_child(bar_line)
	action_box = HFlowContainer.new()
	action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_box.add_theme_constant_override("h_separation", 6)
	action_box.add_theme_constant_override("v_separation", 6)
	bar_line.add_child(action_box)
	end_turn_button = Palette.button("End Turn", true)
	end_turn_button.pressed.connect(_on_end_turn)
	bar_line.add_child(end_turn_button)

	# Log.
	var log_panel := PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(log_panel)
	log_label = RichTextLabel.new()
	log_label.scroll_following = true
	log_label.bbcode_enabled = false
	log_label.custom_minimum_size = Vector2(0, 170)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.add_theme_font_size_override("normal_font_size", Palette.font(13))
	log_label.add_theme_color_override("default_color", Palette.MUTED)
	log_panel.add_child(log_label)


# --- Rendering --------------------------------------------------------------

func _on_log(text: String) -> void:
	log_label.append_text(text + "\n")


func _refresh() -> void:
	if battle == null:
		return
	round_label.text = "Round %d" % battle.round_number
	energy_label.text = "Energy %d  ·  Enemy energy %d" % [battle.player_energy, battle.enemy_energy]
	_refresh_row(enemy_row, battle.enemy_team, false)
	_refresh_row(player_row, battle.player_team, true)
	_refresh_actions()


func _refresh_row(row: HFlowContainer, team: Array[CardInstance], is_player: bool) -> void:
	Palette.clear(row)
	var allies := battle.living(battle.player_team) if is_player else battle.living(battle.enemy_team)
	for card in team:
		var view := CardView.new()
		var opts := {}
		if is_player and card == selected_card:
			opts["selected"] = true
		if not is_player and targeting and card.alive:
			opts["targetable"] = true
		if card.has_acted and card.alive:
			opts["spent"] = true
		view.setup(card, card.attack_total(allies), card.hp, card.max_hp, opts)
		view.custom_minimum_size = Vector2(200, 250)
		view.card_pressed.connect(_on_card_pressed)
		row.add_child(view)


func _refresh_actions() -> void:
	Palette.clear(action_box)
	if battle.is_over:
		hint_label.text = "Battle over."
		end_turn_button.disabled = true
		return
	if busy:
		hint_label.text = "Enemy turn..."
		end_turn_button.disabled = true
		return
	end_turn_button.disabled = false

	if selected_card == null or not selected_card.alive:
		selected_card = null
		targeting = false
		hint_label.text = "Select one of your cards to act."
		return

	if targeting:
		hint_label.text = "Choose an enemy for %s to attack." % selected_card.card_name()
		var cancel := Palette.button("Cancel")
		cancel.pressed.connect(_cancel_targeting)
		action_box.add_child(cancel)
		return

	if selected_card.has_acted:
		hint_label.text = "%s has already acted this round." % selected_card.card_name()
		return

	var allies := battle.living(battle.player_team)
	hint_label.text = "%s · %d ATK · %d/%d HP" % [
		selected_card.card_name(),
		selected_card.attack_total(allies),
		selected_card.hp,
		selected_card.max_hp,
	]

	var attack := Palette.button("Attack (1)")
	attack.disabled = battle.player_energy < Battle.ATTACK_COST
	attack.pressed.connect(_on_attack_pressed)
	action_box.add_child(attack)

	var ability := selected_card.ability()
	if not ability.is_empty():
		var ability_button := Palette.button("%s (%d)" % [String(ability.get("name", "Ability")), int(ability.get("cost", 0))])
		ability_button.disabled = battle.player_energy < int(ability.get("cost", 0))
		ability_button.pressed.connect(_on_ability_pressed)
		action_box.add_child(ability_button)

	var skip := Palette.button("Skip")
	skip.pressed.connect(_on_skip_pressed)
	action_box.add_child(skip)


# --- Interaction ------------------------------------------------------------

func _on_card_pressed(card: CardInstance) -> void:
	if battle == null or battle.is_over or busy:
		return
	if not card.is_player:
		if targeting and selected_card != null and selected_card.alive:
			_perform_attack(selected_card, card)
		return
	if not card.alive:
		return
	selected_card = card
	targeting = false
	_refresh()


func _cancel_targeting() -> void:
	targeting = false
	_refresh()


func _on_attack_pressed() -> void:
	if selected_card == null:
		return
	if battle.living(battle.enemy_team).is_empty():
		return
	targeting = true
	_refresh()


func _perform_attack(attacker: CardInstance, target: CardInstance) -> void:
	targeting = false
	battle.player_attack(attacker, target)
	selected_card = null
	_refresh()
	if battle.is_over:
		_finish()


func _on_ability_pressed() -> void:
	if selected_card == null:
		return
	var caster := selected_card
	battle.player_ability(caster)
	selected_card = null
	_refresh()
	if battle.is_over:
		_finish()


func _on_skip_pressed() -> void:
	if selected_card == null:
		return
	battle.player_pass(selected_card)
	selected_card = null
	_refresh()


func _on_end_turn() -> void:
	if battle == null or battle.is_over or busy:
		return
	busy = true
	selected_card = null
	targeting = false
	_refresh()

	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	battle.end_player_turn()
	busy = false
	_refresh()
	if battle.is_over:
		_finish()


# --- End of battle ----------------------------------------------------------

func _finish() -> void:
	if finished:
		return
	finished = true
	targeting = false
	selected_card = null
	_refresh()

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var won := battle.player_won
	box.add_child(Palette.label("Victory" if won else "Defeat", 30, Palette.GOOD if won else Palette.BAD))
	var encounter := DB.encounter(encounter_index)
	if won:
		box.add_child(Palette.wrapped("%s is cleared. Your squad keeps whatever traits you stacked on it." % String(encounter.get("name", "The encounter")), 13, Palette.TEXT))
	else:
		box.add_child(Palette.wrapped("Your squad fell. Rebuild it: stack more auras, or stack the traits that answer what killed you.", 13, Palette.TEXT))
	var cont := Palette.button("Continue", true)
	cont.pressed.connect(_on_continue)
	box.add_child(cont)


func _on_continue() -> void:
	battle_finished.emit(battle.player_won, encounter_index)
