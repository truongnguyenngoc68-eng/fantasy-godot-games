extends RefCounted
class_name BastionUI

# ============================================================================
# BASTION FORGE 2.0 — CLASH OF CLANS / CLASH ROYALE TACTILE UI & VECTOR ICONS
# Implements the exact visual audit specifications from clash-visual-audit.md:
# - Bevelled Golden / Green / Blue / Stone-Beige / Red-Close tactile buttons
# - Stone-grey headers (#81786D -> #5C554F) & Earth-brown panels (#664632)
# - Thick dark-outlined cream display text (#FFF9E8 with #241C17 outline + shadow)
# - Custom shaded vector game icons (Zero emoji dependency)
# ============================================================================

const COL_CREAM_TEXT := Color(1.0, 0.976, 0.91)      # #FFF9E8
const COL_GOLD_TEXT := Color(1.0, 0.878, 0.45)       # #FFE073
const COL_OUTLINE_DARK := Color(0.14, 0.11, 0.09)    # #241C17
const COL_BORDER_DARK := Color(0.19, 0.15, 0.12)     # #30261E

class VectorIcon extends Control:
	var icon_type: String = "sword"
	var badge_text: String = ""
	var badge_color: Color = Color(0.91, 0.27, 0.32)

	func _init(p_type: String = "sword", p_size: Vector2 = Vector2(42, 42), p_badge: String = "") -> void:
		icon_type = p_type
		custom_minimum_size = p_size
		size = p_size
		badge_text = p_badge
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var s: float = minf(size.x, size.y) / 48.0
		var stroke := Color(0.20, 0.14, 0.10)

		match icon_type:
			"sword":
				# Diagonal broadsword with gold crossguard & silver bevel blade
				var p_tip := c + Vector2(15.0 * s, -15.0 * s)
				var p_base := c + Vector2(-6.0 * s, 6.0 * s)
				draw_line(p_base, p_tip, stroke, 11.0 * s)
				draw_line(p_base, p_tip, Color(0.91, 0.96, 0.99), 7.0 * s)
				draw_line(p_base + Vector2(1.5 * s, 1.5 * s), p_tip, Color(0.60, 0.73, 0.82), 3.2 * s)
				# Gold Crossguard
				var g0 := c + Vector2(-13.0 * s, -1.0 * s)
				var g1 := c + Vector2(1.0 * s, 13.0 * s)
				draw_line(g0, g1, stroke, 7.5 * s)
				draw_line(g0, g1, Color(0.98, 0.76, 0.20), 4.6 * s)
				# Grip & Pommel
				var pom := c + Vector2(-15.0 * s, 15.0 * s)
				draw_line(p_base, pom, stroke, 7.0 * s)
				draw_line(p_base, pom, Color(0.62, 0.38, 0.19), 4.2 * s)
				draw_circle(pom, 4.0 * s, stroke)
				draw_circle(pom, 2.8 * s, Color(0.98, 0.78, 0.22))

			"cleaver":
				# Heavy Crimson/Gold Lunge Greatsword
				var p_tip := c + Vector2(16.0 * s, -14.0 * s)
				var p_base := c + Vector2(-7.0 * s, 7.0 * s)
				draw_line(p_base, p_tip, stroke, 14.0 * s)
				draw_line(p_base, p_tip, Color(1.0, 0.56, 0.18), 9.5 * s)
				draw_line(p_base, p_tip, Color(1.0, 0.90, 0.42), 4.0 * s)
				var g0 := c + Vector2(-14.0 * s, 0.0)
				var g1 := c + Vector2(0.0, 14.0 * s)
				draw_line(g0, g1, stroke, 8.0 * s)
				draw_line(g0, g1, Color(0.96, 0.76, 0.22), 5.0 * s)

			"hammer":
				# Builder / Upgrade Hammer (Wood handle + bevelled steel head)
				var h0 := c + Vector2(-13.0 * s, 15.0 * s)
				var h1 := c + Vector2(7.0 * s, -7.0 * s)
				draw_line(h0, h1, stroke, 8.5 * s)
				draw_line(h0, h1, Color(0.72, 0.48, 0.24), 5.2 * s)
				var head_poly := PackedVector2Array([
					c + Vector2(-6.0 * s, -12.0 * s),
					c + Vector2(6.0 * s, -19.0 * s),
					c + Vector2(18.0 * s, -6.0 * s),
					c + Vector2(6.0 * s, 2.0 * s)
				])
				draw_colored_polygon(head_poly, Color(0.84, 0.90, 0.95))
				draw_polyline(head_poly, stroke, 2.8 * s)

			"shield":
				# Gold-rimmed Royal Blue Heater Shield
				var sh_out := PackedVector2Array([
					c + Vector2(-15.0 * s, -15.0 * s),
					c + Vector2(0.0, -18.0 * s),
					c + Vector2(15.0 * s, -15.0 * s),
					c + Vector2(13.0 * s, 5.0 * s),
					c + Vector2(0.0, 18.0 * s),
					c + Vector2(-13.0 * s, 5.0 * s)
				])
				draw_colored_polygon(sh_out, stroke)
				var sh_gold := PackedVector2Array([
					c + Vector2(-13.0 * s, -13.0 * s),
					c + Vector2(0.0, -16.0 * s),
					c + Vector2(13.0 * s, -13.0 * s),
					c + Vector2(11.0 * s, 4.0 * s),
					c + Vector2(0.0, 15.5 * s),
					c + Vector2(-11.0 * s, 4.0 * s)
				])
				draw_colored_polygon(sh_gold, Color(0.97, 0.80, 0.34))
				var sh_blue := PackedVector2Array([
					c + Vector2(-9.5 * s, -9.5 * s),
					c + Vector2(0.0, -12.0 * s),
					c + Vector2(9.5 * s, -9.5 * s),
					c + Vector2(8.0 * s, 3.0 * s),
					c + Vector2(0.0, 11.5 * s),
					c + Vector2(-8.0 * s, 3.0 * s)
				])
				draw_colored_polygon(sh_blue, Color(0.22, 0.56, 0.90))
				draw_circle(c + Vector2(0.0, -1.0 * s), 4.2 * s, Color(0.98, 0.84, 0.36))

			"coin":
				draw_circle(c, 16.5 * s, stroke)
				draw_circle(c, 14.2 * s, Color(1.0, 0.76, 0.14))
				draw_circle(c + Vector2(-1.0 * s, -1.5 * s), 11.0 * s, Color(1.0, 0.89, 0.34))
				draw_rect(Rect2(c - Vector2(2.2 * s, 6.0 * s), Vector2(4.4 * s, 12.0 * s)), Color(0.88, 0.58, 0.08), true)

			"gem":
				var g_out := PackedVector2Array([
					c + Vector2(0.0, -17.0 * s),
					c + Vector2(13.0 * s, -8.0 * s),
					c + Vector2(15.0 * s, 8.0 * s),
					c + Vector2(0.0, 17.0 * s),
					c + Vector2(-15.0 * s, 8.0 * s),
					c + Vector2(-13.0 * s, -8.0 * s)
				])
				draw_colored_polygon(g_out, stroke)
				var g_in := PackedVector2Array([
					c + Vector2(0.0, -14.5 * s),
					c + Vector2(11.0 * s, -6.5 * s),
					c + Vector2(12.5 * s, 6.5 * s),
					c + Vector2(0.0, 14.5 * s),
					c + Vector2(-12.5 * s, 6.5 * s),
					c + Vector2(-11.0 * s, -6.5 * s)
				])
				draw_colored_polygon(g_in, Color(0.56, 0.86, 0.20))
				draw_circle(c + Vector2(-2.5 * s, -3.5 * s), 5.5 * s, Color(0.80, 1.0, 0.46))

			"chest":
				var r_box := Rect2(c - Vector2(16.0 * s, 8.0 * s), Vector2(32.0 * s, 23.0 * s))
				draw_rect(r_box.grow(2.2 * s), stroke, true)
				draw_rect(r_box, Color(0.64, 0.40, 0.22), true)
				draw_rect(Rect2(r_box.position, Vector2(r_box.size.x, 9.0 * s)), Color(0.82, 0.56, 0.30), true)
				# Gold bands & lock
				draw_rect(Rect2(c.x - 16.0 * s, c.y - 1.0 * s, 32.0 * s, 4.0 * s), Color(0.97, 0.78, 0.28), true)
				draw_rect(Rect2(c.x - 4.0 * s, c.y - 3.5 * s, 8.0 * s, 9.0 * s), Color(1.0, 0.90, 0.48), true)

			"calendar":
				var r_cal := Rect2(c - Vector2(14.0 * s, 14.0 * s), Vector2(28.0 * s, 28.0 * s))
				draw_rect(r_cal.grow(2.2 * s), stroke, true)
				draw_rect(r_cal, Color(1.0, 0.95, 0.84), true)
				draw_rect(Rect2(r_cal.position, Vector2(r_cal.size.x, 8.5 * s)), Color(0.86, 0.34, 0.28), true)
				# Red exclamation mark inside calendar
				draw_rect(Rect2(c.x - 2.2 * s, c.y - 2.5 * s, 4.4 * s, 8.5 * s), Color(0.88, 0.22, 0.26), true)
				draw_circle(c + Vector2(0.0, 9.5 * s), 2.4 * s, Color(0.88, 0.22, 0.26))

			"helm":
				draw_circle(c + Vector2(0.0, 2.0 * s), 13.5 * s, stroke)
				draw_circle(c + Vector2(0.0, 2.0 * s), 11.2 * s, Color(0.82, 0.88, 0.95))
				draw_arc(c + Vector2(0.0, -8.0 * s), 9.0 * s, -PI * 0.9, -PI * 0.1, 10, Color(0.18, 0.48, 0.92), 5.0 * s)
				draw_line(c + Vector2(-10.0 * s, 2.0 * s), c + Vector2(10.0 * s, 2.0 * s), Color(0.97, 0.78, 0.24), 3.5 * s)

			"armor":
				var a_poly := PackedVector2Array([
					c + Vector2(-13.0 * s, -12.0 * s),
					c + Vector2(13.0 * s, -12.0 * s),
					c + Vector2(10.0 * s, 14.0 * s),
					c + Vector2(-10.0 * s, 14.0 * s)
				])
				draw_colored_polygon(a_poly, Color(0.20, 0.48, 0.88))
				draw_polyline(a_poly, Color(0.97, 0.78, 0.24), 3.0 * s)
				draw_circle(c, 4.5 * s, Color(0.98, 0.84, 0.32))

			"pauldron":
				draw_circle(c, 13.0 * s, stroke)
				draw_circle(c, 10.8 * s, Color(0.85, 0.90, 0.96))
				draw_arc(c, 9.5 * s, -PI * 0.8, PI * 0.2, 10, Color(0.98, 0.78, 0.24), 3.5 * s)

			"cape":
				var c_poly := PackedVector2Array([
					c + Vector2(-8.0 * s, -14.0 * s),
					c + Vector2(8.0 * s, -14.0 * s),
					c + Vector2(15.0 * s, 14.0 * s),
					c + Vector2(-15.0 * s, 14.0 * s)
				])
				draw_colored_polygon(c_poly, Color(0.16, 0.44, 0.88))
				draw_polyline(c_poly, Color(0.98, 0.78, 0.24), 2.8 * s)

			"dragon":
				# Stylized Azure Dragon head + golden horn icon
				draw_circle(c + Vector2(0.0, 2.0 * s), 13.5 * s, stroke)
				draw_circle(c + Vector2(0.0, 2.0 * s), 11.2 * s, Color(0.14, 0.52, 0.92))
				draw_line(c + Vector2(-4.0 * s, -6.0 * s), c + Vector2(-12.0 * s, -16.0 * s), Color(0.98, 0.80, 0.24), 4.2 * s)
				draw_line(c + Vector2(4.0 * s, -6.0 * s), c + Vector2(12.0 * s, -16.0 * s), Color(0.98, 0.80, 0.24), 4.2 * s)
				draw_circle(c + Vector2(4.0 * s, 0.0), 2.8 * s, Color.WHITE)

			"trophy":
				var t_poly := PackedVector2Array([
					c + Vector2(-11.0 * s, -12.0 * s),
					c + Vector2(11.0 * s, -12.0 * s),
					c + Vector2(7.0 * s, 4.0 * s),
					c + Vector2(-7.0 * s, 4.0 * s)
				])
				draw_colored_polygon(t_poly, Color(0.98, 0.78, 0.20))
				draw_rect(Rect2(c.x - 8.0 * s, c.y + 5.0 * s, 16.0 * s, 6.0 * s), Color(0.75, 0.55, 0.18), true)

			_:
				draw_circle(c, 12.0 * s, stroke)
				draw_circle(c, 9.5 * s, Color(0.95, 0.78, 0.25))

		if badge_text != "":
			var b_rect := Rect2(size.x - 24.0, -2.0, 24.0, 18.0)
			draw_rect(b_rect, Color.WHITE, true)
			draw_rect(b_rect.grow(-1.5), badge_color, true)
			draw_string(ThemeDB.fallback_font, b_rect.position + Vector2(4.0, 13.5), badge_text, HORIZONTAL_ALIGNMENT_CENTER, 16.0, 11, Color.WHITE)

