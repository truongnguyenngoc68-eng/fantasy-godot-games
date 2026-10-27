extends Node2D
class_name CatCityIdle

# ============================================================================
# MEOWTOPIA 2.5D ISOMETRIC TYCOON & 4-UI ARCHITECTURE SELECTOR
# - True 2.5D Isometric Diamond Grid + Pre-rendered 256x256 Isometric Packs
# - 4 Distinct Live-Switchable UI Layouts & World Styles (Keys 1/2/3/4 or Top Bar):
#   [UI 1] 🏯 Cổ Phong Giang Nam (Floating Radial Dock + Inspector Card)
#   [UI 2] 🏰 Học Viện Phép Thuật (Left Strategy Sidebar + Right Inspector Split)
#   [UI 3] 🌆 Siêu Đô Thị Tương Lai (Cyber-Glass Telemetry HUD + Minimap Radar)
#   [UI 4] 🌾 Thung Lũng Nông Trại (Cozy Wooden Notebook Deck + Contract Board)
# - Deep Tycoon Gameplay: Supply Chain Crafting + Hero Cat Managers + Tech Tree
# ============================================================================

const SAVE_PATH: String = "user://cat_city_save.json"
const SAVE_VERSION: int = 3
const GROUND_Y: float = 430.0
const MAP_CENTER_X: float = 1400.0
const ISO_TILE_W: float = 152.0
const ISO_TILE_H: float = 78.0

const MAP_TIERS: Array[Dictionary] = [
	{"level": 1, "name": "Cấp 1: Đảo Trung Tâm Khởi Đầu", "half_w": 460.0, "cost": 0, "zoom": 1.0},
	{"level": 2, "name": "Cấp 2: Bến Cảng & Thủy Đình Giang Nam", "half_w": 720.0, "cost": 180, "zoom": 0.94},
	{"level": 3, "name": "Cấp 3: Khu Chế Tác & Suối Khoáng", "half_w": 980.0, "cost": 520, "zoom": 0.88},
	{"level": 4, "name": "Cấp 4: Đại Đô Thị 2.5D & Kỳ Quan", "half_w": 1260.0, "cost": 1350, "zoom": 0.82},
]

# 4 Distinct UI Layouts & Isometric World Packs
const UI_PRESETS: Array[Dictionary] = [
	{
		"id": 1, "code": "oriental",
		"name": "UI 1: 🏯 Cổ Phong Giang Nam",
		"subtitle": "Giao Diện Dock Nổi Vòng Cung + Thẻ Chi Tiết (Tối ưu 85% Tầm Nhìn 2.5D)",
		"pack_main": "oriental", "pack_sub": "parks", "theme_link": "sakura",
		"bg_top": Color(0.14, 0.22, 0.34), "bg_mid": Color(0.26, 0.44, 0.56), "bg_water": Color(0.16, 0.48, 0.62),
		"tile_top": Color(0.58, 0.78, 0.54), "tile_left": Color(0.42, 0.58, 0.38), "tile_right": Color(0.32, 0.46, 0.28),
		"road_col": Color(0.84, 0.78, 0.68), "panel_bg": Color(0.20, 0.13, 0.10, 0.94), "border_col": Color(0.94, 0.74, 0.32)
	},
	{
		"id": 2, "code": "magic",
		"name": "UI 2: 🏰 Học Viện Phép Thuật",
		"subtitle": "Giao Diện Chiến Thuật PC (Sidebar Trái + Bảng Chế Tác & Quản Lý Phải)",
		"pack_main": "magic", "pack_sub": "mansions", "theme_link": "royal_gold",
		"bg_top": Color(0.10, 0.08, 0.24), "bg_mid": Color(0.22, 0.16, 0.42), "bg_water": Color(0.18, 0.26, 0.54),
		"tile_top": Color(0.46, 0.64, 0.48), "tile_left": Color(0.32, 0.46, 0.36), "tile_right": Color(0.24, 0.34, 0.28),
		"road_col": Color(0.66, 0.64, 0.72), "panel_bg": Color(0.14, 0.11, 0.26, 0.95), "border_col": Color(0.78, 0.56, 1.0)
	},
	{
		"id": 3, "code": "modern",
		"name": "UI 3: 🌆 Siêu Đô Thị Tương Lai",
		"subtitle": "Giao Diện Cyber-Glass Tối Giản + Radar Minimap 2.5D & Thẻ Kính Mờ",
		"pack_main": "modern", "pack_sub": "parks", "theme_link": "neon_night",
		"bg_top": Color(0.05, 0.09, 0.18), "bg_mid": Color(0.10, 0.20, 0.36), "bg_water": Color(0.08, 0.36, 0.58),
		"tile_top": Color(0.38, 0.68, 0.62), "tile_left": Color(0.24, 0.46, 0.44), "tile_right": Color(0.18, 0.34, 0.34),
		"road_col": Color(0.36, 0.44, 0.54), "panel_bg": Color(0.07, 0.13, 0.22, 0.90), "border_col": Color(0.22, 0.92, 1.0)
	},
	{
		"id": 4, "code": "farm",
		"name": "UI 4: 🌾 Thung Lũng Nông Trại",
		"subtitle": "Giao Diện Sổ Tay Gỗ Ấm Áp (Thẻ Bài Lớn + Bảng Thương Thuyền Nông Sản)",
		"pack_main": "farm", "pack_sub": "mansions", "theme_link": "sunny",
		"bg_top": Color(0.34, 0.64, 0.88), "bg_mid": Color(0.62, 0.82, 0.94), "bg_water": Color(0.24, 0.62, 0.82),
		"tile_top": Color(0.62, 0.82, 0.44), "tile_left": Color(0.46, 0.64, 0.32), "tile_right": Color(0.36, 0.52, 0.24),
		"road_col": Color(0.88, 0.76, 0.56), "panel_bg": Color(0.32, 0.21, 0.13, 0.96), "border_col": Color(0.96, 0.80, 0.38)
	}
]

const CAT_SKINS: Array[Dictionary] = [
	{"id": "ginger", "name": "🐱 Mèo Cam Mập", "cost": 0, "desc": "Bộ lông cam ấm áp (+0% Xu)", "body": Color(0.98, 0.62, 0.22), "belly": Color(1.0, 0.93, 0.80), "stripe": Color(0.82, 0.40, 0.10), "eye": Color(0.22, 0.58, 0.24), "income_mult": 1.0, "aura": Color(0, 0, 0, 0)},
	{"id": "calico", "name": "🐾 Miu Tam Thể Nhật", "cost": 60, "desc": "Mèo tam thể may mắn (+15% Thu Nhập)", "body": Color(0.98, 0.96, 0.92), "belly": Color(1.0, 0.98, 0.95), "stripe": Color(0.92, 0.48, 0.18), "eye": Color(0.85, 0.55, 0.12), "income_mult": 1.15, "aura": Color(0, 0, 0, 0)},
	{"id": "tuxedo", "name": "🤵 Mèo Mun Áo Vest", "cost": 120, "desc": "Lịch lãm chuẩn quý ông (+25% Thu Nhập)", "body": Color(0.20, 0.22, 0.28), "belly": Color(0.96, 0.96, 0.98), "stripe": Color(0.12, 0.13, 0.18), "eye": Color(0.98, 0.82, 0.18), "income_mult": 1.25, "aura": Color(0, 0, 0, 0)},
	{"id": "persian", "name": "👑 Mèo Trắng Quý Tộc", "cost": 220, "desc": "Lông trắng mắt xanh ngọc (+40% Thu Nhập)", "body": Color(0.97, 0.97, 1.0), "belly": Color(1.0, 1.0, 1.0), "stripe": Color(0.84, 0.88, 0.98), "eye": Color(0.20, 0.68, 0.98), "income_mult": 1.40, "aura": Color(0.65, 0.88, 1.0, 0.22)},
	{"id": "siamese", "name": "💎 Mèo Xiêm Hoàng Gia", "cost": 360, "desc": "Tai socola & mắt sapphire (+60% Thu Nhập)", "body": Color(0.95, 0.89, 0.78), "belly": Color(0.98, 0.94, 0.86), "stripe": Color(0.38, 0.24, 0.18), "eye": Color(0.18, 0.60, 0.98), "income_mult": 1.60, "aura": Color(0.35, 0.75, 1.0, 0.25)},
	{"id": "sakura_pink", "name": "🌸 Mèo Hồng Anh Đào", "cost": 520, "desc": "Lông hồng phấn tỏa hương (+85% Thu Nhập)", "body": Color(1.0, 0.74, 0.86), "belly": Color(1.0, 0.92, 0.96), "stripe": Color(0.94, 0.44, 0.68), "eye": Color(0.72, 0.24, 0.62), "income_mult": 1.85, "aura": Color(1.0, 0.58, 0.82, 0.30)},
	{"id": "galaxy", "name": "🌌 Mèo Vũ Trụ Galaxy", "cost": 780, "desc": "Lông tím ngân hà lấp lánh (+120% Thu Nhập)", "body": Color(0.36, 0.22, 0.68), "belly": Color(0.62, 0.48, 0.94), "stripe": Color(0.22, 0.86, 0.98), "eye": Color(1.0, 0.92, 0.28), "income_mult": 2.20, "aura": Color(0.56, 0.36, 1.0, 0.38)},
	{"id": "lucky_gold", "name": "✨ Mèo Thần Tài Hoàng Kim", "cost": 1150, "desc": "Skin Huyền Thoại vàng ròng (+175% Thu Nhập)", "body": Color(1.0, 0.84, 0.22), "belly": Color(1.0, 0.96, 0.78), "stripe": Color(0.92, 0.24, 0.20), "eye": Color(0.88, 0.18, 0.18), "income_mult": 2.75, "aura": Color(1.0, 0.88, 0.22, 0.45)}
]

const COSTUME_SKINS: Array[Dictionary] = [
	{"id": "none", "name": "🐾 Tự Nhiên Đáng Yêu", "cost": 0, "desc": "Không đội mũ, giữ nét mộc mạc", "bonus": 0.0},
	{"id": "red_bow", "name": "🎀 Nơ Đỏ Chuông Vàng", "cost": 80, "desc": "Đeo nơ đỏ và lục lạc vàng (+12% Xu)", "bonus": 0.12},
	{"id": "cool_shades", "name": "🕶️ Kính Râm Idol Ngầu", "cost": 180, "desc": "Mèo đeo kính đen dạo phố (+25% Xu)", "bonus": 0.25},
	{"id": "wizard_hat", "name": "🧙 Mũ Phù Thủy Ánh Sao", "cost": 340, "desc": "Mũ phép thuật tím điểm sao (+45% Xu)", "bonus": 0.45},
	{"id": "royal_crown", "name": "👑 Vương Miện Hoàng Thượng", "cost": 600, "desc": "Vương miện vàng đính ngọc (+75% Xu)", "bonus": 0.75},
	{"id": "angel_halo", "name": "👼 Cánh Thiên Thần & Hào Quang", "cost": 980, "desc": "Đôi cánh trắng & hào quang (+120% Xu)", "bonus": 1.20}
]

const CITY_THEME_SKINS: Array[Dictionary] = [
	{"id": "sunny", "name": "☀️ Thung Lũng Nắng Ấm", "cost": 0, "desc": "Nắng ấm cổ điển & đồng cỏ xanh", "bonus": 0.0, "particle_col": Color(1.0, 0.95, 0.70)},
	{"id": "sakura", "name": "🌸 Giang Nam Hoa Anh Đào", "cost": 150, "desc": "Cánh hoa đào bay & thủy đình (+20% Xu)", "bonus": 0.20, "particle_col": Color(1.0, 0.72, 0.86)},
	{"id": "neon_night", "name": "🌃 Đô Thị Tương Lai Cyber", "cost": 320, "desc": "Đêm ánh sáng hào quang & tháp kính (+40% Xu)", "bonus": 0.40, "particle_col": Color(0.35, 0.96, 1.0)},
	{"id": "snow_xmas", "name": "❄️ Thành Cổ Tuyết Trắng", "cost": 520, "desc": "Tuyết rơi lãng mạn trên mái ngói (+65% Xu)", "bonus": 0.65, "particle_col": Color(1.0, 1.0, 1.0)},
	{"id": "candy_land", "name": "🍬 Đảo Nghỉ Dưỡng Pastel", "cost": 780, "desc": "Sắc màu lễ hội rực rỡ (+95% Xu)", "bonus": 0.95, "particle_col": Color(1.0, 0.88, 0.42)},
	{"id": "royal_gold", "name": "👑 Học Viện Hoàng Kim", "cost": 1200, "desc": "Lâu đài phép thuật & hoàng hôn vàng (+150% Xu)", "bonus": 1.50, "particle_col": Color(1.0, 0.90, 0.28)}
]

