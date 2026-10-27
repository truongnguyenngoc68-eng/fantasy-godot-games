extends Node3D
class_name Train09Defense

# ==============================================================================
# ĐOÀN TÀU SỐ 09 — CHƯƠNG 1: THÀNH PHỐ KHÔNG TẮT ĐÈN (PHƯƠNG ÁN 3: GÓC RỘNG)
# Built 100% from verified CC0 3D models (Quaternius + Kenney + OpenGameArt CC0)
# Core Loop (Idle Archer TD style):
#   Moving Maglev Train 09 -> Auto-firing Hero An, 2 Rotary Turrets & 2 Drones
#   -> 10 Waves of Mech Enemies + Boss Titan George -> In-run Energy Upgrades
#   (TÀU SỐ 09 / NHÂN VẬT AN) -> Persistent Scrap Bonus on Defeat & Retry.
# ==============================================================================

const SAVE_PATH: String = "user://train09_save.json"
const GLB_BASE: String = "res://assets/train09_glb/"

# Camera Presets (Default = Preset 3: Góc nhìn rộng toàn chiến trường)
const CAM_PRESETS: Array[Dictionary] = [
	{"id": 1, "name": "PA 1: TRÊN XUỐNG", "pos": Vector3(0.0, 22.0, 9.2), "target": Vector3(0.0, 0.4, 0.4), "fov": 43.0},
	{"id": 2, "name": "PA 2: GÓC 3/4", "pos": Vector3(9.6, 11.8, -14.5), "target": Vector3(-0.4, 0.4, -0.5), "fov": 43.0},
	{"id": 3, "name": "PA 3: GÓC RỘNG", "pos": Vector3(-6.8, 19.5, 14.5), "target": Vector3(0.0, 0.4, 0.2), "fov": 50.0},
]

var cam_preset_idx: int = 2 # Index 2 = Phương án 3 (Approved default)
var camera: Camera3D
var city_chunks: Array[Node3D] = []
var train_root: Node3D
var enemies_root: Node3D
var an_node: Node3D
var turret1_node: Node3D
var turret2_node: Node3D
var drone_left_node: Node3D
var drone_right_node: Node3D
var radar_node: Node3D
var hud_control: Control

var _glb_cache: Dictionary = {}
var _sign_textures: Array[Texture2D] = []

# Game State & Progression
var energy: int = 450
var scrap_run: int = 0
var scrap_total: int = 0
var current_wave: int = 1
var max_waves: int = 10
var enemies_killed_run: int = 0

var train_hp: float = 5000.0
var train_max_hp: float = 5000.0
var train_shield: float = 1200.0
var train_max_shield: float = 1200.0

var game_speed: float = 1.0
var is_paused: bool = false
var is_game_over: bool = false
var is_victory: bool = false

# 4 Core Upgrade Levels (2 Train + 2 Hero An)
var lv_turret: int = 1
var lv_armor_drone: int = 1
var lv_an_rifle: int = 1
var lv_an_crit: int = 1

# Combat Cooldowns
var cd_an: float = 0.0
var cd_turret1: float = 0.0
var cd_turret2: float = 0.0
var cd_drones: float = 0.0
var shield_regen_timer: float = 0.0
var anim_time: float = 0.0
var shake_strength: float = 0.0

# Wave Spawning
var wave_to_spawn: Array[Dictionary] = []
var spawn_timer: float = 0.0
var wave_banner_timer: float = 2.5

# Active Entities & Projected 2D VFX
var active_enemies: Array[Dictionary] = []
var active_beams: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

# UI Click Rectangles (computed dynamically in _draw_hud)
var rect_btn_speed: Rect2 = Rect2()
var rect_btn_pause: Rect2 = Rect2()
var rect_btn_cam: Rect2 = Rect2()
var rect_upg_cards: Array[Rect2] = [Rect2(), Rect2(), Rect2(), Rect2()]
var rect_btn_retry: Rect2 = Rect2()

var _screenshot_path: String = ""
var _screenshot_frames: int = 0

func _ready() -> void:
	# Configure 9:16 portrait window on desktop unless headless
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Đoàn Tàu Số 09 — Chương 1: Thành Phố Không Tắt Đèn (Phương án 3)")
		DisplayServer.window_set_size(Vector2i(630, 1120))
		var screen_sz: Vector2i = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_sz - Vector2i(630, 1120)) / 2)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")

	_load_persistent_save()
	_load_sign_textures()
	_setup_environment_and_lights()
	_build_scrolling_city()
	_build_train_09()
	_setup_hud_layer()
	_start_wave(1)

	# If --screenshot is requested, spawn an instant action showcase wave so the screenshot shows active beams & mechs
	if _screenshot_path != "":
		_spawn_showcase_enemies_for_screenshot()

func _load_persistent_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.ReadFlags.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				scrap_total = int(parsed.get("scrap_total", 0))

func _save_persistent_data() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.ModeFlags.WRITE)
	if f:
		f.store_string(JSON.stringify({"scrap_total": scrap_total}))

func _get_perm_bonus_mult() -> float:
	return 1.0 + float(scrap_total) * 0.001 # +10% per 100 Scrap

func _load_sign_textures() -> void:
	for sname in ["sign_1.png", "sign_2.png", "sign_3.png"]:
		var abs_p: String = ProjectSettings.globalize_path(GLB_BASE + sname)
		var img := Image.new()
		if img.load(abs_p) == OK:
			_sign_textures.append(ImageTexture.create_from_image(img))

func _load_glb_template(filename: String) -> Node3D:
	if _glb_cache.has(filename):
		return (_glb_cache[filename] as Node3D).duplicate()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var abs_p: String = ProjectSettings.globalize_path(GLB_BASE + filename)
	var err: Error = doc.append_from_file(abs_p, state)
	if err == OK:
		var root_node: Node = doc.generate_scene(state)
		if root_node is Node3D:
			_glb_cache[filename] = root_node
			return (root_node as Node3D).duplicate()
	var fallback := Node3D.new()
	return fallback

func _make_box(parent: Node3D, extents: Vector3, pos: Vector3, col: Color, emissive: Color = Color(0, 0, 0, 0), tex: Texture2D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = extents
	mi.mesh = bm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.35
	mat.roughness = 0.55
	if tex != null:
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = 0.9
	elif emissive.r > 0.01 or emissive.g > 0.01 or emissive.b > 0.01:
		mat.emission_enabled = true
		mat.emission = emissive
		mat.emission_energy_multiplier = 1.4
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _make_ring(parent: Node3D, radius: float, pos: Vector3, col: Color, thickness: float = 0.07) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(0.05, radius - thickness)
	tm.outer_radius = radius
	tm.rings = 32
	tm.ring_segments = 12
	mi.mesh = tm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _add_glb(parent: Node3D, filename: String, pos: Vector3, ry_deg: float = 0.0, sc: Vector3 = Vector3.ONE) -> Node3D:
	var inst: Node3D = _load_glb_template(filename)
	inst.position = pos
	inst.rotation_degrees = Vector3(0.0, ry_deg, 0.0)
	inst.scale = sc
	parent.add_child(inst)
	return inst

func _setup_environment_and_lights() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.54)
	env.ambient_light_energy = 1.15
	we.environment = env
	add_child(we)

	# Key Light
	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(0.96, 0.98, 1.0)
	key_light.light_energy = 1.45
	key_light.position = Vector3(12, 18, 10)
	add_child(key_light)
	key_light.look_at(Vector3.ZERO, Vector3.UP)

	# Cyan Rim Light
	var rim_light := DirectionalLight3D.new()
	rim_light.light_color = Color(0.0, 0.85, 1.0)
	rim_light.light_energy = 0.85
	rim_light.position = Vector3(-14, 10, -8)
	add_child(rim_light)
	rim_light.look_at(Vector3.ZERO, Vector3.UP)

	# Warm Street Fill Light
	var fill_light := DirectionalLight3D.new()
	fill_light.light_color = Color(1.0, 0.58, 0.25)
	fill_light.light_energy = 0.65
	fill_light.position = Vector3(14, 9, 8)
	add_child(fill_light)
	fill_light.look_at(Vector3.ZERO, Vector3.UP)

	camera = Camera3D.new()
	add_child(camera)
	_apply_camera_preset()

