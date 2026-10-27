extends Node

# ============================================================================
# CONTENT DATABASE & EXTENSIBLE DATA ARCHITECTURE (Milestone 1 - Requirement 5)
# Designed so new Units, Monsters, Bosses, Equipment, Skills, Evolution Trees,
# Buildings, and Maps can be added purely via data dictionaries/JSON without
# rewriting simulation or rendering code.
# ============================================================================

const SCHEMA_VERSION: int = 1

# 6 Modular Equipment Socket Keys
const SOCKET_MAIN_WEAPON: String = "main_weapon"
const SOCKET_OFFHAND: String = "offhand"
const SOCKET_HELMET: String = "helmet"
const SOCKET_CHEST_ARMOR: String = "chest_armor"
const SOCKET_PAULDRON: String = "pauldron"
const SOCKET_BACK_CAPE: String = "back_cape"

const SOCKET_LIST: Array[String] = [
	SOCKET_MAIN_WEAPON,
	SOCKET_OFFHAND,
	SOCKET_HELMET,
	SOCKET_CHEST_ARMOR,
	SOCKET_PAULDRON,
	SOCKET_BACK_CAPE
]

# 1. MODULAR EQUIPMENT CATALOG (6 Sockets with Stat & Visual Definitions)
const EQUIPMENT: Dictionary = {
	# --- SOCKET 1: MAIN WEAPONS ---
	"wpn_aethel_blade": {
		"id": "wpn_aethel_blade",
		"socket": SOCKET_MAIN_WEAPON,
		"name": "Kiếm Tinh Thạch (Aethel Longsword)",
		"style": "LONGSWORD",
		"length": 54.0,
		"width": 7.5,
		"damage_bonus": 12.0,
		"reach_bonus": 8.0,
		"speed_mult": 1.0,
		"blade_color": Color(0.82, 0.92, 1.0),
		"glow_color": Color(0.20, 0.85, 1.0),
		"hilt_color": Color(0.95, 0.78, 0.25)
	},
	"wpn_crimson_greatsword": {
		"id": "wpn_crimson_greatsword",
		"socket": SOCKET_MAIN_WEAPON,
		"name": "Đại Đao Hỏa Long (Crimson Cleaver)",
		"style": "GREATSWORD",
		"length": 66.0,
		"width": 11.5,
		"damage_bonus": 24.0,
		"reach_bonus": 16.0,
		"speed_mult": 0.88,
		"blade_color": Color(0.28, 0.18, 0.22),
		"glow_color": Color(1.0, 0.36, 0.10),
		"hilt_color": Color(0.92, 0.65, 0.18)
	},
	"wpn_thunder_halberd": {
		"id": "wpn_thunder_halberd",
		"socket": SOCKET_MAIN_WEAPON,
		"name": "Chiến Kích Lôi Đình (Thunder Halberd)",
		"style": "SPEAR_HALBERD",
		"length": 74.0,
		"width": 8.5,
		"damage_bonus": 18.0,
		"reach_bonus": 24.0,
		"speed_mult": 0.94,
		"blade_color": Color(0.95, 0.92, 0.55),
		"glow_color": Color(0.85, 0.55, 1.0),
		"hilt_color": Color(0.55, 0.42, 0.28)
	},
	"wpn_obsidian_reaver": {
		"id": "wpn_obsidian_reaver",
		"socket": SOCKET_MAIN_WEAPON,
		"name": "Song Đoản Đao Hắc Ám (Void Reaver)",
		"style": "CURVED_REAVER",
		"length": 50.0,
		"width": 8.0,
		"damage_bonus": 15.0,
		"reach_bonus": 4.0,
		"speed_mult": 1.15,
		"blade_color": Color(0.18, 0.12, 0.26),
		"glow_color": Color(0.95, 0.22, 0.45),
		"hilt_color": Color(0.65, 0.20, 0.35)
	},

	# --- SOCKET 2: OFFHAND (SHIELDS & PARRY GEAR) ---
	"off_none": {
		"id": "off_none",
		"socket": SOCKET_OFFHAND,
		"name": "Tay Không (Cơ Động)",
		"style": "NONE",
		"hp_bonus": 0.0,
		"block_reduction": 0.35,
		"primary_color": Color.TRANSPARENT,
		"trim_color": Color.TRANSPARENT
	},
	"off_aegis_buckler": {
		"id": "off_aegis_buckler",
		"socket": SOCKET_OFFHAND,
		"name": "Khiên Tinh Thạch (Aegis Kite Shield)",
		"style": "KITE_SHIELD",
		"hp_bonus": 60.0,
		"block_reduction": 0.65,
		"primary_color": Color(0.18, 0.32, 0.52),
		"trim_color": Color(0.30, 0.88, 1.0)
	},
	"off_royal_tower": {
		"id": "off_royal_tower",
		"socket": SOCKET_OFFHAND,
		"name": "Khiên Tháp Hoàng Kim (Golden Bastion)",
		"style": "TOWER_SHIELD",
		"hp_bonus": 120.0,
		"block_reduction": 0.80,
		"primary_color": Color(0.26, 0.22, 0.16),
		"trim_color": Color(1.0, 0.82, 0.24)
	},
	"off_parry_dagger": {
		"id": "off_parry_dagger",
		"socket": SOCKET_OFFHAND,
		"name": "Đoản Kiếm Phản Đòn (Twin Fang)",
		"style": "OFF_BLADE",
		"hp_bonus": 20.0,
		"block_reduction": 0.50,
		"primary_color": Color(0.85, 0.92, 1.0),
		"trim_color": Color(0.25, 0.95, 0.70)
	},

	# --- SOCKET 3: HELMET / HEADGEAR ---
	"hlm_none": {
		"id": "hlm_none",
		"socket": SOCKET_HELMET,
		"name": "Không Đội Mũ (Mắt Phát Sáng)",
		"style": "NONE",
		"hp_bonus": 0.0,
		"primary_color": Color.TRANSPARENT,
		"plume_color": Color.TRANSPARENT
	},
	"hlm_vanguard_visor": {
		"id": "hlm_vanguard_visor",
		"socket": SOCKET_HELMET,
		"name": "Mũ Hiệp Sĩ Tiên Phong (Vanguard Helm)",
		"style": "KNIGHT_VISOR",
		"hp_bonus": 35.0,
		"primary_color": Color(0.68, 0.78, 0.90),
		"plume_color": Color(0.22, 0.86, 1.0)
	},
	"hlm_spartan_crest": {
		"id": "hlm_spartan_crest",
		"socket": SOCKET_HELMET,
		"name": "Mũ Chiến Thần Bờm Đỏ (Grand Crest)",
		"style": "SPARTAN_CREST",
		"hp_bonus": 55.0,
		"primary_color": Color(1.0, 0.82, 0.25),
		"plume_color": Color(0.96, 0.20, 0.22)
	},
	"hlm_abyss_horns": {
		"id": "hlm_abyss_horns",
		"socket": SOCKET_HELMET,
		"name": "Vương Miện Sừng Ma (Abyssal Horns)",
		"style": "DEMON_HORNS",
		"hp_bonus": 45.0,
		"primary_color": Color(0.24, 0.16, 0.30),
		"plume_color": Color(1.0, 0.32, 0.20)
	},

	# --- SOCKET 4: CHEST ARMOR ---
	"arm_light_tunic": {
		"id": "arm_light_tunic",
		"socket": SOCKET_CHEST_ARMOR,
		"name": "Giáp Đai Nhẹ (Scout Harness)",
		"style": "HARNESS",
		"hp_bonus": 20.0,
		"armor_reduction": 0.05,
		"primary_color": Color(0.22, 0.28, 0.38),
		"core_color": Color(0.25, 0.85, 1.0)
	},
	"arm_aethel_cuirass": {
		"id": "arm_aethel_cuirass",
		"socket": SOCKET_CHEST_ARMOR,
		"name": "Giáp Tinh Thạch (Aethel Cuirass)",
		"style": "CUIRASS",
		"hp_bonus": 65.0,
		"armor_reduction": 0.15,
		"primary_color": Color(0.58, 0.68, 0.82),
		"core_color": Color(0.20, 0.92, 1.0)
	},
	"arm_royal_plate": {
		"id": "arm_royal_plate",
		"socket": SOCKET_CHEST_ARMOR,
		"name": "Chiến Giáp Hoàng Kim (Sunplate Armor)",
		"style": "HEAVY_PLATE",
		"hp_bonus": 110.0,
		"armor_reduction": 0.25,
		"primary_color": Color(0.95, 0.78, 0.24),
		"core_color": Color(1.0, 0.45, 0.15)
	},

	# --- SOCKET 5: SHOULDER PAULDRONS ---
	"pld_none": {
		"id": "pld_none",
		"socket": SOCKET_PAULDRON,
		"name": "Không Giáp Vai",
		"style": "NONE",
		"hp_bonus": 0.0,
		"primary_color": Color.TRANSPARENT,
		"trim_color": Color.TRANSPARENT
	},
	"pld_steel_spaulders": {
		"id": "pld_steel_spaulders",
		"socket": SOCKET_PAULDRON,
		"name": "Giáp Vai Hiệp Sĩ (Steel Spaulders)",
		"style": "KNIGHT_SPAULDER",
		"hp_bonus": 30.0,
		"primary_color": Color(0.62, 0.72, 0.86),
		"trim_color": Color(0.25, 0.86, 1.0)
	},
	"pld_dragon_wings": {
		"id": "pld_dragon_wings",
		"socket": SOCKET_PAULDRON,
		"name": "Giáp Vai Cánh Rồng (Dragonscale Guard)",
		"style": "WINGED_PAULDRON",
		"hp_bonus": 50.0,
		"primary_color": Color(0.96, 0.78, 0.22),
		"trim_color": Color(1.0, 0.30, 0.18)
	},

	# --- SOCKET 6: BACK CAPE / ACCESSORY ---
	"cpe_none": {
		"id": "cpe_none",
		"socket": SOCKET_BACK_CAPE,
		"name": "Không Áo Choàng",
		"style": "NONE",
		"speed_bonus": 0.0,
		"primary_color": Color.TRANSPARENT,
		"secondary_color": Color.TRANSPARENT
	},
	"cpe_wind_scarf": {
		"id": "cpe_wind_scarf",
		"socket": SOCKET_BACK_CAPE,
		"name": "Khăn Choàng Gió (Windrunner Scarf)",
		"style": "SCARF",
		"speed_bonus": 15.0,
		"primary_color": Color(0.20, 0.82, 0.98),
		"secondary_color": Color(0.10, 0.45, 0.72)
	},
	"cpe_royal_mantle": {
		"id": "cpe_royal_mantle",
		"socket": SOCKET_BACK_CAPE,
		"name": "Áo Choàng Đại Tướng (Crimson Mantle)",
		"style": "FULL_CAPE",
		"speed_bonus": 8.0,
		"primary_color": Color(0.85, 0.16, 0.22),
		"secondary_color": Color(1.0, 0.80, 0.22)
	},
	"cpe_aether_halo": {
		"id": "cpe_aether_halo",
		"socket": SOCKET_BACK_CAPE,
		"name": "Vòng Thánh Quang Tinh Thạch (Aether Halo)",
		"style": "AETHER_HALO",
		"speed_bonus": 12.0,
		"primary_color": Color(0.35, 0.95, 1.0),
		"secondary_color": Color(1.0, 0.92, 0.40)
	}
}