# 8 Isometric Districts with grid coords (gx, gy) and per-pack sprite cell evolutions [col, row]
const BUILDING_DEFS: Array[Dictionary] = [
	{
		"id": "feeder", "name": "🍲 Thủy Đình & Trạm Lương Thực",
		"desc": "Sản xuất 🐟 Cá Tươi & 🌾 Lúa Mạch nuôi mèo và cung cấp nguyên liệu chế tác",
		"x": 1165.0, "gx": 1, "gy": 2, "req_map": 1, "base_cost": 25, "cost_mult": 1.45, "base_gps": 2.5,
		"prod_type": "raw_fish", "prod_rate": 1.2,
		"cells": {
			"oriental": [Vector2i(2, 0), Vector2i(0, 4), Vector2i(3, 4)],
			"magic": [Vector2i(1, 1), Vector2i(0, 4), Vector2i(3, 4)],
			"modern": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 0)],
			"farm": [Vector2i(1, 4), Vector2i(4, 2), Vector2i(0, 1)]
		}
	},
	{
		"id": "house", "name": "🏠 Dinh Thự & Học Viện Mèo",
		"desc": "Tăng giới hạn dân số Mèo (+2 Mèo/cấp) & tiến hóa từ trang viên lên Đại Dinh Thự 2.5D",
		"x": 1400.0, "gx": 2, "gy": 2, "req_map": 1, "base_cost": 35, "cost_mult": 1.50, "base_gps": 3.5,
		"prod_type": "raw_herb", "prod_rate": 0.8,
		"cells": {
			"oriental": [Vector2i(1, 3), Vector2i(4, 1), Vector2i(4, 0)],
			"magic": [Vector2i(3, 3), Vector2i(1, 2), Vector2i(3, 0)],
			"modern": [Vector2i(1, 3), Vector2i(2, 3), Vector2i(0, 0)],
			"farm": [Vector2i(0, 2), Vector2i(2, 2), Vector2i(3, 4)]
		}
	},
	{
		"id": "playground", "name": "🧶 Quảng Trường & Khu Vui Chơi",
		"desc": "Tăng Hạnh Phúc toàn thành phố & thu hút du khách thưởng ngoạn",
		"x": 1635.0, "gx": 3, "gy": 2, "req_map": 1, "base_cost": 45, "cost_mult": 1.50, "base_gps": 5.0,
		"prod_type": "essence", "prod_rate": 0.6,
		"cells": {
			"oriental": [Vector2i(2, 1), Vector2i(3, 2), Vector2i(4, 5)],
			"magic": [Vector2i(3, 2), Vector2i(2, 1), Vector2i(4, 5)],
			"modern": [Vector2i(0, 1), Vector2i(3, 2), Vector2i(4, 5)],
			"farm": [Vector2i(2, 0), Vector2i(0, 3), Vector2i(2, 3)]
		}
	},
	{
		"id": "fish_pond", "name": "🎣 Thủy Các & Bến Cảng",
		"desc": "Khai thác 🐟 Cá Koi Hoàng Gia & mở thương thuyền giao thương đường thủy",
		"x": 930.0, "gx": 0, "gy": 2, "req_map": 2, "base_cost": 120, "cost_mult": 1.55, "base_gps": 14.0,
		"prod_type": "raw_fish", "prod_rate": 2.4,
		"cells": {
			"oriental": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 5)],
			"magic": [Vector2i(4, 0), Vector2i(0, 5), Vector2i(1, 5)],
			"modern": [Vector2i(1, 1), Vector2i(1, 5), Vector2i(0, 5)],
			"farm": [Vector2i(3, 3), Vector2i(1, 4), Vector2i(4, 3)]
		}
	},
	{
		"id": "cat_cafe", "name": "☕ Tửu Lầu & Trà Các Thượng Hạng",
		"desc": "Tăng +15% Tổng Thu Nhập/cấp & chế biến trà bánh cho thương đoàn",
		"x": 1870.0, "gx": 4, "gy": 2, "req_map": 2, "base_cost": 160, "cost_mult": 1.55, "base_gps": 20.0,
		"prod_type": "raw_herb", "prod_rate": 2.0,
		"cells": {
			"oriental": [Vector2i(4, 3), Vector2i(3, 0), Vector2i(1, 0)],
			"magic": [Vector2i(2, 0), Vector2i(2, 2), Vector2i(4, 4)],
			"modern": [Vector2i(4, 3), Vector2i(0, 3), Vector2i(1, 0)],
			"farm": [Vector2i(4, 4), Vector2i(1, 3), Vector2i(4, 3)]
		}
	},
	{
		"id": "bakery", "name": "🥐 Xưởng Luyện Chế & Tiệm Bánh",
		"desc": "Xưởng chế tác Sushi, Bánh Matcha & Bảo Vật xuất khẩu giá trị cao",
		"x": 695.0, "gx": 1, "gy": 1, "req_map": 3, "base_cost": 380, "cost_mult": 1.60, "base_gps": 46.0,
		"prod_type": "essence", "prod_rate": 2.2,
		"cells": {
			"oriental": [Vector2i(2, 4), Vector2i(2, 2), Vector2i(4, 4)],
			"magic": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(1, 0)],
			"modern": [Vector2i(2, 0), Vector2i(4, 4), Vector2i(2, 2)],
			"farm": [Vector2i(0, 4), Vector2i(2, 4), Vector2i(3, 2)]
		}
	},
	{
		"id": "onsen", "name": "♨️ Khu Nghỉ Dưỡng & Kỳ Cảnh",
		"desc": "Suối khoáng & vườn sinh thái giúp Mèo Quản Lý hồi phục 100% năng lượng",
		"x": 2105.0, "gx": 3, "gy": 1, "req_map": 3, "base_cost": 520, "cost_mult": 1.60, "base_gps": 65.0,
		"prod_type": "raw_herb", "prod_rate": 3.0,
		"cells": {
			"oriental": [Vector2i(0, 3), Vector2i(2, 3), Vector2i(3, 5)],
			"magic": [Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 5)],
			"modern": [Vector2i(0, 2), Vector2i(4, 1), Vector2i(3, 5)],
			"farm": [Vector2i(0, 0), Vector2i(3, 0), Vector2i(4, 0)]
		}
	},
	{
		"id": "palace", "name": "🏰 Kỳ Quan Trung Tâm Đại Đô Thị",
		"desc": "Biểu tượng quyền uy tối thượng (+35% Tổng Thu Nhập/cấp & +3 Mèo/cấp)",
		"x": 2340.0, "gx": 2, "gy": 0, "req_map": 4, "base_cost": 1200, "cost_mult": 1.70, "base_gps": 150.0,
		"prod_type": "essence", "prod_rate": 4.5,
		"cells": {
			"oriental": [Vector2i(0, 2), Vector2i(2, 5), Vector2i(0, 0)],
			"magic": [Vector2i(0, 0), Vector2i(4, 1), Vector2i(0, 2)],
			"modern": [Vector2i(1, 2), Vector2i(2, 5), Vector2i(4, 2)],
			"farm": [Vector2i(1, 0), Vector2i(1, 2), Vector2i(0, 5)]
		}
	}
]

# Deep Gameplay 1: Supply Chain Crafting & Trade Recipes
const CRAFT_RECIPES: Array[Dictionary] = [
	{
		"id": "sushi_feast", "name": "🍣 Đại Tiệc Sushi Cá Koi",
		"cost_fish": 8, "cost_herb": 4, "cost_essence": 0,
		"reward_coins": 240, "reward_gems": 2, "desc": "Chế biến từ 8 Cá + 4 Thảo Mộc -> Giao thương nhận +240 Xu & +2 Ngọc"
	},
	{
		"id": "matcha_cake", "name": "🍵 Bánh Matcha Hoàng Gia",
		"cost_fish": 4, "cost_herb": 10, "cost_essence": 3,
		"reward_coins": 480, "reward_gems": 4, "desc": "Chế biến từ 4 Cá + 10 Thảo Mộc + 3 Tinh Hoa -> +480 Xu & +4 Ngọc"
	},
	{
		"id": "arcane_relic", "name": "💎 Bảo Vật Khinh Khí Cầu",
		"cost_fish": 12, "cost_herb": 12, "cost_essence": 10,
		"reward_coins": 1250, "reward_gems": 10, "desc": "Xuất khẩu đường không: 12 Cá + 12 Thảo Mộc + 10 Tinh Hoa -> +1250 Xu & +10 Ngọc"
	}
]

# Deep Gameplay 2: Hero Cat Managers (Governors)
const HERO_MANAGERS: Array[Dictionary] = [
	{"id": "chef_mochi", "name": "👨‍🍳 Bếp Trưởng Mochi", "role": "Quản Lý Lương Thực", "base_cost": 120, "bonus_desc": "+35% Sản lượng Cá & Thảo Mộc/cấp"},
	{"id": "arch_ginger", "name": "👷 Kiến Trúc Sư Cam", "role": "Tổng Công Trình Sư", "base_cost": 180, "bonus_desc": "Giảm 12% giá xây dựng & +25% Xu Công Trình/cấp"},
	{"id": "mage_luna", "name": "🧙 Pháp Sư Ánh Trăng", "role": "Viện Trưởng Nghiên Cứu", "base_cost": 260, "bonus_desc": "+40% Tinh Hoa & Tự Động Chế Tác Đơn Hàng/cấp"},
	{"id": "admiral_snow", "name": "🚢 Đô Đốc Bông Gòn", "role": "Chỉ Huy Thương Thuyền", "base_cost": 400, "bonus_desc": "+50% Thưởng Xuất Khẩu Cảng & Khinh Khí Cầu/cấp"}
]

# Deep Gameplay 3: City Tech & Edicts
const TECH_DEFS: Array[Dictionary] = [
	{"id": "iso_roads", "name": "🛣️ Quy Hoạch Đại Lộ Đá Cẩm Thạch", "cost": 150, "mult": 0.25, "desc": "+25% Tốc độ di chuyển & Thu nhập toàn đô thị"},
	{"id": "water_trade", "name": "⛵ Thương Cảng & Thủy Đội Tự Động", "cost": 320, "mult": 0.40, "desc": "+40% Sản lượng nguyên liệu & mở tàu buôn trên sông"},
	{"id": "guild_craft", "name": "⚗️ Hiệp Hội Luyện Kim & Chế Tác", "cost": 640, "mult": 0.65, "desc": "+65% Giá trị đơn hàng xuất khẩu & tự động giao thương"},
	{"id": "sky_airship", "name": "🎈 Hạm Đội Khinh Khí Cầu Hoàng Gia", "cost": 1100, "mult": 1.10, "desc": "+110% Tổng Thu Nhập Đô Thị & hiệu ứng Kỳ Quan"}
]

# Authoritative Game State
var fish_coins: float = 160.0
var total_coins_earned: float = 160.0
var jade_gems: int = 12
var map_level: int = 1
var ui_style_id: int = 1 # 1..4 live switchable UI & visual architecture
var selected_building_id: String = "house"

var building_levels: Dictionary = {
	"feeder": 1, "house": 1, "playground": 1,
	"fish_pond": 0, "cat_cafe": 0, "bakery": 0, "onsen": 0, "palace": 0
}
var stock_fish: float = 18.0
var stock_herb: float = 12.0
var stock_essence: float = 6.0
var manager_levels: Dictionary = {"chef_mochi": 1, "arch_ginger": 0, "mage_luna": 0, "admiral_snow": 0}
var unlocked_techs: Array[String] = []
var contracts_completed: int = 0

var food_bowl_fill: float = 100.0
var max_food_bowl: float = 100.0
var city_happiness: float = 96.0

var unlocked_cat_skins: Array[String] = ["ginger"]
var active_cat_skin: String = "MIX"
var unlocked_costumes: Array[String] = ["none"]
var active_costume: String = "none"
var unlocked_themes: Array[String] = ["sunny"]
var active_theme: String = "sunny"

var auto_care_enabled: bool = true
var auto_build_enabled: bool = false
var auto_cam_enabled: bool = true
var game_speed: float = 1.0

var cats: Array[Dictionary] = []
var toys: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var sky_particles: Array[Dictionary] = []
var river_boats: Array[Dictionary] = []

var cam_x: float = MAP_CENTER_X
var cam_target_x: float = MAP_CENTER_X
var _tour_timer: float = 0.0
var _tour_index: int = 0
var _time_sec: float = 0.0
var _autosave_timer: float = 0.0
var _ui_refresh_timer: float = 0.0
var _auto_care_timer: float = 0.0
var _auto_build_timer: float = 0.0
var _craft_timer: float = 0.0
var _showcase_cli: bool = false
var _showcase_timer: float = 0.0
var _iso_textures: Dictionary = {}
var _building_screen_rects: Dictionary = {}

# UI References
var _ui_layer: CanvasLayer = null
var _ui_root: Control = null
var _layout_container: Control = null
var _ui_style_buttons: Dictionary = {}
var _lbl_top_coins: Label = null
var _lbl_top_stats: Label = null
var _lbl_top_status: Label = null
var _lbl_inspector_title: Label = null
var _lbl_inspector_body: Label = null
var _btn_inspector_upgrade: Button = null
var _btn_expand_map: Button = null
var _btn_adopt_cat: Button = null
var _btn_open_skins: Button = null
var _btn_open_deep: Button = null
var _btn_auto_care: Button = null
var _btn_auto_build: Button = null
var _btn_auto_cam: Button = null
var _btn_speed: Button = null
var _bldg_buttons: Dictionary = {}
var _toast_panel: PanelContainer = null
var _toast_label: Label = null
var _toast_timer: float = 0.0

var _skin_modal: PanelContainer = null
var _skin_tab_mode: String = "CAT"
var _skin_tab_buttons: Dictionary = {}
var _skin_grid: GridContainer = null
var _lbl_skin_summary: Label = null

var _deep_modal: PanelContainer = null
var _deep_tab_mode: String = "CRAFT" # "CRAFT", "MANAGER", "TECH"
var _deep_tab_buttons: Dictionary = {}
var _deep_grid: GridContainer = null
var _lbl_deep_summary: Label = null

func _ready() -> void:
	seed(20261025)
	_load_iso_textures()
	RenderingServer.set_default_clear_color(Color(0.14, 0.22, 0.34))

	for i in range(8):
		clouds.append({
			"x": 180.0 + float(i) * 340.0,
			"y": 54.0 + float(i % 3) * 28.0,
			"w": 115.0 + float(i % 4) * 24.0,
			"spd": 12.0 + float(i % 3) * 4.5
		})

	for i in range(32):
		sky_particles.append({
			"x": randf_range(0.0, 1280.0),
			"y": randf_range(80.0, 660.0),
			"vx": randf_range(-16.0, 20.0),
			"vy": randf_range(14.0, 32.0),
			"sz": randf_range(2.8, 5.5),
			"phase": randf() * TAU
		})

	for i in range(4):
		river_boats.append({
			"t": float(i) * 0.25,
			"spd": 0.035 + float(i % 2) * 0.012,
			"lane": i % 2
		})

	_build_ui()

	var all_args: PackedStringArray = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--capture-cat-city" in all_args:
		_showcase_cli = true
		_setup_showcase_city_state("--open-skin-shop" in all_args)
	else:
		var loaded: bool = load_game_atomic()
		if not loaded:
			_sync_cat_population()
		_rebuild_active_ui_layout()
		_refresh_all_ui()

func _load_iso_textures() -> void:
	var packs := ["oriental", "magic", "modern", "farm", "parks", "mansions"]
	for p in packs:
		var path: String = "res://assets/iso_packs/iso_pack_%s.png" % p
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path)
			if tex != null:
				_iso_textures[p] = tex

func _exit_tree() -> void:
	if not _showcase_cli and DisplayServer.get_name() != "headless":
		save_game_atomic()
	SoundEngine.shutdown()
	cats.clear()
	toys.clear()
	popups.clear()
	sky_particles.clear()
	_iso_textures.clear()

func _setup_showcase_city_state(open_skins: bool = false) -> void:
	map_level = 4
	fish_coins = 6850.0
	jade_gems = 48
	stock_fish = 85.0
	stock_herb = 64.0
	stock_essence = 42.0
	building_levels["feeder"] = 5
	building_levels["house"] = 5
	building_levels["playground"] = 4
	building_levels["fish_pond"] = 4
	building_levels["cat_cafe"] = 4
	building_levels["bakery"] = 4
	building_levels["onsen"] = 3
	building_levels["palace"] = 4
	manager_levels = {"chef_mochi": 3, "arch_ginger": 2, "mage_luna": 2, "admiral_snow": 2}
	unlocked_techs = ["iso_roads", "water_trade", "guild_craft"]
	contracts_completed = 14
	unlocked_cat_skins = ["ginger", "calico", "tuxedo", "persian", "siamese", "sakura_pink", "galaxy", "lucky_gold"]
	active_cat_skin = "MIX"
	unlocked_costumes = ["none", "red_bow", "cool_shades", "wizard_hat", "royal_crown", "angel_halo"]
	active_costume = "royal_crown"
	unlocked_themes = ["sunny", "sakura", "neon_night", "snow_xmas", "candy_land", "royal_gold"]
	active_theme = "sakura"
	food_bowl_fill = 100.0
	_sync_cat_population()
	_spawn_toy_at(1540.0, "yarn")
	_spawn_toy_at(1320.0, "feather")
	_spawn_popup(Vector2(640.0, 260.0), "🏯 Đô Thị Isometric 2.5D + Chuỗi Chế Tác & Quản Lý Mèo!", Color(1.0, 0.92, 0.32))
	if open_skins and _skin_modal != null:
		_skin_modal.visible = true
	_rebuild_active_ui_layout()
	_refresh_all_ui()

# ============================================================================
# ATOMIC CRASH-SAFE SAVE / LOAD & OFFLINE EARNINGS
# ============================================================================