func _apply_camera_preset() -> void:
	var p: Dictionary = CAM_PRESETS[cam_preset_idx]
	camera.fov = float(p["fov"])
	camera.look_at_from_position(p["pos"] as Vector3, p["target"] as Vector3, Vector3.UP)

func _build_scrolling_city() -> void:
	# Static ground base & endless maglev glowing rails
	var static_base := Node3D.new()
	add_child(static_base)
	_make_box(static_base, Vector3(80, 0.1, 120), Vector3(0, -0.05, 0), Color(0.06, 0.08, 0.11))
	for side in [-1.0, 1.0]:
		_make_box(static_base, Vector3(6.5, 0.02, 110), Vector3(side * 5.2, 0.01, 0), Color(0.08, 0.10, 0.14))
		_make_box(static_base, Vector3(3.5, 0.18, 110), Vector3(side * 10.2, 0.09, 0), Color(0.13, 0.16, 0.21))
		_make_box(static_base, Vector3(0.08, 0.05, 110), Vector3(side * 8.45, 0.19, 0), Color(0.95, 0.55, 0.1), Color(0.8, 0.45, 0.05))
	# Central Raised Maglev Trackbed
	_make_box(static_base, Vector3(2.3, 0.14, 110), Vector3(0, 0.07, 0), Color(0.11, 0.14, 0.19))
	_make_box(static_base, Vector3(0.10, 0.08, 110), Vector3(-0.84, 0.16, 0), Color(0.0, 0.92, 1.0), Color(0.0, 0.92, 1.0))
	_make_box(static_base, Vector3(0.10, 0.08, 110), Vector3(0.84, 0.16, 0), Color(0.0, 0.92, 1.0), Color(0.0, 0.92, 1.0))

	# 2 Scrolling City Chunks (each 36m long) for seamless endless motion
	for c_idx in range(2):
		var chunk := Node3D.new()
		chunk.position = Vector3(0, 0, -18.0 + float(c_idx) * 36.0)
		add_child(chunk)
		city_chunks.append(chunk)

		# Sleepers & road stripes inside chunk (-18..+18)
		for i in range(18):
			var lz: float = -17.0 + float(i) * 2.0
			_make_box(chunk, Vector3(2.55, 0.10, 0.28), Vector3(0, 0.06, lz), Color(0.18, 0.23, 0.29))
			_make_box(chunk, Vector3(0.22, 0.04, 0.65), Vector3(0, 0.15, lz), Color(0.0, 0.75, 1.0), Color(0.0, 0.65, 0.95))
			for side in [-1.0, 1.0]:
				_make_box(chunk, Vector3(0.12, 0.03, 1.0), Vector3(side * 5.2, 0.025, lz), Color(0.22, 0.30, 0.40))

		# Buildings, Neon Billboards, Streetlights & Evacuation Props
		for b_i in range(6):
			var bz: float = -15.0 + float(b_i) * 6.0
			for side_idx in range(2):
				var side: float = -1.0 if side_idx == 0 else 1.0
				var xb: float = side * 11.2
				var hb: float = 4.5 + float((b_i + c_idx) % 3) * 1.5
				_make_box(chunk, Vector3(3.2, hb, 4.8), Vector3(xb, hb * 0.5, bz), Color(0.09, 0.12, 0.17))

				var face_x: float = side * 9.52
				if _sign_textures.size() > 0:
					var stex: Texture2D = _sign_textures[(b_i + side_idx + c_idx) % _sign_textures.size()]
					_make_box(chunk, Vector3(0.10, 1.15, 2.6), Vector3(face_x, 2.3 + float(b_i % 2) * 0.7, bz), Color.WHITE, Color.BLACK, stex)

				# Lit office windows
				_make_box(chunk, Vector3(0.06, 0.20, 3.4), Vector3(face_x, 1.0, bz), Color(0.95, 0.88, 0.65), Color(0.85, 0.78, 0.55))
				if hb > 4.2:
					_make_box(chunk, Vector3(0.06, 0.20, 3.4), Vector3(face_x, 3.6, bz), Color(0.95, 0.88, 0.65), Color(0.85, 0.78, 0.55))

				# Streetlight pole
				if b_i % 2 == 0:
					_make_box(chunk, Vector3(0.14, 2.4, 0.14), Vector3(side * 8.6, 1.2, bz + 2.2), Color(0.22, 0.26, 0.34))
					_make_box(chunk, Vector3(0.55, 0.10, 0.24), Vector3(side * 8.2, 2.45, bz + 2.2), Color(0.85, 0.96, 1.0), Color(0.8, 0.95, 1.0))

		# Evacuation props on roadside
		_add_glb(chunk, "prop_rover.glb", Vector3(-7.3, 0.02, -8.5), 28.0)
		_add_glb(chunk, "prop_round_rover.glb", Vector3(7.3, 0.02, -5.2), -35.0)
		_add_glb(chunk, "prop_container.glb", Vector3(7.4, 0.02, 6.5), -18.0)
		_add_glb(chunk, "prop_crate.glb", Vector3(-7.1, 0.02, 2.5), 18.0)
		_add_glb(chunk, "prop_barrel.glb", Vector3(-6.6, 0.02, 3.1), 0.0)
		_add_glb(chunk, "prop_crate.glb", Vector3(7.1, 0.02, -11.5), -24.0)

func _add_chassis_bogie(parent: Node3D, z_pos: float, length: float = 2.7, width: float = 1.24) -> void:
	_make_box(parent, Vector3(width, 0.24, length), Vector3(0, 0.26, z_pos), Color(0.08, 0.11, 0.15))
	for dz in [-length * 0.34, length * 0.34]:
		_make_box(parent, Vector3(width + 0.22, 0.16, length * 0.22), Vector3(0, 0.22, z_pos + dz), Color(0.14, 0.18, 0.24))
	_make_box(parent, Vector3(width + 0.10, 0.045, length * 0.84), Vector3(0, 0.18, z_pos), Color(0.0, 0.92, 1.0), Color(0.0, 0.92, 1.0))

func _add_symmetrical_car(parent: Node3D, glb_name: String, z_center: float, scale_x: float = 0.60) -> void:
	var sc := Vector3(scale_x, 0.96, 0.67)
	_add_glb(parent, glb_name, Vector3(0, 0.32, z_center - 0.40), 0.0, sc)
	_add_glb(parent, glb_name, Vector3(0, 0.32, z_center + 0.40), 180.0, sc)