# 2. PLAYER UNIT ARCHETYPES (Extensible Schema for Milestone 1..5)
const UNITS: Dictionary = {
	"vanguard_hero": {
		"id": "vanguard_hero",
		"name": "Chiến Binh Tinh Thạch (Aethel Vanguard)",
		"role": "MELEE_DUELIST",
		"base_hp": 320.0,
		"base_damage": 34.0,
		"base_speed": 210.0,
		"attack_range": 74.0,
		"scale": 1.0,
		"body_color": Color(0.13, 0.16, 0.24),
		"limb_highlight": Color(0.24, 0.30, 0.44),
		"eye_color": Color(0.25, 0.92, 1.0),
		"default_loadout": {
			SOCKET_MAIN_WEAPON: "wpn_aethel_blade",
			SOCKET_OFFHAND: "off_aegis_buckler",
			SOCKET_HELMET: "hlm_vanguard_visor",
			SOCKET_CHEST_ARMOR: "arm_aethel_cuirass",
			SOCKET_PAULDRON: "pld_steel_spaulders",
			SOCKET_BACK_CAPE: "cpe_wind_scarf"
		}
	}
}

# 3. ENEMY MONSTER ARCHETYPES (Extensible Schema)
const MONSTERS: Dictionary = {
	"abyssal_challenger": {
		"id": "abyssal_challenger",
		"name": "Kẻ Thách Đấu Hắc Ám (Abyssal Challenger)",
		"role": "AI_DUELIST",
		"base_hp": 320.0,
		"base_damage": 32.0,
		"base_speed": 195.0,
		"attack_range": 74.0,
		"scale": 1.02,
		"body_color": Color(0.18, 0.11, 0.16),
		"limb_highlight": Color(0.34, 0.18, 0.26),
		"eye_color": Color(1.0, 0.26, 0.22),
		"default_loadout": {
			SOCKET_MAIN_WEAPON: "wpn_crimson_greatsword",
			SOCKET_OFFHAND: "off_parry_dagger",
			SOCKET_HELMET: "hlm_abyss_horns",
			SOCKET_CHEST_ARMOR: "arm_royal_plate",
			SOCKET_PAULDRON: "pld_dragon_wings",
			SOCKET_BACK_CAPE: "cpe_royal_mantle"
		}
	}
}

