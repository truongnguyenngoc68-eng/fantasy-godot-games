extends RefCounted
class_name StickmanRig2D

# ============================================================================
# BASTION FORGE 2.0 — 3D-PAINTED MODULAR SKELETAL CHARACTER & EQUIPMENT RIG
# - Uses the 3D-painted modular parts from `modular-warrior-concept.png`
#   packed with all 20 equipment variants into a single shared `_modular_atlas_tex`.
# - Preserves 100% of the 12-Bone Forward Kinematics (FK) solver & 6 sockets.
# - Renders every unit's individual 6-socket `loadout` in both 1v1 and 300-unit
#   crowds from the same texture atlas (zero clone-stamp `default_loadout` rows).
# ============================================================================

const BONE_HIP: int = 0
const BONE_LOWER_SPINE: int = 1
const BONE_UPPER_CHEST: int = 2
const BONE_HEAD: int = 3
const BONE_UPPER_ARM_L: int = 4
const BONE_FOREARM_L: int = 5
const BONE_UPPER_ARM_R: int = 6
const BONE_FOREARM_R: int = 7
const BONE_THIGH_L: int = 8
const BONE_SHIN_L: int = 9
const BONE_THIGH_R: int = 10
const BONE_SHIN_R: int = 11

const BONE_COUNT: int = 12
const BONE_NAMES: Array[String] = [
	"1.Hip", "2.LowerSpine", "3.UpperChest", "4.Head",
	"5.UpperArm_L", "6.Forearm_L", "7.UpperArm_R", "8.Forearm_R",
	"9.Thigh_L", "10.Shin_L", "11.Thigh_R", "12.Shin_R"
]
const OUTLINE_DARK := Color(0.14, 0.10, 0.08, 1.0)

var bone_start: PackedVector2Array = PackedVector2Array()
var bone_end: PackedVector2Array = PackedVector2Array()
var bone_angle: PackedFloat32Array = PackedFloat32Array()

# Shared static Modular Atlas Texture & Region Dictionary across all Rig instances
static var _atlas_ready: bool = false
static var _modular_atlas_tex: ImageTexture = null
static var _part_rects: Dictionary = {}

func _init() -> void:
	bone_start.resize(BONE_COUNT)
	bone_end.resize(BONE_COUNT)
	bone_angle.resize(BONE_COUNT)
	ensure_atlas_ready()

static func cleanup_static_resources() -> void:
	_modular_atlas_tex = null
	_atlas_ready = false

# ============================================================================
# UNIFIED 3D-PAINTED MODULAR ATLAS BUILDER (BODY PARTS + ALL 20 EQUIPMENT ITEMS)
# ============================================================================