func _build_train_09() -> void:
	train_root = Node3D.new()
	add_child(train_root)

	# 1. Lead Locomotive #09 (Z = -5.8, Executioner Maglev)
	_add_chassis_bogie(train_root, -5.5, 3.2, 1.24)
	_add_glb(train_root, "loco_executioner.glb", Vector3(0, 0.32, -5.8), 180.0, Vector3(0.58, 1.02, 0.96))
	# Headlights
	_make_box(train_root, Vector3(0.18, 0.08, 0.12), Vector3(-0.36, 0.48, -7.55), Color(0.8, 0.98, 1.0), Color(0.8, 0.98, 1.0))
	_make_box(train_root, Vector3(0.18, 0.08, 0.12), Vector3(0.36, 0.48, -7.55), Color(0.8, 0.98, 1.0), Color(0.8, 0.98, 1.0))

	# Coupling 1
	_add_glb(train_root, "connector.glb", Vector3(0, 0.30, -3.55), 0.0, Vector3(0.75, 0.75, 0.85))

	# 2. Car 1 (Z = -1.5): Boong Chiến Đấu của AN + Pháo Xoay 1
	_add_chassis_bogie(train_root, -1.5, 2.7, 1.24)
	_add_symmetrical_car(train_root, "car_insurgent.glb", -1.5, 0.60)
	_make_ring(train_root, 0.48, Vector3(0, 0.84, -2.05), Color(0.0, 0.98, 1.0), 0.06)
	an_node = _add_glb(train_root, "hero_an.glb", Vector3(0, 0.83, -2.05), -80.0, Vector3.ONE)
	turret1_node = _add_glb(train_root, "rotary_turret.glb", Vector3(0, 0.82, -0.95), 75.0, Vector3.ONE)

	# Coupling 2
	_add_glb(train_root, "connector.glb", Vector3(0, 0.30, 0.55), 0.0, Vector3(0.75, 0.75, 0.85))

	# 3. Car 2 (Z = +2.6): Lõi Năng Lượng & 2 Drone Hộ Tống
	_add_chassis_bogie(train_root, 2.6, 2.7, 1.24)
	_add_symmetrical_car(train_root, "car_executioner.glb", 2.6, 0.56)
	_add_glb(train_root, "energy_capsule.glb", Vector3(0, 0.78, 2.15))
	_add_glb(train_root, "energy_capsule.glb", Vector3(0, 0.78, 3.05))
	drone_left_node = _add_glb(train_root, "combat_drone.glb", Vector3(-0.95, 1.62, 2.2), -75.0)
	drone_right_node = _add_glb(train_root, "combat_drone.glb", Vector3(0.95, 1.62, 2.9), 75.0)

	# Coupling 3
	_add_glb(train_root, "connector.glb", Vector3(0, 0.30, 4.65), 0.0, Vector3(0.75, 0.75, 0.85))

	# 4. Car 3 (Z = +6.7): Pháo Xoay Bọc Hậu & Chảo Radar
	_add_chassis_bogie(train_root, 6.7, 2.7, 1.24)
	_add_symmetrical_car(train_root, "car_insurgent.glb", 6.7, 0.60)
	turret2_node = _add_glb(train_root, "rotary_turret.glb", Vector3(0, 0.82, 6.2), -65.0)
	radar_node = _add_glb(train_root, "roof_radar.glb", Vector3(0, 0.82, 7.25), 0.0)

	enemies_root = Node3D.new()
	add_child(enemies_root)

func _setup_hud_layer() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	hud_control = Control.new()
	hud_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_control.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_control.draw.connect(_draw_hud)
	hud_control.gui_input.connect(_on_hud_input)
	cl.add_child(hud_control)

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_banner_timer = 2.6
	wave_to_spawn.clear()

	var count: int = 6 + wave_num * 2
	var hp_scale: float = pow(1.22, float(wave_num - 1))
	for i in range(count):
		var side: float = -1.0 if (i % 2 == 0) else 1.0
		var z_lane: float = randf_range(-5.8, 6.4)
		var kind: int = (i + wave_num) % 5
		var glb_file: String = "enemy_trilobite.glb"
		var base_hp: float = 420.0
		var spd: float = 1.15
		var dmg: float = 42.0
		var reward_e: int = 45
		var reward_s: int = 12
		if kind == 1:
			glb_file = "enemy_quadshell.glb"
			base_hp = 560.0
			spd = 0.98
			dmg = 55.0
			reward_e = 55
			reward_s = 15
		elif kind == 2:
			glb_file = "enemy_leela.glb"
			base_hp = 780.0
			spd = 0.88
			dmg = 72.0
			reward_e = 75
			reward_s = 20
		elif kind == 3:
			glb_file = "enemy_stan.glb"
			base_hp = 1050.0
			spd = 0.72
			dmg = 90.0
			reward_e = 95
			reward_s = 26
		elif kind == 4:
			glb_file = "enemy_mike.glb"
			base_hp = 1280.0
			spd = 0.68
			dmg = 110.0
			reward_e = 115
			reward_s = 32

		wave_to_spawn.append({
			"glb": glb_file,
			"is_boss": false,
			"name": "Quái Máy",
			"hp": base_hp * hp_scale,
			"max_hp": base_hp * hp_scale,
			"speed": spd,
			"dmg": dmg * (1.0 + float(wave_num - 1) * 0.12),
			"side": side,
			"z": z_lane,
			"energy": reward_e,
			"scrap": reward_s,
		})

	# Spawn Boss Titan George on Wave 5 (Mini-Boss) and Wave 10 (Chapter Boss)
	if wave_num == 5 or wave_num == 10:
		var boss_hp: float = 6500.0 if wave_num == 5 else 16000.0
		wave_to_spawn.append({
			"glb": "boss_george.glb",
			"is_boss": true,
			"name": "TIỂU BOSS GEORGE" if wave_num == 5 else "BOSS TITAN GEORGE",
			"hp": boss_hp,
			"max_hp": boss_hp,
			"speed": 0.52,
			"dmg": 240.0 if wave_num == 5 else 420.0,
			"side": -1.0,
			"z": -1.8,
			"energy": 450 if wave_num == 5 else 1200,
			"scrap": 150 if wave_num == 5 else 450,
		})

	spawn_timer = 0.25

func _spawn_enemy_dict(spec: Dictionary, start_x_abs: float = 8.2) -> Dictionary:
	var root := Node3D.new()
	var side: float = float(spec["side"])
	var z_pos: float = float(spec["z"])
	root.position = Vector3(side * start_x_abs, 0.02, z_pos)
	enemies_root.add_child(root)

	var is_boss: bool = bool(spec.get("is_boss", false))
	var ring_r: float = 1.05 if is_boss else 0.65
	var ring_col: Color = Color(1.0, 0.12, 0.18) if is_boss else Color(1.0, 0.25, 0.15)
	_make_ring(root, ring_r, Vector3(0, 0.03, 0), ring_col, 0.08 if is_boss else 0.06)

	var ry: float = 90.0 if side < 0.0 else -90.0
	var model: Node3D = _add_glb(root, String(spec["glb"]), Vector3.ZERO, ry, Vector3.ONE)
	var e_data: Dictionary = {
		"node": root,
		"model": model,
		"is_boss": is_boss,
		"name": spec.get("name", "Quái Máy"),
		"hp": float(spec["hp"]),
		"max_hp": float(spec["max_hp"]),
		"speed": float(spec["speed"]),
		"dmg": float(spec["dmg"]),
		"side": side,
		"z": z_pos,
		"energy": int(spec["energy"]),
		"scrap": int(spec["scrap"]),
		"atk_cd": 0.8,
		"phase": randf() * TAU,
	}
	active_enemies.append(e_data)
	return e_data

