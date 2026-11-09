class_name TeamBuilder
extends Control

## Squad drafting: pick up to five cards, then spend trait points to stack
## traits on them. Auras are what make stacking matter: two Pack Leaders add up.

signal back_requested
signal begin_battle(squad: Array[CardInstance], encounter_index: int)

const MAX_SQUAD := 5
const TRAIT_BUDGET := 12

var squad: Array[CardInstance] = []
var selected_index := -1
var encounter_index := 0

var roster_box: VBoxContainer
var trait_box: VBoxContainer
var squad_box: HFlowContainer
var points_label: Label
var hint_label: Label
var begin_button: Button
var encounter_buttons: Array[Button] = []


func _ready() -> void:
	_build()
	_refresh()


# --- Structure --------------------------------------------------------------

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	# Header: title and back on one line, the rules hint and points below, so a
	# phone in portrait keeps both readable.
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	root.add_child(header)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	header.add_child(title_row)
	title_row.add_child(Palette.label("Squad Builder", 26, Palette.TEXT))
	title_row.add_child(Palette.spacer())
	var back := Palette.button("Back")
	back.pressed.connect(func() -> void: back_requested.emit())
	title_row.add_child(back)

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	header.add_child(info_row)
	var tagline := Palette.wrapped("Auras stack from every living ally.", 12, Palette.MUTED)
	tagline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(tagline)
	points_label = Palette.label("", 16, Palette.ACCENT_2)
	info_row.add_child(points_label)

	# Roster and codex on top, squad underneath, so a phone-sized screen keeps
	# readable columns instead of squeezing three side by side.
	var columns := VBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	root.add_child(columns)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var top_scroll := ScrollContainer.new()
	top_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	top_scroll.add_child(top_row)
	columns.add_child(top_scroll)

	var roster_col := _make_column("ROSTER", 280, false)
	top_row.add_child(roster_col)
	roster_box = VBoxContainer.new()
	roster_box.add_theme_constant_override("separation", 6)
	roster_col.add_child(_make_scroll(roster_box))

	var trait_col := _make_column("TRAIT CODEX", 320, false)
	top_row.add_child(trait_col)
	trait_box = VBoxContainer.new()
	trait_box.add_theme_constant_override("separation", 6)
	trait_col.add_child(_make_scroll(trait_box))

	var squad_col := _make_column("YOUR SQUAD", 0, true)
	columns.add_child(squad_col)
	squad_box = HFlowContainer.new()
	squad_box.add_theme_constant_override("h_separation", 8)
	squad_box.add_theme_constant_override("v_separation", 8)
	var squad_scroll := ScrollContainer.new()
	squad_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	squad_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	squad_scroll.custom_minimum_size = Vector2(0, 280)
	squad_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	squad_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	squad_scroll.add_child(squad_box)
	squad_col.add_child(squad_scroll)

	# Footer: encounter picker on one line, hint and Begin Battle below it.
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	root.add_child(footer)

	var encounter_row := HBoxContainer.new()
	encounter_row.add_theme_constant_override("separation", 8)
	footer.add_child(encounter_row)
	encounter_row.add_child(Palette.label("Encounter:", 13, Palette.MUTED))

	var encounter_scroll := ScrollContainer.new()
	encounter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	encounter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	encounter_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_row.add_child(encounter_scroll)
	var encounter_box := HBoxContainer.new()
	encounter_box.add_theme_constant_override("separation", 8)
	encounter_scroll.add_child(encounter_box)

	for i in DB.ENCOUNTERS.size():
		var button := Palette.button("")
		button.pressed.connect(_select_encounter.bind(i))
		encounter_box.add_child(button)
		encounter_buttons.append(button)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	footer.add_child(action_row)
	hint_label = Palette.label("", 12, Palette.MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(hint_label)
	begin_button = Palette.button("Begin Battle", true)
	begin_button.pressed.connect(_on_begin_pressed)
	action_row.add_child(begin_button)


func _make_column(title: String, min_width: int, expand: bool) -> VBoxContainer:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.custom_minimum_size = Vector2(min_width, 0)
	if expand:
		outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(Palette.label(title, 12, Palette.MUTED))
	return outer


func _make_scroll(content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll


# --- Refresh ----------------------------------------------------------------

func _refresh() -> void:
	_refresh_roster()
	_refresh_codex()
	_refresh_squad()
	_refresh_footer()


func _refresh_roster() -> void:
	Palette.clear(roster_box)
	for card_id in DB.CARD_ORDER:
		var definition := DB.card(String(card_id))
		if definition.is_empty():
			continue
		var in_squad := _squad_has(String(card_id))

		var row := PanelContainer.new()
		var row_bg := Palette.PANEL_ALT if in_squad else Palette.PANEL
		row.add_theme_stylebox_override("panel", Palette.panel(row_bg, 8))

		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)

		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(info)

		var element := String(definition.get("element", ""))
		var name_label := Palette.label(String(definition.get("name", card_id)), 15, Palette.element_color(element))
		name_label.clip_text = true
		info.add_child(name_label)
		var ability: Dictionary = definition.get("ability", {})
		var stats_label := Palette.label(
			"%d ATK · %d HP" % [int(definition.get("atk", 0)), int(definition.get("hp", 0))],
			11,
			Palette.MUTED
		)
		stats_label.clip_text = true
		info.add_child(stats_label)
		row.tooltip_text = "%s: %s\n%s" % [String(ability.get("name", "No ability")), DB.ability_summary(ability), element]

		var toggle := Palette.button("Remove" if in_squad else "Add")
		toggle.custom_minimum_size = Vector2(80, 0)
		toggle.disabled = not in_squad and squad.size() >= MAX_SQUAD
		toggle.pressed.connect(_toggle_card.bind(String(card_id)))
		line.add_child(toggle)

		roster_box.add_child(row)


func _refresh_codex() -> void:
	Palette.clear(trait_box)
	var selected: CardInstance = null
	if selected_index >= 0 and selected_index < squad.size():
		selected = squad[selected_index]

	for trait_id in DB.TRAIT_ORDER:
		var definition := DB.trait_def(String(trait_id))
		if definition.is_empty():
			continue
		var own := 0
		if selected != null:
			own = selected.trait_stacks(String(trait_id))

		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", Palette.panel(Palette.PANEL, 8))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)

		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 1)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(info)

		info.add_child(Palette.label(String(definition.get("name", trait_id)), 15, Palette.ACCENT))
		info.add_child(Palette.wrapped(DB.trait_summary(String(trait_id), 1), 11, Palette.MUTED))
		var own_text := ""
		if own > 0:
			own_text = "  ·  on %s: %d" % [selected.card_name(), own]
		info.add_child(Palette.label(
			"%d pt/stack · max %d%s" % [int(definition.get("cost", 1)), int(definition.get("max_stacks", 1)), own_text],
			11,
			Palette.ACCENT_2
		))

		var add := Palette.button("+1")
		add.custom_minimum_size = Vector2(54, 0)
		var over_budget := _points_used() + int(definition.get("cost", 1)) > TRAIT_BUDGET
		var at_max := own >= int(definition.get("max_stacks", 1))
		add.disabled = selected == null or at_max or over_budget
		add.pressed.connect(_add_stack.bind(String(trait_id)))
		line.add_child(add)

		trait_box.add_child(row)