static func ensure_atlas_ready() -> void:
	if _atlas_ready and _modular_atlas_tex != null:
		return
	_atlas_ready = true

	var src_tex: Texture2D = load("res://assets/bastion_forge/modular-warrior-concept.png") as Texture2D
	if src_tex == null:
		return
	var raw_img: Image = src_tex.get_image()
	if raw_img == null:
		return
	if raw_img.is_compressed():
		raw_img.decompress()
	raw_img.convert(Image.FORMAT_RGBA8)

	# Work at 768x512 (half of 1536x1024) for fast startup & crisp mip-free sampling
	var w: int = 768
	var h: int = 512
	raw_img.resize(w, h, Image.INTERPOLATE_BILINEAR)

	# Create 1024x1024 RGBA8 Unified Modular Atlas
	# Top 768x512 holds the 12 base 3D-painted cells from modular-warrior-concept.png
	# Bottom 1024x512 holds the 3D-shaded material/silhouette variants for all 20 items
	var atlas_img := Image.create(1024, 1280, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0, 0, 0, 0))

	# Exact cell bounding boxes in 768x512 space (4 cols x 3 rows)
	var base_cells: Dictionary = {
		"torso_knight": Rect2i(10, 6, 180, 162),
		"head_knight": Rect2i(200, 4, 178, 162),
		"torso_orc": Rect2i(388, 10, 184, 156),
		"head_orc": Rect2i(586, 6, 174, 160),

		"uarm_knight": Rect2i(28, 170, 134, 138),
		"farm_knight": Rect2i(228, 166, 118, 144),
		"thigh_knight": Rect2i(414, 166, 126, 142),
		"boot_knight": Rect2i(604, 176, 154, 132),

		"wpn_aethel_blade": Rect2i(42, 318, 118, 186),
		"off_solar_aegis": Rect2i(210, 318, 162, 184),
		"cpe_azure_scarf": Rect2i(386, 318, 188, 180),
		"cpe_orc_tattered": Rect2i(582, 318, 182, 180)
	}

	for key in base_cells.keys():
		var r: Rect2i = base_cells[key]
		var sub: Image = raw_img.get_region(r)
		_strip_white_background_flood(sub)
		atlas_img.blit_rect(sub, Rect2i(0, 0, r.size.x, r.size.y), r.position)
		_part_rects[key] = Rect2(r.position, r.size)

	# --- Generate 3D-Painted Equipment & Faction Limb Variants in Bottom Half (y >= 520) ---
	# 1. wpn_crimson_greatsword / wpn_sunfire_greatsword (Đại Đao Hỏa Long - Blazing Magma-Gold & Crimson Greatsword)
	var sword_base: Image = atlas_img.get_region(base_cells["wpn_aethel_blade"])
	var sunfire_img: Image = sword_base.duplicate()
	_recolor_3d_part(sunfire_img, "SUNFIRE_SWORD")
	var r_sunfire := Rect2i(16, 524, sunfire_img.get_width(), sunfire_img.get_height())
	atlas_img.blit_rect(sunfire_img, Rect2i(0, 0, r_sunfire.size.x, r_sunfire.size.y), r_sunfire.position)
	_part_rects["wpn_sunfire_greatsword"] = Rect2(r_sunfire.position, r_sunfire.size)
	_part_rects["wpn_crimson_greatsword"] = Rect2(r_sunfire.position, r_sunfire.size)

	# 2. wpn_obsidian_reaver / wpn_frostbite_reaver (Trường Kiếm Băng Tinh - Crystalline Cyan-Sapphire Runeblade)
	var frost_img: Image = sword_base.duplicate()
	_recolor_3d_part(frost_img, "FROSTBITE_SWORD")
	var r_frost := Rect2i(148, 524, frost_img.get_width(), frost_img.get_height())
	atlas_img.blit_rect(frost_img, Rect2i(0, 0, r_frost.size.x, r_frost.size.y), r_frost.position)
	_part_rects["wpn_frostbite_reaver"] = Rect2(r_frost.position, r_frost.size)
	_part_rects["wpn_obsidian_reaver"] = Rect2(r_frost.position, r_frost.size)

	# 3. wpn_thunder_halberd (Chiến Kích Lôi Đình - True 3D Poleaxe/Halberd with Long Shaft, Spear Tip, Crescent Axe & Back Spike)
	var halberd_img := Image.create(124, 186, false, Image.FORMAT_RGBA8)
	_paint_3d_thunder_halberd(halberd_img)
	var r_halberd := Rect2i(276, 524, halberd_img.get_width(), halberd_img.get_height())
	atlas_img.blit_rect(halberd_img, Rect2i(0, 0, r_halberd.size.x, r_halberd.size.y), r_halberd.position)
	_part_rects["wpn_thunder_halberd"] = Rect2(r_halberd.position, r_halberd.size)

	# 4. off_aegis_buckler / off_iron_buckler (Khiên Tinh Thạch - Steel & Azure Vanguard Shield)
	_part_rects["off_royal_tower"] = _part_rects["off_solar_aegis"]
	_part_rects["off_bastion_tower"] = _part_rects["off_solar_aegis"]
	var shield_base: Image = atlas_img.get_region(base_cells["off_solar_aegis"])
	var buckler_img: Image = shield_base.duplicate()
	_recolor_3d_part(buckler_img, "IRON_BUCKLER")
	var r_buckler := Rect2i(408, 524, buckler_img.get_width(), buckler_img.get_height())
	atlas_img.blit_rect(buckler_img, Rect2i(0, 0, r_buckler.size.x, r_buckler.size.y), r_buckler.position)
	_part_rects["off_iron_buckler"] = Rect2(r_buckler.position, r_buckler.size)
	_part_rects["off_aegis_buckler"] = Rect2(r_buckler.position, r_buckler.size)

	# 5. off_parry_dagger / off_twin_dagger (Song Đao Phản Đòn - Crossed Twin Amethyst-Silver Daggers)
	var single_dagger: Image = sword_base.duplicate()
	_recolor_3d_part(single_dagger, "TWIN_DAGGER")
	var twin_dagger_img := Image.create(136, 186, false, Image.FORMAT_RGBA8)
	_build_crossed_twin_daggers(twin_dagger_img, single_dagger)
	var r_dagger := Rect2i(576, 524, twin_dagger_img.get_width(), twin_dagger_img.get_height())
	atlas_img.blit_rect(twin_dagger_img, Rect2i(0, 0, r_dagger.size.x, r_dagger.size.y), r_dagger.position)
	_part_rects["off_twin_dagger"] = Rect2(r_dagger.position, r_dagger.size)
	_part_rects["off_parry_dagger"] = Rect2(r_dagger.position, r_dagger.size)

	# 6. cpe_royal_mantle / cpe_royal_crimson (Áo Choàng Đại Tướng - Velvet Crimson & Gold Grand Marshal Cape)
	_part_rects["cpe_wind_scarf"] = _part_rects["cpe_azure_scarf"]
	var cape_base: Image = atlas_img.get_region(base_cells["cpe_azure_scarf"])
	var crimson_cape: Image = cape_base.duplicate()
	_recolor_3d_part(crimson_cape, "CRIMSON_CAPE")
	var r_crim_cape := Rect2i(718, 524, crimson_cape.get_width(), crimson_cape.get_height())
	atlas_img.blit_rect(crimson_cape, Rect2i(0, 0, r_crim_cape.size.x, r_crim_cape.size.y), r_crim_cape.position)
	_part_rects["cpe_royal_crimson"] = Rect2(r_crim_cape.position, r_crim_cape.size)
	_part_rects["cpe_royal_mantle"] = Rect2(r_crim_cape.position, r_crim_cape.size)

	# 7. cpe_aether_halo (Hào Quang Thiên Sứ - Radiant 3D Golden Celestial Halo)
	var halo_img := Image.create(140, 140, false, Image.FORMAT_RGBA8)
	_paint_3d_golden_halo(halo_img)
	var r_halo := Rect2i(768, 20, 140, 140)
	atlas_img.blit_rect(halo_img, Rect2i(0, 0, 140, 140), r_halo.position)
	_part_rects["cpe_aether_halo"] = Rect2(r_halo.position, r_halo.size)

	# 8. Head/Helmet Variants: hlm_vanguard_visor, hlm_spartan_crest, hlm_abyss_horns, hlm_none
	_part_rects["hlm_vanguard_visor"] = _part_rects["head_knight"]
	var head_k_base: Image = atlas_img.get_region(base_cells["head_knight"])

	var head_spartan: Image = head_k_base.duplicate()
	_recolor_3d_part(head_spartan, "SPARTAN_CREST")
	var r_spartan := Rect2i(16, 730, head_spartan.get_width(), head_spartan.get_height())
	atlas_img.blit_rect(head_spartan, Rect2i(0, 0, r_spartan.size.x, r_spartan.size.y), r_spartan.position)
	_part_rects["hlm_spartan_crest"] = Rect2(r_spartan.position, r_spartan.size)

	var head_horns: Image = head_k_base.duplicate()
	_recolor_3d_part(head_horns, "ABYSS_HORNS")
	_sculpt_abyss_horns(head_horns)
	var r_horns := Rect2i(204, 730, head_horns.get_width(), head_horns.get_height())
	atlas_img.blit_rect(head_horns, Rect2i(0, 0, r_horns.size.x, r_horns.size.y), r_horns.position)
	_part_rects["hlm_abyss_horns"] = Rect2(r_horns.position, r_horns.size)

	var head_bare: Image = head_k_base.duplicate()
	_recolor_3d_part(head_bare, "BARE_HEAD")
	var r_bare := Rect2i(392, 730, head_bare.get_width(), head_bare.get_height())
	atlas_img.blit_rect(head_bare, Rect2i(0, 0, r_bare.size.x, r_bare.size.y), r_bare.position)
	_part_rects["hlm_none"] = Rect2(r_bare.position, r_bare.size)

	# 9. Torso Armor Variants: arm_vanguard_cuirass, arm_aegis_plate, arm_light_tunic
	_part_rects["arm_vanguard_cuirass"] = _part_rects["torso_knight"]
	_part_rects["arm_aethel_cuirass"] = _part_rects["torso_knight"]
	var torso_k_base: Image = atlas_img.get_region(base_cells["torso_knight"])

	var torso_aegis: Image = torso_k_base.duplicate()
	_recolor_3d_part(torso_aegis, "AEGIS_GOLD_PLATE")
	var r_aegis := Rect2i(580, 730, torso_aegis.get_width(), torso_aegis.get_height())
	atlas_img.blit_rect(torso_aegis, Rect2i(0, 0, r_aegis.size.x, r_aegis.size.y), r_aegis.position)
	_part_rects["arm_aegis_plate"] = Rect2(r_aegis.position, r_aegis.size)
	_part_rects["arm_royal_plate"] = Rect2(r_aegis.position, r_aegis.size)

	var torso_tunic: Image = torso_k_base.duplicate()
	_recolor_3d_part(torso_tunic, "LIGHT_TUNIC")
	var r_tunic := Rect2i(770, 730, torso_tunic.get_width(), torso_tunic.get_height())
	atlas_img.blit_rect(torso_tunic, Rect2i(0, 0, r_tunic.size.x, r_tunic.size.y), r_tunic.position)
	_part_rects["arm_light_tunic"] = Rect2(r_tunic.position, r_tunic.size)

	# 10. Pauldron & Orc Limb Variants (Green/Purple/Iron 3D Limbs for Orc Faction)
	_part_rects["pld_iron_guard"] = _part_rects["uarm_knight"]
	_part_rects["pld_steel_spaulders"] = _part_rects["uarm_knight"]
	_part_rects["pld_none"] = _part_rects["uarm_knight"]

	var uarm_base: Image = atlas_img.get_region(base_cells["uarm_knight"])
	var uarm_gold: Image = uarm_base.duplicate()
	_recolor_3d_part(uarm_gold, "AEGIS_GOLD_PLATE")
	var r_uarm_gold := Rect2i(772, 170, uarm_gold.get_width(), uarm_gold.get_height())
	atlas_img.blit_rect(uarm_gold, Rect2i(0, 0, r_uarm_gold.size.x, r_uarm_gold.size.y), r_uarm_gold.position)
	_part_rects["pld_gold_wings"] = Rect2(r_uarm_gold.position, r_uarm_gold.size)
	_part_rects["pld_dragon_wings"] = Rect2(r_uarm_gold.position, r_uarm_gold.size)

	var uarm_orc: Image = uarm_base.duplicate()
	_recolor_3d_part(uarm_orc, "ORC_LIMB")
	var r_uarm_orc := Rect2i(772, 316, uarm_orc.get_width(), uarm_orc.get_height())
	atlas_img.blit_rect(uarm_orc, Rect2i(0, 0, r_uarm_orc.size.x, r_uarm_orc.size.y), r_uarm_orc.position)
	_part_rects["uarm_orc"] = Rect2(r_uarm_orc.position, r_uarm_orc.size)

	var farm_base: Image = atlas_img.get_region(base_cells["farm_knight"])
	var farm_orc: Image = farm_base.duplicate()
	_recolor_3d_part(farm_orc, "ORC_FOREARM")
	var r_farm_orc := Rect2i(906, 170, farm_orc.get_width(), farm_orc.get_height())
	atlas_img.blit_rect(farm_orc, Rect2i(0, 0, r_farm_orc.size.x, r_farm_orc.size.y), r_farm_orc.position)
	_part_rects["farm_orc"] = Rect2(r_farm_orc.position, r_farm_orc.size)

	var thigh_base: Image = atlas_img.get_region(base_cells["thigh_knight"])
	var thigh_orc: Image = thigh_base.duplicate()
	_recolor_3d_part(thigh_orc, "ORC_LIMB")
	var r_thigh_orc := Rect2i(896, 320, thigh_orc.get_width(), thigh_orc.get_height())
	atlas_img.blit_rect(thigh_orc, Rect2i(0, 0, r_thigh_orc.size.x, r_thigh_orc.size.y), r_thigh_orc.position)
	_part_rects["thigh_orc"] = Rect2(r_thigh_orc.position, r_thigh_orc.size)

	# 11. Orc Warlord Helmet Variant (keeps full 174x160 Orc 3D face & tusks with Crimson-Gold Warlord Helm)
	var head_orc_base: Image = atlas_img.get_region(base_cells["head_orc"])
	var head_orc_warlord: Image = head_orc_base.duplicate()
	_recolor_3d_part(head_orc_warlord, "ORC_WARLORD_HELM")
	var r_orc_wl := Rect2i(16, 910, head_orc_warlord.get_width(), head_orc_warlord.get_height())
	atlas_img.blit_rect(head_orc_warlord, Rect2i(0, 0, r_orc_wl.size.x, r_orc_wl.size.y), r_orc_wl.position)
	_part_rects["head_orc_warlord"] = Rect2(r_orc_wl.position, r_orc_wl.size)

	# 12. Soft Ground Contact Shadow Ellipse baked into the same Unified Atlas (0 polygon draw call break!)
	var sh_img := Image.create(128, 44, false, Image.FORMAT_RGBA8)
	_paint_soft_shadow(sh_img)
	var r_sh := Rect2i(220, 920, 128, 44)
	atlas_img.blit_rect(sh_img, Rect2i(0, 0, 128, 44), r_sh.position)
	_part_rects["unit_shadow"] = Rect2(r_sh.position, r_sh.size)

	_modular_atlas_tex = ImageTexture.create_from_image(atlas_img)