func capture_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"fish_coins": fish_coins,
		"total_coins_earned": total_coins_earned,
		"jade_gems": jade_gems,
		"map_level": map_level,
		"ui_style_id": ui_style_id,
		"building_levels": building_levels.duplicate(),
		"stock_fish": stock_fish,
		"stock_herb": stock_herb,
		"stock_essence": stock_essence,
		"manager_levels": manager_levels.duplicate(),
		"unlocked_techs": unlocked_techs.duplicate(),
		"contracts_completed": contracts_completed,
		"food_bowl_fill": food_bowl_fill,
		"city_happiness": city_happiness,
		"unlocked_cat_skins": unlocked_cat_skins.duplicate(),
		"active_cat_skin": active_cat_skin,
		"unlocked_costumes": unlocked_costumes.duplicate(),
		"active_costume": active_costume,
		"unlocked_themes": unlocked_themes.duplicate(),
		"active_theme": active_theme,
		"auto_care_enabled": auto_care_enabled,
		"auto_build_enabled": auto_build_enabled,
		"last_save_unix": int(Time.get_unix_time_from_system())
	}

func apply_state(data: Dictionary) -> void:
	fish_coins = maxf(0.0, float(data.get("fish_coins", 160.0)))
	total_coins_earned = maxf(fish_coins, float(data.get("total_coins_earned", fish_coins)))
	jade_gems = maxi(0, int(data.get("jade_gems", 12)))
	map_level = clampi(int(data.get("map_level", 1)), 1, MAP_TIERS.size())
	ui_style_id = clampi(int(data.get("ui_style_id", 1)), 1, 4)

	var saved_b: Variant = data.get("building_levels", {})
	if saved_b is Dictionary:
		for k in building_levels.keys():
			if (saved_b as Dictionary).has(k):
				building_levels[k] = maxi(0, int((saved_b as Dictionary)[k]))

	stock_fish = maxf(0.0, float(data.get("stock_fish", 18.0)))
	stock_herb = maxf(0.0, float(data.get("stock_herb", 12.0)))
	stock_essence = maxf(0.0, float(data.get("stock_essence", 6.0)))
	contracts_completed = maxi(0, int(data.get("contracts_completed", 0)))

	var saved_m: Variant = data.get("manager_levels", {})
	if saved_m is Dictionary:
		for k in manager_levels.keys():
			if (saved_m as Dictionary).has(k):
				manager_levels[k] = maxi(0, int((saved_m as Dictionary)[k]))

	unlocked_techs.clear()
	var raw_t: Variant = data.get("unlocked_techs", [])
	if raw_t is Array:
		for item in (raw_t as Array):
			var s: String = str(item)
			if s != "" and not (s in unlocked_techs):
				unlocked_techs.append(s)

	_load_string_array(data.get("unlocked_cat_skins", ["ginger"]), unlocked_cat_skins, "ginger")
	active_cat_skin = str(data.get("active_cat_skin", "MIX"))
	_load_string_array(data.get("unlocked_costumes", ["none"]), unlocked_costumes, "none")
	active_costume = str(data.get("active_costume", "none"))
	_load_string_array(data.get("unlocked_themes", ["sunny"]), unlocked_themes, "sunny")
	active_theme = str(data.get("active_theme", "sunny"))

	food_bowl_fill = clampf(float(data.get("food_bowl_fill", 100.0)), 0.0, get_max_food_bowl())
	city_happiness = clampf(float(data.get("city_happiness", 95.0)), 40.0, 100.0)
	auto_care_enabled = bool(data.get("auto_care_enabled", true))
	auto_build_enabled = bool(data.get("auto_build_enabled", false))
	_sync_cat_population()

	var last_ts: int = int(data.get("last_save_unix", 0))
	var now_ts: int = int(Time.get_unix_time_from_system())
	if last_ts > 0 and now_ts > last_ts + 5:
		var offline_sec: float = minf(float(now_ts - last_ts), 28800.0)
		var offline_gain: float = floorf(offline_sec * get_coins_per_sec() * 0.65)
		if offline_gain >= 5.0:
			fish_coins += offline_gain
			total_coins_earned += offline_gain
			_show_toast("💤 Đô thị vận hành khi bạn vắng mặt (%ds): +%d Xu Cá Vàng!" % [int(offline_sec), int(offline_gain)])

func _load_string_array(raw: Variant, target: Array[String], fallback_first: String) -> void:
	target.clear()
	if raw is Array:
		for item in (raw as Array):
			var s: String = str(item)
			if s != "" and not (s in target):
				target.append(s)
	if not (fallback_first in target):
		target.insert(0, fallback_first)