# 4. EXTENSIBLE PLACEHOLDER REGISTRIES FOR FUTURE MILESTONES (2..5)
const BOSSES: Dictionary = {
	"molten_colossus": {
		"id": "molten_colossus",
		"name": "Khổng Lồ Dung Nham",
		"scale": 1.95,
		"telegraph_radius": 150.0
	}
}

const SKILLS: Dictionary = {
	"slash_combo": {"id": "slash_combo", "name": "Liên Hoàn Trảm", "cooldown": 0.45},
	"lunge_cleave": {"id": "lunge_cleave", "name": "Phá Giáp Đột Kích", "cooldown": 3.5}
}

const EVOLUTION_TREES: Dictionary = {
	"vanguard_hero": {
		"tier_1": "Kiếm Sĩ Tiên Phong",
		"tier_2": "Hiệp Sĩ Tinh Thạch",
		"tier_3_branches": ["Thánh Kiếm Sư", "Song Kiếm Ảnh Vũ"]
	}
}

const BUILDINGS: Dictionary = {
	"aethel_bastion": {"id": "aethel_bastion", "name": "Pháo Đài Tinh Thạch", "base_hp": 2200.0}
}

const MAPS: Dictionary = {
	"twilight_ruins": {
		"id": "twilight_ruins",
		"name": "Thánh Tích Hoàng Hôn (Twilight Aethel Ruins)",
		"width": 2400.0,
		"ground_y": 500.0,
		"sky_top": Color(0.05, 0.08, 0.16),
		"sky_horizon": Color(0.16, 0.24, 0.40),
		"ground_color": Color(0.14, 0.17, 0.23)
	}
}

func get_items_for_socket(socket_key: String) -> Array[String]:
	var result: Array[String] = []
	for item_id in EQUIPMENT.keys():
		if str(EQUIPMENT[item_id]["socket"]) == socket_key:
			result.append(str(item_id))
	return result

func validate_all_schemas() -> Dictionary:
	var errors: Array[String] = []
	for item_id in EQUIPMENT.keys():
		var item: Dictionary = EQUIPMENT[item_id]
		if not item.has("socket") or not (str(item["socket"]) in SOCKET_LIST):
			errors.append("Invalid socket on equipment: " + str(item_id))
	for uid in UNITS.keys():
		var u: Dictionary = UNITS[uid]
		var ld: Dictionary = u.get("default_loadout", {})
		for sk in SOCKET_LIST:
			if not ld.has(sk) or not EQUIPMENT.has(str(ld[sk])):
				errors.append("Missing socket %s on unit %s" % [sk, uid])
	return {
		"valid": errors.is_empty(),
		"error_count": errors.size(),
		"errors": errors
	}
