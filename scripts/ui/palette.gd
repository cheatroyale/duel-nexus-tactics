class_name Palette
extends RefCounted

## Shared colours and small widget factories, so every screen looks the same.

const BG := Color("0d1017")
const PANEL := Color("171c28")
const PANEL_ALT := Color("222a3b")
const BORDER := Color("333d55")
const TEXT := Color("e8edf7")
const MUTED := Color("8b97ad")
const ACCENT := Color("7c6cff")
const ACCENT_2 := Color("ffb457")
const GOOD := Color("4ade80")
const BAD := Color("f87171")

const EMBER := Color("ff7a45")
const VERDANT := Color("5ed67a")
const HOLLOW := Color("b07cf7")
const FROST := Color("5bc0ff")
const STORM := Color("ffd166")
const STONE := Color("9aa6b2")
const SPIRIT := Color("6fe3e1")
const WILD := Color("f472b6")

## All text is drawn at size * FONT_SCALE. The design is a 960x600 canvas, so on
## a phone (which scales that down to fit) the raw sizes would be tiny; this
## keeps body text readable without touching every call site.
const FONT_SCALE := 1.35


static func font(size: int) -> int:
	return int(round(size * FONT_SCALE))


static func panel(bg: Color = PANEL, radius: int = 10, border: Color = BORDER, border_width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_width)
	box.border_color = border
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box


static func bar_box(bg: Color, radius: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.content_margin_left = 0.0
	box.content_margin_right = 0.0
	box.content_margin_top = 0.0
	box.content_margin_bottom = 0.0
	return box


static func button_box(bg: Color, radius: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.set_border_width_all(1)
	box.border_color = bg.lightened(0.12)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	return box


static func label(text: String, size: int = 14, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font(size))
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrapped(text: String, size: int = 13, color: Color = MUTED) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font(14))
	var base := ACCENT if primary else PANEL_ALT
	b.add_theme_stylebox_override("normal", button_box(base))
	b.add_theme_stylebox_override("hover", button_box(base.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", button_box(base.darkened(0.12)))
	b.add_theme_stylebox_override("disabled", button_box(base.darkened(0.5)))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_color_override("font_pressed_color", TEXT)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.35))
	return b


static func chip(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font(10))
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var base := PANEL_ALT
	var box := button_box(base, 4)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	b.add_theme_stylebox_override("normal", box)

	var hover := button_box(base.lightened(0.18), 4)
	hover.content_margin_left = 6.0
	hover.content_margin_right = 6.0
	hover.content_margin_top = 1.0
	hover.content_margin_bottom = 1.0
	b.add_theme_stylebox_override("hover", hover)

	var pressed := button_box(base.darkened(0.12), 4)
	pressed.content_margin_left = 6.0
	pressed.content_margin_right = 6.0
	pressed.content_margin_top = 1.0
	pressed.content_margin_bottom = 1.0
	b.add_theme_stylebox_override("pressed", pressed)

	b.add_theme_color_override("font_color", ACCENT)
	b.add_theme_color_override("font_hover_color", TEXT)
	return b


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func gap(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


static func element_color(element: String) -> Color:
	match element:
		"Ember":
			return EMBER
		"Verdant":
			return VERDANT
		"Hollow":
			return HOLLOW
		"Frost":
			return FROST
		"Storm":
			return STORM
		"Stone":
			return STONE
		"Spirit":
			return SPIRIT
		"Wild":
			return WILD
	return MUTED
