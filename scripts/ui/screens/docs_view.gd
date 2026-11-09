class_name DocsView
extends Control

## Renders the markdown in res://docs/ inside the game, plus a couple of
## project-root notes (the sync check), so design notes and the Xogot transfer
## instructions are readable from the main menu without leaving the app.

signal back_requested

const DOCS_DIR := "res://docs"
const FALLBACK_DOCS := ["architecture.md", "roadmap.md", "transfer-to-xogot.md"]
const TITLES := {
	"architecture.md": "Architecture",
	"roadmap.md": "Roadmap",
	"transfer-to-xogot.md": "Transfer to Xogot",
}

## Notes that live at the project root rather than in docs/. Listed first so the
## sync check is the first thing the Docs button shows.
const EXTRA_DOCS := [
	{"title": "Sync check", "path": "res://SYNC-CHECK.md"},
]

var entries: Array[Dictionary] = []
var current_path := ""
var tabs: HBoxContainer
var body: RichTextLabel


func _ready() -> void:
	entries = available_docs()
	_build()
	if not entries.is_empty():
		_open_doc(String(entries[0].get("path", "")))


## Every document the viewer can show, as {title, path} dictionaries: root
## notes first, then the markdown in res://docs sorted by name. Falls back to
## the known docs when the folder is missing (for example in an export that
## does not ship them).
static func available_docs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for extra in EXTRA_DOCS:
		var extra_path := String(extra.get("path", ""))
		if FileAccess.file_exists(extra_path):
			result.append({"title": String(extra.get("title", extra_path)), "path": extra_path})

	var names: Array[String] = []
	var dir := DirAccess.open(DOCS_DIR)
	if dir != null:
		for file in dir.get_files():
			if String(file).ends_with(".md"):
				names.append(String(file))
	names.sort()
	if names.is_empty():
		names = _fallback_docs()

	for name in names:
		result.append({"title": _title_for(name), "path": DOCS_DIR + "/" + name})
	return result


static func _fallback_docs() -> Array[String]:
	var out: Array[String] = []
	for name in FALLBACK_DOCS:
		out.append(String(name))
	return out


static func _title_for(doc: String) -> String:
	if TITLES.has(doc):
		return String(TITLES[doc])
	return doc.get_basename().replace("-", " ").capitalize()


# --- Structure --------------------------------------------------------------

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	header.add_child(Palette.label("Docs", 26, Palette.TEXT))
	header.add_child(Palette.label("Design notes, plans and transfer instructions.", 12, Palette.MUTED))
	header.add_child(Palette.spacer())
	var back := Palette.button("Back")
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)

	var tabs_scroll := ScrollContainer.new()
	tabs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tabs_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(tabs_scroll)

	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs_scroll.add_child(tabs)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)

	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = true
	body.selection_enabled = true
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", Palette.font(14))
	body.add_theme_color_override("default_color", Palette.TEXT)
	panel.add_child(body)


# --- Rendering --------------------------------------------------------------

func _open_doc(path: String) -> void:
	current_path = path
	_render_tabs()
	body.text = _markdown_to_bbcode(_read_doc(path))


func _render_tabs() -> void:
	Palette.clear(tabs)
	for entry in entries:
		var path := String(entry.get("path", ""))
		var button := Palette.button(String(entry.get("title", path)))
		button.tooltip_text = path
		if path == current_path:
			button.add_theme_stylebox_override("normal", Palette.button_box(Palette.ACCENT))
			button.add_theme_stylebox_override("hover", Palette.button_box(Palette.ACCENT.lightened(0.12)))
		button.pressed.connect(_open_doc.bind(path))
		tabs.add_child(button)


func _read_doc(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "Missing document: %s\n\nCreate it or restore it from git." % path
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not read %s." % path
	return file.get_as_text()


## Minimal markdown to BBCode: headings, bullets, code fences and bold.
## Brackets are escaped first so note text can never inject BBCode.
func _markdown_to_bbcode(source: String) -> String:
	var lines := PackedStringArray()
	var in_code := false
	var bold := RegEx.new()
	bold.compile("\\*\\*([^*]+)\\*\\*")

	for raw_line in source.split("\n"):
		var line := String(raw_line)
		if line.strip_edges().begins_with("```"):
			in_code = not in_code
			continue
		var escaped := line.replace("[", "[lb]")
		if in_code:
			if escaped.strip_edges() == "":
				lines.append("")
			else:
				lines.append("[color=#8b97ad]%s[/color]" % escaped)
			continue
		escaped = bold.sub(escaped, "[b]$1[/b]", true)
		if escaped.begins_with("# "):
			lines.append("[font_size=22][b]%s[/b][/font_size]" % escaped.substr(2))
		elif escaped.begins_with("## "):
			lines.append("[font_size=18][b]%s[/b][/font_size]" % escaped.substr(3))
		elif escaped.begins_with("### "):
			lines.append("[b]%s[/b]" % escaped.substr(4))
		elif escaped.begins_with("- ") or escaped.begins_with("* "):
			lines.append("  - %s" % escaped.substr(2))
		else:
			lines.append(escaped)
	return "\n".join(lines)