func save_game_atomic(path: String = SAVE_PATH) -> Error:
	var data: Dictionary = capture_state()
	var abs_path: String = ProjectSettings.globalize_path(path)
	var tmp_path: String = abs_path + ".tmp"
	var bak_path: String = abs_path + ".bak"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	if not f.store_string(JSON.stringify(data)):
		f.close()
		return ERR_FILE_CANT_WRITE
	f.close()
	if FileAccess.file_exists(abs_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		DirAccess.rename_absolute(abs_path, bak_path)
	return DirAccess.rename_absolute(tmp_path, abs_path)

func load_game_atomic(path: String = SAVE_PATH) -> bool:
	var abs_path: String = ProjectSettings.globalize_path(path)
	for candidate in [abs_path, abs_path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var raw: String = FileAccess.get_file_as_string(candidate)
			var parsed: Variant = JSON.parse_string(raw)
			if parsed is Dictionary and (parsed as Dictionary).has("version"):
				apply_state(parsed as Dictionary)
				return true
	return false

# ============================================================================
# ECONOMY, SUPPLY CHAIN, MANAGERS, TECH & SKIN MULTIPLIERS
# ============================================================================

func get_active_ui_preset() -> Dictionary:
	var idx: int = clampi(ui_style_id - 1, 0, UI_PRESETS.size() - 1)
	return UI_PRESETS[idx]

func get_total_unlocked_skins() -> int:
	return unlocked_cat_skins.size() + unlocked_costumes.size() + unlocked_themes.size()

func get_total_possible_skins() -> int:
	return CAT_SKINS.size() + COSTUME_SKINS.size() + CITY_THEME_SKINS.size()

func get_skin_collection_multiplier() -> float:
	var mult: float = 1.0
	for cs in CAT_SKINS:
		if str(cs["id"]) in unlocked_cat_skins:
			mult += (float(cs["income_mult"]) - 1.0) * 0.35
	for cos in COSTUME_SKINS:
		if str(cos["id"]) in unlocked_costumes:
			mult += float(cos["bonus"]) * 0.50
	for th in CITY_THEME_SKINS:
		if str(th["id"]) in unlocked_themes:
			mult += float(th["bonus"]) * 0.50
	return mult

func get_tech_multiplier() -> float:
	var mult: float = 1.0
	for t in TECH_DEFS:
		if str(t["id"]) in unlocked_techs:
			mult += float(t["mult"])
	return mult

func get_manager_multiplier() -> float:
	var arch_lv: int = int(manager_levels.get("arch_ginger", 0))
	var adm_lv: int = int(manager_levels.get("admiral_snow", 0))
	return 1.0 + float(arch_lv) * 0.25 + float(adm_lv) * 0.20

func get_active_theme_dict() -> Dictionary:
	for th in CITY_THEME_SKINS:
		if str(th["id"]) == active_theme:
			return th
	return CITY_THEME_SKINS[0]

func get_cat_skin_dict_by_id(skin_id: String) -> Dictionary:
	for cs in CAT_SKINS:
		if str(cs["id"]) == skin_id:
			return cs
	return CAT_SKINS[0]

func get_building_def(b_id: String) -> Dictionary:
	for b in BUILDING_DEFS:
		if str(b["id"]) == b_id:
			return b
	return BUILDING_DEFS[0]

func get_map_half_width() -> float:
	var idx: int = clampi(map_level - 1, 0, MAP_TIERS.size() - 1)
	return float(MAP_TIERS[idx]["half_w"])

func get_max_cats() -> int:
	var house_lv: int = int(building_levels.get("house", 1))
	var palace_lv: int = int(building_levels.get("palace", 0))
	return 4 + house_lv * 2 + palace_lv * 3 + (map_level - 1) * 2

func get_max_food_bowl() -> float:
	var feeder_lv: int = maxi(1, int(building_levels.get("feeder", 1)))
	return 90.0 + float(feeder_lv) * 45.0

func get_building_cost(b_id: String) -> int:
	for b in BUILDING_DEFS:
		if str(b["id"]) == b_id:
			var lv: int = int(building_levels.get(b_id, 0))
			var arch_lv: int = int(manager_levels.get("arch_ginger", 0))
			var discount: float = clampf(1.0 - float(arch_lv) * 0.08, 0.60, 1.0)
			return maxi(10, int(round(float(b["base_cost"]) * pow(float(b["cost_mult"]), float(lv)) * discount)))
	return 999999

func get_adopt_cat_cost() -> int:
	var n: int = cats.size()
	return int(round(30.0 * pow(1.30, float(maxi(0, n - 3)))))

func get_manager_cost(m_id: String) -> int:
	for m in HERO_MANAGERS:
		if str(m["id"]) == m_id:
			var lv: int = int(manager_levels.get(m_id, 0))
			return int(round(float(m["base_cost"]) * pow(1.75, float(lv))))
	return 999999

func get_coins_per_sec() -> float:
	var total_gps: float = 3.0
	for b in BUILDING_DEFS:
		var b_id: String = str(b["id"])
		var lv: int = int(building_levels.get(b_id, 0))
		if lv > 0:
			var arch_mult: float = 1.0 + (0.25 if lv >= 3 else 0.0) + (0.50 if lv >= 5 else 0.0)
			total_gps += float(b["base_gps"]) * float(lv) * (1.0 + float(lv - 1) * 0.14) * arch_mult

	var cat_gps: float = 0.0
	for c in cats:
		var cs_dict: Dictionary = get_cat_skin_dict_by_id(str(c.get("skin_id", "ginger")))
		var mult: float = float(cs_dict["income_mult"])
		var happy_ratio: float = clampf(float(c["happiness"]) / 100.0, 0.6, 1.5)
		cat_gps += 2.2 * mult * happy_ratio

	total_gps += cat_gps
	var cafe_lv: int = int(building_levels.get("cat_cafe", 0))
	var palace_lv: int = int(building_levels.get("palace", 0))
	var global_mult: float = (1.0 + float(cafe_lv) * 0.15 + float(palace_lv) * 0.35) * get_skin_collection_multiplier() * get_tech_multiplier() * get_manager_multiplier()
	var happy_bonus: float = 0.80 + (city_happiness / 100.0) * 0.45
	return total_gps * global_mult * happy_bonus

func _sync_cat_population() -> void:
	var target_min: int = mini(get_max_cats(), 4 + int(building_levels.get("house", 1)))
	while cats.size() < target_min:
		_spawn_one_cat()
	_reassign_cat_skins()

func _reassign_cat_skins() -> void:
	if unlocked_cat_skins.is_empty():
		unlocked_cat_skins.append("ginger")
	for i in range(cats.size()):
		if active_cat_skin != "MIX" and (active_cat_skin in unlocked_cat_skins):
			cats[i]["skin_id"] = active_cat_skin
		else:
			cats[i]["skin_id"] = unlocked_cat_skins[i % unlocked_cat_skins.size()]

func _spawn_one_cat() -> Dictionary:
	var idx: int = cats.size()
	var skin_id: String = "ginger"
	if active_cat_skin != "MIX" and (active_cat_skin in unlocked_cat_skins):
		skin_id = active_cat_skin
	elif unlocked_cat_skins.size() > 0:
		skin_id = unlocked_cat_skins[idx % unlocked_cat_skins.size()]

	var hw: float = get_map_half_width() - 80.0
	var start_x: float = MAP_CENTER_X + randf_range(-hw * 0.55, hw * 0.55)
	var lane_y: float = randf_range(-28.0, 52.0)
	var cat_names: Array[String] = [
		"Miu Cam", "Bông Gòn", "Mực Nhỏ", "Mochi", "Bánh Cá", "Đậu Đỏ",
		"Sữa Tươi", "Mật Ong", "Nắng Ấm", "Bơ Sữa", "Trà Sữa", "Phô Mai",
		"Hạt Dẻ", "Mây Trắng", "Vừng Đen", "Hoàng Thượng", "Sakura", "Galaxy"
	]
	var c := {
		"name": cat_names[idx % cat_names.size()],
		"skin_id": skin_id,
		"x": start_x,
		"y_off": lane_y,
		"facing": 1.0 if (idx % 2 == 0) else -1.0,
		"state": "WALK",
		"state_timer": randf_range(1.5, 4.0),
		"target_x": start_x + randf_range(-160.0, 160.0),
		"hunger": randf_range(70.0, 98.0),
		"happiness": randf_range(85.0, 100.0),
		"anim_phase": randf() * TAU,
		"coin_timer": randf_range(1.5, 3.8),
		"Bubble": ""
	}
	cats.append(c)
	return c

# ============================================================================
# ACTIONS: UI SWITCHER, CRAFTING, MANAGERS, TECH, BUILDINGS & SKINS
# ============================================================================

func action_switch_ui_style(style_id: int) -> void:
	ui_style_id = clampi(style_id, 1, UI_PRESETS.size())
	var preset: Dictionary = get_active_ui_preset()
	RenderingServer.set_default_clear_color(preset["bg_top"])
	_rebuild_active_ui_layout()
	_refresh_all_ui()
	_show_toast("🎨 Đã chuyển sang [%s] — %s" % [str(preset["name"]), str(preset["subtitle"])])
	SoundEngine.play_sfx("ui_click")
	queue_redraw()

func action_craft_recipe(recipe_id: String, is_auto: bool = false) -> bool:
	for r in CRAFT_RECIPES:
		if str(r["id"]) == recipe_id:
			var req_f: float = float(r["cost_fish"])
			var req_h: float = float(r["cost_herb"])
			var req_e: float = float(r["cost_essence"])
			if stock_fish < req_f or stock_herb < req_h or stock_essence < req_e:
				if not is_auto:
					_show_toast("📦 Chưa đủ nguyên liệu kho! Cần %d🐟 %d🌾 %d⚡" % [int(req_f), int(req_h), int(req_e)])
				return false
			stock_fish -= req_f
			stock_herb -= req_h
			stock_essence -= req_e
			var adm_lv: int = int(manager_levels.get("admiral_snow", 0))
			var guild_mult: float = 1.65 if ("guild_craft" in unlocked_techs) else 1.0
			var trade_mult: float = (1.0 + float(adm_lv) * 0.50) * guild_mult * get_skin_collection_multiplier()
			var gain_coins: int = int(round(float(r["reward_coins"]) * trade_mult))
			var gain_gems: int = int(r["reward_gems"]) + (1 if adm_lv >= 2 else 0)
			fish_coins += float(gain_coins)
			total_coins_earned += float(gain_coins)
			jade_gems += gain_gems
			contracts_completed += 1
			_spawn_popup(Vector2(640.0, 290.0), "🚢 Xuất Khẩu [%s]: +%d Xu & +%d💎!" % [str(r["name"]), gain_coins, gain_gems], Color(0.45, 1.0, 0.72))
			if not is_auto:
				SoundEngine.play_sfx("parry_clang")
			_refresh_all_ui()
			return true
	return false

func action_hire_manager(m_id: String) -> bool:
	for m in HERO_MANAGERS:
		if str(m["id"]) == m_id:
			var cost: int = get_manager_cost(m_id)
			if fish_coins < float(cost):
				_show_toast("🪙 Cần %d Xu Cá để bổ nhiệm/thăng cấp [%s]!" % [cost, str(m["name"])])
				return false
			fish_coins -= float(cost)
			var new_lv: int = int(manager_levels.get(m_id, 0)) + 1
			manager_levels[m_id] = new_lv
			_show_toast("👑 Đã bổ nhiệm %s lên Cấp %d!" % [str(m["name"]), new_lv])
			SoundEngine.play_sfx("parry_clang")
			save_game_atomic()
			_refresh_all_ui()
			return true
	return false

func action_unlock_tech(tech_id: String) -> bool:
	if tech_id in unlocked_techs:
		return true
	for t in TECH_DEFS:
		if str(t["id"]) == tech_id:
			var cost: int = int(t["cost"])
			if fish_coins < float(cost):
				_show_toast("🪙 Cần %d Xu Cá để nghiên cứu [%s]!" % [cost, str(t["name"])])
				return false
			fish_coins -= float(cost)
			unlocked_techs.append(tech_id)
			_show_toast("📜 ĐÃ BAN HÀNH SẮC LỆNH: %s!" % str(t["name"]))
			SoundEngine.play_sfx("parry_clang")
			save_game_atomic()
			_refresh_all_ui()
			return true
	return false

func action_buy_or_equip_cat_skin(skin_id: String) -> bool:
	if skin_id == "MIX":
		active_cat_skin = "MIX"
		_reassign_cat_skins()
		_refresh_all_ui()
		return true
	var skin_def: Dictionary = get_cat_skin_dict_by_id(skin_id)
	if not (skin_id in unlocked_cat_skins):
		var cost: int = int(skin_def["cost"])
		if fish_coins < float(cost):
			_show_toast("🪙 Cần %d Xu Cá để mở khóa Skin [%s]!" % [cost, str(skin_def["name"])])
			return false
		fish_coins -= float(cost)
		unlocked_cat_skins.append(skin_id)
		_show_toast("🎉 ĐÃ MỞ KHÓA SKIN MÈO: %s!" % str(skin_def["name"]))
		SoundEngine.play_sfx("parry_clang")
	active_cat_skin = skin_id
	_reassign_cat_skins()
	for c in cats:
		c["state"] = "HAPPY_JUMP"
		c["state_timer"] = 1.6
		c["Bubble"] = "✨"
	save_game_atomic()
	_refresh_all_ui()
	return true

func action_buy_or_equip_costume(costume_id: String) -> bool:
	for cos in COSTUME_SKINS:
		if str(cos["id"]) == costume_id:
			if not (costume_id in unlocked_costumes):
				var cost: int = int(cos["cost"])
				if fish_coins < float(cost):
					_show_toast("🪙 Cần %d Xu Cá để mua Phụ Kiện [%s]!" % [cost, str(cos["name"])])
					return false
				fish_coins -= float(cost)
				unlocked_costumes.append(costume_id)
				_show_toast("🎩 ĐÃ SỞ HỮU TRANG PHỤC: %s!" % str(cos["name"]))
				SoundEngine.play_sfx("parry_clang")
			active_costume = costume_id
			for c in cats:
				c["state"] = "HAPPY_JUMP"
				c["state_timer"] = 1.6
				c["Bubble"] = "👑"
			save_game_atomic()
			_refresh_all_ui()
			return true
	return false

func action_buy_or_equip_theme(theme_id: String) -> bool:
	for th in CITY_THEME_SKINS:
		if str(th["id"]) == theme_id:
			if not (theme_id in unlocked_themes):
				var cost: int = int(th["cost"])
				if fish_coins < float(cost):
					_show_toast("🪙 Cần %d Xu Cá để mở khóa Chủ Đề [%s]!" % [cost, str(th["name"])])
					return false
				fish_coins -= float(cost)
				unlocked_themes.append(theme_id)
				_show_toast("🎨 ĐÃ MỞ KHÓA CHỦ ĐỀ: %s!" % str(th["name"]))
				SoundEngine.play_sfx("parry_clang")
			active_theme = theme_id
			save_game_atomic()
			_refresh_all_ui()
			return true
	return false

func action_feed_all_cats(is_auto: bool = false) -> void:
	max_food_bowl = get_max_food_bowl()
	food_bowl_fill = max_food_bowl
	var fed_count: int = 0
	for c in cats:
		if float(c["hunger"]) < 88.0 or not is_auto:
			c["state"] = "WALK"
			c["target_x"] = 1165.0 + randf_range(-55.0, 55.0)
			c["state_timer"] = 2.8
			c["hunger"] = minf(100.0, float(c["hunger"]) + 35.0)
			c["happiness"] = minf(100.0, float(c["happiness"]) + 12.0)
			c["Bubble"] = "🐟"
			fed_count += 1
	var bonus_coins: float = float(maxi(1, fed_count)) * (5.0 + float(building_levels.get("feeder", 1)) * 3.5) * get_skin_collection_multiplier()
	fish_coins += bonus_coins
	total_coins_earned += bonus_coins
	stock_fish += 3.0
	_spawn_popup(Vector2(540.0, 340.0), "🍲 Tiếp Lương Thực Đảo! +%d Xu & +3🐟" % int(bonus_coins), Color(1.0, 0.90, 0.28))
	if not is_auto:
		SoundEngine.play_sfx("ui_click")
	_refresh_all_ui()

func action_play_with_cats(is_auto: bool = false) -> void:
	_spawn_toy_at(1635.0 + randf_range(-90.0, 90.0), "yarn" if (randi() % 2 == 0) else "feather")
	for c in cats:
		c["happiness"] = minf(100.0, float(c["happiness"]) + 18.0)
		c["Bubble"] = "🧶" if (randi() % 2 == 0) else "💕"
		if randf() < 0.65:
			c["state"] = "PLAY"
			c["target_x"] = 1635.0 + randf_range(-85.0, 85.0)
			c["state_timer"] = 3.2
	city_happiness = minf(100.0, city_happiness + 8.0)
	var play_bonus: float = float(cats.size()) * (4.0 + float(building_levels.get("playground", 1)) * 3.0) * get_skin_collection_multiplier()
	fish_coins += play_bonus
	total_coins_earned += play_bonus
	stock_essence += 1.5
	_spawn_popup(Vector2(720.0, 320.0), "🏮 Mở Hội Đèn Lồng! +%d Xu & +1.5⚡" % int(play_bonus), Color(1.0, 0.58, 0.78))
	if not is_auto:
		SoundEngine.play_sfx("ui_click")
	_refresh_all_ui()

func action_adopt_cat() -> bool:
	if cats.size() >= get_max_cats():
		_show_toast("🏠 Dinh Thự đã đầy (%d/%d)! Hãy nâng cấp [Dinh Thự & Học Viện Mèo] nhé!" % [cats.size(), get_max_cats()])
		return false
	var cost: int = get_adopt_cat_cost()
	if fish_coins < float(cost):
		_show_toast("🪙 Cần %d Xu Cá để chiêu mộ công dân mèo mới!" % cost)
		return false
	fish_coins -= float(cost)
	var new_cat: Dictionary = _spawn_one_cat()
	new_cat["state"] = "HAPPY_JUMP"
	new_cat["state_timer"] = 2.0
	new_cat["Bubble"] = "😻"
	var cs_dict: Dictionary = get_cat_skin_dict_by_id(str(new_cat["skin_id"]))
	_spawn_popup(Vector2(640.0, 310.0), "🐱 Đón %s (%s)!" % [str(new_cat["name"]), str(cs_dict["name"])], Color(0.45, 1.0, 0.62))
	SoundEngine.play_sfx("ui_click")
	_refresh_all_ui()
	return true

func action_upgrade_building(b_id: String) -> bool:
	for b in BUILDING_DEFS:
		if str(b["id"]) == b_id:
			selected_building_id = b_id
			var req_map: int = int(b["req_map"])
			if map_level < req_map:
				_show_toast("🗺️ Hãy Mở Rộng Đô Thị lên Cấp %d để mở khóa [%s]!" % [req_map, str(b["name"])])
				return false
			var cost: int = get_building_cost(b_id)
			if fish_coins < float(cost):
				_show_toast("🪙 Cần %d Xu Cá để nâng cấp [%s]!" % [cost, str(b["name"])])
				return false
			fish_coins -= float(cost)
			var new_lv: int = int(building_levels.get(b_id, 0)) + 1
			building_levels[b_id] = new_lv
			if b_id == "house":
				_sync_cat_population()
			elif b_id == "feeder":
				max_food_bowl = get_max_food_bowl()
				food_bowl_fill = max_food_bowl
			var spos: Vector2 = _iso_grid_to_screen(float(b["gx"]), float(b["gy"]))
			var tier_msg: String = "✨ TIẾN HÓA KIẾN TRÚC 2.5D CẤP %d!" % new_lv if (new_lv == 3 or new_lv == 5) else "✨ %s -> Cấp %d!" % [str(b["name"]), new_lv]
			_spawn_popup(spos + Vector2(0, -90), tier_msg, Color(1.0, 0.92, 0.28))
			SoundEngine.play_sfx("ui_click")
			_refresh_all_ui()
			return true
	return false

func action_expand_map() -> bool:
	if map_level >= MAP_TIERS.size():
		_show_toast("👑 Đô Thị Isometric 2.5D đã đạt quy mô tối đa!")
		return false
	var next_tier: Dictionary = MAP_TIERS[map_level]
	var cost: int = int(next_tier["cost"])
	if fish_coins < float(cost):
		_show_toast("🪙 Cần %d Xu Cá để mở rộng lên [%s]!" % [cost, str(next_tier["name"])])
		return false
	fish_coins -= float(cost)
	map_level += 1
	for b in BUILDING_DEFS:
		if int(b["req_map"]) == map_level and int(building_levels.get(str(b["id"]), 0)) == 0:
			building_levels[str(b["id"])] = 1
	_sync_cat_population()
	_show_toast("🎉 ĐÃ MỞ RỘNG ĐÔ THỊ 2.5D: %s!" % str(next_tier["name"]))
	SoundEngine.play_sfx("parry_clang")
	save_game_atomic()
	_refresh_all_ui()
	return true

func _spawn_toy_at(tx: float, kind: String) -> void:
	if toys.size() >= 8:
		toys.remove_at(0)
	toys.append({"x": tx, "vx": randf_range(-60.0, 60.0), "kind": kind, "rot": 0.0, "life": 6.5})

func _spawn_popup(screen_pos: Vector2, text: String, col: Color) -> void:
	if popups.size() >= 30:
		popups.remove_at(0)
	popups.append({"pos": screen_pos, "vel": Vector2(0.0, -42.0), "text": text, "col": col, "life": 0.0, "max_life": 1.35})

func _save_viewport_png(res_path: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(res_path)
		print("Saved UI preview: ", res_path)

# ============================================================================
# MAIN SIMULATION LOOP (CAT AI, SUPPLY CHAIN, AUTO-CARE & AUTO-BUILD)
# ============================================================================

func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.05) * game_speed
	_time_sec += dt

	if _showcase_cli:
		_showcase_timer += delta
		cam_x = MAP_CENTER_X
		_step_cats_and_city(dt)
		var stage: int = int(_showcase_timer / 0.45)
		if stage == 0 and ui_style_id != 1:
			action_switch_ui_style(1)
			_toast_panel.visible = false
		elif stage == 1 and ui_style_id != 2:
			_save_viewport_png("res://ui_preview_1_oriental.png")
			_save_viewport_png("res://bf4_01_cat_city_idle.png")
			action_switch_ui_style(2)
			_toast_panel.visible = false
		elif stage == 2 and ui_style_id != 3:
			_save_viewport_png("res://ui_preview_2_magic.png")
			action_switch_ui_style(3)
			_toast_panel.visible = false
		elif stage == 3 and ui_style_id != 4:
			_save_viewport_png("res://ui_preview_3_modern.png")
			action_switch_ui_style(4)
			_toast_panel.visible = false
		elif stage == 4 and (_deep_modal != null and not _deep_modal.visible):
			_save_viewport_png("res://ui_preview_4_farm.png")
			action_switch_ui_style(1)
			_toast_panel.visible = false
			_deep_modal.visible = true
			_refresh_deep_modal()
		elif stage >= 5:
			_save_viewport_png("res://ui_preview_5_deep_tycoon.png")
			get_tree().quit(0)
		queue_redraw()
		return

	_step_cats_and_city(dt)
	_step_camera(delta)

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_panel != null:
			_toast_panel.visible = false

	_autosave_timer += delta
	if _autosave_timer >= 12.0:
		_autosave_timer = 0.0
		save_game_atomic()

	queue_redraw()

func _step_cats_and_city(dt: float) -> void:
	var gps: float = get_coins_per_sec()
	fish_coins += gps * dt
	total_coins_earned += gps * dt

	# Supply Chain Raw Resource Production
	var chef_mult: float = 1.0 + float(manager_levels.get("chef_mochi", 0)) * 0.35
	var mage_mult: float = 1.0 + float(manager_levels.get("mage_luna", 0)) * 0.40
	var water_mult: float = 1.40 if ("water_trade" in unlocked_techs) else 1.0
	for b in BUILDING_DEFS:
		var lv: int = int(building_levels.get(str(b["id"]), 0))
		if lv > 0:
			var rate: float = float(b["prod_rate"]) * float(lv) * water_mult * dt * 0.35
			var ptype: String = str(b["prod_type"])
			if ptype == "raw_fish":
				stock_fish = minf(999.0, stock_fish + rate * chef_mult)
			elif ptype == "raw_herb":
				stock_herb = minf(999.0, stock_herb + rate * chef_mult)
			elif ptype == "essence":
				stock_essence = minf(999.0, stock_essence + rate * mage_mult)

	# Auto-Crafting if Mage Manager Lv >= 1 or Guild Tech unlocked
	if int(manager_levels.get("mage_luna", 0)) >= 1 or ("guild_craft" in unlocked_techs):
		_craft_timer += dt
		if _craft_timer >= 5.0:
			_craft_timer = 0.0
			if not action_craft_recipe("arcane_relic", true):
				if not action_craft_recipe("matcha_cake", true):
					action_craft_recipe("sushi_feast", true)

	var eat_drain: float = float(cats.size()) * 0.42 * dt
	food_bowl_fill = maxf(0.0, food_bowl_fill - eat_drain)

	if auto_care_enabled:
		_auto_care_timer += dt
		if food_bowl_fill < get_max_food_bowl() * 0.35:
			action_feed_all_cats(true)
		elif _auto_care_timer >= 6.5:
			_auto_care_timer = 0.0
			action_play_with_cats(true)

	if auto_build_enabled:
		_auto_build_timer += dt
		if _auto_build_timer >= 1.4:
			_auto_build_timer = 0.0
			_run_smart_auto_builder()

	for rb in river_boats:
		rb["t"] = fposmod(float(rb["t"]) + float(rb["spd"]) * dt, 1.0)

	var hw: float = get_map_half_width() + 300.0
	for cl in clouds:
		cl["x"] = float(cl["x"]) + float(cl["spd"]) * dt
		if float(cl["x"]) > MAP_CENTER_X + hw:
			cl["x"] = MAP_CENTER_X - hw

	for sp in sky_particles:
		sp["x"] = fposmod(float(sp["x"]) + (float(sp["vx"]) + sin(_time_sec * 2.0 + float(sp["phase"])) * 14.0) * dt, 1280.0)
		sp["y"] = float(sp["y"]) + float(sp["vy"]) * dt
		if float(sp["y"]) > 680.0:
			sp["y"] = 70.0

	var t_idx: int = 0
	while t_idx < toys.size():
		var ty: Dictionary = toys[t_idx]
		ty["life"] = float(ty["life"]) - dt
		if float(ty["life"]) <= 0.0:
			toys.remove_at(t_idx)
		else:
			ty["x"] = clampf(float(ty["x"]) + float(ty["vx"]) * dt, MAP_CENTER_X - 420.0, MAP_CENTER_X + 420.0)
			ty["vx"] = float(ty["vx"]) * (1.0 - 1.2 * dt)
			ty["rot"] = float(ty["rot"]) + float(ty["vx"]) * 0.04 * dt
			t_idx += 1

	var min_x: float = MAP_CENTER_X - 380.0
	var max_x: float = MAP_CENTER_X + 380.0
	var happy_sum: float = 0.0

	for c in cats:
		c["anim_phase"] = float(c["anim_phase"]) + dt * 6.5
		c["hunger"] = maxf(25.0, float(c["hunger"]) - 1.1 * dt)
		c["state_timer"] = float(c["state_timer"]) - dt
		c["coin_timer"] = float(c["coin_timer"]) - dt

		if float(c["coin_timer"]) <= 0.0:
			c["coin_timer"] = randf_range(3.2, 5.6)
			var cs_dict: Dictionary = get_cat_skin_dict_by_id(str(c.get("skin_id", "ginger")))
			var drop_val: int = maxi(2, int(round(4.0 * float(cs_dict["income_mult"]) * float(map_level))))
			fish_coins += float(drop_val)
			total_coins_earned += float(drop_val)
			if popups.size() < 10:
				var cpos: Vector2 = _cat_world_to_screen(c)
				_spawn_popup(cpos + Vector2(0, -34.0), "🪙 +%d" % drop_val, Color(1.0, 0.92, 0.28))

		if float(c["state_timer"]) <= 0.0:
			if float(c["hunger"]) < 55.0 and food_bowl_fill > 5.0:
				c["state"] = "EAT"
				c["target_x"] = 1240.0 + randf_range(-48.0, 48.0)
				c["state_timer"] = randf_range(2.4, 3.8)
				c["Bubble"] = "🐟"
			elif toys.size() > 0 and randf() < 0.55:
				var toy_ref: Dictionary = toys[randi() % toys.size()]
				c["state"] = "PLAY"
				c["target_x"] = float(toy_ref["x"]) + randf_range(-28.0, 28.0)
				c["state_timer"] = randf_range(2.2, 3.6)
				c["Bubble"] = "🧶"
			elif randf() < 0.20:
				c["state"] = "SLEEP"
				c["state_timer"] = randf_range(2.5, 4.2)
				c["Bubble"] = "💤"
			else:
				c["state"] = "WALK"
				c["target_x"] = randf_range(min_x, max_x)
				c["state_timer"] = randf_range(2.2, 4.5)
				c["Bubble"] = "🎵" if (randf() < 0.35) else ""

		var st: String = str(c["state"])
		if st == "WALK" or st == "PLAY" or st == "EAT":
			var tx: float = clampf(float(c["target_x"]), min_x, max_x)
			var dx: float = tx - float(c["x"])
			if absf(dx) > 6.0:
				var spd: float = 95.0 if st == "PLAY" else 62.0
				var dir: float = signf(dx)
				c["facing"] = dir
				c["x"] = clampf(float(c["x"]) + dir * spd * dt, min_x, max_x)
			elif st == "EAT" and food_bowl_fill > 0.0:
				c["hunger"] = minf(100.0, float(c["hunger"]) + 28.0 * dt)
				c["happiness"] = minf(100.0, float(c["happiness"]) + 10.0 * dt)

		happy_sum += float(c["happiness"])

	if cats.size() > 0:
		city_happiness = happy_sum / float(cats.size())

	var p_idx: int = 0
	while p_idx < popups.size():
		var pp: Dictionary = popups[p_idx]
		pp["life"] = float(pp["life"]) + dt
		if float(pp["life"]) >= float(pp["max_life"]):
			popups.remove_at(p_idx)
		else:
			pp["pos"] = (pp["pos"] as Vector2) + (pp["vel"] as Vector2) * dt
			p_idx += 1

	_ui_refresh_timer += dt
	if _ui_refresh_timer >= 0.22:
		_ui_refresh_timer = 0.0
		_refresh_top_labels()

func _run_smart_auto_builder() -> void:
	if map_level < MAP_TIERS.size():
		var exp_cost: int = int(MAP_TIERS[map_level]["cost"])
		if fish_coins >= float(exp_cost):
			action_expand_map()
			return
	for t in TECH_DEFS:
		var tid: String = str(t["id"])
		if not (tid in unlocked_techs) and fish_coins >= float(t["cost"]) * 1.15:
			action_unlock_tech(tid)
			return
	for m in HERO_MANAGERS:
		var mid: String = str(m["id"])
		var mcost: int = get_manager_cost(mid)
		if fish_coins >= float(mcost) * 1.25:
			action_hire_manager(mid)
			return
	if cats.size() < get_max_cats() and fish_coins >= float(get_adopt_cat_cost()):
		action_adopt_cat()
		return
	var best_id: String = ""
	var best_cost: int = 999999999
	for b in BUILDING_DEFS:
		if int(b["req_map"]) <= map_level:
			var b_id: String = str(b["id"])
			var c_cost: int = get_building_cost(b_id)
			if c_cost < best_cost:
				best_cost = c_cost
				best_id = b_id
	if best_id != "" and fish_coins >= float(best_cost):
		action_upgrade_building(best_id)

func _step_camera(delta: float) -> void:
	var pan_dir: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_dir += 1.0
	var min_cam: float = MAP_CENTER_X - 180.0
	var max_cam: float = MAP_CENTER_X + 180.0
	if pan_dir != 0.0:
		cam_x = clampf(cam_x + pan_dir * 320.0 * delta, min_cam, max_cam)
		cam_target_x = cam_x
		return
	if auto_cam_enabled:
		cam_x = lerpf(cam_x, MAP_CENTER_X + sin(_time_sec * 0.35) * 45.0, 1.0 - exp(-2.5 * delta))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if (_skin_modal != null and _skin_modal.visible) or (_deep_modal != null and _deep_modal.visible):
			return
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.position.y > 70.0 and mb.position.y < 610.0:
			if not _try_click_building_at_screen(mb.position):
				_try_pet_cat_at_screen(mb.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).keycode
		if k == KEY_1 or k == KEY_F1:
			action_switch_ui_style(1)
		elif k == KEY_2 or k == KEY_F2:
			action_switch_ui_style(2)
		elif k == KEY_3 or k == KEY_F3:
			action_switch_ui_style(3)
		elif k == KEY_4 or k == KEY_F4:
			action_switch_ui_style(4)
		elif k == KEY_F:
			action_feed_all_cats(false)
		elif k == KEY_P or k == KEY_SPACE:
			action_play_with_cats(false)
		elif k == KEY_C:
			action_adopt_cat()
		elif k == KEY_M:
			action_expand_map()
		elif k == KEY_K:
			if _skin_modal != null:
				_skin_modal.visible = not _skin_modal.visible
				if _deep_modal != null:
					_deep_modal.visible = false
				_refresh_skin_modal()
		elif k == KEY_T or k == KEY_G:
			if _deep_modal != null:
				_deep_modal.visible = not _deep_modal.visible
				if _skin_modal != null:
					_skin_modal.visible = false
				_refresh_deep_modal()

func _try_click_building_at_screen(spos: Vector2) -> bool:
	for b_id in _building_screen_rects.keys():
		var rect: Rect2 = _building_screen_rects[b_id]
		if rect.has_point(spos):
			selected_building_id = str(b_id)
			var b: Dictionary = get_building_def(selected_building_id)
			_show_toast("🏛️ Đang chọn [%s] — Bấm Nâng Cấp hoặc Phím [T] mở Chế Tác!" % str(b["name"]))
			SoundEngine.play_sfx("ui_click")
			_refresh_all_ui()
			return true
	return false

func _try_pet_cat_at_screen(screen_pos: Vector2) -> void:
	for c in cats:
		var cpos: Vector2 = _cat_world_to_screen(c)
		if screen_pos.distance_to(cpos) <= 44.0:
			c["state"] = "HAPPY_JUMP"
			c["state_timer"] = 1.6
			c["happiness"] = 100.0
			c["Bubble"] = "💕"
			var pet_bonus: int = int(round((15.0 + float(map_level) * 10.0) * get_skin_collection_multiplier()))
			fish_coins += float(pet_bonus)
			total_coins_earned += float(pet_bonus)
			_spawn_popup(cpos + Vector2(0, -36.0), "💕 Meow~ +%d Xu Cá!" % pet_bonus, Color(1.0, 0.55, 0.78))
			SoundEngine.play_sfx("ui_click")
			_refresh_top_labels()
			return

# ============================================================================
# TRUE 2.5D ISOMETRIC DIAMOND WORLD + HIGH-RES SPRITE ATLAS RENDERER
# ============================================================================

func _iso_origin() -> Vector2:
	var cx: float = 610.0 + (MAP_CENTER_X - cam_x) * 0.40
	if ui_style_id == 2:
		cx = 640.0 + (MAP_CENTER_X - cam_x) * 0.25 # Centered between Left & Right Sidebars
	elif ui_style_id == 3:
		cx = 650.0 + (MAP_CENTER_X - cam_x) * 0.35
	var cy: float = 216.0 if ui_style_id != 2 else 208.0
	return Vector2(cx, cy)

func _iso_grid_to_screen(gx: float, gy: float) -> Vector2:
	var orig: Vector2 = _iso_origin()
	var sx: float = orig.x + (gx - gy) * (ISO_TILE_W * 0.5)
	var sy: float = orig.y + (gx + gy) * (ISO_TILE_H * 0.5)
	return Vector2(sx, sy)

func _cat_world_to_screen(c: Dictionary) -> Vector2:
	var norm_x: float = (float(c["x"]) - MAP_CENTER_X) / 380.0
	var norm_y: float = float(c["y_off"]) / 60.0
	var gx: float = clampf(2.0 + norm_x * 2.0, -0.3, 4.3)
	var gy: float = clampf(2.0 + norm_y * 1.1, 0.2, 3.8)
	return _iso_grid_to_screen(gx, gy)

func _draw() -> void:
	var preset: Dictionary = get_active_ui_preset()
	var th: Dictionary = get_active_theme_dict()
	_draw_isometric_backdrop_and_water(preset)
	_draw_isometric_island_grid(preset)
	_draw_isometric_river_boats(preset)
	_draw_isometric_buildings_and_parks(preset)
	_draw_all_cats()
	_draw_sky_particles(th)
	_draw_popups()

func _draw_isometric_backdrop_and_water(preset: Dictionary) -> void:
	var bg_top: Color = preset["bg_top"]
	var bg_mid: Color = preset["bg_mid"]
	var bg_water: Color = preset["bg_water"]

	# Rich atmospheric sky + deep isometric ocean/river basin
	draw_rect(Rect2(0, 0, 1280, 190), bg_top, true)
	draw_rect(Rect2(0, 190, 1280, 180), bg_mid, true)
	draw_rect(Rect2(0, 370, 1280, 350), bg_water, true)

	# Celestial Sun / Arcane Moon / Cyber Halo
	var sun_pos := Vector2(1040, 122) if ui_style_id != 2 else Vector2(880, 118)
	draw_circle(sun_pos, 52.0, Color(1.0, 0.90, 0.55, 0.18))
	draw_circle(sun_pos, 32.0, Color(1.0, 0.95, 0.74, 0.85))

	# Animated water shimmer waves across the isometric river surrounds
	for w_i in range(18):
		var wy: float = 210.0 + float(w_i) * 28.0
		var wx: float = fposmod(float(w_i * 173) + _time_sec * (18.0 + float(w_i % 3) * 6.0), 1360.0) - 40.0
		var wave_col := Color(0.65, 0.92, 1.0, 0.22)
		draw_line(Vector2(wx, wy), Vector2(wx + 68.0, wy), wave_col, 2.5)
		draw_line(Vector2(wx + 18.0, wy + 6.0), Vector2(wx + 52.0, wy + 6.0), wave_col, 1.5)

	# Distant floating clouds
	for cl in clouds:
		var cx: float = fposmod(float(cl["x"]), 1420.0) - 70.0
		var cy: float = float(cl["y"])
		var cw: float = float(cl["w"])
		var ccol := Color(1, 1, 1, 0.28)
		draw_circle(Vector2(cx, cy), cw * 0.26, ccol)
		draw_circle(Vector2(cx + cw * 0.22, cy + 4.0), cw * 0.20, ccol)

func _draw_iso_tile_block(gx: float, gy: float, top_col: Color, left_col: Color, right_col: Color, thickness: float = 26.0, is_road: bool = false) -> void:
	var c: Vector2 = _iso_grid_to_screen(gx, gy)
	var hw: float = ISO_TILE_W * 0.5
	var hh: float = ISO_TILE_H * 0.5
	var p_top := Vector2(c.x, c.y - hh)
	var p_right := Vector2(c.x + hw, c.y)
	var p_bot := Vector2(c.x, c.y + hh)
	var p_left := Vector2(c.x - hw, c.y)

	# 3D Isometric Extruded Left & Right Cliff Faces
	if thickness > 0.0:
		var left_face := PackedVector2Array([
			p_left, p_bot, p_bot + Vector2(0, thickness), p_left + Vector2(0, thickness)
		])
		var right_face := PackedVector2Array([
			p_bot, p_right, p_right + Vector2(0, thickness), p_bot + Vector2(0, thickness)
		])
		draw_colored_polygon(left_face, left_col)
		draw_colored_polygon(right_face, right_col)
		# Waterline foam highlight at bottom of cliff
		draw_line(p_left + Vector2(0, thickness), p_bot + Vector2(0, thickness), Color(0.85, 0.96, 1.0, 0.45), 2.5)
		draw_line(p_bot + Vector2(0, thickness), p_right + Vector2(0, thickness), Color(0.85, 0.96, 1.0, 0.35), 2.5)

	# Top Diamond Surface
	var top_poly := PackedVector2Array([p_top, p_right, p_bot, p_left])
	draw_colored_polygon(top_poly, top_col)

	# Crisp Isometric Grid Border & Road Paving
	var border_c: Color = top_col.lightened(0.16)
	draw_polyline(PackedVector2Array([p_top, p_right, p_bot, p_left, p_top]), border_c, 1.6)

	if is_road:
		var r_hw: float = hw * 0.32
		var r_hh: float = hh * 0.32
		var road_poly := PackedVector2Array([
			Vector2(c.x, c.y - r_hh), Vector2(c.x + r_hw, c.y),
			Vector2(c.x, c.y + r_hh), Vector2(c.x - r_hw, c.y)
		])
		draw_colored_polygon(road_poly, Color(0.95, 0.90, 0.78, 0.65))

func _draw_isometric_island_grid(preset: Dictionary) -> void:
	var t_top: Color = preset["tile_top"]
	var t_left: Color = preset["tile_left"]
	var t_right: Color = preset["tile_right"]
	var road_col: Color = preset["road_col"]

	# Back-to-front painter's order (gy + gx from 0 to 8)
	for gy in range(5):
		for gx in range(5):
			# Grand canal runs along gy == 3 (with isometric stone bridges at gx == 1 and gx == 3)
			if gy == 3 and gx != 1 and gx != 3:
				var wc: Vector2 = _iso_grid_to_screen(float(gx), float(gy))
				draw_circle(wc, 18.0, Color(0.45, 0.88, 1.0, 0.16))
				continue

			var is_bridge: bool = (gy == 3 and (gx == 1 or gx == 3))
			var is_avenue: bool = (gy == 2 or gx == 2 or is_bridge)
			var tile_c: Color = road_col if is_bridge else (t_top.lerp(road_col, 0.38) if is_avenue else t_top)
			if (gx + gy) % 2 == 1 and not is_bridge:
				tile_c = tile_c.darkened(0.05)

			var elev: float = 30.0 if gy < 3 else 22.0
			_draw_iso_tile_block(float(gx), float(gy), tile_c, t_left, t_right, elev, is_avenue)

			# Draw arched stone bridge railings on canal bridges
			if is_bridge:
				var bc: Vector2 = _iso_grid_to_screen(float(gx), float(gy))
				draw_arc(bc + Vector2(0, 6), 34.0, PI + 0.35, TAU - 0.35, 12, Color(0.92, 0.32, 0.26), 4.5)

func _draw_isometric_river_boats(preset: Dictionary) -> void:
	var outline := Color(0.16, 0.11, 0.08)
	for rb in river_boats:
		var t: float = float(rb["t"])
		var gx: float = lerpf(-0.6, 4.6, t)
		var gy: float = 3.0 if int(rb["lane"]) == 0 else 4.55
		var bpos: Vector2 = _iso_grid_to_screen(gx, gy) + Vector2(0, 10.0)
		# Wake ripples
		draw_circle(bpos + Vector2(-14, 4), 10.0, Color(0.85, 0.98, 1.0, 0.35))
		# Isometric wooden hull / cargo barge
		var hull := PackedVector2Array([
			bpos + Vector2(-22, 0), bpos + Vector2(-10, -8),
			bpos + Vector2(22, -2), bpos + Vector2(12, 8)
		])
		draw_colored_polygon(hull, Color(0.58, 0.34, 0.18))
		draw_polyline(hull, outline, 2.0)
		# Sail / cabin
		var sail_col: Color = preset["border_col"]
		var sail := PackedVector2Array([
			bpos + Vector2(0, -6), bpos + Vector2(0, -28), bpos + Vector2(16, -12)
		])
		draw_colored_polygon(sail, sail_col)

func _draw_iso_sprite_cell(pack_name: String, cell: Vector2i, screen_center: Vector2, draw_size: float = 168.0, alpha: float = 1.0) -> void:
	var tex: Texture2D = _iso_textures.get(pack_name, null)
	if tex == null:
		return
	var src_rect := Rect2(float(cell.x * 256), float(cell.y * 256), 256.0, 256.0)
	var dst_rect := Rect2(screen_center.x - draw_size * 0.5, screen_center.y - draw_size * 0.78, draw_size, draw_size)
	draw_texture_rect_region(tex, dst_rect, src_rect, Color(1, 1, 1, alpha))

func _draw_isometric_buildings_and_parks(preset: Dictionary) -> void:
	var fnt: Font = ThemeDB.fallback_font
	var main_pack: String = str(preset["pack_main"])
	var sub_pack: String = str(preset["pack_sub"])
	var border_col: Color = preset["border_col"]
	var outline := Color(0.12, 0.08, 0.06, 0.95)
	_building_screen_rects.clear()

	# Decorative peripheral parks, docks & mansions on non-building tiles (sorted back-to-front)
	var deco_slots: Array[Dictionary] = [
		{"gx": 0, "gy": 0, "pack": sub_pack, "cell": Vector2i(0, 1), "scale": 146.0},
		{"gx": 1, "gy": 0, "pack": main_pack, "cell": Vector2i(3, 0), "scale": 152.0},
		{"gx": 3, "gy": 0, "pack": main_pack, "cell": Vector2i(4, 0), "scale": 152.0},
		{"gx": 4, "gy": 0, "pack": sub_pack, "cell": Vector2i(1, 1), "scale": 146.0},
		{"gx": 0, "gy": 1, "pack": sub_pack, "cell": Vector2i(2, 0), "scale": 144.0},
		{"gx": 2, "gy": 1, "pack": sub_pack, "cell": Vector2i(1, 0), "scale": 148.0},
		{"gx": 4, "gy": 1, "pack": sub_pack, "cell": Vector2i(3, 1), "scale": 144.0},
		{"gx": 0, "gy": 4, "pack": main_pack, "cell": Vector2i(0, 5), "scale": 158.0},
		{"gx": 1, "gy": 4, "pack": sub_pack, "cell": Vector2i(0, 3), "scale": 146.0},
		{"gx": 2, "gy": 4, "pack": main_pack, "cell": Vector2i(1, 5), "scale": 162.0},
		{"gx": 3, "gy": 4, "pack": sub_pack, "cell": Vector2i(2, 3), "scale": 146.0},
		{"gx": 4, "gy": 4, "pack": main_pack, "cell": Vector2i(4, 5), "scale": 158.0},
	]

	# Combine decorative and interactive buildings and sort by (gx + gy) painter's algorithm
	var render_queue: Array[Dictionary] = []
	for d in deco_slots:
		var depth: int = int(d["gx"]) + int(d["gy"])
		render_queue.append({"kind": "deco", "depth": depth, "data": d})

	for b in BUILDING_DEFS:
		var depth: int = int(b["gx"]) + int(b["gy"])
		render_queue.append({"kind": "bldg", "depth": depth, "data": b})

	render_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["depth"]) < int(b["depth"])
	)

	for item in render_queue:
		if str(item["kind"]) == "deco":
			var d: Dictionary = item["data"]
			var spos: Vector2 = _iso_grid_to_screen(float(d["gx"]), float(d["gy"]))
			_draw_iso_sprite_cell(str(d["pack"]), d["cell"] as Vector2i, spos, float(d["scale"]), 0.95)
		else:
			var b: Dictionary = item["data"]
			var b_id: String = str(b["id"])
			var req_map: int = int(b["req_map"])
			var lv: int = int(building_levels.get(b_id, 0))
			var spos: Vector2 = _iso_grid_to_screen(float(b["gx"]), float(b["gy"]))
			var is_sel: bool = (selected_building_id == b_id)

			# Store clickable rect for mouse selection
			_building_screen_rects[b_id] = Rect2(spos.x - 68.0, spos.y - 115.0, 136.0, 135.0)

			if is_sel:
				var pulse: float = 44.0 + sin(_time_sec * 4.5) * 4.0
				draw_arc(spos + Vector2(0, 2), pulse, 0.0, TAU, 24, border_col, 3.0)

			var cells_dict: Dictionary = b["cells"]
			var pack_cells: Array = cells_dict.get(main_pack, cells_dict["oriental"])
			var tier_idx: int = 0
			if lv >= 5:
				tier_idx = 2
			elif lv >= 3:
				tier_idx = 1
			var cell_coord: Vector2i = pack_cells[clampi(tier_idx, 0, pack_cells.size() - 1)]

			if map_level < req_map or lv <= 0:
				# Ghosted isometric preview + construction scaffold badge
				_draw_iso_sprite_cell(main_pack, cell_coord, spos, 152.0, 0.42)
				var lock_txt: String = "🔒 Map Cấp %d" % req_map if map_level < req_map else "🔨 Bấm Xây"
				draw_rect(Rect2(spos.x - 54.0, spos.y - 38.0, 108.0, 20.0), Color(0.10, 0.08, 0.14, 0.88), true)
				draw_string_outline(fnt, Vector2(spos.x - 52.0, spos.y - 24.0), lock_txt, HORIZONTAL_ALIGNMENT_CENTER, 104, 11, 3, outline)
				draw_string(fnt, Vector2(spos.x - 52.0, spos.y - 24.0), lock_txt, HORIZONTAL_ALIGNMENT_CENTER, 104, 11, Color(1.0, 0.88, 0.36))
			else:
				var draw_sz: float = 164.0 + minf(28.0, float(lv) * 4.5)
				_draw_iso_sprite_cell(main_pack, cell_coord, spos, draw_sz, 1.0)

				# Compact Floating Nameplate with Stars
				var stars: String = "★".repeat(mini(5, 1 + int(lv / 2)))
				var short_name: String = str(b["name"]).substr(0, 18)
				var badge_str: String = "%s [Lv.%d %s]" % [short_name, lv, stars]
				var by_top: float = spos.y - draw_sz * 0.68
				var bg_c: Color = Color(0.14, 0.10, 0.22, 0.92) if is_sel else Color(0.10, 0.08, 0.12, 0.82)
				draw_rect(Rect2(spos.x - 76.0, by_top - 15.0, 152.0, 19.0), bg_c, true)
				if is_sel:
					draw_rect(Rect2(spos.x - 76.0, by_top - 15.0, 152.0, 19.0), border_col, false, 1.5)
				draw_string_outline(fnt, Vector2(spos.x - 74.0, by_top - 1.0), badge_str, HORIZONTAL_ALIGNMENT_CENTER, 148, 10, 3, outline)
				draw_string(fnt, Vector2(spos.x - 74.0, by_top - 1.0), badge_str, HORIZONTAL_ALIGNMENT_CENTER, 148, 10, Color(1.0, 0.96, 0.78))