func _spawn_showcase_enemies_for_screenshot() -> void:
	current_wave = 4
	energy = 2450
	scrap_run = 840
	lv_turret = 4
	lv_armor_drone = 3
	lv_an_rifle = 5
	lv_an_crit = 4
	train_hp = 4400.0
	train_max_hp = 5000.0
	wave_to_spawn.clear()

	var demo_specs: Array[Dictionary] = [
		{"glb": "boss_george.glb", "is_boss": false, "name": "George", "hp": 1400.0, "max_hp": 2200.0, "speed": 0.6, "dmg": 60.0, "side": -1.0, "z": -2.5, "energy": 80, "scrap": 20, "x": 3.8},
		{"glb": "enemy_mike.glb", "is_boss": false, "name": "Mike", "hp": 1100.0, "max_hp": 1600.0, "speed": 0.6, "dmg": 60.0, "side": -1.0, "z": 2.0, "energy": 80, "scrap": 20, "x": 4.5},
		{"glb": "enemy_quadshell.glb", "is_boss": false, "name": "QuadShell", "hp": 700.0, "max_hp": 900.0, "speed": 0.8, "dmg": 45.0, "side": -1.0, "z": -5.8, "energy": 50, "scrap": 15, "x": 3.5},
		{"glb": "enemy_trilobite.glb", "is_boss": false, "name": "Trilobite", "hp": 520.0, "max_hp": 800.0, "speed": 0.9, "dmg": 40.0, "side": -1.0, "z": 5.5, "energy": 45, "scrap": 12, "x": 3.6},
		{"glb": "enemy_leela.glb", "is_boss": false, "name": "Leela", "hp": 950.0, "max_hp": 1400.0, "speed": 0.8, "dmg": 65.0, "side": 1.0, "z": -1.2, "energy": 70, "scrap": 18, "x": 3.9},
		{"glb": "enemy_quadshell.glb", "is_boss": false, "name": "QuadShell", "hp": 620.0, "max_hp": 900.0, "speed": 0.8, "dmg": 45.0, "side": 1.0, "z": 2.8, "energy": 50, "scrap": 15, "x": 3.5},
		{"glb": "enemy_stan.glb", "is_boss": false, "name": "Stan", "hp": 1200.0, "max_hp": 1500.0, "speed": 0.7, "dmg": 75.0, "side": 1.0, "z": -5.2, "energy": 85, "scrap": 22, "x": 4.6},
	]
	for sp in demo_specs:
		_spawn_enemy_dict(sp, float(sp["x"]))

	# Fire initial beams so frame 1-5 has full combat VFX
	_fire_beam(Vector3(-0.42, 1.48, -2.05), Vector3(-3.65, 0.92, -2.5), Color(0.0, 0.96, 1.0), "-1,250 CRIT!", true)
	_fire_beam(Vector3(0.45, 1.15, -0.95), Vector3(3.75, 0.92, -1.2), Color(1.0, 0.78, 0.22), "-680", false)
	_fire_beam(Vector3(-0.95, 1.62, 2.2), Vector3(-4.35, 0.98, 2.0), Color(0.16, 0.92, 1.0), "-490", false)
	_fire_beam(Vector3(0.95, 1.62, 2.9), Vector3(3.4, 0.58, 2.8), Color(0.16, 0.92, 1.0), "-420", false)
	_fire_beam(Vector3(-0.45, 1.15, 6.2), Vector3(-3.45, 0.55, 5.5), Color(1.0, 0.78, 0.22), "-710", false)

func _fire_beam(from_3d: Vector3, to_3d: Vector3, col: Color, dmg_label: String, is_crit: bool) -> void:
	active_beams.append({
		"from": from_3d,
		"to": to_3d,
		"col": col,
		"ttl": 0.26,
		"max_ttl": 0.26,
	})
	floating_texts.append({
		"pos_3d": to_3d + Vector3(0, 0.55, 0),
		"text": dmg_label,
		"col": Color(0.0, 0.98, 1.0) if is_crit else col,
		"ttl": 0.75,
		"vy": 38.0,
	})

func _find_nearest_enemy(origin_3d: Vector3, prefer_boss: bool = false) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = 999999.0
	for e in active_enemies:
		var n: Node3D = e["node"] as Node3D
		if not is_instance_valid(n):
			continue
		var d: float = origin_3d.distance_to(n.position)
		if prefer_boss and bool(e["is_boss"]):
			d *= 0.35
		if d < best_score:
			best_score = d
			best = e
	return best

func _damage_enemy(e: Dictionary, amount: float, muzzle_3d: Vector3, beam_col: Color, is_crit: bool = false) -> void:
	if not e.has("node") or not is_instance_valid(e["node"]):
		return
	var n: Node3D = e["node"] as Node3D
	var hit_pos: Vector3 = n.position + Vector3(0, 0.85 if bool(e["is_boss"]) else 0.65, 0)
	e["hp"] = float(e["hp"]) - amount
	var txt: String = "-%d%s" % [int(round(amount)), " CRIT!" if is_crit else ""]
	_fire_beam(muzzle_3d, hit_pos, beam_col, txt, is_crit)

	if float(e["hp"]) <= 0.0:
		energy += int(e["energy"])
		var s_gain: int = int(e["scrap"])
		scrap_run += s_gain
		scrap_total += s_gain
		enemies_killed_run += 1
		_save_persistent_data()
		n.queue_free()
		active_enemies.erase(e)

func _aim_node_at(node: Node3D, target_pos: Vector3) -> void:
	if not is_instance_valid(node):
		return
	var dx: float = target_pos.x - node.global_position.x
	var dz: float = target_pos.z - node.global_position.z
	node.rotation.y = atan2(dx, dz)