static func style_display_label(
	lbl: Label,
	font_size: int = 18,
	font_col: Color = COL_CREAM_TEXT,
	outline_px: int = 5
) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_col)
	lbl.add_theme_color_override("font_outline_color", COL_OUTLINE_DARK)
	lbl.add_theme_constant_override("outline_size", outline_px)
	lbl.add_theme_color_override("font_shadow_color", Color(0.10, 0.07, 0.05, 0.92))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 2)

static func make_stylebox(
	bg_col: Color,
	border_col: Color = COL_BORDER_DARK,
	bottom_lip_col: Color = Color(0.18, 0.13, 0.09),
	radius: int = 10,
	border_w: int = 2,
	bottom_lip_px: int = 5,
	pad_x: int = 10,
	pad_y: int = 6
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.border_width_left = border_w
	sb.border_width_right = border_w
	sb.border_width_top = border_w
	sb.border_width_bottom = border_w + bottom_lip_px
	sb.set_corner_radius_all(radius)
	sb.shadow_color = bottom_lip_col
	sb.shadow_size = 0
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y + int(bottom_lip_px * 0.5)
	return sb

static func apply_clash_button_style(
	btn: Button,
	preset: String = "stone",
	font_size: int = 16
) -> void:
	var bg_col := Color(0.82, 0.77, 0.64)     # Stone/beige default (#D1C4A3)
	var border_col := COL_BORDER_DARK
	var lip_col := Color(0.35, 0.28, 0.21)
	var radius: int = 10
	var lip_px: int = 4

	match preset:
		"gold":
			bg_col = Color(1.0, 0.78, 0.14)   # #FFC724 Clash Gold CTA
			lip_col = Color(0.68, 0.42, 0.04)
			radius = 12
			lip_px = 6
		"green":
			bg_col = Color(0.54, 0.84, 0.22)  # #8AD638 Clash Green Confirm
			lip_col = Color(0.26, 0.48, 0.08)
			radius = 10
			lip_px = 5
		"blue":
			bg_col = Color(0.26, 0.62, 0.90)  # #429EE6 Clash Blue Secondary
			lip_col = Color(0.12, 0.34, 0.56)
			radius = 10
			lip_px = 5
		"red_close":
			bg_col = Color(0.92, 0.22, 0.28)  # #EB3847 Clash Red X
			lip_col = Color(0.52, 0.08, 0.12)
			radius = 9
			lip_px = 4
		"row_tan":
			bg_col = Color(0.64, 0.49, 0.36)  # #A37D5C Build list row
			border_col = Color(0.31, 0.21, 0.15)
			lip_col = Color(0.26, 0.18, 0.12)
			radius = 9
			lip_px = 3
		"wood_tab":
			bg_col = Color(0.72, 0.54, 0.36)
			border_col = Color(0.28, 0.19, 0.13)
			lip_col = Color(0.24, 0.16, 0.10)
			radius = 12
			lip_px = 3
		"stone_tab":
			bg_col = Color(0.52, 0.46, 0.40)
			border_col = Color(0.22, 0.16, 0.12)
			lip_col = Color(0.18, 0.13, 0.10)
			radius = 8
			lip_px = 3

	var sb_norm: StyleBoxFlat = make_stylebox(bg_col, border_col, lip_col, radius, 2, lip_px, 10, 6)
	var sb_hover: StyleBoxFlat = make_stylebox(bg_col.lightened(0.12), border_col, lip_col, radius, 2, lip_px, 10, 6)
	var sb_press: StyleBoxFlat = make_stylebox(bg_col.darkened(0.08), border_col, lip_col, radius, 2, 1, 10, 8)
	var sb_focus: StyleBoxFlat = make_stylebox(bg_col, Color.WHITE, lip_col, radius, 3, lip_px, 10, 6)

	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("focus", sb_focus)

	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COL_CREAM_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", COL_GOLD_TEXT)
	btn.add_theme_color_override("font_outline_color", COL_OUTLINE_DARK)
	btn.add_theme_constant_override("outline_size", 5)