func _refresh_squad() -> void:
	Palette.clear(squad_box)
	if squad.is_empty():
		squad_box.add_child(Palette.label("Pick up to %d cards from the roster." % MAX_SQUAD, 13, Palette.MUTED))
		return

	for i in squad.size():
		var card := squad[i]
		var view := CardView.new()
		view.setup(card, card.attack_total(squad), card.hp, card.max_hp, {
			"selected": i == selected_index,
			"chips_clickable": true,
		})
		view.custom_minimum_size = Vector2(200, 250)
		view.card_pressed.connect(_on_squad_card_pressed)
		view.trait_pressed.connect(_remove_stack)
		squad_box.add_child(view)


func _refresh_footer() -> void:
	points_label.text = "Trait Points: %d / %d" % [TRAIT_BUDGET - _points_used(), TRAIT_BUDGET]

	for i in encounter_buttons.size():
		var button := encounter_buttons[i]
		var encounter := DB.encounter(i)
		button.text = "%d · %s" % [i + 1, String(encounter.get("name", "?"))]
		var is_active := i == encounter_index
		var base := Palette.ACCENT if is_active else Palette.PANEL_ALT
		button.add_theme_stylebox_override("normal", Palette.button_box(base))
		button.add_theme_stylebox_override("hover", Palette.button_box(base.lightened(0.12)))

	var encounter_desc := String(DB.encounter(encounter_index).get("desc", ""))
	if squad.size() < MAX_SQUAD:
		hint_label.text = "%s  (add %d more card%s)" % [encounter_desc, MAX_SQUAD - squad.size(), "" if MAX_SQUAD - squad.size() == 1 else "s"]
	else:
		hint_label.text = encounter_desc

	begin_button.disabled = squad.is_empty()


# --- Interaction ------------------------------------------------------------

func _on_squad_card_pressed(card: CardInstance) -> void:
	selected_index = squad.find(card)
	_refresh()


func _toggle_card(card_id: String) -> void:
	if _squad_has(card_id):
		var index := -1
		for i in squad.size():
			if squad[i].id == card_id:
				index = i
				break
		if index >= 0:
			squad.remove_at(index)
			if selected_index >= squad.size():
				selected_index = squad.size() - 1
	else:
		if squad.size() >= MAX_SQUAD:
			return
		var card := CardInstance.create(card_id)
		card.max_hp = card.max_hp_total()
		card.hp = card.max_hp
		squad.append(card)
		selected_index = squad.size() - 1
	_refresh()


func _add_stack(trait_id: String) -> void:
	if selected_index < 0 or selected_index >= squad.size():
		return
	var card := squad[selected_index]
	var definition := DB.trait_def(trait_id)
	if definition.is_empty():
		return
	if card.trait_stacks(trait_id) >= int(definition.get("max_stacks", 1)):
		return
	if _points_used() + int(definition.get("cost", 1)) > TRAIT_BUDGET:
		return
	card.add_trait(trait_id)
	card.max_hp = card.max_hp_total()
	card.hp = card.max_hp
	_refresh()


func _remove_stack(card: CardInstance, trait_id: String) -> void:
	card.remove_trait(trait_id)
	card.max_hp = card.max_hp_total()
	card.hp = card.max_hp
	_refresh()


func _select_encounter(index: int) -> void:
	encounter_index = clampi(index, 0, DB.ENCOUNTERS.size() - 1)
	_refresh_footer()


func _on_begin_pressed() -> void:
	if squad.is_empty():
		return
	var team: Array[CardInstance] = []
	for card in squad:
		var copy := CardInstance.create(card.id)
		copy.traits = CardInstance.traits_from(card.traits)
		copy.max_hp = copy.max_hp_total()
		copy.hp = copy.max_hp
		team.append(copy)
	begin_battle.emit(team, encounter_index)


# --- Helpers ----------------------------------------------------------------

func _squad_has(card_id: String) -> bool:
	for card in squad:
		if card.id == card_id:
			return true
	return false


func _points_used() -> int:
	var total := 0
	for card in squad:
		for trait_id in card.traits:
			total += int(card.traits[trait_id]) * int(DB.trait_def(String(trait_id)).get("cost", 1))
	return total