func _process(delta: float) -> void:
	if _screenshot_path != "":
		_screenshot_frames += 1
		if _screenshot_frames >= 5:
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png(_screenshot_path)
			print("Saved in-engine screenshot to: ", _screenshot_path)
			get_tree().quit()
			return

	if is_paused or is_game_over or is_victory:
		hud_control.queue_redraw()
		return

	var dt: float = delta * game_speed
	anim_time += dt
	if wave_banner_timer > 0.0:
		wave_banner_timer = maxf(0.0, wave_banner_timer - dt)

	# 1. Scroll the 3D City to convey Train 09 speeding along the Maglev rail
	var scroll_spd: float = 7.5
	for chunk in city_chunks:
		chunk.position.z += scroll_spd * dt
		if chunk.position.z > 36.0:
			chunk.position.z -= 72.0

	# Subtle train hover & drone bobbing + radar spin
	if is_instance_valid(drone_left_node):
		drone_left_node.position.y = 1.62 + sin(anim_time * 3.5) * 0.12
	if is_instance_valid(drone_right_node):
		drone_right_node.position.y = 1.62 + cos(anim_time * 3.5) * 0.12
	if is_instance_valid(radar_node):
		radar_node.rotation.y += dt * 1.8

	# Shield passive regeneration
	shield_regen_timer += dt
	if shield_regen_timer >= 1.0:
		shield_regen_timer = 0.0
		train_shield = minf(train_max_shield, train_shield + 25.0 + float(lv_armor_drone) * 10.0)

	# 2. Spawn Enemies from Current Wave Queue
	if wave_to_spawn.size() > 0:
		spawn_timer -= dt
		if spawn_timer <= 0.0:
			var next_spec: Dictionary = wave_to_spawn.pop_front()
			_spawn_enemy_dict(next_spec, 8.8)
			spawn_timer = 0.85

	# 3. Update Enemies (Move toward Maglev Track & Attack Train 09)
	for i in range(active_enemies.size() - 1, -1, -1):
		var e: Dictionary = active_enemies[i]
		var n: Node3D = e["node"] as Node3D
		if not is_instance_valid(n):
			active_enemies.remove_at(i)
			continue
		var side: float = float(e["side"])
		var target_x: float = side * 1.95
		if absf(n.position.x) > 2.02:
			n.position.x = move_toward(n.position.x, target_x, float(e["speed"]) * dt)
			var m: Node3D = e["model"] as Node3D
			if is_instance_valid(m):
				m.position.y = absf(sin(anim_time * 6.0 + float(e["phase"]))) * 0.10
		else:
			e["atk_cd"] = float(e["atk_cd"]) - dt
			if float(e["atk_cd"]) <= 0.0:
				e["atk_cd"] = 1.15
				_apply_damage_to_train(float(e["dmg"]), n.position + Vector3(0, 0.7, 0))

	# 4. Auto-Fire Weapons: Hero An, 2 Rotary Turrets, and 2 Combat Drones
	var perm_mult: float = _get_perm_bonus_mult()

	# (A) Hero An — High-Damage Cyber-Sniper (prioritizes Boss/Elite)
	cd_an -= dt
	if cd_an <= 0.0 and active_enemies.size() > 0:
		var tgt_an: Dictionary = _find_nearest_enemy(Vector3(0, 1.2, -2.05), true)
		if not tgt_an.is_empty():
			var tn: Node3D = tgt_an["node"] as Node3D
			_aim_node_at(an_node, tn.position)
			var base_dmg: float = (260.0 + float(lv_an_rifle - 1) * 65.0) * perm_mult
			var crit_chance: float = minf(0.75, 0.15 + float(lv_an_crit - 1) * 0.05)
			var is_crit: bool = randf() < crit_chance
			if is_crit:
				base_dmg *= 2.4
			_damage_enemy(tgt_an, base_dmg, Vector3(0, 1.48, -2.05), Color(0.0, 0.96, 1.0), is_crit)
			cd_an = maxf(0.28, 0.95 * pow(0.90, float(lv_an_crit - 1)))

	# (B) Forward Rotary Turret (Car 1)
	cd_turret1 -= dt
	if cd_turret1 <= 0.0 and active_enemies.size() > 0:
		var tgt_t1: Dictionary = _find_nearest_enemy(Vector3(0, 1.1, -0.95), false)
		if not tgt_t1.is_empty():
			var tn1: Node3D = tgt_t1["node"] as Node3D
			_aim_node_at(turret1_node, tn1.position)
			var t_dmg: float = (135.0 * pow(1.18, float(lv_turret - 1))) * perm_mult
			_damage_enemy(tgt_t1, t_dmg, Vector3(0, 1.15, -0.95), Color(1.0, 0.78, 0.22), false)
			cd_turret1 = maxf(0.22, 0.68 * pow(0.92, float(lv_turret - 1)))

	# (C) Rear Heavy Rotary Turret (Car 3)
	cd_turret2 -= dt
	if cd_turret2 <= 0.0 and active_enemies.size() > 0:
		var tgt_t2: Dictionary = _find_nearest_enemy(Vector3(0, 1.1, 6.2), false)
		if not tgt_t2.is_empty():
			var tn2: Node3D = tgt_t2["node"] as Node3D
			_aim_node_at(turret2_node, tn2.position)
			var t2_dmg: float = (145.0 * pow(1.18, float(lv_turret - 1))) * perm_mult
			_damage_enemy(tgt_t2, t2_dmg, Vector3(0, 1.15, 6.2), Color(1.0, 0.78, 0.22), false)
			cd_turret2 = maxf(0.24, 0.72 * pow(0.92, float(lv_turret - 1)))

	# (D) Twin Support Drones (Car 2)
	cd_drones -= dt
	if cd_drones <= 0.0 and active_enemies.size() > 0:
		var shots_per_drone: int = 1 + int((lv_armor_drone - 1) / 2)
		for d_node in [drone_left_node, drone_right_node]:
			if not is_instance_valid(d_node):
				continue
			for _s in range(shots_per_drone):
				if active_enemies.is_empty():
					break
				var tgt_d: Dictionary = active_enemies[randi() % active_enemies.size()]
				var d_dmg: float = (85.0 + float(lv_armor_drone - 1) * 28.0) * perm_mult
				_damage_enemy(tgt_d, d_dmg, d_node.global_position, Color(0.18, 0.92, 1.0), false)
		cd_drones = 0.82

	# 5. Advance Wave when all enemies are cleared
	if wave_to_spawn.is_empty() and active_enemies.is_empty():
		if current_wave < max_waves:
			_start_wave(current_wave + 1)
		else:
			is_victory = true

	# 6. Decay Beams & Floating Combat Text
	for i in range(active_beams.size() - 1, -1, -1):
		active_beams[i]["ttl"] = float(active_beams[i]["ttl"]) - delta
		if float(active_beams[i]["ttl"]) <= 0.0:
			active_beams.remove_at(i)

	for i in range(floating_texts.size() - 1, -1, -1):
		floating_texts[i]["ttl"] = float(floating_texts[i]["ttl"]) - delta
		floating_texts[i]["pos_3d"] = (floating_texts[i]["pos_3d"] as Vector3) + Vector3(0, delta * 0.85, 0)
		if float(floating_texts[i]["ttl"]) <= 0.0:
			floating_texts.remove_at(i)

	hud_control.queue_redraw()

func _apply_damage_to_train(dmg: float, attacker_pos: Vector3) -> void:
	_fire_beam(attacker_pos, Vector3(0, 0.75, clampf(attacker_pos.z, -5.8, 6.7)), Color(1.0, 0.25, 0.2), "", false)
	if train_shield > 0.0:
		var absorbed: float = minf(train_shield, dmg)
		train_shield -= absorbed
		dmg -= absorbed
	if dmg > 0.0:
		train_hp = maxf(0.0, train_hp - dmg)
		if train_hp <= 0.0:
			is_game_over = true

func _get_upgrade_cost(idx: int) -> int:
	match idx:
		0: return 150 + (lv_turret - 1) * 85
		1: return 180 + (lv_armor_drone - 1) * 95
		2: return 140 + (lv_an_rifle - 1) * 80
		3: return 165 + (lv_an_crit - 1) * 90
	return 200

