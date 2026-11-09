extends Control

## Screen router: main menu -> squad builder -> battle -> back to the menu.

var current_screen: Control = null


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Palette.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	show_menu()


func show_menu() -> void:
	_swap(_build_menu())


func _swap(screen: Control) -> void:
	if is_instance_valid(current_screen):
		current_screen.queue_free()
	current_screen = screen
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_menu() -> Control:
	var root := Control.new()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	root.add_child(margin)

	# Scrolls instead of clipping on short screens (phones in landscape).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(660, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	box.add_child(Palette.label(game_title(), 44, Palette.ACCENT))

	var build := build_label()
	if build != "":
		box.add_child(Palette.label(build, 12, Palette.MUTED))

	box.add_child(Palette.wrapped(
		"A team-building card battler. Draft five cards, stack traits on them until they multiply each other, then fight through three encounters.",
		15,
		Palette.TEXT
	))

	var rules := PanelContainer.new()
	box.add_child(rules)
	var rules_box := VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", 4)
	rules.add_child(rules_box)
	rules_box.add_child(Palette.label("HOW STACKING WORKS", 12, Palette.ACCENT_2))
	rules_box.add_child(Palette.wrapped("You have 12 trait points for the whole squad. A trait costs its price per stack, so three stacks of Frenzy cost three points.", 13, Palette.TEXT))
	rules_box.add_child(Palette.wrapped("Self traits (Frenzy, Vitality, Bulwark, Thornmail, ...) only buff the card carrying them.", 13, Palette.TEXT))
	rules_box.add_child(Palette.wrapped("Aura traits (Pack Leader, Aegis) buff every living ally, and identical auras add up: two Pack Leaders give the whole squad +2 ATK. Auras switch off when their carrier dies.", 13, Palette.TEXT))
	rules_box.add_child(Palette.wrapped("In battle each card acts once per round. Attacking costs 1 energy, abilities cost their printed price, and every round grants both sides 2 energy.", 13, Palette.TEXT))

	box.add_child(Palette.gap(4))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var start := Palette.button("Build a Squad", true)
	start.custom_minimum_size = Vector2(0, 44)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_open_builder)
	actions.add_child(start)

	var docs_button := Palette.button("Docs")
	docs_button.custom_minimum_size = Vector2(0, 44)
	docs_button.tooltip_text = "Sync check, design notes, roadmap and how to move the project into Xogot."
	docs_button.pressed.connect(_open_docs)
	actions.add_child(docs_button)

	box.add_child(Palette.label(
		"Encounters cleared: %d / %d" % [GameState.cleared, DB.ENCOUNTERS.size()],
		13,
		Palette.MUTED
	))
	return root


func game_title() -> String:
	return String(ProjectSettings.get_setting("application/config/name", "Duel Nexus Tactics"))


## Reads res://VERSION so a copy can be told apart from an older download.
func build_label() -> String:
	var path := "res://VERSION"
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return "build %s" % file.get_as_text().strip_edges()


func _open_builder() -> void:
	var builder := TeamBuilder.new()
	builder.back_requested.connect(show_menu)
	builder.begin_battle.connect(_start_battle)
	_swap(builder)


func _open_docs() -> void:
	var view := DocsView.new()
	view.back_requested.connect(show_menu)
	_swap(view)


func _start_battle(squad: Array[CardInstance], encounter_index: int) -> void:
	var view := BattleView.new()
	view.start(squad, encounter_index)
	view.quit_requested.connect(show_menu)
	view.battle_finished.connect(_on_battle_finished)
	_swap(view)


func _on_battle_finished(won: bool, encounter_index: int) -> void:
	if won and encounter_index + 1 > GameState.cleared:
		GameState.cleared = encounter_index + 1
		GameState.save()
	show_menu()