func _draw_all_cats() -> void:
	var fnt: Font = ThemeDB.fallback_font
	var outline := Color(0.18, 0.12, 0.08)

	for c in cats:
		var cpos: Vector2 = _cat_world_to_screen(c)
		var phase: float = float(c["anim_phase"])
		var st: String = str(c["state"])
		var facing: float = float(c["facing"])
		var breed: Dictionary = get_cat_skin_dict_by_id(str(c.get("skin_id", "ginger")))
		var body_col: Color = breed["body"]
		var belly_col: Color = breed["belly"]
		var stripe_col: Color = breed["stripe"]
		var eye_col: Color = breed["eye"]
		var aura_col: Color = breed["aura"]

		var bounce_y: float = -absf(sin(phase)) * 4.5 if st == "WALK" else (-absf(sin(phase * 1.6)) * 11.0 if (st == "PLAY" or st == "HAPPY_JUMP") else 0.0)
		var pos := cpos + Vector2(0, bounce_y)

		draw_circle(cpos + Vector2(0, 3.0), 10.0, Color(0, 0, 0, 0.24))
		if aura_col.a > 0.01:
			draw_circle(pos + Vector2(0, -12.0), 17.0 + sin(phase) * 2.0, aura_col)

		# Body & Head scaled for 2.5D Isometric Plaza
		draw_circle(pos + Vector2(0, -10.0), 11.5, outline)
		draw_circle(pos + Vector2(0, -10.0), 9.8, body_col)
		draw_circle(pos + Vector2(facing * 2.0, -9.0), 6.2, belly_col)

		var head_pos := pos + Vector2(facing * 5.0, -20.0)
		draw_circle(head_pos, 10.5, outline)
		draw_circle(head_pos, 8.8, body_col)

		for ear_side in [-1.0, 1.0]:
			var ex: float = head_pos.x + ear_side * 5.8
			var ey: float = head_pos.y - 6.0
			var ear_poly := PackedVector2Array([
				Vector2(ex - 3.8, ey + 1.5),
				Vector2(ex + ear_side * 1.5, ey - 7.5),
				Vector2(ex + 3.8, ey + 1.5)
			])
			draw_colored_polygon(ear_poly, stripe_col)

		var eye_x: float = head_pos.x + facing * 3.2
		var eye_y: float = head_pos.y - 1.0
		draw_circle(Vector2(eye_x, eye_y), 2.2, eye_col)

		if active_costume == "royal_crown":
			draw_circle(head_pos + Vector2(0, -11.0), 4.2, Color(1.0, 0.84, 0.16))
		elif active_costume == "wizard_hat":
			draw_circle(head_pos + Vector2(0, -12.0), 4.8, Color(0.42, 0.24, 0.78))

		var bub: String = str(c["Bubble"])
		if bub != "":
			draw_string_outline(fnt, head_pos + Vector2(-8.0, -15.0), bub, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, 3, outline)
			draw_string(fnt, head_pos + Vector2(-8.0, -15.0), bub, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color.WHITE)