func _buy_upgrade(idx: int) -> void:
	var cost: int = _get_upgrade_cost(idx)
	if energy < cost:
		return
	energy -= cost
	match idx:
		0:
			lv_turret += 1
		1:
			lv_armor_drone += 1
			train_max_hp += 500.0
			train_hp = minf(train_max_hp, train_hp + 600.0)
			train_max_shield += 250.0
			train_shield = minf(train_max_shield, train_shield + 350.0)
		2:
			lv_an_rifle += 1
		3:
			lv_an_crit += 1

func _restart_run() -> void:
	for e in active_enemies:
		var n: Node3D = e.get("node") as Node3D
		if is_instance_valid(n):
			n.queue_free()
	active_enemies.clear()
	active_beams.clear()
	floating_texts.clear()

	energy = 450
	scrap_run = 0
	enemies_killed_run = 0
	lv_turret = 1
	lv_armor_drone = 1
	lv_an_rifle = 1
	lv_an_crit = 1

	var perm_mult: float = _get_perm_bonus_mult()
	train_max_hp = round(5000.0 * perm_mult)
	train_hp = train_max_hp
	train_max_shield = round(1200.0 * perm_mult)
	train_shield = train_max_shield

	is_game_over = false
	is_victory = false
	is_paused = false
	_start_wave(1)

func _on_hud_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ke := event as InputEventKey
		if ke.keycode == KEY_1:
			cam_preset_idx = 0
			_apply_camera_preset()
		elif ke.keycode == KEY_2:
			cam_preset_idx = 1
			_apply_camera_preset()
		elif ke.keycode == KEY_3:
			cam_preset_idx = 2
			_apply_camera_preset()
		elif ke.keycode == KEY_SPACE:
			is_paused = not is_paused

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mp: Vector2 = event.position
		if is_game_over or is_victory:
			if rect_btn_retry.has_point(mp):
				_restart_run()
			return

		if rect_btn_speed.has_point(mp):
			game_speed = 2.0 if is_equal_approx(game_speed, 1.0) else 1.0
			return
		if rect_btn_pause.has_point(mp):
			is_paused = not is_paused
			return
		if rect_btn_cam.has_point(mp):
			cam_preset_idx = (cam_preset_idx + 1) % CAM_PRESETS.size()
			_apply_camera_preset()
			return

		for i in range(4):
			if rect_upg_cards[i].has_point(mp):
				_buy_upgrade(i)
				return

		# Clicking on battlefield triggers manual sniper focus shot from An!
		if active_enemies.size() > 0 and not is_paused:
			var best_e: Dictionary = {}
			var best_d: float = 99999.0
			for e in active_enemies:
				var n: Node3D = e["node"] as Node3D
				if is_instance_valid(n) and not camera.is_position_behind(n.global_position):
					var sp: Vector2 = camera.unproject_position(n.global_position)
					var d: float = sp.distance_to(mp)
					if d < best_d:
						best_d = d
						best_e = e
			if not best_e.is_empty() and best_d < 140.0:
				var tn: Node3D = best_e["node"] as Node3D
				_aim_node_at(an_node, tn.position)
				var manual_dmg: float = (160.0 + float(lv_an_rifle - 1) * 45.0) * _get_perm_bonus_mult()
				_damage_enemy(best_e, manual_dmg, Vector3(0, 1.48, -2.05), Color(0.0, 0.98, 1.0), true)

