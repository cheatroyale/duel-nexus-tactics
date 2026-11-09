class_name CardView
extends PanelContainer

## A single card: name, ATK, HP bar, ability and trait chips.
##
## Used both in the squad builder (chips clickable, to peel a stack off) and in
## battle (chips read-only, card clickable to select or to target).

signal card_pressed(card: CardInstance)
signal trait_pressed(card: CardInstance, trait_id: String)

const DEAD_BG := Color("141821")

var card: CardInstance


func setup(c: CardInstance, atk: int, hp: int, max_hp: int, opts: Dictionary = {}) -> void:
	card = c
	var selected: bool = bool(opts.get("selected", false))
	var targetable: bool = bool(opts.get("targetable", false))
	var chips_clickable: bool = bool(opts.get("chips_clickable", false))
	var spent: bool = bool(opts.get("spent", false))
	var dead: bool = not c.alive

	custom_minimum_size = Vector2(150, 186)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var border := Palette.element_color(c.element())
	if selected:
		border = Palette.ACCENT
	if targetable:
		border = Palette.BAD
	if dead:
		border = Palette.BORDER

	var bg := DEAD_BG if dead else Palette.PANEL
	var border_width := 2 if (selected or targetable) else 1
	add_theme_stylebox_override("panel", Palette.panel(bg, 10, border, border_width))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)

	var name_color := Palette.MUTED if dead else Palette.element_color(c.element())
	var name_label := Palette.label(c.card_name(), 15, name_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	head.add_child(name_label)
	head.add_child(Palette.label("ATK %d" % atk, 12, Palette.MUTED if dead else Palette.ACCENT_2))

	var bar := ProgressBar.new()
	bar.max_value = maxi(1, max_hp)
	bar.value = hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", Palette.bar_box(Palette.BG, 4))
	bar.add_theme_stylebox_override("fill", Palette.bar_box(_hp_color(hp, max_hp), 4))
	col.add_child(bar)

	col.add_child(Palette.label("HP %d / %d" % [hp, max_hp], 11, Palette.MUTED))

	var ability := c.ability()
	var ability_text := "-"
	if not ability.is_empty():
		ability_text = "%s (%d)" % [String(ability.get("name", "Ability")), int(ability.get("cost", 0))]
	col.add_child(Palette.label("%s · %s" % [c.element(), ability_text], 10, Palette.MUTED))

	var chips := VBoxContainer.new()
	chips.add_theme_constant_override("separation", 2)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(chips)

	var trait_ids := c.trait_list()
	var tooltip_traits := ""
	if trait_ids.is_empty():
		chips.add_child(Palette.label("no traits", 10, Palette.MUTED.darkened(0.3)))
	else:
		for trait_id in trait_ids:
			var stacks := c.trait_stacks(trait_id)
			var definition := DB.trait(trait_id)
			var chip_text := "%s x%d" % [String(definition.get("name", trait_id)), stacks]
			tooltip_traits += "\n%s x%d: %s" % [String(definition.get("name", trait_id)), stacks, DB.trait_summary(trait_id, stacks)]
			if chips_clickable:
				var chip_button := Palette.chip(chip_text)
				chip_button.tooltip_text = "%s\nClick to remove a stack." % DB.trait_summary(trait_id, stacks)
				chip_button.pressed.connect(_on_chip_pressed.bind(trait_id))
				chips.add_child(chip_button)
			else:
				chips.add_child(Palette.label(chip_text, 10, Palette.ACCENT))

	var rest := Control.new()
	rest.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rest)

	if dead:
		col.add_child(Palette.label("FALLEN", 12, Palette.BAD))
	elif spent:
		col.add_child(Palette.label("acted", 11, Palette.MUTED))

	tooltip_text = "%s · %d ATK / %d HP\nAbility: %s (%d energy) — %s%s" % [
		c.card_name(),
		atk,
		max_hp,
		String(ability.get("name", "none")),
		int(ability.get("cost", 0)),
		DB.ability_summary(ability),
		tooltip_traits,
	]


func _hp_color(hp: int, max_hp: int) -> Color:
	var ratio := float(hp) / float(maxi(1, max_hp))
	if ratio > 0.6:
		return Palette.GOOD
	if ratio > 0.3:
		return Palette.ACCENT_2
	return Palette.BAD


func _on_chip_pressed(trait_id: String) -> void:
	trait_pressed.emit(card, trait_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit(card)
			accept_event()