func _draw_sky_particles(th: Dictionary) -> void:
	var p_col: Color = th["particle_col"]
	for sp in sky_particles:
		draw_circle(Vector2(float(sp["x"]), float(sp["y"])), float(sp["sz"]), Color(p_col.r, p_col.g, p_col.b, 0.72))

func _draw_popups() -> void:
	var fnt: Font = ThemeDB.fallback_font
	for pp in popups:
		var p: float = float(pp["life"]) / float(pp["max_life"])
		var col: Color = pp["col"]
		col.a = 1.0 - p * p
		var spos: Vector2 = pp["pos"]
		draw_string_outline(fnt, spos, str(pp["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, 4, Color(0.12, 0.08, 0.06, col.a))
		draw_string(fnt, spos, str(pp["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, col)

# ============================================================================
# 4 SELECTABLE UI ARCHITECTURES + DEEP TYCOON MODAL + SKIN WARDROBE MODAL
# ============================================================================

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	_ui_root = Control.new()
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_ui_root)

	# Persistent Top-Center Live UI Switcher Bar (Always accessible to preview UI 1 / 2 / 3 / 4)
	var switcher_bar := PanelContainer.new()
	switcher_bar.position = Vector2(210, 6)
	switcher_bar.size = Vector2(860, 38)
	switcher_bar.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.10, 0.08, 0.16, 0.96), Color(1.0, 0.84, 0.28), Color.BLACK, 10, 2, 3, 10, 4))
	_ui_root.add_child(switcher_bar)

	var sw_hbox := HBoxContainer.new()
	sw_hbox.add_theme_constant_override("separation", 6)
	switcher_bar.add_child(sw_hbox)

	var lbl_sw := Label.new()
	lbl_sw.text = "🎨 CHỌN GIAO DIỆN [1-4]:"
	BastionUI.style_display_label(lbl_sw, 11, BastionUI.COL_GOLD_TEXT, 3)
	sw_hbox.add_child(lbl_sw)

	for p in UI_PRESETS:
		var pid: int = int(p["id"])
		var btn_sw := Button.new()
		btn_sw.text = str(p["name"])
		btn_sw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_sw.custom_minimum_size = Vector2(155, 28)
		btn_sw.pressed.connect(func() -> void: action_switch_ui_style(pid))
		sw_hbox.add_child(btn_sw)
		_ui_style_buttons[pid] = btn_sw

	# Dynamic Layout Container (rebuilt when switching UI 1..4)
	_layout_container = Control.new()
	_layout_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_layout_container)

	# Modals & Toast (sit above active layout)
	_build_deep_tycoon_modal(_ui_root)
	_build_skin_wardrobe_modal(_ui_root)

	_toast_panel = PanelContainer.new()
	_toast_panel.position = Vector2(260, 98)
	_toast_panel.size = Vector2(760, 38)
	_toast_panel.visible = false
	_toast_panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.16, 0.11, 0.08, 0.96), BastionUI.COL_GOLD_TEXT, Color.BLACK, 10, 2, 3, 12, 5))
	_ui_root.add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(_toast_label, 13, BastionUI.COL_GOLD_TEXT, 4)
	_toast_panel.add_child(_toast_label)