func _draw_pill(r: Rect2, bg: Color, border: Color, radius: float = 8.0, border_w: float = 2.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(int(border_w))
	sb.set_corner_radius_all(int(radius))
	hud_control.draw_style_box(sb, r)

func _draw_hud() -> void:
	var vp: Vector2 = hud_control.size
	var w: float = vp.x
	var h: float = vp.y
	var font: Font = ThemeDB.fallback_font

	# ==========================================================================
	# 1. 3D -> 2D PROJECTED LASER BEAMS, ENEMY HP BARS & CALLOUTS
	# ==========================================================================
	for b in active_beams:
		var p1_3d: Vector3 = b["from"]
		var p2_3d: Vector3 = b["to"]
		if camera.is_position_behind(p1_3d) or camera.is_position_behind(p2_3d):
			continue
		var p1: Vector2 = camera.unproject_position(p1_3d)
		var p2: Vector2 = camera.unproject_position(p2_3d)
		var alpha: float = clampf(float(b["ttl"]) / float(b["max_ttl"]), 0.0, 1.0)
		var col: Color = b["col"]
		hud_control.draw_line(p1, p2, Color(col.r, col.g, col.b, 0.38 * alpha), 10.0)
		hud_control.draw_line(p1, p2, Color(col.r, col.g, col.b, 0.85 * alpha), 4.5)
		hud_control.draw_line(p1, p2, Color(1, 1, 1, 0.95 * alpha), 2.0)
		hud_control.draw_circle(p1, 5.5, Color(col.r, col.g, col.b, 0.85 * alpha))
		hud_control.draw_circle(p1, 3.0, Color(1, 1, 1, alpha))
		hud_control.draw_circle(p2, 8.0, Color(col.r, col.g, col.b, 0.75 * alpha))
		hud_control.draw_arc(p2, 12.0 * (1.2 - alpha * 0.5), 0.0, TAU, 24, Color(col.r, col.g, col.b, alpha), 2.0)

	# Enemy Overhead HP Bars
	var active_boss: Dictionary = {}
	for e in active_enemies:
		if bool(e["is_boss"]):
			active_boss = e
		var n: Node3D = e["node"] as Node3D
		if not is_instance_valid(n) or camera.is_position_behind(n.global_position):
			continue
		var sp: Vector2 = camera.unproject_position(n.global_position + Vector3(0, 1.35 if bool(e["is_boss"]) else 1.05, 0))
		var bw: float = 58.0 if bool(e["is_boss"]) else 42.0
		var bh: float = 6.0
		var ratio: float = clampf(float(e["hp"]) / maxf(1.0, float(e["max_hp"])), 0.0, 1.0)
		hud_control.draw_rect(Rect2(sp.x - bw * 0.5 - 1, sp.y - 1, bw + 2, bh + 2), Color(0.06, 0.08, 0.12, 0.9))
		hud_control.draw_rect(Rect2(sp.x - bw * 0.5, sp.y, bw * ratio, bh), Color(1.0, 0.24, 0.20, 0.95))

	# Callouts on Train 09 & Hero An
	if not camera.is_position_behind(Vector3(0, 2.08, -2.05)):
		var p_an: Vector2 = camera.unproject_position(Vector3(0, 2.08, -2.05))
		var r_an := Rect2(p_an.x - 44, p_an.y - 26, 88, 20)
		_draw_pill(r_an, Color(0.03, 0.09, 0.16, 0.88), Color(0.0, 0.96, 1.0, 0.95), 5.0, 1.5)
		hud_control.draw_string(font, Vector2(r_an.position.x + 8, r_an.position.y + 14), "AN (XẠ THỦ)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.0, 0.96, 1.0))

	if not camera.is_position_behind(Vector3(0, 1.15, -5.8)):
		var p_loco: Vector2 = camera.unproject_position(Vector3(0, 1.15, -5.8))
		var r_loco := Rect2(p_loco.x - 48, p_loco.y - 12, 96, 20)
		_draw_pill(r_loco, Color(0.04, 0.10, 0.18, 0.85), Color(0.0, 0.88, 1.0, 0.85), 5.0, 1.0)
		hud_control.draw_string(font, Vector2(r_loco.position.x + 8, r_loco.position.y + 14), "ĐẦU TÀU SỐ 09", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.98, 1.0))

	# Floating Damage Numbers
	for ft in floating_texts:
		var p3: Vector3 = ft["pos_3d"]
		if camera.is_position_behind(p3):
			continue
		var sp: Vector2 = camera.unproject_position(p3)
		var col: Color = ft["col"]
		hud_control.draw_string(font, sp + Vector2(1, 1), String(ft["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.9))
		hud_control.draw_string(font, sp, String(ft["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)

	# ==========================================================================
	# 2. TOP STATUS BAR (MINIMALIST & HIGH-CONTRAST)
	# ==========================================================================
	var top_h: float = 114.0
	hud_control.draw_rect(Rect2(0, 0, w, top_h), Color(0.03, 0.05, 0.09, 0.90))
	hud_control.draw_line(Vector2(0, top_h), Vector2(w, top_h), Color(0.0, 0.85, 1.0, 0.75), 2.0)

	# Top Title Strip
	hud_control.draw_rect(Rect2(0, 0, w, 26), Color(0.0, 0.16, 0.27, 0.95))
	var cam_info: Dictionary = CAM_PRESETS[cam_preset_idx]
	hud_control.draw_string(font, Vector2(12, 18), "ĐOÀN TÀU SỐ 09  •  " + String(cam_info["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.0, 0.96, 1.0))
	rect_btn_cam = Rect2(w - 118, 3, 108, 20)
	_draw_pill(rect_btn_cam, Color(0.06, 0.24, 0.38, 0.95), Color(0.0, 0.9, 1.0, 0.8), 4.0, 1.0)
	hud_control.draw_string(font, Vector2(rect_btn_cam.position.x + 8, 17), "ĐỔI GÓC NHÌN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# Wave Pill
	var r_wave := Rect2(10, 32, w * 0.42, 38)
	_draw_pill(r_wave, Color(0.05, 0.09, 0.16, 0.95), Color(0.0, 0.75, 0.92, 0.75), 7.0, 1.5)
	hud_control.draw_string(font, Vector2(18, 46), "CHƯƠNG 1: THÀNH PHỐ KHÔNG TẮT ĐÈN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.65, 0.85, 0.96))
	hud_control.draw_string(font, Vector2(18, 63), "ĐỢT ĐỊCH: %02d / %02d" % [current_wave, max_waves], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	# Energy Pill
	var r_en := Rect2(w * 0.44, 32, w * 0.20, 38)
	_draw_pill(r_en, Color(0.05, 0.09, 0.16, 0.95), Color(0.0, 0.88, 1.0, 0.70), 7.0, 1.5)
	hud_control.draw_circle(Vector2(r_en.position.x + 14, r_en.position.y + 19), 7.0, Color(0.0, 0.92, 1.0))
	hud_control.draw_string(font, Vector2(r_en.position.x + 26, 46), "NĂNG LƯỢNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.82, 0.95))
	hud_control.draw_string(font, Vector2(r_en.position.x + 26, 63), str(energy), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.0, 0.96, 1.0))

	# Scrap Pill
	var r_sc := Rect2(w * 0.65, 32, w * 0.20, 38)
	_draw_pill(r_sc, Color(0.05, 0.09, 0.16, 0.95), Color(1.0, 0.76, 0.25, 0.70), 7.0, 1.5)
	hud_control.draw_circle(Vector2(r_sc.position.x + 14, r_sc.position.y + 19), 7.0, Color(1.0, 0.78, 0.25))
	hud_control.draw_string(font, Vector2(r_sc.position.x + 26, 46), "MẢNH CƠ KHÍ", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.92, 0.80, 0.60))
	hud_control.draw_string(font, Vector2(r_sc.position.x + 26, 63), str(scrap_total), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.82, 0.32))

	# Speed & Pause Buttons
	rect_btn_speed = Rect2(w * 0.86, 32, w * 0.06, 38)
	_draw_pill(rect_btn_speed, Color(0.08, 0.16, 0.26, 0.95), Color(0.4, 0.75, 0.95, 0.8), 6.0, 1.5)
	hud_control.draw_string(font, Vector2(rect_btn_speed.position.x + 8, 56), "x2" if game_speed > 1.5 else "x1", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.0, 0.96, 1.0) if game_speed > 1.5 else Color.WHITE)

	rect_btn_pause = Rect2(w * 0.93, 32, w * 0.055, 38)
	_draw_pill(rect_btn_pause, Color(0.08, 0.16, 0.26, 0.95), Color(0.4, 0.75, 0.95, 0.8), 6.0, 1.5)
	hud_control.draw_string(font, Vector2(rect_btn_pause.position.x + 10, 56), "||", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	# Train 09 HP & Shield Bar
	var r_hp_bg := Rect2(10, 76, w - 20, 30)
	_draw_pill(r_hp_bg, Color(0.06, 0.09, 0.14, 0.95), Color(0.25, 0.38, 0.52, 0.8), 7.0, 1.5)
	var hp_ratio: float = clampf(train_hp / maxf(1.0, train_max_hp), 0.0, 1.0)
	var sh_ratio: float = clampf(train_shield / maxf(1.0, train_max_shield), 0.0, 1.0)
	if hp_ratio > 0.0:
		_draw_pill(Rect2(13, 79, (w - 26) * hp_ratio, 24), Color(0.0, 0.72, 0.52, 0.92), Color(0, 0, 0, 0), 5.0, 0.0)
	if sh_ratio > 0.0:
		_draw_pill(Rect2(13, 79, (w - 26) * sh_ratio, 6), Color(0.0, 0.92, 1.0, 0.95), Color(0, 0, 0, 0), 3.0, 0.0)
	hud_control.draw_string(font, Vector2(22, 96), "MÁU ĐOÀN TÀU SỐ 09: %d / %d HP" % [int(train_hp), int(train_max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	hud_control.draw_string(font, Vector2(w - 210, 96), "LÁ CHẮN: +%d" % int(train_shield), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.76, 0.97, 1.0))

	# Boss Warning Banner & HP Bar (when Boss is alive)
	if not active_boss.is_empty():
		var r_boss := Rect2(16, top_h + 8, w - 32, 52)
		_draw_pill(r_boss, Color(0.18, 0.03, 0.06, 0.92), Color(1.0, 0.22, 0.25, 0.95), 8.0, 2.0)
		hud_control.draw_string(font, Vector2(28, top_h + 26), "[!] CẢNH BÁO: " + String(active_boss["name"]) + " ĐANG TẤN CÔNG!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.42, 0.42))
		var b_ratio: float = clampf(float(active_boss["hp"]) / maxf(1.0, float(active_boss["max_hp"])), 0.0, 1.0)
		hud_control.draw_rect(Rect2(28, top_h + 34, w - 56, 16), Color(0.08, 0.03, 0.05, 0.95))
		hud_control.draw_rect(Rect2(28, top_h + 34, (w - 56) * b_ratio, 16), Color(0.92, 0.15, 0.22, 0.95))
		hud_control.draw_string(font, Vector2(w * 0.35, top_h + 47), "%d / %d HP" % [int(active_boss["hp"]), int(active_boss["max_hp"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# ==========================================================================
	# 3. BOTTOM UPGRADE DOCK (2 COLUMNS: TÀU SỐ 09 / NHÂN VẬT AN)
	# ==========================================================================
	var dock_h: float = 245.0
	var dock_y: float = h - dock_h
	hud_control.draw_rect(Rect2(0, dock_y, w, dock_h), Color(0.03, 0.05, 0.09, 0.95))
	hud_control.draw_line(Vector2(0, dock_y), Vector2(w, dock_y), Color(0.0, 0.88, 1.0, 0.85), 2.5)

	var col_w: float = (w - 30.0) * 0.5
	var x_left: float = 10.0
	var x_right: float = 20.0 + col_w

	# Column Headers
	_draw_pill(Rect2(x_left, dock_y + 8, col_w, 28), Color(0.0, 0.42, 0.64, 0.95), Color(0.0, 0.94, 1.0, 0.95), 6.0, 1.5)
	hud_control.draw_string(font, Vector2(x_left + 16, dock_y + 27), "NÂNG CẤP TÀU SỐ 09", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	_draw_pill(Rect2(x_right, dock_y + 8, col_w, 28), Color(0.06, 0.25, 0.42, 0.95), Color(0.0, 0.82, 0.96, 0.85), 6.0, 1.5)
	hud_control.draw_string(font, Vector2(x_right + 16, dock_y + 27), "NÂNG CẤP NHÂN VẬT (AN)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.0, 0.96, 1.0))

	var cards_info: Array[Dictionary] = [
		{"col": 0, "row": 0, "title": "PHÁO XOAY TÀU (CẤP %d)" % lv_turret, "stat": "+18% Sát thương & Tốc quay", "accent": Color(0.0, 0.84, 1.0)},
		{"col": 0, "row": 1, "title": "GIÁP TÀU & DRONE (CẤP %d)" % lv_armor_drone, "stat": "+500 Máu Tàu & +Tia Drone", "accent": Color(0.0, 0.84, 1.0)},
		{"col": 1, "row": 0, "title": "SÚNG TRƯỜNG AN (CẤP %d)" % lv_an_rifle, "stat": "+65 Sát thương xuyên giáp", "accent": Color(1.0, 0.78, 0.27)},
		{"col": 1, "row": 1, "title": "TỐC BẮN & CHÍ MẠNG (CẤP %d)" % lv_an_crit, "stat": "+10% Tốc bắn • +%d%% CRIT" % min(75, 15 + (lv_an_crit - 1) * 5), "accent": Color(1.0, 0.78, 0.27)},
	]

	for i in range(4):
		var ci: Dictionary = cards_info[i]
		var cx: float = x_left if int(ci["col"]) == 0 else x_right
		var cy: float = dock_y + 42.0 + float(ci["row"]) * 96.0
		var r_card := Rect2(cx, cy, col_w, 88.0)
		rect_upg_cards[i] = r_card
		var cost: int = _get_upgrade_cost(i)
		var can_afford: bool = energy >= cost
		var acc: Color = ci["accent"]
		_draw_pill(r_card, Color(0.06, 0.12, 0.21, 0.96), acc if can_afford else Color(0.25, 0.32, 0.40, 0.7), 8.0, 1.5)
		hud_control.draw_string(font, Vector2(cx + 12, cy + 20), String(ci["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		hud_control.draw_string(font, Vector2(cx + 12, cy + 39), String(ci["stat"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.85, 0.95))

		var r_buy := Rect2(cx + 10, cy + 48, col_w - 20, 32)
		var btn_bg: Color = (Color(0.0, 0.56, 0.80) if int(ci["col"]) == 0 else Color(0.80, 0.50, 0.08)) if can_afford else Color(0.16, 0.20, 0.26)
		_draw_pill(r_buy, btn_bg, Color(1, 1, 1, 0.25 if can_afford else 0.05), 6.0, 1.0)
		hud_control.draw_string(font, Vector2(cx + 24, cy + 69), "NÂNG CẤP  •  %d Năng lượng" % cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if can_afford else Color(0.55, 0.62, 0.70))

	# ==========================================================================
	# 4. MODAL OVERLAY: DEFEAT / VICTORY & RETRY
	# ==========================================================================
	if is_game_over or is_victory:
		hud_control.draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.03, 0.06, 0.78))
		var mw: float = minf(w - 40.0, 480.0)
		var mh: float = 410.0
		var mx: float = (w - mw) * 0.5
		var my: float = (h - mh) * 0.5 - 20.0
		_draw_pill(Rect2(mx, my, mw, mh), Color(0.04, 0.08, 0.14, 0.98), Color(0.0, 0.88, 1.0, 0.95), 14.0, 2.5)
		var header_col: Color = Color(0.0, 0.62, 0.45) if is_victory else Color(0.68, 0.12, 0.18)
		_draw_pill(Rect2(mx, my, mw, 54), header_col, Color(0, 0, 0, 0), 14.0, 0.0)
		var title_txt: String = "VƯỢT QUA CHƯƠNG 1 THÀNH CÔNG!" if is_victory else "ĐOÀN TÀU SỐ 09 THẤT THỦ!"
		hud_control.draw_string(font, Vector2(mx + 24, my + 34), title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

		hud_control.draw_string(font, Vector2(mx + 24, my + 82), "CHƯƠNG 1: THÀNH PHỐ KHÔNG TẮT ĐÈN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.0, 0.94, 1.0))
		hud_control.draw_string(font, Vector2(mx + 24, my + 108), "Tiến độ đợt địch:  ĐỢT %02d / %02d" % [current_wave, max_waves], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

		var r_stats := Rect2(mx + 20, my + 126, mw - 40, 165)
		_draw_pill(r_stats, Color(0.06, 0.11, 0.19, 0.98), Color(0.25, 0.45, 0.65, 0.8), 10.0, 1.5)
		hud_control.draw_string(font, Vector2(mx + 36, my + 156), "• Quái máy đã tiêu diệt:  %d đơn vị" % enemies_killed_run, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.92, 1.0))
		hud_control.draw_string(font, Vector2(mx + 36, my + 190), "• Mảnh cơ khí thu thập trận này:  +%d Mảnh" % scrap_run, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.82, 0.30))
		hud_control.draw_string(font, Vector2(mx + 36, my + 224), "• Tổng Mảnh cơ khí tích lũy:  %d Mảnh" % scrap_total, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.82, 0.30))
		var bonus_pct: int = int(round((_get_perm_bonus_mult() - 1.0) * 100.0))
		hud_control.draw_string(font, Vector2(mx + 36, my + 262), "+ Cường Hóa Vĩnh Viễn: +%d%% Sát Thương & Giáp Tàu" % bonus_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.0, 0.96, 0.72))

		rect_btn_retry = Rect2(mx + 30, my + 312, mw - 60, 62)
		_draw_pill(rect_btn_retry, Color(0.0, 0.65, 0.90, 1.0), Color(0.65, 0.98, 1.0, 1.0), 10.0, 2.0)
		hud_control.draw_string(font, Vector2(mx + 64, my + 350), "KHỞI ĐỘNG LẠI TÀU SỐ 09 (CHƠI LẠI)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