static func get_item_atlas_rect(item_id: String) -> Rect2:
	ensure_atlas_ready()
	if _part_rects.has(item_id):
		return _part_rects[item_id]
	return _part_rects.get("wpn_aethel_blade", Rect2(0, 0, 64, 64))

static func _strip_white_background_flood(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	var queue := PackedInt32Array()

	# Seed BFS from all 4 border edges of the cell
	for x in range(w):
		var top_idx: int = x
		var bot_idx: int = (h - 1) * w + x
		visited[top_idx] = 1
		visited[bot_idx] = 1
		queue.append(top_idx)
		queue.append(bot_idx)
	for y in range(1, h - 1):
		var l_idx: int = y * w
		var r_idx: int = y * w + (w - 1)
		visited[l_idx] = 1
		visited[r_idx] = 1
		queue.append(l_idx)
		queue.append(r_idx)

	var head: int = 0
	while head < queue.size():
		var idx: int = queue[head]
		head += 1
		var cx: int = idx % w
		var cy: int = idx / w
		var c: Color = img.get_pixel(cx, cy)
		var min_c: float = minf(c.r, minf(c.g, c.b))
		var max_c: float = maxf(c.r, maxf(c.g, c.b))
		var sat: float = max_c - min_c
		# Studio white/light-grey background check (preserves interior highlights)
		var is_bg: bool = (min_c > 0.80 and sat < 0.14) or (min_c > 0.91 and sat < 0.22)
		if not is_bg:
			continue

		img.set_pixel(cx, cy, Color(0.0, 0.0, 0.0, 0.0))

		if cx > 0 and visited[idx - 1] == 0:
			visited[idx - 1] = 1
			queue.append(idx - 1)
		if cx + 1 < w and visited[idx + 1] == 0:
			visited[idx + 1] = 1
			queue.append(idx + 1)
		if cy > 0 and visited[idx - w] == 0:
			visited[idx - w] = 1
			queue.append(idx - w)
		if cy + 1 < h and visited[idx + w] == 0:
			visited[idx + w] = 1
			queue.append(idx + w)

	# Clean 1px boundary edge: replace white anti-aliased fringe with warm dark Clash Royale outline
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			var touches_alpha: bool = (
				img.get_pixel(x - 1, y).a < 0.05 or
				img.get_pixel(x + 1, y).a < 0.05 or
				img.get_pixel(x, y - 1).a < 0.05 or
				img.get_pixel(x, y + 1).a < 0.05
			)
			if touches_alpha:
				var min_c: float = minf(c.r, minf(c.g, c.b))
				if min_c > 0.65:
					img.set_pixel(x, y, Color(0.18, 0.13, 0.10, 0.96))
				else:
					img.set_pixel(x, y, c.darkened(0.42))

static func _recolor_3d_part(img: Image, mode: String) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			var out: Color = c

			match mode:
				"SUNFIRE_SWORD":
					# Transform steel blade into blazing magma-crimson & molten gold greatsword
					if y < int(float(h) * 0.68):
						var edge_dist: float = absf(float(x) - float(w) * 0.5) / (float(w) * 0.28)
						var fire_t: float = clampf(lum * 1.15 - edge_dist * 0.25, 0.0, 1.0)
						out = Color(
							clampf(0.45 + fire_t * 0.65, 0.0, 1.0),
							clampf(0.10 + fire_t * fire_t * 0.78, 0.0, 1.0),
							clampf(0.05 + fire_t * 0.18, 0.0, 1.0),
							c.a
						)
					elif c.b > c.r * 1.15:
						# Blue gem -> blazing ruby gem
						out = Color(c.b, c.g * 0.35, c.r * 0.35, c.a)

				"FROSTBITE_SWORD":
					# Transform steel blade into crystalline ice-cyan & sapphire runeblade
					if y < int(float(h) * 0.68):
						out = Color(
							clampf(lum * 0.52, 0.08, 0.85),
							clampf(lum * 1.05 + 0.08, 0.18, 0.98),
							clampf(lum * 1.28 + 0.16, 0.32, 1.0),
							c.a
						)
					else:
						out = Color(c.r * 0.75, c.g * 0.92, minf(1.0, c.b * 1.25 + 0.1), c.a)

				"IRON_BUCKLER":
					# Cool steel-silver rim & deep cyan-slate core
					if c.r > c.b * 1.25:
						out = Color(lum * 0.86, lum * 0.91, minf(1.0, lum * 1.02), c.a)
					else:
						out = Color(c.r * 0.75, minf(1.0, c.g * 1.15), minf(1.0, c.b * 1.05), c.a)

				"TWIN_DAGGER":
					# Sleek shadow-amethyst & silver parrying blade
					out = Color(
						clampf(lum * 0.82 + 0.12, 0.12, 0.95),
						clampf(lum * 0.68, 0.08, 0.88),
						clampf(lum * 1.18 + 0.18, 0.24, 1.0),
						c.a
					)

				"CRIMSON_CAPE":
					# Swap royal blue fabric into rich Grand Marshal Crimson while preserving gold trim
					if c.b > c.r * 1.12:
						out = Color(minf(1.0, c.b * 1.06), c.g * 0.36, c.r * 0.42, c.a)

				"SPARTAN_CREST":
					# Swap blue feather plume on top-left into Spartan Crimson-Red & Gold
					if c.b > c.r * 1.18 and y < int(float(h) * 0.72):
						out = Color(minf(1.0, c.b * 1.08), c.g * 0.42, c.r * 0.35, c.a)

				"ABYSS_HORNS":
					# Strip the blue feather plume completely & tint helmet into dark obsidian-violet plate
					if c.b > c.r * 1.12 and y < int(float(h) * 0.72) and x < int(float(w) * 0.76):
						out = Color(0, 0, 0, 0)
					elif absf(c.r - c.b) < 0.14 and y < int(float(h) * 0.68):
						out = Color(lum * 0.48, lum * 0.38, lum * 0.62, c.a)
					elif c.r > c.b * 1.25 and y < int(float(h) * 0.68):
						out = Color(minf(1.0, c.r * 1.05), c.g * 0.75, c.b * 0.55, c.a)

				"BARE_HEAD":
					# Trim top plume & tint helmet into warm golden-brown hair/headband
					if x < int(float(w) * 0.42) and y < int(float(h) * 0.48) and c.b > c.r * 1.15:
						out = Color(0, 0, 0, 0)
					elif c.b > c.r * 1.12 or (absf(c.r - c.b) < 0.09 and y < int(float(h) * 0.52)):
						out = Color(clampf(lum * 0.78 + 0.12, 0.15, 0.85), clampf(lum * 0.52 + 0.05, 0.10, 0.62), clampf(lum * 0.28, 0.05, 0.38), c.a)

				"AEGIS_GOLD_PLATE":
					# Gleaming royal gold & crimson-trimmed heavy plate
					if absf(c.r - c.b) < 0.14 and lum > 0.32:
						out = Color(minf(1.0, lum * 1.22 + 0.08), minf(1.0, lum * 0.96 + 0.02), lum * 0.38, c.a)
					elif c.b > c.r * 1.18:
						out = Color(minf(1.0, c.b * 0.95), c.g * 0.35, c.r * 0.38, c.a)

				"LIGHT_TUNIC":
					# Warm ranger leather & cobalt cloth tunic
					if absf(c.r - c.b) < 0.12:
						out = Color(clampf(lum * 0.82 + 0.08, 0.14, 0.78), clampf(lum * 0.56 + 0.04, 0.10, 0.56), clampf(lum * 0.36, 0.06, 0.38), c.a)

				"ORC_LIMB":
					# Dark iron plate & purple war-cloth for Orc limbs
					if c.b > c.r * 1.12:
						out = Color(c.b * 0.68, c.g * 0.38, c.b * 0.85, c.a)
					else:
						out = Color(lum * 0.58, lum * 0.52, lum * 0.64, c.a)

				"ORC_FOREARM":
					# Muscular Orc green skin & dark iron bracer
					if c.r > c.b * 1.20:
						out = Color(lum * 0.64, minf(1.0, lum * 0.95 + 0.06), lum * 0.32, c.a)
					else:
						out = Color(lum * 0.56, lum * 0.50, lum * 0.62, c.a)

				"ORC_WARLORD_HELM":
					# Preserve green Orc face & ivory tusks while tinting upper helmet bronze-crimson
					if y < int(float(h) * 0.52) and c.g < c.r * 1.15:
						out = Color(minf(1.0, lum * 1.15 + 0.12), lum * 0.58, lum * 0.32, c.a)

			img.set_pixel(x, y, out)

static func _paint_3d_thunder_halberd(img: Image) -> void:
	# Paint a true 3D Poleaxe / Halberd (Chiến Kích Lôi Đình):
	# Long hardwood-and-gold pole, tall spear point, broad right crescent axe blade, left back-spike & violet lightning gem
	var w: int = img.get_width()
	var h: int = img.get_height()
	var cx: float = float(w) * 0.46
	var outline := Color(0.16, 0.11, 0.08, 0.98)

	for y in range(6, h - 6):
		for x in range(6, w - 6):
			var dx: float = float(x) - cx
			var adx: float = absf(dx)

			# 1. Top Spear Tip (y = 6 .. 48)
			if y < 48:
				var tip_t: float = float(y - 6) / 42.0
				var half_w: float = 1.5 + tip_t * 9.5
				if adx <= half_w:
					if adx >= half_w - 1.8:
						img.set_pixel(x, y, outline)
					else:
						var bevel: float = 0.88 if dx < 0.0 else 0.64
						img.set_pixel(x, y, Color(bevel * 0.92, bevel * 0.95, minf(1.0, bevel * 1.08), 1.0))
					continue

			# 2. Crescent Axe Blade on Right (y = 32 .. 108, dx > 4) and Back-Spike on Left (y = 50 .. 84, dx < -4)
			if y >= 32 and y <= 108 and dx > 4.0:
				var ny: float = (float(y) - 70.0) / 38.0
				var outer_reach: float = 14.0 + sqrt(maxf(0.0, 1.0 - ny * ny)) * 34.0
				var inner_cut: float = 7.0 + maxf(0.0, 1.0 - ny * ny * 2.2) * 10.0
				if dx <= outer_reach and (dx >= inner_cut or absf(ny) < 0.28):
					if dx >= outer_reach - 2.2 or (dx <= inner_cut + 1.8 and absf(ny) >= 0.28):
						img.set_pixel(x, y, outline)
					else:
						var edge_ratio: float = (dx - inner_cut) / maxf(1.0, outer_reach - inner_cut)
						if edge_ratio > 0.68:
							# Razor silver-gold cutting edge
							var s_lum: float = 0.85 + (edge_ratio - 0.68) * 0.45 - ny * 0.08
							img.set_pixel(x, y, Color(minf(1.0, s_lum * 1.05), minf(1.0, s_lum * 0.96), s_lum * 0.68, 1.0))
						else:
							# Forged bronze-gold axe body
							var b_lum: float = 0.68 - ny * 0.12 + edge_ratio * 0.15
							img.set_pixel(x, y, Color(minf(1.0, b_lum * 1.08), b_lum * 0.78, b_lum * 0.28, 1.0))
					continue

			if y >= 48 and y <= 88 and dx < -4.0:
				var sy: float = (float(y) - 68.0) / 20.0
				var spike_reach: float = maxf(0.0, (1.0 - absf(sy))) * 28.0 + 5.0
				if -dx <= spike_reach:
					if -dx >= spike_reach - 2.0 or absf(sy) > 0.86:
						img.set_pixel(x, y, outline)
					else:
						var sp_lum: float = 0.76 - sy * 0.14
						img.set_pixel(x, y, Color(sp_lum * 0.95, sp_lum * 0.82, sp_lum * 0.42, 1.0))
					continue

			# 3. Long Pole Shaft, Golden Collars & Pommel (y = 44 .. h - 8)
			if y >= 44 and y <= h - 8:
				var is_collar: bool = (y >= 44 and y <= 54) or (y >= 84 and y <= 92) or (y >= 132 and y <= 138) or (y >= h - 16)
				var pole_hw: float = 7.5 if is_collar else 5.2
				if adx <= pole_hw:
					if adx >= pole_hw - 1.6 or y == h - 8:
						img.set_pixel(x, y, outline)
					elif is_collar:
						var g_sh: float = 1.0 - (dx / pole_hw) * 0.28
						img.set_pixel(x, y, Color(minf(1.0, 0.95 * g_sh), 0.76 * g_sh, 0.24 * g_sh, 1.0))
					else:
						var w_sh: float = 1.0 - (dx / pole_hw) * 0.32
						img.set_pixel(x, y, Color(0.52 * w_sh, 0.30 * w_sh, 0.18 * w_sh, 1.0))

	# 4. Storm-Violet Lightning Gem at Halberd Socket Center (cx, y = 68)
	var gem_c := Vector2(cx, 68.0)
	for y in range(58, 79):
		for x in range(int(cx - 10.0), int(cx + 11.0)):
			var d: float = Vector2(x, y).distance_to(gem_c)
			if d <= 7.5:
				if d >= 5.8:
					img.set_pixel(x, y, outline)
				else:
					var g_t: float = 1.0 - d / 5.8
					img.set_pixel(x, y, Color(0.75 + g_t * 0.25, 0.35 + g_t * 0.45, 1.0, 1.0))

static func _build_crossed_twin_daggers(dst_img: Image, single_dagger: Image) -> void:
	# Composite TWO angled 3D-shaded daggers crossed in an 'X' so "Song Đao Phản Đòn" shows 2 blades
	var dw: int = dst_img.get_width()
	var dh: int = dst_img.get_height()
	var sw: int = single_dagger.get_width()
	var sh: int = single_dagger.get_height()
	var dst_c := Vector2(dw * 0.5, dh * 0.54)
	var src_c := Vector2(sw * 0.5, sh * 0.54)

	var angles: Array[float] = [-0.40, 0.40]
	var offsets: Array[Vector2] = [Vector2(-10.0, 4.0), Vector2(10.0, -2.0)]
	var shades: Array[float] = [0.86, 1.0]

	for b_idx in range(2):
		var ang: float = angles[b_idx]
		var ca: float = cos(-ang)
		var sa: float = sin(-ang)
		var scale_inv: float = 1.18 # slightly shorter/sleeker than full longsword
		var off: Vector2 = offsets[b_idx]
		var sh_mult: float = shades[b_idx]

		for y in range(dh):
			for x in range(dw):
				var p: Vector2 = Vector2(x, y) - (dst_c + off)
				var sx: int = int(round((p.x * ca - p.y * sa) * scale_inv + src_c.x))
				var sy: int = int(round((p.x * sa + p.y * ca) * scale_inv + src_c.y))
				if sx >= 0 and sx < sw and sy >= 0 and sy < sh:
					var c: Color = single_dagger.get_pixel(sx, sy)
					if c.a > 0.15:
						dst_img.set_pixel(x, y, Color(c.r * sh_mult, c.g * sh_mult, c.b * sh_mult, c.a))

static func _sculpt_abyss_horns(img: Image) -> void:
	# Paint two curved 3D-beveled ivory/obsidian horns sweeping up from the helmet temples
	var w: int = img.get_width()
	var h: int = img.get_height()
	var outline := Color(0.16, 0.11, 0.08, 0.98)

	# Back horn (left-top sweep) and Front horn (center-top sweep)
	var horn_defs: Array[Array] = [
		[Vector2(w * 0.36, h * 0.38), Vector2(w * 0.10, h * 0.16), Vector2(w * 0.18, h * 0.04), 13.5, 0.84],
		[Vector2(w * 0.56, h * 0.36), Vector2(w * 0.28, h * 0.12), Vector2(w * 0.38, h * 0.02), 16.0, 1.00]
	]

	for hd in horn_defs:
		var p0: Vector2 = hd[0]
		var p1: Vector2 = hd[1]
		var p2: Vector2 = hd[2]
		var base_r: float = float(hd[3])
		var shade_m: float = float(hd[4])

		for step_i in range(64):
			var t: float = float(step_i) / 63.0
			var omt: float = 1.0 - t
			var center: Vector2 = p0 * (omt * omt) + p1 * (2.0 * omt * t) + p2 * (t * t)
			var rad: float = lerpf(base_r, 2.2, pow(t, 0.85))
			var r_int: int = int(ceil(rad + 2.0))

			for dy in range(-r_int, r_int + 1):
				for dx in range(-r_int, r_int + 1):
					var px: int = int(round(center.x)) + dx
					var py: int = int(round(center.y)) + dy
					if px < 1 or px >= w - 1 or py < 1 or py >= h - 1:
						continue
					var dist: float = sqrt(float(dx * dx + dy * dy))
					if dist <= rad:
						if dist >= rad - 1.8:
							img.set_pixel(px, py, outline)
						else:
							# 3D cylinder shading + dark base transitioning to ivory tip
							var light: float = clampf(0.65 - float(dy) / maxf(1.0, rad) * 0.32 + t * 0.25, 0.22, 1.0) * shade_m
							var ring_band: float = 0.88 if (int(t * 18.0) % 2 == 0 and t < 0.7) else 1.0
							var col := Color(
								clampf(light * 0.96 * ring_band, 0.18, 0.98),
								clampf(light * 0.88 * ring_band, 0.15, 0.92),
								clampf(light * 0.74 * ring_band, 0.14, 0.82),
								1.0
							)
							img.set_pixel(px, py, col)

static func _paint_3d_golden_halo(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var c := Vector2(w * 0.5, h * 0.5)
	for y in range(h):
		for x in range(w):
			var d: float = Vector2(x, y).distance_to(c)
			if d >= 42.0 and d <= 62.0:
				var ring_t: float = 1.0 - absf(d - 52.0) / 10.0
				if ring_t < 0.18:
					img.set_pixel(x, y, Color(0.18, 0.12, 0.06, 0.95))
				else:
					var spec: float = clampf(0.72 + ring_t * 0.35 - float(y - h * 0.5) * 0.004, 0.4, 1.0)
					img.set_pixel(x, y, Color(spec, spec * 0.84, spec * 0.24, 1.0))

static func _paint_soft_shadow(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var cx: float = float(w) * 0.5
	var cy: float = float(h) * 0.5
	var rx: float = float(w) * 0.46
	var ry: float = float(h) * 0.42
	for y in range(h):
		for x in range(w):
			var nx: float = (float(x) - cx) / rx
			var ny: float = (float(y) - cy) / ry
			var d2: float = nx * nx + ny * ny
			if d2 < 1.0:
				var a: float = (1.0 - d2) * 0.44
				img.set_pixel(x, y, Color(0.05, 0.10, 0.04, a))

# ============================================================================
# 12-BONE FORWARD KINEMATICS (FK) SOLVER (ENHANCED WEIGHT & FOLLOW-THROUGH)
# ============================================================================

func solve_12_bones(
	root_pos: Vector2,
	facing: float,
	scale: float,
	anim_state: String,
	anim_time: float,
	anim_duration: float,
	recoil_impulse: float
) -> void:
	var s: float = scale
	var t_norm: float = clampf(anim_time / maxf(0.01, anim_duration), 0.0, 1.0)

	var hip_offset := Vector2(0.0, -40.0 * s)
	var spine_lean: float = 0.06
	var chest_lean: float = 0.09
	var head_tilt: float = 0.02

	var uarm_l: float = -0.20
	var farm_l: float = -0.65
	var uarm_r: float = 0.25
	var farm_r: float = -1.25

	var thigh_l: float = -0.26
	var shin_l: float = 0.24
	var thigh_r: float = 0.28
	var shin_r: float = 0.18

	match anim_state:
		"IDLE":
			var breath: float = sin(anim_time * 3.8)
			hip_offset.y = (-40.0 + breath * 2.4) * s
			spine_lean = 0.05 + breath * 0.03
			chest_lean = 0.08 + breath * 0.04
			head_tilt = 0.02 - breath * 0.03
			uarm_l = -0.22 + breath * 0.05
			farm_l = -0.68
			uarm_r = 0.26 - breath * 0.06
			farm_r = -1.28 + breath * 0.05
			thigh_l = -0.26
			shin_l = 0.24
			thigh_r = 0.28
			shin_r = 0.18

		"RUN":
			var cycle: float = anim_time * 11.5
			var s_wave: float = sin(cycle)
			var c_wave: float = cos(cycle)
			hip_offset.y = (-38.0 - absf(c_wave) * 5.8) * s
			hip_offset.x = facing * 4.0 * s
			spine_lean = 0.26 + absf(s_wave) * 0.08
			chest_lean = 0.32 + absf(s_wave) * 0.09
			head_tilt = -0.12

			thigh_r = s_wave * 0.85
			shin_r = maxf(0.10, -c_wave * 0.88 + 0.36)
			thigh_l = -s_wave * 0.85
			shin_l = maxf(0.10, c_wave * 0.88 + 0.36)

			uarm_r = -s_wave * 0.65 + 0.05
			farm_r = -1.05 - s_wave * 0.22
			uarm_l = s_wave * 0.58 - 0.10
			farm_l = -0.78

		"ATTACK_1":
			# 3-Phase Heavy Overhead Cleave: Windup -> Strike -> Recovery
			if t_norm < 0.34:
				var p: float = smoothstep(0.0, 0.34, t_norm)
				hip_offset.x = lerpf(0.0, -8.5 * s * facing, p)
				hip_offset.y = (-40.0 + p * 4.0) * s
				spine_lean = lerpf(0.06, -0.34, p)
				chest_lean = lerpf(0.09, -0.44, p)
				uarm_r = lerpf(0.26, -2.35, p)
				farm_r = lerpf(-1.28, -0.45, p)
				uarm_l = lerpf(-0.22, -0.42, p)
				thigh_r = lerpf(0.28, 0.52, p)
				thigh_l = lerpf(-0.26, -0.48, p)
			elif t_norm < 0.58:
				var p: float = smoothstep(0.34, 0.58, t_norm)
				hip_offset.x = lerpf(-8.5 * s * facing, 16.5 * s * facing, p)
				hip_offset.y = (-36.0 + p * 4.5) * s
				spine_lean = lerpf(-0.34, 0.48, p)
				chest_lean = lerpf(-0.44, 0.58, p)
				uarm_r = lerpf(-2.35, 0.82, p)
				farm_r = lerpf(-0.45, 0.15, p)
				uarm_l = lerpf(-0.42, 0.45, p)
				thigh_r = lerpf(0.52, 0.76, p)
				shin_r = lerpf(0.25, 0.56, p)
				thigh_l = lerpf(-0.48, -0.62, p)
			else:
				var p: float = smoothstep(0.58, 1.0, t_norm)
				hip_offset.x = lerpf(16.5 * s * facing, 0.0, p)
				hip_offset.y = lerpf(-31.5 * s, -40.0 * s, p)
				spine_lean = lerpf(0.48, 0.06, p)
				chest_lean = lerpf(0.58, 0.09, p)
				uarm_r = lerpf(0.82, 0.26, p)
				farm_r = lerpf(0.15, -1.28, p)
				uarm_l = lerpf(0.45, -0.22, p)
				thigh_r = lerpf(0.76, 0.28, p)
				shin_r = lerpf(0.56, 0.18, p)
				thigh_l = lerpf(-0.62, -0.26, p)

		"ATTACK_2":
			# Deep Lunge Thrust -> Rising Uppercut Cleave
			if t_norm < 0.28:
				var p: float = smoothstep(0.0, 0.28, t_norm)
				hip_offset.x = lerpf(0.0, -10.0 * s * facing, p)
				hip_offset.y = (-40.0 + p * 5.5) * s
				spine_lean = lerpf(0.06, 0.36, p)
				chest_lean = lerpf(0.09, 0.48, p)
				uarm_r = lerpf(0.26, 0.96, p)
				farm_r = lerpf(-1.28, -1.10, p)
				uarm_l = lerpf(-0.22, 0.52, p)
			elif t_norm < 0.62:
				var p: float = smoothstep(0.28, 0.62, t_norm)
				hip_offset.x = lerpf(-10.0 * s * facing, 20.0 * s * facing, p)
				hip_offset.y = (-34.5 - sin(p * PI) * 9.0) * s
				spine_lean = lerpf(0.36, -0.26, p)
				chest_lean = lerpf(0.48, -0.34, p)
				uarm_r = lerpf(0.96, -1.95, p)
				farm_r = lerpf(-1.10, -0.18, p)
				uarm_l = lerpf(0.52, -0.45, p)
				thigh_r = lerpf(0.32, 0.80, p)
				shin_r = lerpf(0.24, 0.64, p)
				thigh_l = lerpf(-0.28, -0.70, p)
			else:
				var p: float = smoothstep(0.62, 1.0, t_norm)
				hip_offset.x = lerpf(20.0 * s * facing, 0.0, p)
				hip_offset.y = lerpf(-34.5 * s, -40.0 * s, p)
				spine_lean = lerpf(-0.26, 0.06, p)
				chest_lean = lerpf(-0.34, 0.09, p)
				uarm_r = lerpf(-1.95, 0.26, p)
				farm_r = lerpf(-0.18, -1.28, p)

		"BLOCK_HIT":
			var brace: float = minf(1.0, anim_time * 8.5)
			hip_offset.x = -5.5 * s * facing * brace
			hip_offset.y = (-36.5 + brace * 3.0) * s
			spine_lean = -0.14 * brace
			chest_lean = -0.10 * brace
			uarm_l = lerpf(-0.22, -0.68, brace)
			farm_l = lerpf(-0.68, -0.92, brace)
			uarm_r = lerpf(0.26, -0.75, brace)
			farm_r = lerpf(-1.28, -1.15, brace)
			thigh_r = 0.48
			shin_r = 0.38
			thigh_l = -0.46
			shin_l = 0.34

		"DEATH":
			var p: float = smoothstep(0.0, 0.78, t_norm)
			hip_offset.x = -20.0 * s * facing * p
			hip_offset.y = lerpf(-40.0 * s, -9.0 * s, p * p)
			spine_lean = lerpf(0.06, -1.38, p)
			chest_lean = lerpf(0.09, -1.50, p)
			head_tilt = lerpf(0.02, -0.38, p)
			uarm_r = lerpf(0.26, -1.55, p)
			farm_r = lerpf(-1.28, -0.10, p)
			uarm_l = lerpf(-0.22, -1.25, p)
			farm_l = lerpf(-0.68, -0.18, p)
			thigh_r = lerpf(0.28, 1.18, p)
			shin_r = lerpf(0.18, 0.25, p)
			thigh_l = lerpf(-0.26, 0.90, p)
			shin_l = lerpf(0.24, 0.42, p)

	if recoil_impulse > 0.01:
		spine_lean -= recoil_impulse * 0.42
		chest_lean -= recoil_impulse * 0.52
		head_tilt -= recoil_impulse * 0.56

	var hip_world: Vector2 = root_pos + hip_offset

	# 1. BONE_HIP
	var a_hip: float = -PI * 0.5 + spine_lean * 0.5 * facing
	var p_waist: Vector2 = hip_world + Vector2.from_angle(a_hip) * (10.5 * s)
	bone_start[0] = hip_world
	bone_end[0] = p_waist
	bone_angle[0] = a_hip

	# 2. BONE_LOWER_SPINE
	var a_spine: float = -PI * 0.5 + spine_lean * facing
	var p_mid_chest: Vector2 = p_waist + Vector2.from_angle(a_spine) * (13.5 * s)
	bone_start[1] = p_waist
	bone_end[1] = p_mid_chest
	bone_angle[1] = a_spine

	# 3. BONE_UPPER_CHEST
	var a_chest: float = -PI * 0.5 + chest_lean * facing
	var p_neck: Vector2 = p_mid_chest + Vector2.from_angle(a_chest) * (15.0 * s)
	bone_start[2] = p_mid_chest
	bone_end[2] = p_neck
	bone_angle[2] = a_chest

	# 4. BONE_HEAD
	var a_head: float = -PI * 0.5 + (chest_lean + head_tilt) * facing
	var head_base: Vector2 = p_neck + Vector2(facing * 1.5 * s, -4.0 * s)
	var p_head_top: Vector2 = head_base + Vector2.from_angle(a_head) * (24.0 * s)
	bone_start[3] = head_base
	bone_end[3] = p_head_top
	bone_angle[3] = a_head

	var shoulder_anchor: Vector2 = p_mid_chest.lerp(p_neck, 0.48)
	var shoulder_l: Vector2 = shoulder_anchor + Vector2(facing * 5.5 * s, 1.5 * s)
	var shoulder_r: Vector2 = shoulder_anchor + Vector2(-facing * 6.0 * s, 2.5 * s)

	# 5 & 6. BONE_UPPER_ARM_L & BONE_FOREARM_L
	var a_uarm_l: float = PI * 0.5 - uarm_l * facing
	var p_elbow_l: Vector2 = shoulder_l + Vector2.from_angle(a_uarm_l) * (15.0 * s)
	bone_start[4] = shoulder_l
	bone_end[4] = p_elbow_l
	bone_angle[4] = a_uarm_l

	var a_farm_l: float = a_uarm_l + farm_l * facing
	var p_hand_l: Vector2 = p_elbow_l + Vector2.from_angle(a_farm_l) * (14.5 * s)
	bone_start[5] = p_elbow_l
	bone_end[5] = p_hand_l
	bone_angle[5] = a_farm_l

	# 7 & 8. BONE_UPPER_ARM_R & BONE_FOREARM_R
	var a_uarm_r: float = PI * 0.5 - uarm_r * facing
	var p_elbow_r: Vector2 = shoulder_r + Vector2.from_angle(a_uarm_r) * (15.5 * s)
	bone_start[6] = shoulder_r
	bone_end[6] = p_elbow_r
	bone_angle[6] = a_uarm_r

	var a_farm_r: float = a_uarm_r + farm_r * facing
	var p_hand_r: Vector2 = p_elbow_r + Vector2.from_angle(a_farm_r) * (15.0 * s)
	bone_start[7] = p_elbow_r
	bone_end[7] = p_hand_r
	bone_angle[7] = a_farm_r

	# 9 & 10. BONE_THIGH_L & BONE_SHIN_L
	var a_thigh_l: float = PI * 0.5 - thigh_l * facing
	var p_knee_l: Vector2 = hip_world + Vector2.from_angle(a_thigh_l) * (18.5 * s)
	bone_start[8] = hip_world
	bone_end[8] = p_knee_l
	bone_angle[8] = a_thigh_l

	var a_shin_l: float = a_thigh_l + shin_l * facing
	var p_foot_l: Vector2 = p_knee_l + Vector2.from_angle(a_shin_l) * (18.5 * s)
	bone_start[9] = p_knee_l
	bone_end[9] = p_foot_l
	bone_angle[9] = a_shin_l

	# 11 & 12. BONE_THIGH_R & BONE_SHIN_R
	var a_thigh_r: float = PI * 0.5 - thigh_r * facing
	var p_knee_r: Vector2 = hip_world + Vector2.from_angle(a_thigh_r) * (18.5 * s)
	bone_start[10] = hip_world
	bone_end[10] = p_knee_r
	bone_angle[10] = a_thigh_r

	var a_shin_r: float = a_thigh_r + shin_r * facing
	var p_foot_r: Vector2 = p_knee_r + Vector2.from_angle(a_shin_r) * (18.5 * s)
	bone_start[11] = p_knee_r
	bone_end[11] = p_foot_r
	bone_angle[11] = a_shin_r

# ============================================================================
# 3D-PAINTED ARTICULATED CHARACTER RENDERING (1V1 & 300-UNIT UNIFIED ATLAS)
# ============================================================================

func draw_character(
	canvas: CanvasItem,
	unit: BattleSimulation.SimUnit,
	render_pos: Vector2,
	show_debug_bones: bool = false,
	lod_crowd_mode: bool = false
) -> void:
	ensure_atlas_ready()
	var s: float = unit.unit_scale * 1.06
	var facing: float = unit.facing
	var is_orc: bool = (unit.team == 2 or unit.archetype_id == "abyssal_challenger")
	var mod_col: Color = Color(2.4, 2.3, 2.1, 1.0) if unit.hit_flash_timer > 0.0 else Color.WHITE
	var back_mod: Color = mod_col.darkened(0.24)
	back_mod.a = 1.0

	solve_12_bones(
		render_pos,
		facing,
		s,
		unit.anim_state,
		unit.anim_time,
		unit.anim_duration,
		unit.hit_recoil_impulse
	)

	if _modular_atlas_tex == null:
		return

	# Ground contact shadow drawn directly from the shared Unified Atlas (0 polygon draw call breaks!)
	_draw_atlas_part(
		canvas,
		"unit_shadow",
		render_pos + Vector2(0.0, 5.0 * s),
		0.0,
		Vector2(s * 0.48, s * 0.42),
		Vector2(0.50, 0.50),
		Color.WHITE
	)

	var thigh_key: String = "thigh_orc" if is_orc else "thigh_knight"
	var farm_key: String = "farm_orc" if is_orc else "farm_knight"

	# --- 1. SOCKET 6: BACK CAPE (Attached to Neck/Shoulders, waving with motion) ---
	var cape_id: String = str(unit.loadout.get(ContentDB.SOCKET_BACK_CAPE, "cpe_none"))
	if cape_id != "cpe_none":
		var cape_key: String = "cpe_orc_tattered" if (is_orc and cape_id == "cpe_azure_scarf") else cape_id
		if not _part_rects.has(cape_key):
			cape_key = "cpe_orc_tattered" if is_orc else "cpe_azure_scarf"
		var cape_wave: float = sin(unit.cape_wave_phase) * 0.10 - (bone_angle[1] + PI * 0.5) * 0.45 * facing
		if cape_key == "cpe_aether_halo":
			_draw_atlas_part(
				canvas,
				cape_key,
				bone_start[3] + Vector2(-facing * 6.0 * s, -8.0 * s),
				unit.cape_wave_phase * 0.25,
				Vector2(facing * s * 0.46, s * 0.46),
				Vector2(0.5, 0.5),
				mod_col
			)
		else:
			_draw_atlas_part(
				canvas,
				cape_key,
				bone_end[2] + Vector2(-facing * 6.0 * s, -4.0 * s),
				cape_wave * facing,
				Vector2(facing * s * 0.36, s * 0.38),
				Vector2(0.52, 0.14),
				mod_col
			)

	# --- 2. BACK LEG (Bones 9 & 10: Thigh_L + Boot_L) ---
	_draw_atlas_part(
		canvas,
		thigh_key,
		bone_start[8],
		bone_angle[8] - PI * 0.5,
		Vector2(facing * s * 0.26, s * 0.26),
		Vector2(0.50, 0.20),
		back_mod
	)
	_draw_atlas_part(
		canvas,
		"boot_knight",
		bone_start[9],
		bone_angle[9] - PI * 0.5,
		Vector2(facing * s * 0.24, s * 0.25),
		Vector2(0.42, 0.22),
		back_mod
	)

	# --- 3. BACK ARM (Bones 5 & 6: UpperArm_L + Forearm_L) ---
	_draw_atlas_part(
		canvas,
		"uarm_orc" if is_orc else "uarm_knight",
		bone_start[4],
		bone_angle[4] - PI * 0.5,
		Vector2(facing * s * 0.24, s * 0.24),
		Vector2(0.50, 0.22),
		back_mod
	)
	_draw_atlas_part(
		canvas,
		farm_key,
		bone_start[5],
		bone_angle[5] - PI * 0.5,
		Vector2(facing * s * 0.24, s * 0.24),
		Vector2(0.50, 0.18),
		back_mod
	)

	# --- 4. TORSO & SOCKET 4: CHEST ARMOR (Bones 1, 2, 3) ---
	var armor_id: String = str(unit.loadout.get(ContentDB.SOCKET_CHEST_ARMOR, "arm_vanguard_cuirass"))
	var torso_key: String = "torso_orc" if (is_orc and armor_id == "arm_vanguard_cuirass") else armor_id
	if not _part_rects.has(torso_key):
		torso_key = "torso_orc" if is_orc else "torso_knight"
	var torso_center: Vector2 = bone_start[0].lerp(bone_end[2], 0.52)
	_draw_atlas_part(
		canvas,
		torso_key,
		torso_center,
		bone_angle[1] + PI * 0.5,
		Vector2(facing * s * 0.34, s * 0.34),
		Vector2(0.50, 0.52),
		mod_col
	)

	# --- 5. FRONT LEG (Bones 11 & 12: Thigh_R + Boot_R) ---
	_draw_atlas_part(
		canvas,
		thigh_key,
		bone_start[10],
		bone_angle[10] - PI * 0.5,
		Vector2(facing * s * 0.28, s * 0.28),
		Vector2(0.50, 0.20),
		mod_col
	)
	_draw_atlas_part(
		canvas,
		"boot_knight",
		bone_start[11],
		bone_angle[11] - PI * 0.5,
		Vector2(facing * s * 0.26, s * 0.27),
		Vector2(0.42, 0.22),
		mod_col
	)

	# --- 6. SOCKET 2: OFFHAND SHIELD / TWIN DAGGER (Attached to Bone 6: Hand_L) ---
	var off_id: String = str(unit.loadout.get(ContentDB.SOCKET_OFFHAND, "off_none"))
	if off_id != "off_none" and _part_rects.has(off_id):
		if off_id == "off_twin_dagger" or off_id == "off_parry_dagger":
			_draw_atlas_part(
				canvas,
				off_id,
				bone_end[5],
				bone_angle[5] + PI * 0.35 * facing,
				Vector2(facing * s * 0.28, s * 0.28),
				Vector2(0.50, 0.65),
				mod_col
			)
		else:
			var sh_rot: float = clampf((bone_angle[5] - PI * 0.5) * 0.28, -0.45, 0.45)
			var sh_offset := Vector2(facing * (10.0 if unit.is_blocking else 5.0) * s, (-6.0 if unit.is_blocking else 0.0) * s)
			_draw_atlas_part(
				canvas,
				off_id,
				bone_end[5] + sh_offset,
				sh_rot,
				Vector2(facing * s * 0.30, s * 0.30),
				Vector2(0.50, 0.50),
				mod_col
			)

	# --- 7. FRONT UPPER ARM & SOCKET 5: PAULDRON (Bone 7) ---
	var pld_id: String = str(unit.loadout.get(ContentDB.SOCKET_PAULDRON, "pld_iron_guard"))
	var is_gold_pld: bool = (pld_id == "pld_gold_wings" or pld_id == "pld_dragon_wings")
	var uarm_key: String = "uarm_orc" if (is_orc and not is_gold_pld) else pld_id
	if not _part_rects.has(uarm_key):
		uarm_key = "uarm_orc" if is_orc else "uarm_knight"
	_draw_atlas_part(
		canvas,
		uarm_key,
		bone_start[6],
		bone_angle[6] - PI * 0.5,
		Vector2(facing * s * 0.28, s * 0.28),
		Vector2(0.50, 0.22),
		mod_col
	)

	# --- 8. OVERSIZED 3D HEAD, SOCKET 3: HELMET & EXPRESSIVE FACE (Bone 4) ---
	var hlm_id: String = str(unit.loadout.get(ContentDB.SOCKET_HELMET, "hlm_vanguard_visor"))
	var head_key: String = hlm_id
	if is_orc:
		head_key = "head_orc_warlord" if (hlm_id == "hlm_spartan_crest" or hlm_id == "hlm_vanguard_visor") else "head_orc"
	elif not _part_rects.has(head_key):
		head_key = "head_knight"

	_draw_atlas_part(
		canvas,
		head_key,
		bone_start[3],
		bone_angle[3] + PI * 0.5,
		Vector2(facing * s * 0.37, s * 0.37),
		Vector2(0.52, 0.82),
		mod_col
	)

	if not lod_crowd_mode:
		_draw_dynamic_facial_expression(canvas, unit, bone_start[3], bone_angle[3], facing, s, is_orc)

	# --- 9. SOCKET 1: MAIN WEAPON (Attached to Bone 8: Hand_R) ---
	var wpn_id: String = str(unit.loadout.get(ContentDB.SOCKET_MAIN_WEAPON, "wpn_aethel_blade"))
	var wpn_key: String = wpn_id if _part_rects.has(wpn_id) else "wpn_aethel_blade"
	var grip_pos: Vector2 = bone_end[7]
	var wpn_angle: float = bone_angle[7] - 0.18 * facing
	if unit.anim_state == "DEATH":
		grip_pos = bone_end[7] + Vector2(facing * 12.0 * s, unit.dropped_weapon_y)
		wpn_angle = unit.dropped_weapon_rot * facing

	var wpn_scale: float = 0.42 if (wpn_key == "wpn_sunfire_greatsword" or wpn_key == "wpn_crimson_greatsword") else (0.46 if wpn_key == "wpn_thunder_halberd" else 0.38)
	_draw_atlas_part(
		canvas,
		wpn_key,
		grip_pos,
		wpn_angle + PI * 0.5,
		Vector2(facing * s * wpn_scale, s * wpn_scale),
		Vector2(0.50, 0.78),
		mod_col
	)

	# --- 10. FRONT FOREARM & GAUNTLET FIST (Bone 8 - Gripping Weapon Hilt) ---
	_draw_atlas_part(
		canvas,
		farm_key,
		bone_start[7],
		bone_angle[7] - PI * 0.5,
		Vector2(facing * s * 0.27, s * 0.27),
		Vector2(0.50, 0.18),
		mod_col
	)

	# Reset canvas transform after drawing articulated parts
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- 11. SLASH RIBBONS, SHIELD AEGIS & DEBUG SKELETON ---
	if not lod_crowd_mode:
		_draw_combat_motion_arcs(canvas, unit, wpn_key, bone_start[6], bone_end[5], wpn_angle, facing, s, is_orc)
		if show_debug_bones:
			_draw_debug_skeleton(canvas, s)

func _draw_atlas_part(
	canvas: CanvasItem,
	part_key: String,
	world_pivot: Vector2,
	rot: float,
	scale_vec: Vector2,
	anchor_uv: Vector2,
	mod_col: Color
) -> void:
	if not _part_rects.has(part_key):
		return
	var src_r: Rect2 = _part_rects[part_key]
	var dst_pos := Vector2(-src_r.size.x * anchor_uv.x, -src_r.size.y * anchor_uv.y)
	canvas.draw_set_transform(world_pivot, rot, scale_vec)
	canvas.draw_texture_rect_region(_modular_atlas_tex, Rect2(dst_pos, src_r.size), src_r, mod_col)

func _draw_dynamic_facial_expression(
	canvas: CanvasItem,
	unit: BattleSimulation.SimUnit,
	p_neck: Vector2,
	a_head: float,
	facing: float,
	s: float,
	is_orc: bool
) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var dir := Vector2.from_angle(a_head)
	var n := Vector2(-dir.y, dir.x) * facing
	if unit.anim_state == "DEATH":
		# Knocked-out 'X' eye at the exact eye socket
		var eye_pos: Vector2 = p_neck + dir * (14.5 * s) + n * (3.2 * s)
		canvas.draw_line(eye_pos + Vector2(-2.5 * s, -2.5 * s), eye_pos + Vector2(2.5 * s, 2.5 * s), OUTLINE_DARK, 2.0 * s)
		canvas.draw_line(eye_pos + Vector2(-2.5 * s, 2.5 * s), eye_pos + Vector2(2.5 * s, -2.5 * s), OUTLINE_DARK, 2.0 * s)

func _draw_combat_motion_arcs(
	canvas: CanvasItem,
	unit: BattleSimulation.SimUnit,
	wpn_key: String,
	p_shoulder: Vector2,
	p_hand_l: Vector2,
	wpn_angle: float,
	facing: float,
	s: float,
	is_orc: bool
) -> void:
	if unit.is_blocking:
		var c: Vector2 = p_hand_l + Vector2(facing * 12.0 * s, -4.0 * s)
		canvas.draw_circle(c, 32.0 * s, Color(1.0, 0.88, 0.32, 0.28))
		canvas.draw_arc(
			c,
			32.0 * s,
			-1.15 if facing > 0 else PI - 1.15,
			1.15 if facing > 0 else PI + 1.15,
			16,
			Color(1.0, 0.95, 0.55, 0.92),
			3.8 * s
		)

	if unit.anim_state == "ATTACK_1" or unit.anim_state == "ATTACK_2":
		var t_norm: float = unit.anim_time / maxf(0.01, unit.anim_duration)
		if t_norm >= 0.24 and t_norm <= 0.74:
			var alpha: float = sin((t_norm - 0.24) / 0.50 * PI)
			var arc_radius: float = 64.0 * s
			var start_a: float = wpn_angle - 1.38 * facing
			var end_a: float = wpn_angle + 0.18 * facing
			if start_a > end_a:
				var tmp: float = start_a
				start_a = end_a
				end_a = tmp
			var ribbon_outer := Color(1.0, 0.78, 0.22, alpha * 0.75)
			if wpn_key == "wpn_sunfire_greatsword":
				ribbon_outer = Color(1.0, 0.38, 0.12, alpha * 0.82)
			elif wpn_key == "wpn_frostbite_reaver":
				ribbon_outer = Color(0.24, 0.88, 1.0, alpha * 0.82)
			elif is_orc:
				ribbon_outer = Color(0.88, 0.32, 0.95, alpha * 0.78)
			var ribbon_core := Color(1.0, 0.98, 0.90, alpha * 0.94)
			canvas.draw_arc(p_shoulder, arc_radius, start_a, end_a, 16, ribbon_outer, 13.0 * s)
			canvas.draw_arc(p_shoulder, arc_radius + 3.2 * s, start_a + 0.08, end_a, 14, ribbon_core, 4.5 * s)

static func draw_equipment_preview(canvas: CanvasItem, item_id: String, dst_rect: Rect2) -> void:
	ensure_atlas_ready()
	if _modular_atlas_tex == null:
		return
	var key: String = item_id
	if not _part_rects.has(key):
		key = "wpn_aethel_blade"
	var src_r: Rect2 = _part_rects[key]
	# Fit aspect ratio cleanly inside dst_rect
	var aspect: float = src_r.size.x / maxf(1.0, src_r.size.y)
	var target_w: float = dst_rect.size.x
	var target_h: float = dst_rect.size.y
	if aspect > 1.0:
		target_h = target_w / aspect
	else:
		target_w = target_h * aspect
	var draw_pos := dst_rect.position + (dst_rect.size - Vector2(target_w, target_h)) * 0.5
	canvas.draw_texture_rect_region(_modular_atlas_tex, Rect2(draw_pos, Vector2(target_w, target_h)), src_r)

func _draw_debug_skeleton(canvas: CanvasItem, s: float) -> void:
	for i in range(12):
		var col: Color = Color(0.2, 1.0, 0.4) if i < 4 else (Color(0.3, 0.85, 1.0) if i < 8 else Color(1.0, 0.85, 0.2))
		canvas.draw_line(bone_start[i], bone_end[i], OUTLINE_DARK, 4.2)
		canvas.draw_line(bone_start[i], bone_end[i], col, 2.4)
		canvas.draw_circle(bone_start[i], 3.4 * s, Color(1.0, 0.25, 0.5))
		canvas.draw_circle(bone_end[i], 2.8 * s, Color.WHITE)