func _rebuild_active_ui_layout() -> void:
	if _layout_container == null:
		return
	for ch in _layout_container.get_children():
		ch.queue_free()
	_bldg_buttons.clear()
	_lbl_inspector_title = null
	_lbl_inspector_body = null
	_btn_inspector_upgrade = null

	var preset: Dictionary = get_active_ui_preset()
	var p_bg: Color = preset["panel_bg"]
	var p_border: Color = preset["border_col"]

	if ui_style_id == 1:
		_build_layout_1_oriental_dock(p_bg, p_border)
	elif ui_style_id == 2:
		_build_layout_2_arcane_sidebar(p_bg, p_border)
	elif ui_style_id == 3:
		_build_layout_3_cyber_glass_hud(p_bg, p_border)
	else:
		_build_layout_4_cozy_farm_deck(p_bg, p_border)

func _create_shared_telemetry_labels(parent: BoxContainer) -> void:
	_lbl_top_coins = Label.new()
	_lbl_top_coins.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BastionUI.style_display_label(_lbl_top_coins, 12, BastionUI.COL_GOLD_TEXT, 4)
	parent.add_child(_lbl_top_coins)

	_lbl_top_stats = Label.new()
	_lbl_top_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BastionUI.style_display_label(_lbl_top_stats, 11, BastionUI.COL_CREAM_TEXT, 3)
	parent.add_child(_lbl_top_stats)

	_lbl_top_status = Label.new()
	_lbl_top_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BastionUI.style_display_label(_lbl_top_status, 11, Color(0.62, 0.98, 0.72), 3)
	parent.add_child(_lbl_top_status)

func _create_quick_action_buttons(parent: Container, btn_h: float = 46.0) -> void:
	var btn_feed := Button.new()
	btn_feed.text = "🐟 Tiếp Lương [F]"
	btn_feed.custom_minimum_size = Vector2(90, btn_h)
	BastionUI.apply_clash_button_style(btn_feed, "green", 10)
	btn_feed.pressed.connect(func() -> void: action_feed_all_cats(false))
	parent.add_child(btn_feed)

	var btn_play := Button.new()
	btn_play.text = "🏮 Lễ Hội [P]"
	btn_play.custom_minimum_size = Vector2(84, btn_h)
	BastionUI.apply_clash_button_style(btn_play, "blue", 10)
	btn_play.pressed.connect(func() -> void: action_play_with_cats(false))
	parent.add_child(btn_play)

	_btn_adopt_cat = Button.new()
	_btn_adopt_cat.custom_minimum_size = Vector2(98, btn_h)
	BastionUI.apply_clash_button_style(_btn_adopt_cat, "gold", 10)
	_btn_adopt_cat.pressed.connect(func() -> void: action_adopt_cat())
	parent.add_child(_btn_adopt_cat)

	_btn_open_deep = Button.new()
	_btn_open_deep.text = "⚗️ Chế Tác [T]"
	_btn_open_deep.custom_minimum_size = Vector2(106, btn_h)
	BastionUI.apply_clash_button_style(_btn_open_deep, "gold", 10)
	_btn_open_deep.pressed.connect(func() -> void:
		_deep_modal.visible = not _deep_modal.visible
		if _skin_modal != null:
			_skin_modal.visible = false
		_refresh_deep_modal()
	)
	parent.add_child(_btn_open_deep)

	_btn_open_skins = Button.new()
	_btn_open_skins.custom_minimum_size = Vector2(106, btn_h)
	BastionUI.apply_clash_button_style(_btn_open_skins, "red", 10)
	_btn_open_skins.pressed.connect(func() -> void:
		_skin_modal.visible = not _skin_modal.visible
		if _deep_modal != null:
			_deep_modal.visible = false
		_refresh_skin_modal()
	)
	parent.add_child(_btn_open_skins)

	_btn_expand_map = Button.new()
	_btn_expand_map.custom_minimum_size = Vector2(106, btn_h)
	BastionUI.apply_clash_button_style(_btn_expand_map, "gold", 10)
	_btn_expand_map.pressed.connect(func() -> void: action_expand_map())
	parent.add_child(_btn_expand_map)

func _create_inspector_card(parent: Control, rect: Rect2, p_bg: Color, p_border: Color) -> void:
	var card := PanelContainer.new()
	card.position = rect.position
	card.size = rect.size
	card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 12, 2, 4, 12, 8))
	parent.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	_lbl_inspector_title = Label.new()
	BastionUI.style_display_label(_lbl_inspector_title, 13, BastionUI.COL_GOLD_TEXT, 4)
	vbox.add_child(_lbl_inspector_title)

	_lbl_inspector_body = Label.new()
	_lbl_inspector_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_inspector_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	BastionUI.style_display_label(_lbl_inspector_body, 11, BastionUI.COL_CREAM_TEXT, 3)
	vbox.add_child(_lbl_inspector_body)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	_btn_inspector_upgrade = Button.new()
	_btn_inspector_upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_inspector_upgrade.custom_minimum_size = Vector2(140, 38)
	_btn_inspector_upgrade.pressed.connect(func() -> void: action_upgrade_building(selected_building_id))
	hbox.add_child(_btn_inspector_upgrade)

	var btn_craft_quick := Button.new()
	btn_craft_quick.text = "🍣 Xuất Khẩu Nhanh"
	btn_craft_quick.custom_minimum_size = Vector2(124, 38)
	BastionUI.apply_clash_button_style(btn_craft_quick, "green", 11)
	btn_craft_quick.pressed.connect(func() -> void:
		if not action_craft_recipe("arcane_relic", false):
			if not action_craft_recipe("matcha_cake", false):
				action_craft_recipe("sushi_feast", false)
	)
	hbox.add_child(btn_craft_quick)

# ----------------------------------------------------------------------------
# LAYOUT 1: 🏯 CỔ PHONG GIANG NAM (Floating Imperial Scroll + Curved Radial Dock)
# ----------------------------------------------------------------------------
func _build_layout_1_oriental_dock(p_bg: Color, p_border: Color) -> void:
	var top_scroll := PanelContainer.new()
	top_scroll.position = Vector2(14, 48)
	top_scroll.size = Vector2(1252, 62)
	top_scroll.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 12, 2, 4, 12, 6))
	_layout_container.add_child(top_scroll)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	top_scroll.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(info_vbox)
	_create_shared_telemetry_labels(info_vbox)
	_create_quick_action_buttons(hbox, 46.0)

	# Right Floating Inspector Card
	_create_inspector_card(_layout_container, Rect2(956, 120, 310, 210), p_bg, p_border)

	# Bottom-Center Floating Curved Dock (8 Compact Pills across 2 rows)
	var dock := PanelContainer.new()
	dock.position = Vector2(110, 588)
	dock.size = Vector2(1060, 124)
	dock.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 16, 2, 5, 12, 8))
	_layout_container.add_child(dock)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	dock.add_child(grid)
	for b in BUILDING_DEFS:
		var b_id: String = str(b["id"])
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: action_upgrade_building(b_id))
		grid.add_child(btn)
		_bldg_buttons[b_id] = btn

# ----------------------------------------------------------------------------
# LAYOUT 2: 🏰 HỌC VIỆN PHÉP THUẬT (PC Strategy Left Command Sidebar + Right Inspector)
# ----------------------------------------------------------------------------
func _build_layout_2_arcane_sidebar(p_bg: Color, p_border: Color) -> void:
	# Left Command Sidebar (8 Districts Stacked Vertically)
	var left_bar := PanelContainer.new()
	left_bar.position = Vector2(10, 48)
	left_bar.size = Vector2(286, 662)
	left_bar.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 12, 2, 5, 10, 10))
	_layout_container.add_child(left_bar)

	var l_vbox := VBoxContainer.new()
	l_vbox.add_theme_constant_override("separation", 5)
	left_bar.add_child(l_vbox)

	var lbl_l := Label.new()
	lbl_l.text = "🏰 QUÂN ĐOÀN KIẾN TRÚC 2.5D"
	lbl_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_l, 13, p_border, 4)
	l_vbox.add_child(lbl_l)

	for b in BUILDING_DEFS:
		var b_id: String = str(b["id"])
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: action_upgrade_building(b_id))
		l_vbox.add_child(btn)
		_bldg_buttons[b_id] = btn

	# Right Command & Inspector Sidebar
	var right_bar := PanelContainer.new()
	right_bar.position = Vector2(984, 48)
	right_bar.size = Vector2(286, 662)
	right_bar.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 12, 2, 5, 10, 10))
	_layout_container.add_child(right_bar)

	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 6)
	right_bar.add_child(r_vbox)

	_create_shared_telemetry_labels(r_vbox)

	var act_grid := GridContainer.new()
	act_grid.columns = 2
	act_grid.add_theme_constant_override("h_separation", 6)
	act_grid.add_theme_constant_override("v_separation", 6)
	r_vbox.add_child(act_grid)
	_create_quick_action_buttons(act_grid, 44.0)

	_create_inspector_card(_layout_container, Rect2(994, 430, 266, 268), p_bg.lightened(0.06), p_border)

# ----------------------------------------------------------------------------
# LAYOUT 3: 🌆 SIÊU ĐÔ THỊ TƯƠNG LAI (Cyber-Glass Minimalist HUD + Floating Cards)
# ----------------------------------------------------------------------------
func _build_layout_3_cyber_glass_hud(p_bg: Color, p_border: Color) -> void:
	# Top-Left Sleek Telemetry Pill
	var tl_pill := PanelContainer.new()
	tl_pill.position = Vector2(14, 48)
	tl_pill.size = Vector2(540, 74)
	tl_pill.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 14, 2, 4, 12, 6))
	_layout_container.add_child(tl_pill)

	var tl_vbox := VBoxContainer.new()
	tl_vbox.add_theme_constant_override("separation", 2)
	tl_pill.add_child(tl_vbox)
	_create_shared_telemetry_labels(tl_vbox)

	# Top-Right Action Strip
	var tr_pill := PanelContainer.new()
	tr_pill.position = Vector2(564, 48)
	tr_pill.size = Vector2(702, 74)
	tr_pill.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 14, 2, 4, 10, 6))
	_layout_container.add_child(tr_pill)

	var tr_hbox := HBoxContainer.new()
	tr_hbox.add_theme_constant_override("separation", 5)
	tr_pill.add_child(tr_hbox)
	_create_quick_action_buttons(tr_hbox, 54.0)

	# Bottom-Left Cyber Inspector & Radar Card
	_create_inspector_card(_layout_container, Rect2(14, 508, 360, 202), p_bg, p_border)

	# Bottom-Right Floating Glass Building Matrix
	var br_glass := PanelContainer.new()
	br_glass.position = Vector2(386, 566)
	br_glass.size = Vector2(880, 144)
	br_glass.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 14, 2, 4, 10, 8))
	_layout_container.add_child(br_glass)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	br_glass.add_child(grid)
	for b in BUILDING_DEFS:
		var b_id: String = str(b["id"])
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: action_upgrade_building(b_id))
		grid.add_child(btn)
		_bldg_buttons[b_id] = btn

# ----------------------------------------------------------------------------
# LAYOUT 4: 🌾 THUNG LŨNG NÔNG TRẠI (Cozy Wooden Notebook Deck + Contract Board)
# ----------------------------------------------------------------------------
func _build_layout_4_cozy_farm_deck(p_bg: Color, p_border: Color) -> void:
	# Left Cozy Wooden Almanac Badge
	var almanac := PanelContainer.new()
	almanac.position = Vector2(14, 48)
	almanac.size = Vector2(370, 240)
	almanac.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 14, 3, 5, 12, 8))
	_layout_container.add_child(almanac)

	var a_vbox := VBoxContainer.new()
	a_vbox.add_theme_constant_override("separation", 5)
	almanac.add_child(a_vbox)
	_create_shared_telemetry_labels(a_vbox)

	var act_grid := GridContainer.new()
	act_grid.columns = 3
	act_grid.add_theme_constant_override("h_separation", 5)
	act_grid.add_theme_constant_override("v_separation", 5)
	a_vbox.add_child(act_grid)
	_create_quick_action_buttons(act_grid, 44.0)

	# Right Farm Contract & Inspector Board
	_create_inspector_card(_layout_container, Rect2(946, 48, 320, 220), p_bg, p_border)

	# Bottom Illustrated Wooden Deck (4x2 Cozy Cards)
	var deck := PanelContainer.new()
	deck.position = Vector2(14, 574)
	deck.size = Vector2(1252, 136)
	deck.add_theme_stylebox_override("panel", BastionUI.make_stylebox(p_bg, p_border, Color.BLACK, 14, 3, 5, 10, 8))
	_layout_container.add_child(deck)

	var d_grid := GridContainer.new()
	d_grid.columns = 4
	d_grid.add_theme_constant_override("h_separation", 8)
	d_grid.add_theme_constant_override("v_separation", 6)
	deck.add_child(d_grid)
	for b in BUILDING_DEFS:
		var b_id: String = str(b["id"])
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: action_upgrade_building(b_id))
		d_grid.add_child(btn)
		_bldg_buttons[b_id] = btn

# ============================================================================
# DEEP TYCOON MODAL (SUPPLY CHAIN CRAFTING + HERO MANAGERS + CITY TECH)
# ============================================================================

func _build_deep_tycoon_modal(root: Control) -> void:
	_deep_modal = PanelContainer.new()
	_deep_modal.position = Vector2(56, 114)
	_deep_modal.size = Vector2(1168, 436)
	_deep_modal.visible = false
	_deep_modal.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.14, 0.11, 0.20, 0.98), BastionUI.COL_GOLD_TEXT, Color.BLACK, 14, 3, 6, 16, 12))
	root.add_child(_deep_modal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_deep_modal.add_child(vbox)

	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	var lbl_t := Label.new()
	lbl_t.text = "⚗️ TRUNG TÂM CHẾ TÁC, QUẢN LÝ MÈO ANH HÙNG & SẮC LỆNH ĐÔ THỊ [Phím T]"
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BastionUI.style_display_label(lbl_t, 15, BastionUI.COL_GOLD_TEXT, 4)
	hdr.add_child(lbl_t)

	var btn_close := Button.new()
	btn_close.text = "✖ Đóng [T]"
	btn_close.custom_minimum_size = Vector2(100, 34)
	BastionUI.apply_clash_button_style(btn_close, "red", 12)
	btn_close.pressed.connect(func() -> void: _deep_modal.visible = false)
	hdr.add_child(btn_close)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(tab_hbox)

	var dtabs := [
		{"id": "CRAFT", "label": "🍣 Chuỗi Sản Xuất & Hợp Đồng Xuất Khẩu"},
		{"id": "MANAGER", "label": "👑 Bổ Nhiệm Quản Lý Mèo Anh Hùng"},
		{"id": "TECH", "label": "📜 Nghiên Cứu Công Nghệ & Sắc Lệnh Đô Thị"}
	]
	for t in dtabs:
		var tid: String = str(t["id"])
		var tbtn := Button.new()
		tbtn.text = str(t["label"])
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.custom_minimum_size = Vector2(220, 38)
		tbtn.pressed.connect(func() -> void:
			_deep_tab_mode = tid
			_refresh_deep_modal()
		)
		tab_hbox.add_child(tbtn)
		_deep_tab_buttons[tid] = tbtn

	_lbl_deep_summary = Label.new()
	_lbl_deep_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(_lbl_deep_summary, 13, Color(0.65, 1.0, 0.78), 4)
	vbox.add_child(_lbl_deep_summary)

	_deep_grid = GridContainer.new()
	_deep_grid.columns = 2
	_deep_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deep_grid.add_theme_constant_override("h_separation", 10)
	_deep_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(_deep_grid)

func _refresh_deep_modal() -> void:
	if _deep_modal == null or not _deep_modal.visible:
		return
	for tid in _deep_tab_buttons.keys():
		var tbtn: Button = _deep_tab_buttons[tid]
		BastionUI.apply_clash_button_style(tbtn, "gold" if tid == _deep_tab_mode else "stone", 12)

	_lbl_deep_summary.text = "📦 Kho Nguyên Liệu: 🐟 %d Cá Tươi  |  🌾 %d Thảo Mộc  |  ⚡ %d Tinh Hoa  |  💎 %d Ngọc Bích  |  🚢 Đã Xuất Khẩu: %d Chuyến" % [
		int(stock_fish), int(stock_herb), int(stock_essence), jade_gems, contracts_completed
	]

	for ch in _deep_grid.get_children():
		ch.queue_free()

	if _deep_tab_mode == "CRAFT":
		for r in CRAFT_RECIPES:
			var rid: String = str(r["id"])
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(540, 86)
			var can_craft: bool = (stock_fish >= float(r["cost_fish"]) and stock_herb >= float(r["cost_herb"]) and stock_essence >= float(r["cost_essence"]))
			btn.text = "%s  [Cần: %d🐟 %d🌾 %d⚡]\n%s" % [
				str(r["name"]), int(r["cost_fish"]), int(r["cost_herb"]), int(r["cost_essence"]), str(r["desc"])
			]
			BastionUI.apply_clash_button_style(btn, "green" if can_craft else "blue", 12)
			btn.pressed.connect(func() -> void: action_craft_recipe(rid, false))
			_deep_grid.add_child(btn)
	elif _deep_tab_mode == "MANAGER":
		for m in HERO_MANAGERS:
			var mid: String = str(m["id"])
			var lv: int = int(manager_levels.get(mid, 0))
			var cost: int = get_manager_cost(mid)
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(540, 86)
			btn.text = "%s — %s [Cấp %d]\n%s  |  🔼 Thăng Cấp: 🪙 %d Xu" % [
				str(m["name"]), str(m["role"]), lv, str(m["bonus_desc"]), cost
			]
			BastionUI.apply_clash_button_style(btn, "gold" if fish_coins >= float(cost) else "stone", 12)
			btn.pressed.connect(func() -> void: action_hire_manager(mid))
			_deep_grid.add_child(btn)
	elif _deep_tab_mode == "TECH":
		for t in TECH_DEFS:
			var tid: String = str(t["id"])
			var unlocked: bool = (tid in unlocked_techs)
			var cost: int = int(t["cost"])
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(540, 86)
			if unlocked:
				btn.text = "%s [✅ ĐÃ BAN HÀNH]\n%s" % [str(t["name"]), str(t["desc"])]
				BastionUI.apply_clash_button_style(btn, "green", 12)
			else:
				btn.text = "🔒 %s (🪙 %d Xu Cá)\n%s" % [str(t["name"]), cost, str(t["desc"])]
				BastionUI.apply_clash_button_style(btn, "gold" if fish_coins >= float(cost) else "stone", 12)
			btn.pressed.connect(func() -> void: action_unlock_tech(tid))
			_deep_grid.add_child(btn)

# ============================================================================
# 20-SKIN WARDROBE MODAL
# ============================================================================

func _build_skin_wardrobe_modal(root: Control) -> void:
	_skin_modal = PanelContainer.new()
	_skin_modal.position = Vector2(36, 112)
	_skin_modal.size = Vector2(1208, 438)
	_skin_modal.visible = false
	_skin_modal.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.22, 0.15, 0.12, 0.98), BastionUI.COL_GOLD_TEXT, Color.BLACK, 14, 3, 6, 16, 12))
	root.add_child(_skin_modal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_skin_modal.add_child(vbox)

	var hdr_hbox := HBoxContainer.new()
	vbox.add_child(hdr_hbox)

	var lbl_title := Label.new()
	lbl_title.text = "👗 KHO SKIN HOÀNG THƯỢNG & CHỦ ĐỀ THÀNH PHỐ (Mỗi Skin đã mở khóa đều cộng dồn % Thu Nhập Vĩnh Viễn!)"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BastionUI.style_display_label(lbl_title, 15, BastionUI.COL_GOLD_TEXT, 4)
	hdr_hbox.add_child(lbl_title)

	var btn_close := Button.new()
	btn_close.text = "✖ Đóng [K]"
	btn_close.custom_minimum_size = Vector2(100, 34)
	BastionUI.apply_clash_button_style(btn_close, "red", 12)
	btn_close.pressed.connect(func() -> void: _skin_modal.visible = false)
	hdr_hbox.add_child(btn_close)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(tab_hbox)

	var tabs := [
		{"id": "CAT", "label": "🐱 8 Skin Giống Mèo Quý Hiếm"},
		{"id": "COSTUME", "label": "🎩 6 Skin Mũ, Kính & Cánh Thiên Thần"},
		{"id": "THEME", "label": "🎨 6 Skin Chủ Đề Thời Tiết & Ánh Sáng"}
	]
	for t in tabs:
		var tid: String = str(t["id"])
		var tbtn := Button.new()
		tbtn.text = str(t["label"])
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.custom_minimum_size = Vector2(220, 38)
		tbtn.pressed.connect(func() -> void:
			_skin_tab_mode = tid
			_refresh_skin_modal()
		)
		tab_hbox.add_child(tbtn)
		_skin_tab_buttons[tid] = tbtn

	_lbl_skin_summary = Label.new()
	_lbl_skin_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(_lbl_skin_summary, 13, Color(0.65, 1.0, 0.72), 4)
	vbox.add_child(_lbl_skin_summary)

	_skin_grid = GridContainer.new()
	_skin_grid.columns = 3
	_skin_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_skin_grid.add_theme_constant_override("h_separation", 10)
	_skin_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(_skin_grid)

func _refresh_skin_modal() -> void:
	if _skin_modal == null or not _skin_modal.visible:
		return

	for tid in _skin_tab_buttons.keys():
		var tbtn: Button = _skin_tab_buttons[tid]
		BastionUI.apply_clash_button_style(tbtn, "gold" if tid == _skin_tab_mode else "stone", 12)

	var bonus_pct: int = int(round((get_skin_collection_multiplier() - 1.0) * 100.0))
	_lbl_skin_summary.text = "✨ Đã Sưu Tầm: %d / %d Skin  |  Tổng Thưởng Bộ Sưu Tập Skin: +%d%% Xu Cá Vĩnh Viễn!" % [
		get_total_unlocked_skins(), get_total_possible_skins(), bonus_pct
	]

	for ch in _skin_grid.get_children():
		ch.queue_free()

	if _skin_tab_mode == "CAT":
		var btn_mix := Button.new()
		btn_mix.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_mix.custom_minimum_size = Vector2(380, 76)
		var is_mix: bool = (active_cat_skin == "MIX")
		btn_mix.text = "🌈 Đàn Mèo Đa Sắc (Hiển thị đủ giống mèo)\n%s" % ("✅ ĐANG DÙNG" if is_mix else "👉 Bấm để bật Đa Sắc")
		BastionUI.apply_clash_button_style(btn_mix, "green" if is_mix else "blue", 11)
		btn_mix.pressed.connect(func() -> void: action_buy_or_equip_cat_skin("MIX"))
		_skin_grid.add_child(btn_mix)

		for cs in CAT_SKINS:
			var sid: String = str(cs["id"])
			var owned: bool = (sid in unlocked_cat_skins)
			var active: bool = (active_cat_skin == sid)
			var cost: int = int(cs["cost"])
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(380, 76)
			if active:
				btn.text = "%s [✅ ĐANG DÙNG]\n%s" % [str(cs["name"]), str(cs["desc"])]
				BastionUI.apply_clash_button_style(btn, "green", 11)
			elif owned:
				btn.text = "%s [ĐÃ MỞ - Bấm Mặc]\n%s" % [str(cs["name"]), str(cs["desc"])]
				BastionUI.apply_clash_button_style(btn, "blue", 11)
			else:
				btn.text = "🔒 %s (🪙 %d Xu Cá)\n%s" % [str(cs["name"]), cost, str(cs["desc"])]
				BastionUI.apply_clash_button_style(btn, "gold" if fish_coins >= float(cost) else "stone", 11)
			btn.pressed.connect(func() -> void: action_buy_or_equip_cat_skin(sid))
			_skin_grid.add_child(btn)
	elif _skin_tab_mode == "COSTUME":
		for cos in COSTUME_SKINS:
			var cid: String = str(cos["id"])
			var owned: bool = (cid in unlocked_costumes)
			var active: bool = (active_costume == cid)
			var cost: int = int(cos["cost"])
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(380, 92)
			if active:
				btn.text = "%s [✅ ĐANG MẶC]\n%s" % [str(cos["name"]), str(cos["desc"])]
				BastionUI.apply_clash_button_style(btn, "green", 11)
			elif owned:
				btn.text = "%s [ĐÃ MỞ - Bấm Trang Bị]\n%s" % [str(cos["name"]), str(cos["desc"])]
				BastionUI.apply_clash_button_style(btn, "blue", 11)
			else:
				btn.text = "🔒 %s (🪙 %d Xu Cá)\n%s" % [str(cos["name"]), cost, str(cos["desc"])]
				BastionUI.apply_clash_button_style(btn, "gold" if fish_coins >= float(cost) else "stone", 11)
			btn.pressed.connect(func() -> void: action_buy_or_equip_costume(cid))
			_skin_grid.add_child(btn)
	elif _skin_tab_mode == "THEME":
		for th in CITY_THEME_SKINS:
			var th_id: String = str(th["id"])
			var owned: bool = (th_id in unlocked_themes)
			var active: bool = (active_theme == th_id)
			var cost: int = int(th["cost"])
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(380, 92)
			if active:
				btn.text = "%s [✅ ĐANG DÙNG]\n%s" % [str(th["name"]), str(th["desc"])]
				BastionUI.apply_clash_button_style(btn, "green", 11)
			elif owned:
				btn.text = "%s [ĐÃ MỞ - Bấm Đổi Cảnh]\n%s" % [str(th["name"]), str(th["desc"])]
				BastionUI.apply_clash_button_style(btn, "blue", 11)
			else:
				btn.text = "🔒 %s (🪙 %d Xu Cá)\n%s" % [str(th["name"]), cost, str(th["desc"])]
				BastionUI.apply_clash_button_style(btn, "gold" if fish_coins >= float(cost) else "stone", 11)
			btn.pressed.connect(func() -> void: action_buy_or_equip_theme(th_id))
			_skin_grid.add_child(btn)

func _show_toast(msg: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = msg
	_toast_panel.visible = true
	_toast_timer = 3.2

func _refresh_top_labels() -> void:
	if _lbl_top_coins == null:
		return
	var gps: float = get_coins_per_sec()
	_lbl_top_coins.text = "🪙 %d Xu (+%.1f/s)  |  💎 %d Ngọc  |  📦 Kho: %d🐟 %d🌾 %d⚡" % [
		int(fish_coins), gps, jade_gems, int(stock_fish), int(stock_herb), int(stock_essence)
	]
	_lbl_top_stats.text = "🐱 Dân Số: %d/%d  |  💕 Hạnh Phúc: %d%%  |  🚢 Xuất Khẩu: %d Chuyến" % [
		cats.size(), get_max_cats(), int(city_happiness), contracts_completed
	]
	var preset: Dictionary = get_active_ui_preset()
	_lbl_top_status.text = "🎨 %s  ·  🗺️ Đô Thị Cấp %d/4  ·  📜 Tech: %d/4" % [
		str(preset["name"]), map_level, unlocked_techs.size()
	]

	if _btn_adopt_cat != null:
		if cats.size() >= get_max_cats():
			_btn_adopt_cat.text = "🐱 Đủ %d/%d Mèo" % [cats.size(), get_max_cats()]
		else:
			_btn_adopt_cat.text = "🐱 Đón Mèo (%d🪙)" % get_adopt_cat_cost()

	if _btn_open_skins != null:
		_btn_open_skins.text = "👗 Kho Skin (%d/%d)" % [get_total_unlocked_skins(), get_total_possible_skins()]

	if _btn_expand_map != null:
		if map_level >= MAP_TIERS.size():
			_btn_expand_map.text = "🗺️ Cấp Tối Đa"
		else:
			var next_cost: int = int(MAP_TIERS[map_level]["cost"])
			_btn_expand_map.text = "🗺️ Mở Cấp %d (%d🪙)" % [map_level + 1, next_cost]

	# Update Inspector Card for selected building
	if _lbl_inspector_title != null and _lbl_inspector_body != null and _btn_inspector_upgrade != null:
		var b: Dictionary = get_building_def(selected_building_id)
		var lv: int = int(building_levels.get(selected_building_id, 0))
		var cost: int = get_building_cost(selected_building_id)
		_lbl_inspector_title.text = "🏛️ %s [Cấp %d]" % [str(b["name"]), lv]
		_lbl_inspector_body.text = "%s\n• Thu nhập cơ bản: +%.1f Xu/s/cấp\n• Sản xuất nguyên liệu: +%.1f/s" % [
			str(b["desc"]), float(b["base_gps"]), float(b["prod_rate"]) * float(maxi(1, lv))
		]
		_btn_inspector_upgrade.text = "🔼 Nâng Cấp (%d🪙)" % cost
		BastionUI.apply_clash_button_style(_btn_inspector_upgrade, "gold" if fish_coins >= float(cost) else "blue", 11)

func _refresh_all_ui() -> void:
	_refresh_top_labels()
	_refresh_skin_modal()
	_refresh_deep_modal()

	for pid in _ui_style_buttons.keys():
		var btn_sw: Button = _ui_style_buttons[pid]
		BastionUI.apply_clash_button_style(btn_sw, "gold" if int(pid) == ui_style_id else "stone", 10)

	for b in BUILDING_DEFS:
		var b_id: String = str(b["id"])
		var btn: Button = _bldg_buttons.get(b_id, null)
		if btn == null:
			continue
		var req_map: int = int(b["req_map"])
		var lv: int = int(building_levels.get(b_id, 0))
		var cost: int = get_building_cost(b_id)
		var short_n: String = str(b["name"]).substr(0, 19)
		if map_level < req_map:
			btn.text = "🔒 %s\n(Cần Map Cấp %d)" % [short_n, req_map]
			BastionUI.apply_clash_button_style(btn, "stone", 10)
		elif lv == 0:
			btn.text = "🔨 Xây %s\n🪙 %d Xu (+%.0f/s)" % [short_n, cost, float(b["base_gps"])]
			BastionUI.apply_clash_button_style(btn, "green", 10)
		else:
			btn.text = "%s [Lv.%d]\n🔼 %d🪙 (+%.1f/s)" % [short_n, lv, cost, float(b["base_gps"])]
			BastionUI.apply_clash_button_style(btn, "gold" if fish_coins >= float(cost) else "blue", 10)
