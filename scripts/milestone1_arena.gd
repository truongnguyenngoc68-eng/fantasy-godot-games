extends Node2D

# ============================================================================
# STICK BASTION: CHRONICLES OF AETHEL — BASTION FORGE 2.0 OVERHAUL (MILESTONE 1)
# Implements clash-visual-audit.md, clash-layout-v2.html & antigravity-brief.md:
# - Clash of Clans Peripheral Base HUD + Right-Side Build/Equipment List Panel
# - Battle Mode Selection (Wood Tabs + Large Artwork Cards), Shop, Events, Army
# - Clash Royale Chunky 3D-Shaded Knight vs Tusked Orc Proportions & Action Cards
# - Hardware-Baked 12-Bone Sprite Atlas LOD + Full-Detail Procedural Rig
# - 3-Run Statistical Benchmark Harness (30/100/200/300 units, p95/p99, Full vs LOD)
# ============================================================================

const GROUND_Y: float = 520.0
const ARENA_WIDTH: float = 2400.0
const CELL_W: int = 256
const CELL_H: int = 160
const ATLAS_COLS: int = 8
const ATLAS_ROWS: int = 12

var sim: BattleSimulation = BattleSimulation.new()
var rig: StickmanRig2D = StickmanRig2D.new()

var player_unit: BattleSimulation.SimUnit = null
var ai_unit: BattleSimulation.SimUnit = null

# Fixed-Timestep Accumulator (60Hz simulation preserved 100%)
var _accumulator: float = 0.0
var time_scale: float = 1.0
var show_debug_bones: bool = false
var use_batched_atlas_lod: bool = true

# Arena Modes: 0 = 1v1 Duel / Base Scene, 1 = Technical Inspector, 2 = Mass Benchmark
var arena_mode: int = 0
# HUD Context: "BASE" (Clash of Clans peripheral HUD), "BATTLE" (1v1 Combat HUD), "LAB" (Tech Lab)
var hud_context: String = "BATTLE"
var active_modal: String = "" # "", "build", "battle", "army", "shop", "events"

# Camera2D state
var cam_pos: Vector2 = Vector2(960.0, 360.0)
var shake_trauma: float = 0.0
var _time_elapsed: float = 0.0

# 6-Socket Equipment Indices for Live Customizer
var _socket_indices: Dictionary = {
	ContentDB.SOCKET_MAIN_WEAPON: 0,
	ContentDB.SOCKET_OFFHAND: 1,
	ContentDB.SOCKET_HELMET: 1,
	ContentDB.SOCKET_CHEST_ARMOR: 1,
	ContentDB.SOCKET_PAULDRON: 1,
	ContentDB.SOCKET_BACK_CAPE: 1,
}
var _build_row_Refs: Dictionary = {}
var _lbl_compare_sheet: Label = null

# Loaded Concept Textures (Used for ModeCards, Dragon Preview & Thumbnails)
var _tex_battlefield: Texture2D = null
var _tex_dragon_sheet: Texture2D = null

const ANIM_ORDER: Array[String] = ["IDLE", "RUN", "ATTACK_1", "ATTACK_2", "BLOCK_HIT", "DEATH"]

# Pooled Combat VFX
const MAX_PARTICLES: int = 180
const MAX_FLOATING_TEXTS: int = 64
const MAX_SHOCK_RINGS: int = 24
var _particles: Array[Dictionary] = []
var _floating_texts: Array[Dictionary] = []
var _shock_rings: Array[Dictionary] = []

# Telemetry & 3-Iteration Statistical Benchmark State (Chặng C)
var _last_sim_ms: float = 0.0
var _last_render_ms: float = 0.0
var _last_visible_units: int = 0
var _last_engaged_units: int = 0
var _fps_window: Array[float] = []

const BENCH_TIERS: Array[int] = [30, 100, 200, 300]
const BENCH_ITERATIONS: int = 3
const BENCH_WARMUP_SEC: float = 10.0
const BENCH_SAMPLE_SEC: float = 60.0
var _active_bench_tiers: Array[int] = [30, 100, 200, 300]
var _bench_running: bool = false
var _bench_cli_mode: bool = false
var _bench_iter_idx: int = 0
var _bench_tier_idx: int = 0
var _bench_elapsed_sec: float = 0.0
var _bench_frame_ms_samples: Array[float] = []
var _bench_sim_ms_samples: Array[float] = []
var _bench_render_ms_samples: Array[float] = []
var _bench_rs_cpu_ms_samples: Array[float] = []
var _bench_gpu_ms_samples: Array[float] = []
var _bench_draw_calls_samples: Array[int] = []
var _bench_vis_units_samples: Array[int] = []
var _bench_engaged_units_samples: Array[int] = []
var _bench_results: Dictionary = {}

# Automated Showcase Screenshot & Video Recording State
var _showcase_mode: bool = false
var _showcase_step: int = 0
var _showcase_timer: float = 0.0
var _video_mode: String = "" # "", "1v1", "300"
var _video_timer: float = 0.0

# UI Containers & Labels
var _ui_layer: CanvasLayer = null
var _hud_base_root: Control = null
var _hud_battle_root: Control = null
var _hud_lab_root: Control = null
var _modals: Dictionary = {}
var _toast_panel: PanelContainer = null
var _toast_label: Label = null
var _toast_timer: float = 0.0

var _lbl_player_hp: Label = null
var _bar_player_fill: ColorRect = null
var _lbl_ai_hp: Label = null
var _bar_ai_fill: ColorRect = null
var _lbl_perf: Label = null
var _panel_bench_report: PanelContainer = null
var _lbl_bench_report: Label = null
var _dragon_preview_ctrl: Control = null

# Stick War Base-Defense / Tug-of-War Gameplay State (Default Playable Mode)
var _hud_stickwar_root: Control = null
var _sw_gold: int = 350
var _sw_wave: int = 1
var _sw_wave_timer: float = 11.0
var _sw_passive_gold_timer: float = 0.0
var _sw_tower_shot_timer: float = 0.0
var _sw_match_over: bool = false
var _lbl_sw_economy: Label = null
var _lbl_sw_bastion1: Label = null
var _bar_sw_bastion1: ColorRect = null
var _lbl_sw_bastion2: Label = null
var _bar_sw_bastion2: ColorRect = null
var _lbl_sw_possess: Label = null
var _btn_stance_gar: Button = null
var _btn_stance_def: Button = null
var _btn_stance_atk: Button = null
var _sw_arrows: Array[Dictionary] = []

func _ready() -> void:
	seed(20261024)
	RenderingServer.set_default_clear_color(Color(0.35, 0.62, 0.92))
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)

	_load_concept_textures()
	_init_vfx_pools()

	sim.combat_event.connect(_on_combat_event)
	sim.sfx_requested.connect(func(sfx_id: String) -> void: SoundEngine.play_sfx(sfx_id))
	sim.gold_deposited.connect(_on_gold_deposited)

	_build_ui()
	_setup_stick_war_match()
	_switch_hud_context("STICK_WAR")

	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if ("--run-benchmark" in args) or ("--run-benchmark" in user_args):
		_bench_cli_mode = true
		_switch_hud_context("LAB")
		_start_benchmark_suite()
	elif ("--capture-showcase" in args) or ("--capture-showcase" in user_args):
		_showcase_mode = true
		_showcase_step = 0
		_showcase_timer = 0.0
		_switch_hud_context("BASE")
		_open_modal("")
	elif ("--capture-stick-war" in args) or ("--capture-stick-war" in user_args):
		_showcase_mode = true
		_showcase_step = 100
		_showcase_timer = 0.0
		_switch_hud_context("STICK_WAR")
		_open_modal("")
		_sw_gold = 600
		_buy_stick_war_unit("spearton")
		_buy_stick_war_unit("champion")
		_spawn_stick_war_orc_wave(3)
		var orc_idx: int = 0
		var miner_set: bool = false
		for u in sim.active_units:
			if u.active and u.team == 2:
				u.x = 920.0 + float(orc_idx) * 38.0
				u.prev_x = u.x
				orc_idx += 1
			elif u.active and u.unit_role == "miner" and not miner_set:
				u.gold_carried = 45
				u.x = 465.0
				u.prev_x = 465.0
				miner_set = true
		_cycle_or_toggle_possession()
	elif ("--record-video-1v1" in args) or ("--record-video-1v1" in user_args):
		_video_mode = "1v1"
		_video_timer = 0.0
		_open_modal("")
		_switch_hud_context("BATTLE")
		_setup_1v1_duel()
		player_unit.unit_scale = 1.45
		ai_unit.unit_scale = 1.45
		player_unit.x = 760.0
		player_unit.prev_x = 760.0
		ai_unit.x = 1040.0
		ai_unit.prev_x = 1040.0
	elif ("--record-video-300" in args) or ("--record-video-300" in user_args):
		_video_mode = "300"
		_video_timer = 0.0
		_open_modal("")
		_switch_hud_context("LAB")
		_spawn_mass_battle(300)

func _exit_tree() -> void:
	SoundEngine.shutdown()
	_sw_arrows.clear()
	if sim != null:
		sim.clear_all_units()
	player_unit = null
	ai_unit = null
	_tex_battlefield = null
	_tex_dragon_sheet = null
	StickmanRig2D.cleanup_static_resources()

func _load_concept_textures() -> void:
	_tex_battlefield = _load_png_texture("res://assets/bastion_forge/battlefield-concept.png")
	_tex_dragon_sheet = _load_png_texture("res://assets/bastion_forge/dragon-flight-concept.png")

func _load_png_texture(res_path: String) -> Texture2D:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _init_vfx_pools() -> void:
	for i in range(MAX_PARTICLES):
		_particles.append({
			"active": false, "pos": Vector2.ZERO, "vel": Vector2.ZERO,
			"col": Color.WHITE, "size": 4.5, "life": 0.0, "max_life": 0.36
		})
	for i in range(MAX_FLOATING_TEXTS):
		_floating_texts.append({
			"active": false, "pos": Vector2.ZERO, "vel": Vector2.ZERO,
			"text": "", "col": Color.WHITE, "life": 0.0, "max_life": 0.75
		})
	for i in range(MAX_SHOCK_RINGS):
		_shock_rings.append({
			"active": false, "pos": Vector2.ZERO, "radius": 8.0,
			"max_radius": 72.0, "col": Color.WHITE, "life": 0.0, "max_life": 0.26
		})

# ============================================================================
# SCENE MODES: 1v1 DUEL, EQUIPMENT INSPECTOR, MASS BATTLE (30/100/200/300)
# ============================================================================

func _setup_1v1_duel() -> void:
	arena_mode = 0
	sim.stick_war_mode = false
	sim.clear_all_units()
	var custom_loadout: Dictionary = _build_loadout_from_indices()
	player_unit = sim.spawn_unit(1, "vanguard_hero", 770.0, 1, true, custom_loadout)
	ai_unit = sim.spawn_unit(2, "abyssal_challenger", 1120.0, 1, false, {})
	player_unit.facing = 1.0
	ai_unit.facing = -1.0
	if hud_context == "BASE":
		# In Base Management HUD, units stand guard / train peacefully until Battle starts
		ai_unit.ai_enabled = false
		player_unit.x = 610.0
		player_unit.prev_x = 610.0
		ai_unit.x = 1260.0
		ai_unit.prev_x = 1260.0
	cam_pos = Vector2(940.0, 360.0)
	_refresh_build_rows_ui()

func _setup_stick_war_match() -> void:
	arena_mode = 3
	sim.stick_war_mode = true
	sim.team1_stance = 1 # Start in DEFEND (Thủ Nhà) so miners dig gold safely and soldiers guard the mine!
	sim.bastion1_max_hp = 2500.0
	sim.bastion1_hp = 2500.0
	sim.bastion2_max_hp = 2500.0
	sim.bastion2_hp = 2500.0
	sim.clear_all_units()
	player_unit = null
	ai_unit = null
	_sw_gold = 360
	_sw_wave = 1
	_sw_wave_timer = 10.0
	_sw_passive_gold_timer = 0.0
	_sw_tower_shot_timer = 0.0
	_sw_match_over = false
	_sw_arrows.clear()

	# Spawn 2 Starting Miners (Thợ Đào Vàng)
	for m_idx in range(2):
		var miner: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 340.0 + float(m_idx) * 38.0, 2 + m_idx * 3, false, {
			ContentDB.SOCKET_MAIN_WEAPON: "wpn_aethel_blade",
			ContentDB.SOCKET_OFFHAND: "off_none",
			ContentDB.SOCKET_HELMET: "hlm_none",
			ContentDB.SOCKET_CHEST_ARMOR: "arm_light_tunic",
			ContentDB.SOCKET_PAULDRON: "pld_none",
			ContentDB.SOCKET_BACK_CAPE: "cpe_none"
		})
		if miner != null:
			miner.unit_role = "miner"
			miner.unit_scale = 0.84
			miner.move_speed = 215.0

	# Spawn 2 Starting Swordsmen (Kiếm Sĩ Thủ Nhà)
	for s_idx in range(2):
		var sw: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 660.0 + float(s_idx) * 36.0, 1 + s_idx * 4, false, {
			ContentDB.SOCKET_MAIN_WEAPON: "wpn_aethel_blade",
			ContentDB.SOCKET_OFFHAND: "off_aegis_buckler",
			ContentDB.SOCKET_HELMET: "hlm_vanguard_visor",
			ContentDB.SOCKET_CHEST_ARMOR: "arm_aethel_cuirass",
			ContentDB.SOCKET_PAULDRON: "pld_steel_spaulders",
			ContentDB.SOCKET_BACK_CAPE: "cpe_wind_scarf"
		})
		if sw != null:
			sw.unit_role = "fighter"
			sw.unit_scale = 0.96

	# Spawn Wave 1 Orc Raiders marching from the Right Orc Stronghold
	_spawn_stick_war_orc_wave(2)
	cam_pos = Vector2(720.0, 360.0)
	_update_stance_buttons_visual()
	_refresh_build_rows_ui()

func _spawn_stick_war_orc_wave(count: int) -> void:
	var wpns: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_MAIN_WEAPON)
	var offs: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_OFFHAND)
	var hlms: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_HELMET)
	var arms: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_CHEST_ARMOR)
	var plds: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_PAULDRON)
	for i in range(count):
		var sl: int = (i * 3 + _sw_wave) % BattleSimulation.NUM_SUB_LANES
		var ox: float = BattleSimulation.BASTION2_X - 80.0 - float(i) * 36.0
		var orc_ld: Dictionary = {
			ContentDB.SOCKET_MAIN_WEAPON: wpns[(i + _sw_wave) % wpns.size()],
			ContentDB.SOCKET_OFFHAND: offs[(i + _sw_wave) % offs.size()],
			ContentDB.SOCKET_HELMET: hlms[(i + _sw_wave) % hlms.size()],
			ContentDB.SOCKET_CHEST_ARMOR: arms[(i + _sw_wave) % arms.size()],
			ContentDB.SOCKET_PAULDRON: plds[(i + _sw_wave) % plds.size()],
			ContentDB.SOCKET_BACK_CAPE: "cpe_none"
		}
		var orc: BattleSimulation.SimUnit = sim.spawn_unit(2, "abyssal_challenger", ox, sl, false, orc_ld)
		if orc != null:
			orc.unit_role = "fighter"
			orc.unit_scale = 0.96 + minf(0.24, float(_sw_wave) * 0.03)
			orc.max_hp = 380.0 + float(_sw_wave) * 35.0
			orc.hp = orc.max_hp
			orc.damage = 32.0 + float(_sw_wave) * 4.0

func _on_gold_deposited(team: int, amount: int, world_pos: Vector2) -> void:
	if team == 1:
		_sw_gold += amount
		SoundEngine.play_sfx("ui_click")
		_spawn_floating_text(world_pos, "💰 +%d Vàng" % amount, Color(1.0, 0.92, 0.22))

func _spawn_mass_battle(unit_count: int) -> void:
	arena_mode = 2
	sim.stick_war_mode = false
	sim.clear_all_units()
	player_unit = null
	ai_unit = null

	var half: int = unit_count / 2
	var base_sc: float = 0.48 if unit_count >= 200 else (0.62 if unit_count >= 100 else 0.78)
	var rank_step: float = 28.0 if unit_count >= 200 else 34.0
	var weapons: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_MAIN_WEAPON)
	var offhands: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_OFFHAND)
	var helmets: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_HELMET)
	var armors: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_CHEST_ARMOR)
	var pauldrons: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_PAULDRON)
	var capes: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_BACK_CAPE)

	for i in range(half):
		var sub_lane: int = i % BattleSimulation.NUM_SUB_LANES
		var rank_in_lane: int = i / BattleSimulation.NUM_SUB_LANES
		# Checkerboard/quincunx stagger across 8 depth lanes (fits all 300 units in 1280x720 camera view with clear spacing)
		var jitter1: float = float((i * 37) % 15) - 7.0
		var x1: float = clampf(1152.0 - float(rank_in_lane) * rank_step - float(sub_lane % 4) * 11.0 + jitter1, 595.0, 1156.0)
		var loadout1: Dictionary = {
			ContentDB.SOCKET_MAIN_WEAPON: weapons[i % weapons.size()],
			ContentDB.SOCKET_OFFHAND: offhands[(i + 1) % offhands.size()],
			ContentDB.SOCKET_HELMET: helmets[(i + 1) % helmets.size()],
			ContentDB.SOCKET_CHEST_ARMOR: armors[(i + 1) % armors.size()],
			ContentDB.SOCKET_PAULDRON: pauldrons[(i + 1) % pauldrons.size()],
			ContentDB.SOCKET_BACK_CAPE: capes[(i + 1) % capes.size()],
		}
		var u1: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", x1, sub_lane, false, loadout1)
		if u1 != null:
			u1.unit_scale = base_sc + float(i % 3) * 0.025
			u1.lane_y_offset += (-7.5 if (rank_in_lane % 2 == 0) else 7.5)
			u1.anim_time = float(i % 15) * 0.05

		var jitter2: float = float((i * 53) % 15) - 7.0
		var x2: float = clampf(1228.0 + float(rank_in_lane) * rank_step + float(sub_lane % 4) * 11.0 + jitter2, 1222.0, 1785.0)
		var loadout2: Dictionary = {
			ContentDB.SOCKET_MAIN_WEAPON: weapons[(i + 2) % weapons.size()],
			ContentDB.SOCKET_OFFHAND: offhands[(i + 2) % offhands.size()],
			ContentDB.SOCKET_HELMET: helmets[(i + 2) % helmets.size()],
			ContentDB.SOCKET_CHEST_ARMOR: armors[(i + 2) % armors.size()],
			ContentDB.SOCKET_PAULDRON: pauldrons[(i + 2) % pauldrons.size()],
			ContentDB.SOCKET_BACK_CAPE: capes[(i + 2) % capes.size()],
		}
		var u2: BattleSimulation.SimUnit = sim.spawn_unit(2, "abyssal_challenger", x2, sub_lane, false, loadout2)
		if u2 != null:
			u2.unit_scale = base_sc + 0.01 + float((i + 2) % 3) * 0.025
			u2.lane_y_offset += (-7.5 if (rank_in_lane % 2 == 1) else 7.5)
			u2.anim_time = float((i + 7) % 15) * 0.05

	cam_pos = Vector2(1190.0, 360.0)
	_fps_window.clear()

func _build_loadout_from_indices() -> Dictionary:
	var result: Dictionary = {}
	for socket_key in _socket_indices.keys():
		var item_ids: Array[String] = ContentDB.get_items_for_socket(socket_key)
		var idx: int = int(_socket_indices[socket_key]) % item_ids.size()
		result[socket_key] = item_ids[idx]
	return result

func _cycle_socket_item(socket_key: String) -> void:
	var items: Array[String] = ContentDB.get_items_for_socket(socket_key)
	var old_idx: int = int(_socket_indices[socket_key]) % items.size()
	var new_idx: int = (old_idx + 1) % items.size()
	var old_name: String = str(ContentDB.EQUIPMENT[items[old_idx]]["name"])
	var new_name: String = str(ContentDB.EQUIPMENT[items[new_idx]]["name"])

	var prev_hp: float = player_unit.max_hp if player_unit != null else 320.0
	var prev_dmg: float = player_unit.damage if player_unit != null else 34.0

	_socket_indices[socket_key] = new_idx
	var custom_loadout: Dictionary = _build_loadout_from_indices()
	if player_unit != null and player_unit.active:
		var hp_ratio: float = player_unit.hp / maxf(1.0, player_unit.max_hp)
		player_unit.loadout = custom_loadout
		sim.recalculate_unit_stats(player_unit, false)
		player_unit.hp = clampf(player_unit.max_hp * hp_ratio, 1.0, player_unit.max_hp)

	_refresh_build_rows_ui()
	if _lbl_compare_sheet != null and player_unit != null:
		var d_hp: int = int(round(player_unit.max_hp - prev_hp))
		var d_dmg: int = int(round(player_unit.damage - prev_dmg))
		var sign_hp: String = "+" if d_hp >= 0 else ""
		var sign_dmg: String = "+" if d_dmg >= 0 else ""
		_lbl_compare_sheet.text = "So sánh Trước → Sau: %s → %s  |  HP: %d (%s%d)  ·  ST: %d (%s%d)  ·  Giáp: %d%%" % [
			old_name.split("(")[0].strip_edges(),
			new_name.split("(")[0].strip_edges(),
			int(round(player_unit.max_hp)), sign_hp, d_hp,
			int(round(player_unit.damage)), sign_dmg, d_dmg,
			int(round(player_unit.armor_reduction * 100.0))
		]

# ============================================================================
# MAIN LOOP: INPUT -> FIXED 60HZ SIMULATION -> CAMERA -> TELEMETRY -> RENDER
# ============================================================================

func _process(delta: float) -> void:
	var clamped_dt: float = minf(delta, 0.1)
	_time_elapsed += clamped_dt

	_poll_player_input()

	# Fixed-Timestep Simulation Accumulator (60Hz)
	var sim_t0: int = Time.get_ticks_usec()
	_accumulator += clamped_dt * time_scale
	var steps: int = 0
	while _accumulator >= BattleSimulation.FIXED_DT and steps < 5:
		sim.step_fixed(BattleSimulation.FIXED_DT)
		_accumulator -= BattleSimulation.FIXED_DT
		steps += 1
	var sim_t1: int = Time.get_ticks_usec()
	if steps > 0:
		_last_sim_ms = float(sim_t1 - sim_t0) / 1000.0

	_update_vfx_pools(clamped_dt * time_scale)
	_update_camera(clamped_dt)
	_update_ui_hud(delta)

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_panel != null:
			_toast_panel.visible = false

	if _dragon_preview_ctrl != null and _dragon_preview_ctrl.is_visible_in_tree():
		_dragon_preview_ctrl.queue_redraw()

	if _bench_running:
		_step_benchmark(delta)
	elif _showcase_mode:
		_step_showcase(delta)
	elif _video_mode != "":
		_step_video_recording(delta)
	elif arena_mode == 3:
		_step_stick_war_gameplay(clamped_dt * time_scale)

	queue_redraw()

func _step_stick_war_gameplay(dt: float) -> void:
	if _sw_match_over:
		return

	# Check Win / Loss conditions on Bastion/Statue HP
	if sim.bastion2_hp <= 0.0:
		_sw_match_over = true
		SoundEngine.play_sfx("parry_clang")
		_show_toast("🏆 CHIẾN THẮNG! Bạn đã phá hủy Tượng Pháo Đài Địch! (Bấm [R] hoặc nút Chơi Lại để đấu ván mới)")
		return
	elif sim.bastion1_hp <= 0.0:
		_sw_match_over = true
		SoundEngine.play_sfx("death")
		_show_toast("💀 THẤT BẠI! Thành Trì của bạn đã thất thủ! (Bấm [R] hoặc nút Chơi Lại để phục thù)")
		return

	# Passive Gold trickle (+10 Gold every 1.2s)
	_sw_passive_gold_timer += dt
	if _sw_passive_gold_timer >= 1.2:
		_sw_passive_gold_timer -= 1.2
		_sw_gold += 10

	# Enemy Orc Wave Director (Spawns a wave every 13s)
	_sw_wave_timer -= dt
	if _sw_wave_timer <= 0.0:
		_sw_wave += 1
		_sw_wave_timer = 13.0
		var wave_size: int = clampi(2 + _sw_wave, 3, 10)
		_spawn_stick_war_orc_wave(wave_size)
		_show_toast("🌊 ĐỢT QUÁI ORC #%d (%d Quân) đang tiến về Thành Trì!" % [_sw_wave, wave_size])

	# Left Bastion Garrison Defense Tower (Fires arrows when in Garrison stance OR enemy approaches gate)
	_sw_tower_shot_timer -= dt
	if _sw_tower_shot_timer <= 0.0:
		var fire_interval: float = 0.42 if sim.team1_stance == 0 else 0.95
		var tower_range_x: float = 1040.0 if sim.team1_stance == 0 else 720.0
		var best_enemy: BattleSimulation.SimUnit = null
		var best_x: float = 99999.0
		for u in sim.active_units:
			if u.active and u.team == 2 and u.anim_state != "DEATH" and u.x <= tower_range_x:
				if u.x < best_x:
					best_x = u.x
					best_enemy = u
		if best_enemy != null:
			_sw_tower_shot_timer = fire_interval
			var start_p := Vector2(BattleSimulation.BASTION1_X + 18.0, GROUND_Y - 190.0)
			var end_p := Vector2(best_enemy.x, GROUND_Y + best_enemy.lane_y_offset - 42.0)
			_sw_arrows.append({
				"start": start_p, "end": end_p, "t": 0.0, "dur": 0.24, "target": best_enemy
			})
			SoundEngine.play_sfx("whoosh")

	# Step flying arrows
	var a_idx: int = 0
	while a_idx < _sw_arrows.size():
		var arr: Dictionary = _sw_arrows[a_idx]
		arr["t"] = float(arr["t"]) + dt
		if float(arr["t"]) >= float(arr["dur"]):
			var tgt: BattleSimulation.SimUnit = arr["target"]
			if tgt != null and tgt.active and tgt.team == 2 and tgt.anim_state != "DEATH":
				var arrow_dmg: float = 38.0 if sim.team1_stance == 0 else 26.0
				tgt.hp -= arrow_dmg
				tgt.hit_flash_timer = 0.10
				_spawn_floating_text(arr["end"], "🏹 -%d" % int(arrow_dmg), Color(0.45, 0.92, 1.0))
				sim.return_if_dead(tgt, 1.0, GROUND_Y + tgt.lane_y_offset)
			_sw_arrows.remove_at(a_idx)
		else:
			a_idx += 1

	# If possessed unit died, release possession automatically
	if player_unit != null and (not player_unit.active or player_unit.anim_state == "DEATH"):
		player_unit.is_player_controlled = false
		player_unit.ai_enabled = true
		player_unit = null

func _poll_player_input() -> void:
	if active_modal != "" and active_modal != "build":
		sim.player_move_dir = 0.0
		sim.player_block_held = false
		return

	var dir: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir += 1.0

	if arena_mode == 3:
		# In Stick War mode: if possessing a unit, A/D moves that unit; otherwise A/D or Left/Right pans the camera!
		if player_unit != null and player_unit.active and player_unit.anim_state != "DEATH":
			sim.player_move_dir = dir
			sim.player_block_held = Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		else:
			sim.player_move_dir = 0.0
			sim.player_block_held = false
			if dir != 0.0:
				cam_pos.x = clampf(cam_pos.x + dir * 640.0 * get_process_delta_time(), 640.0, ARENA_WIDTH - 640.0)
		if Input.is_key_pressed(KEY_Q):
			cam_pos.x = clampf(cam_pos.x - 640.0 * get_process_delta_time(), 640.0, ARENA_WIDTH - 640.0)
		elif Input.is_key_pressed(KEY_E) and player_unit == null:
			cam_pos.x = clampf(cam_pos.x + 640.0 * get_process_delta_time(), 640.0, ARENA_WIDTH - 640.0)
		return

	sim.player_move_dir = dir
	sim.player_block_held = Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if arena_mode == 2 and dir != 0.0:
		cam_pos.x = clampf(cam_pos.x + dir * 520.0 * get_process_delta_time(), 640.0, ARENA_WIDTH - 640.0)

func _unhandled_input(event: InputEvent) -> void:
	if arena_mode == 3 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.position.y > 125.0 and mb.position.y < 595.0 and active_modal == "":
			_try_possess_unit_at_screen_pos(mb.position)

	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_ESCAPE:
			if active_modal != "":
				_open_modal("")
			elif arena_mode == 3 and player_unit != null:
				_release_possessed_unit()
			elif hud_context != "STICK_WAR":
				_switch_hud_context("STICK_WAR")
		elif k == KEY_TAB and arena_mode == 3:
			_cycle_or_toggle_possession()
		elif k == KEY_Z and arena_mode == 3:
			_set_stick_war_stance(0)
		elif k == KEY_X and arena_mode == 3:
			_set_stick_war_stance(1)
		elif k == KEY_C and arena_mode == 3:
			_set_stick_war_stance(2)
		elif k == KEY_J or k == KEY_SPACE:
			if arena_mode == 3 and player_unit == null:
				_cycle_or_toggle_possession()
			sim.player_queued_attack = 1
		elif k == KEY_L or k == KEY_E:
			sim.player_queued_attack = 2
		elif k == KEY_R:
			if arena_mode == 3:
				_setup_stick_war_match()
			else:
				_setup_1v1_duel()
		elif k == KEY_B:
			show_debug_bones = not show_debug_bones
		elif k == KEY_F3:
			_switch_hud_context("LAB")
			_start_benchmark_suite()
		elif k >= KEY_1 and k <= KEY_4 and arena_mode == 3 and hud_context == "STICK_WAR":
			var buy_types: Array[String] = ["miner", "sword", "spearton", "champion"]
			_buy_stick_war_unit(buy_types[k - KEY_1])
		elif k >= KEY_1 and k <= KEY_6:
			_trigger_player_anim_preview(ANIM_ORDER[k - KEY_1])

func _trigger_player_anim_preview(state_name: String) -> void:
	if player_unit == null or not player_unit.active:
		_setup_1v1_duel()
	if player_unit.anim_state == "DEATH" and state_name != "DEATH":
		player_unit.hp = player_unit.max_hp
	sim.force_unit_animation(player_unit, state_name)

func _update_camera(dt: float) -> void:
	var target_x: float = cam_pos.x
	if active_modal == "build":
		if player_unit != null:
			target_x = clampf(player_unit.x + 220.0, 640.0, ARENA_WIDTH - 640.0)
	elif arena_mode == 3:
		if player_unit != null and player_unit.active and player_unit.anim_state != "DEATH":
			target_x = clampf(player_unit.x + player_unit.facing * 80.0, 640.0, ARENA_WIDTH - 640.0)
	elif arena_mode == 0 and player_unit != null and ai_unit != null:
		var mid_x: float = (player_unit.x + ai_unit.x) * 0.5
		target_x = clampf(mid_x + player_unit.facing * 25.0, 640.0, ARENA_WIDTH - 640.0)
	elif arena_mode == 2:
		target_x = 1200.0

	cam_pos.x = lerpf(cam_pos.x, target_x, clampf(dt * 6.5, 0.0, 1.0))
	cam_pos.y = 360.0
	if shake_trauma > 0.0:
		shake_trauma = maxf(0.0, shake_trauma - dt * 2.8)

# ============================================================================
# POOLED COMBAT VFX & FLOATING NUMBERS
# ============================================================================

func _on_combat_event(event_type: String, world_pos: Vector2, _value: int, text: String, color: Color) -> void:
	var mass_crowd: bool = sim.active_units.size() > 60
	# In mass crowd mode, strictly throttle floating damage numbers & particles so the frontline remains 100% readable
	if not mass_crowd or event_type == "DEATH" or (sim.tick_count % 24 == 0):
		_spawn_floating_text(world_pos + Vector2(0.0, -18.0 if mass_crowd else -24.0), text, color)

	var spark_count: int = (1 if (sim.tick_count % 3 == 0) else 0) if mass_crowd else (12 if event_type == "PARRY" else 8)
	for i in range(spark_count):
		var angle: float = -PI * 0.85 + float(i) / float(max(1, spark_count - 1)) * (PI * 0.70)
		var speed: float = 115.0 + float((i * 53) % 140)
		_spawn_particle(world_pos, Vector2.from_angle(angle) * speed, color, 3.0 if mass_crowd else (4.5 if event_type != "PARRY" else 6.0))

	if (event_type == "PARRY" or event_type == "HIT") and not mass_crowd:
		_spawn_shock_ring(world_pos, 78.0 if event_type == "PARRY" else 46.0, color)
		if sim.active_units.size() <= 4:
			shake_trauma = minf(1.0, shake_trauma + (0.50 if event_type == "PARRY" else 0.25))

func _spawn_particle(pos: Vector2, vel: Vector2, col: Color, size: float) -> void:
	for i in range(MAX_PARTICLES):
		var p: Dictionary = _particles[i]
		if not p["active"]:
			p["active"] = true
			p["pos"] = pos
			p["vel"] = vel
			p["col"] = col
			p["size"] = size
			p["life"] = 0.0
			p["max_life"] = 0.34
			return

func _spawn_floating_text(pos: Vector2, text: String, col: Color) -> void:
	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_texts[i]
		if not ft["active"]:
			ft["active"] = true
			ft["pos"] = pos
			ft["vel"] = Vector2(0.0, -64.0)
			ft["text"] = text
			ft["col"] = col
			ft["life"] = 0.0
			ft["max_life"] = 0.72
			return

func _spawn_shock_ring(pos: Vector2, max_r: float, col: Color) -> void:
	for i in range(MAX_SHOCK_RINGS):
		var sr: Dictionary = _shock_rings[i]
		if not sr["active"]:
			sr["active"] = true
			sr["pos"] = pos
			sr["radius"] = 10.0
			sr["max_radius"] = max_r
			sr["col"] = col
			sr["life"] = 0.0
			sr["max_life"] = 0.24
			return

func _update_vfx_pools(dt: float) -> void:
	for i in range(MAX_PARTICLES):
		var p: Dictionary = _particles[i]
		if p["active"]:
			p["life"] = float(p["life"]) + dt
			if float(p["life"]) >= float(p["max_life"]):
				p["active"] = false
			else:
				var vel: Vector2 = p["vel"]
				vel.y += 480.0 * dt
				p["vel"] = vel
				p["pos"] = (p["pos"] as Vector2) + vel * dt

	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_texts[i]
		if ft["active"]:
			ft["life"] = float(ft["life"]) + dt
			if float(ft["life"]) >= float(ft["max_life"]):
				ft["active"] = false
			else:
				ft["pos"] = (ft["pos"] as Vector2) + (ft["vel"] as Vector2) * dt

	for i in range(MAX_SHOCK_RINGS):
		var sr: Dictionary = _shock_rings[i]
		if sr["active"]:
			sr["life"] = float(sr["life"]) + dt
			if float(sr["life"]) >= float(sr["max_life"]):
				sr["active"] = false

# ============================================================================
# BASTION FORGE 2.0 DAYLIGHT ALPINE BATTLEFIELD + CITADELS + CHARACTER RENDER
# ============================================================================

func _draw() -> void:
	var render_t0: int = Time.get_ticks_usec()

	var shake_offset := Vector2.ZERO
	if shake_trauma > 0.01:
		var mag: float = shake_trauma * shake_trauma * 9.0
		shake_offset = Vector2(sin(_time_elapsed * 67.0) * mag, cos(_time_elapsed * 53.0) * mag)

	var view_offset: Vector2 = Vector2(640.0, 360.0) - cam_pos + shake_offset

	_draw_bastion_daylight_environment(view_offset)
	_draw_interactive_citadels(view_offset)

	var alpha: float = clampf(_accumulator / BattleSimulation.FIXED_DT, 0.0, 1.0)
	var units: Array[BattleSimulation.SimUnit] = sim.active_units
	var n_units: int = units.size()
	var vis_count: int = 0
	var eng_count: int = 0

	var is_crowd_lod: bool = use_batched_atlas_lod and (n_units >= 30) and not show_debug_bones

	# Pass 1: Draw all units back-to-front across all 8 sub_lanes using each unit's own 6-socket loadout!
	# (Ground contact shadows + 12-bone articulated 3D parts + equipment are all drawn from the single shared _modular_atlas_tex)
	for sub in range(BattleSimulation.NUM_SUB_LANES):
		for i in range(n_units):
			var u: BattleSimulation.SimUnit = units[i]
			if not u.active or u.sub_lane != sub:
				continue
			var interp_x: float = lerpf(u.prev_x, u.x, alpha)
			var screen_x: float = interp_x + view_offset.x
			if screen_x < -80.0 or screen_x > 1360.0:
				continue
			vis_count += 1
			if u.anim_state == "ATTACK_1" or u.anim_state == "ATTACK_2" or u.anim_state == "BLOCK_HIT" or u.anim_state == "DEATH" or u.lane_rank <= 1:
				eng_count += 1
			var world_pos := Vector2(interp_x, GROUND_Y + u.lane_y_offset) + view_offset
			rig.draw_character(self, u, world_pos, show_debug_bones, is_crowd_lod)

	# Pass 3: Draw subtle frontline slash ribbons & compact overhead HP bars for frontline fighters only
	for i in range(n_units):
		var u: BattleSimulation.SimUnit = units[i]
		if not u.active:
			continue
		var interp_x: float = lerpf(u.prev_x, u.x, alpha)
		var screen_x: float = interp_x + view_offset.x
		if screen_x < -80.0 or screen_x > 1360.0:
			continue
		var world_pos := Vector2(interp_x, GROUND_Y + u.lane_y_offset) + view_offset

		if is_crowd_lod and u.lane_rank == 0 and (u.anim_state == "ATTACK_1" or u.anim_state == "ATTACK_2"):
			var wpn_id: String = str(u.loadout.get(ContentDB.SOCKET_MAIN_WEAPON, "wpn_aethel_blade"))
			var is_orc: bool = (u.team == 2 or u.archetype_id == "abyssal_challenger")
			rig._draw_combat_motion_arcs(
				self,
				u,
				wpn_id,
				world_pos + Vector2(0.0, -48.0 * u.unit_scale),
				world_pos + Vector2(u.facing * 14.0 * u.unit_scale, -40.0 * u.unit_scale),
				-0.35 * u.facing,
				u.facing,
				u.unit_scale * 0.82,
				is_orc
			)

		if (n_units <= 10 or (u.lane_rank == 0 and u.hp < u.max_hp and u.hp > 0.0)) and u.hp < u.max_hp and u.hp > 0.0:
			var bw: float = 34.0 if is_crowd_lod else 48.0
			var bh: float = 5.0 if is_crowd_lod else 7.0
			var bar_pos: Vector2 = world_pos + Vector2(-bw * 0.5, -104.0 * u.unit_scale)
			draw_rect(Rect2(bar_pos, Vector2(bw, bh)), Color(0.14, 0.10, 0.07, 0.88), true)
			var ratio: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
			var hp_col: Color = Color(0.32, 0.88, 0.28) if u.team == 1 else Color(0.95, 0.28, 0.26)
			draw_rect(Rect2(bar_pos + Vector2(1, 1), Vector2((bw - 2.0) * ratio, bh - 2.0)), hp_col, true)

		# Stick War Visual Indicators: Gold Sack on Miner's Back & Possessed Unit Highlight
		if arena_mode == 3 and u.anim_state != "DEATH":
			if u.unit_role == "miner" and u.gold_carried > 0:
				var sack_pos: Vector2 = world_pos + Vector2(-u.facing * 14.0 * u.unit_scale, -46.0 * u.unit_scale)
				draw_circle(sack_pos, 11.5, Color(0.18, 0.12, 0.06))
				draw_circle(sack_pos, 9.5, Color(1.0, 0.84, 0.18))
				draw_circle(sack_pos + Vector2(-2.5, -2.5), 4.0, Color(1.0, 0.96, 0.65))
			if u.is_player_controlled:
				draw_arc(world_pos + Vector2(0, 2), 26.0 * u.unit_scale, 0.0, TAU, 24, Color(1.0, 0.90, 0.20, 0.95), 3.5)
				var arrow_y: float = -118.0 * u.unit_scale + sin(_time_elapsed * 7.0) * 4.5
				var tri := PackedVector2Array([
					world_pos + Vector2(0, arrow_y + 10),
					world_pos + Vector2(-8, arrow_y - 2),
					world_pos + Vector2(8, arrow_y - 2)
				])
				draw_colored_polygon(tri, Color(1.0, 0.92, 0.22))

	if arena_mode == 3:
		for arr in _sw_arrows:
			var p_arr: float = clampf(float(arr["t"]) / maxf(0.01, float(arr["dur"])), 0.0, 1.0)
			var a_start: Vector2 = (arr["start"] as Vector2) + view_offset
			var a_end: Vector2 = (arr["end"] as Vector2) + view_offset
			var cur_p: Vector2 = a_start.lerp(a_end, p_arr)
			cur_p.y -= sin(p_arr * PI) * 48.0
			var dir_v: Vector2 = (a_end - a_start).normalized()
			draw_line(cur_p - dir_v * 18.0, cur_p + dir_v * 6.0, Color(0.15, 0.10, 0.06), 4.5)
			draw_line(cur_p - dir_v * 16.0, cur_p + dir_v * 6.0, Color(0.45, 0.95, 1.0), 2.5)

	_last_visible_units = vis_count
	_last_engaged_units = eng_count
	_draw_combat_vfx(view_offset)

	var render_t1: int = Time.get_ticks_usec()
	_last_render_ms = float(render_t1 - render_t0) / 1000.0

func _draw_bastion_daylight_environment(view_offset: Vector2) -> void:
	# Render the lush Bastion Forge 2.0 Alpine Valley & Fortresses backdrop with camera parallax
	if _tex_battlefield != null:
		var tw: float = float(_tex_battlefield.get_width())
		var th: float = float(_tex_battlefield.get_height())
		var pan_norm: float = clampf((cam_pos.x - 640.0) / maxf(1.0, ARENA_WIDTH - 1280.0), 0.0, 1.0)
		var crop_w: float = tw * 0.88
		var crop_x: float = (tw - crop_w) * pan_norm
		draw_texture_rect_region(
			_tex_battlefield,
			Rect2(0.0, 0.0, 1280.0, 720.0),
			Rect2(crop_x, th * 0.04, crop_w, th * 0.92)
		)
		return

	# Fallback procedural daylight sky & lane if texture is absent
	draw_rect(Rect2(0, 0, 1280, 460), Color(0.36, 0.68, 0.95), true)
	draw_rect(Rect2(0, 425, 1280, 55), Color(0.48, 0.74, 0.22), true)
	draw_rect(Rect2(0, GROUND_Y - 42.0, 1280, 86.0), Color(0.76, 0.65, 0.34), true)
	draw_rect(Rect2(0, GROUND_Y + 44.0, 1280, 220.0), Color(0.25, 0.48, 0.15), true)

func _draw_interactive_citadels(view_offset: Vector2) -> void:
	var stroke := Color(0.18, 0.13, 0.09)
	# Only draw procedural fallback keeps if the painted battlefield concept texture is unavailable
	if _tex_battlefield == null:
		# --- LEFT DAWN BASTION CITADEL (Fallback) ---
		var lx: float = 215.0 + view_offset.x
		if lx > -260.0 and lx < 1450.0:
			var by: float = GROUND_Y - 12.0
			draw_rect(Rect2(lx - 98.0, by - 165.0, 176.0, 165.0), stroke, true)
			draw_rect(Rect2(lx - 94.0, by - 161.0, 168.0, 157.0), Color(0.84, 0.80, 0.72), true)
		# --- RIGHT ORC STRONGHOLD (Fallback) ---
		var rx: float = 2185.0 + view_offset.x
		if rx > -260.0 and rx < 1540.0:
			var by: float = GROUND_Y - 12.0
			draw_rect(Rect2(rx - 78.0, by - 170.0, 176.0, 170.0), stroke, true)
			draw_rect(Rect2(rx - 74.0, by - 166.0, 168.0, 162.0), Color(0.42, 0.38, 0.44), true)

	# --- STICK WAR GOLD CRYSTAL MINE, BASTION BANNERS & DEFENSE RALLY LINE (when arena_mode == 3) ---
	if arena_mode == 3:
		var fnt: Font = ThemeDB.fallback_font
		var b1_sx: float = BattleSimulation.BASTION1_X - 75.0 + view_offset.x
		if b1_sx > -120.0 and b1_sx < 1340.0:
			draw_string_outline(fnt, Vector2(b1_sx - 60.0, GROUND_Y - 210.0), "🏰 THÀNH TRÌ TA (%d HP)" % int(sim.bastion1_hp), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, 4, Color(0.10, 0.08, 0.06))
			draw_string(fnt, Vector2(b1_sx - 60.0, GROUND_Y - 210.0), "🏰 THÀNH TRÌ TA (%d HP)" % int(sim.bastion1_hp), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.52, 0.96, 0.44))
		var b2_sx: float = BattleSimulation.BASTION2_X + 30.0 + view_offset.x
		if b2_sx > -120.0 and b2_sx < 1340.0:
			draw_string_outline(fnt, Vector2(b2_sx - 70.0, GROUND_Y - 210.0), "🗿 TƯỢNG ĐỊCH ORC (%d HP)" % int(sim.bastion2_hp), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, 4, Color(0.10, 0.08, 0.06))
			draw_string(fnt, Vector2(b2_sx - 70.0, GROUND_Y - 210.0), "🗿 TƯỢNG ĐỊCH ORC (%d HP)" % int(sim.bastion2_hp), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1.0, 0.48, 0.44))
		for c_idx in range(4):
			var gx: float = BattleSimulation.GOLD_MINE1_X + float(c_idx) * 28.0 + view_offset.x
			var gy: float = GROUND_Y + 22.0 + float((c_idx % 2) * 14)
			if gx > -60.0 and gx < 1340.0:
				var crys := PackedVector2Array([
					Vector2(gx - 12.0, gy),
					Vector2(gx - 6.0, gy - 26.0 - float(c_idx % 2) * 6.0),
					Vector2(gx + 3.0, gy - 32.0),
					Vector2(gx + 12.0, gy - 18.0),
					Vector2(gx + 14.0, gy)
				])
				draw_colored_polygon(crys, Color(0.98, 0.80, 0.14))
				draw_polyline(crys, stroke, 2.5)
		var mine_label_x: float = BattleSimulation.GOLD_MINE1_X + 42.0 + view_offset.x
		if mine_label_x > -80.0 and mine_label_x < 1340.0:
			draw_string_outline(fnt, Vector2(mine_label_x - 45.0, GROUND_Y + 52.0), "⛏️ MỎ VÀNG TINH THẠCH", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, 4, Color(0.12, 0.08, 0.05))
			draw_string(fnt, Vector2(mine_label_x - 45.0, GROUND_Y + 52.0), "⛏️ MỎ VÀNG TINH THẠCH", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1.0, 0.92, 0.28))

		var def_screen_x: float = BattleSimulation.DEFEND_LINE_X + view_offset.x
		if sim.team1_stance == 1 and def_screen_x > 0.0 and def_screen_x < 1280.0:
			draw_line(Vector2(def_screen_x, GROUND_Y - 82.0), Vector2(def_screen_x, GROUND_Y + 75.0), Color(0.28, 0.78, 1.0, 0.55), 3.0)
			draw_string_outline(fnt, Vector2(def_screen_x - 62.0, GROUND_Y - 90.0), "🛡️ TUYẾN PHÒNG THỦ", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, 4, Color(0.10, 0.08, 0.06))
			draw_string(fnt, Vector2(def_screen_x - 62.0, GROUND_Y - 90.0), "🛡️ TUYẾN PHÒNG THỦ", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.55, 0.92, 1.0))

func _draw_combat_vfx(view_offset: Vector2) -> void:
	for i in range(MAX_SHOCK_RINGS):
		var sr: Dictionary = _shock_rings[i]
		if sr["active"]:
			var p: float = float(sr["life"]) / float(sr["max_life"])
			var r: float = lerpf(10.0, float(sr["max_radius"]), p)
			var c: Color = sr["col"]
			c.a = (1.0 - p) * 0.80
			draw_arc((sr["pos"] as Vector2) + view_offset, r, 0.0, TAU, 20, c, 3.8)

	for i in range(MAX_PARTICLES):
		var pt: Dictionary = _particles[i]
		if pt["active"]:
			var p: float = float(pt["life"]) / float(pt["max_life"])
			var c: Color = pt["col"]
			c.a = 1.0 - p
			var pt_pos: Vector2 = (pt["pos"] as Vector2) + view_offset
			draw_circle(pt_pos, float(pt["size"]) * (1.0 - p * 0.45) + 1.2, BastionUI.COL_OUTLINE_DARK)
			draw_circle(pt_pos, float(pt["size"]) * (1.0 - p * 0.45), c)

	var font: Font = ThemeDB.fallback_font
	var f_sz: int = 14 if sim.active_units.size() > 60 else 19
	var f_out: int = 4 if sim.active_units.size() > 60 else 5
	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_texts[i]
		if ft["active"]:
			var p: float = float(ft["life"]) / float(ft["max_life"])
			var c: Color = ft["col"]
			c.a = 1.0 - p * p
			var pos: Vector2 = (ft["pos"] as Vector2) + view_offset
			draw_string_outline(font, pos, str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, f_sz, f_out, Color(0.14, 0.10, 0.07, c.a))
			draw_string(font, pos, str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, f_sz, c)

# ============================================================================
# BASTION FORGE 2.0 CLASH OF CLANS / CLASH ROYALE UI & MODALS
# ============================================================================

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	_build_stick_war_hud()
	_build_base_hud()
	_build_battle_hud()
	_build_lab_hud()

	_build_right_equipment_panel()
	_build_battle_modal()
	_build_army_modal()
	_build_shop_modal()
	_build_events_modal()
	_build_toast()

func _switch_hud_context(ctx: String) -> void:
	hud_context = ctx
	if _hud_stickwar_root != null:
		_hud_stickwar_root.visible = (ctx == "STICK_WAR")
	if _hud_base_root != null:
		_hud_base_root.visible = (ctx == "BASE")
	if _hud_battle_root != null:
		_hud_battle_root.visible = (ctx == "BATTLE" or ctx == "LAB")
	if _hud_lab_root != null:
		_hud_lab_root.visible = (ctx == "LAB")

	if ctx == "STICK_WAR":
		if arena_mode != 3:
			_setup_stick_war_match()
	elif ctx == "BASE":
		_setup_1v1_duel()
	elif ctx == "BATTLE":
		if arena_mode != 0 or player_unit == null or ai_unit == null:
			_setup_1v1_duel()
		if ai_unit != null:
			ai_unit.ai_enabled = true

# --- 0. HUD STICK WAR CHÍNH (Thủ Nhà · Đào Vàng · Mua Quân · 3 Thế Trận · Nhập Vai · Phá Tượng) ---
func _build_stick_war_hud() -> void:
	_hud_stickwar_root = Control.new()
	_hud_stickwar_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_stickwar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_hud_stickwar_root)

	# 1. Top-Left: Economy Banner + 4 Unit Spawn Buttons (Thợ Mỏ, Kiếm Sĩ, Hộ Vệ, Chiến Thần)
	var econ_card := PanelContainer.new()
	econ_card.position = Vector2(10, 10)
	econ_card.size = Vector2(464, 106)
	econ_card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.28, 0.20, 0.14, 0.94), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 8, 6))
	_hud_stickwar_root.add_child(econ_card)

	var evbox := VBoxContainer.new()
	evbox.add_theme_constant_override("separation", 6)
	econ_card.add_child(evbox)

	_lbl_sw_economy = Label.new()
	_lbl_sw_economy.text = "💰 Vàng: 360  |  ⛏️ Thợ: 2  |  ⚔️ Quân: 2/40  |  🌊 Đợt 1 (10s)"
	BastionUI.style_display_label(_lbl_sw_economy, 13, BastionUI.COL_GOLD_TEXT, 4)
	evbox.add_child(_lbl_sw_economy)

	var buy_row := HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 5)
	evbox.add_child(buy_row)

	var spawn_defs: Array[Array] = [
		["miner", "[1] ⛏️ Thợ Mỏ\n75 Vàng", "stone"],
		["sword", "[2] 🗡️ Kiếm Sĩ\n120 Vàng", "blue"],
		["spearton", "[3] 🛡️ Hộ Vệ\n200 Vàng", "gold"],
		["champion", "[4] 👑 Chiến Thần\n350 Vàng", "green"]
	]
	for sd in spawn_defs:
		var u_type: String = str(sd[0])
		var b_buy := Button.new()
		b_buy.text = str(sd[1])
		b_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_buy.custom_minimum_size = Vector2(88, 54)
		BastionUI.apply_clash_button_style(b_buy, str(sd[2]), 12)
		b_buy.pressed.connect(func() -> void:
			_buy_stick_war_unit(u_type)
		)
		buy_row.add_child(b_buy)

	# 2. Top-Center: 3 Stick War Global Stance Buttons (ĐỒN TRÚ [Z] · THỦ NHÀ [X] · TẤN CÔNG [C])
	var stance_card := PanelContainer.new()
	stance_card.position = Vector2(494, 10)
	stance_card.size = Vector2(366, 106)
	stance_card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.24, 0.17, 0.12, 0.94), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 8, 6))
	_hud_stickwar_root.add_child(stance_card)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 6)
	stance_card.add_child(svbox)

	var lbl_st_head := Label.new()
	lbl_st_head.text = "LỆNH ĐIỀU QUÂN TOÀN BẢN ĐỒ (STICK WAR)"
	lbl_st_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_st_head, 13, BastionUI.COL_CREAM_TEXT, 4)
	svbox.add_child(lbl_st_head)

	var st_row := HBoxContainer.new()
	st_row.add_theme_constant_override("separation", 5)
	svbox.add_child(st_row)

	_btn_stance_gar = Button.new()
	_btn_stance_gar.text = "🏰 Đồn Trú\n[Phím Z]"
	_btn_stance_gar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_stance_gar.custom_minimum_size = Vector2(96, 54)
	_btn_stance_gar.pressed.connect(func() -> void: _set_stick_war_stance(0))
	st_row.add_child(_btn_stance_gar)

	_btn_stance_def = Button.new()
	_btn_stance_def.text = "🛡️ Thủ Nhà\n[Phím X]"
	_btn_stance_def.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_stance_def.custom_minimum_size = Vector2(96, 54)
	_btn_stance_def.pressed.connect(func() -> void: _set_stick_war_stance(1))
	st_row.add_child(_btn_stance_def)

	_btn_stance_atk = Button.new()
	_btn_stance_atk.text = "⚔️ Tấn Công\n[Phím C]"
	_btn_stance_atk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_stance_atk.custom_minimum_size = Vector2(96, 54)
	_btn_stance_atk.pressed.connect(func() -> void: _set_stick_war_stance(2))
	st_row.add_child(_btn_stance_atk)

	# 3. Top-Right: Bastion vs Enemy Statue HP Bars + Quick Tools
	var hp_card := PanelContainer.new()
	hp_card.position = Vector2(874, 10)
	hp_card.size = Vector2(392, 108)
	hp_card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.22, 0.16, 0.12, 0.94), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 8, 6))
	_hud_stickwar_root.add_child(hp_card)

	var hvbox := VBoxContainer.new()
	hvbox.add_theme_constant_override("separation", 4)
	hp_card.add_child(hvbox)

	_lbl_sw_bastion1 = Label.new()
	_lbl_sw_bastion1.text = "🏰 Thành Trì Ta: 2500 / 2500 HP"
	BastionUI.style_display_label(_lbl_sw_bastion1, 13, Color(0.55, 0.95, 0.45), 4)
	hvbox.add_child(_lbl_sw_bastion1)

	var b1_bg := ColorRect.new()
	b1_bg.custom_minimum_size = Vector2(372, 10)
	b1_bg.color = Color(0.12, 0.10, 0.08)
	hvbox.add_child(b1_bg)
	_bar_sw_bastion1 = ColorRect.new()
	_bar_sw_bastion1.position = Vector2(1, 1)
	_bar_sw_bastion1.size = Vector2(370, 8)
	_bar_sw_bastion1.color = Color(0.32, 0.88, 0.28)
	b1_bg.add_child(_bar_sw_bastion1)

	_lbl_sw_bastion2 = Label.new()
	_lbl_sw_bastion2.text = "🗿 Tượng Địch Orc: 2500 / 2500 HP"
	BastionUI.style_display_label(_lbl_sw_bastion2, 13, Color(1.0, 0.55, 0.52), 4)
	hvbox.add_child(_lbl_sw_bastion2)

	var b2_bg := ColorRect.new()
	b2_bg.custom_minimum_size = Vector2(372, 10)
	b2_bg.color = Color(0.12, 0.10, 0.08)
	hvbox.add_child(b2_bg)
	_bar_sw_bastion2 = ColorRect.new()
	_bar_sw_bastion2.position = Vector2(1, 1)
	_bar_sw_bastion2.size = Vector2(370, 8)
	_bar_sw_bastion2.color = Color(0.95, 0.30, 0.28)
	b2_bg.add_child(_bar_sw_bastion2)

	var tools_row := HBoxContainer.new()
	tools_row.add_theme_constant_override("separation", 5)
	hvbox.add_child(tools_row)

	var btn_early_wave := Button.new()
	btn_early_wave.text = "🌊 Gọi Đợt (+80G)"
	btn_early_wave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BastionUI.apply_clash_button_style(btn_early_wave, "gold", 12)
	btn_early_wave.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_sw_gold += 80
		_sw_wave_timer = 0.05
	)
	tools_row.add_child(btn_early_wave)

	var btn_sw_gear := Button.new()
	btn_sw_gear.text = "🛡️ 6 Trang Bị"
	btn_sw_gear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BastionUI.apply_clash_button_style(btn_sw_gear, "stone", 12)
	btn_sw_gear.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("build" if active_modal != "build" else "")
	)
	tools_row.add_child(btn_sw_gear)

	var btn_sw_lab := Button.new()
	btn_sw_lab.text = "⚡ Lab 300 Quân"
	btn_sw_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BastionUI.apply_clash_button_style(btn_sw_lab, "blue", 12)
	btn_sw_lab.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("")
		_switch_hud_context("LAB")
	)
	tools_row.add_child(btn_sw_lab)

	# 4. Bottom Bar: Direct Unit Possession Controls (Nhập Vai 1 Lính) & Camera Pan
	var bot_card := PanelContainer.new()
	bot_card.position = Vector2(180, 636)
	bot_card.size = Vector2(920, 74)
	bot_card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.26, 0.18, 0.12, 0.92), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 10, 5))
	_hud_stickwar_root.add_child(bot_card)

	var bvbox := VBoxContainer.new()
	bvbox.add_theme_constant_override("separation", 4)
	bot_card.add_child(bvbox)

	_lbl_sw_possess = Label.new()
	_lbl_sw_possess.text = "💡 Click chuột vào bất kỳ lính nào (hoặc bấm [Tab]) để NHẬP VAI điều khiển trực tiếp · Dùng [A/D] hoặc [←/→] để lia Camera"
	_lbl_sw_possess.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(_lbl_sw_possess, 13, BastionUI.COL_GOLD_TEXT, 4)
	bvbox.add_child(_lbl_sw_possess)

	var bot_btns := HBoxContainer.new()
	bot_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_btns.add_theme_constant_override("separation", 8)
	bvbox.add_child(bot_btns)

	var act_defs: Array[Array] = [
		["🎮 Nhập Vai / Đổi Lính [Tab]", "blue", func() -> void: _cycle_or_toggle_possession()],
		["⚔️ Chém [J / Space]", "gold", func() -> void: _trigger_stick_war_combat_btn(1)],
		["💥 Đột Kích [L / E]", "gold", func() -> void: _trigger_stick_war_combat_btn(2)],
		["🛡️ Đỡ / Parry [Giữ K]", "stone", func() -> void: _trigger_stick_war_combat_btn(3)],
		["🤖 Trả AI Tự Đánh [ESC]", "stone", func() -> void: _release_possessed_unit()],
		["🔄 Ván Mới [R]", "green", func() -> void: _setup_stick_war_match()]
	]
	for ad in act_defs:
		var ab := Button.new()
		ab.text = str(ad[0])
		ab.custom_minimum_size = Vector2(138, 36)
		BastionUI.apply_clash_button_style(ab, str(ad[1]), 12)
		var cb_a: Callable = ad[2]
		ab.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			cb_a.call()
		)
		bot_btns.add_child(ab)

func _trigger_stick_war_combat_btn(action_id: int) -> void:
	if player_unit == null:
		_cycle_or_toggle_possession()
	if action_id == 1:
		sim.player_queued_attack = 1
	elif action_id == 2:
		sim.player_queued_attack = 2
	elif action_id == 3 and player_unit != null:
		sim.force_unit_animation(player_unit, "BLOCK_HIT")

func _update_stance_buttons_visual() -> void:
	if _btn_stance_gar == null or _btn_stance_def == null or _btn_stance_atk == null:
		return
	BastionUI.apply_clash_button_style(_btn_stance_gar, "gold" if sim.team1_stance == 0 else "stone", 13)
	BastionUI.apply_clash_button_style(_btn_stance_def, "gold" if sim.team1_stance == 1 else "stone", 13)
	BastionUI.apply_clash_button_style(_btn_stance_atk, "gold" if sim.team1_stance == 2 else "stone", 13)

func _set_stick_war_stance(new_stance: int) -> void:
	sim.team1_stance = clampi(new_stance, 0, 2)
	SoundEngine.play_sfx("ui_click")
	_update_stance_buttons_visual()
	var st_names: Array[String] = [
		"🏰 LỆNH ĐỒN TRÚ: Toàn quân & Thợ mỏ rút về Thành Trì, Cung thủ bắn tên yểm trợ!",
		"🛡️ LỆNH THỦ NHÀ: Thợ mỏ đào vàng, quân chiến đấu lập phòng tuyến bảo vệ Mỏ Vàng!",
		"⚔️ LỆNH TỔNG TẤN CÔNG: Đại quân tiến lên tiêu diệt Orc và phá hủy Tượng Địch!"
	]
	_show_toast(st_names[sim.team1_stance])

func _buy_stick_war_unit(unit_type: String) -> void:
	var costs: Dictionary = {"miner": 75, "sword": 120, "spearton": 200, "champion": 350}
	var cost: int = int(costs.get(unit_type, 120))
	var team1_count: int = 0
	for u in sim.active_units:
		if u.active and u.team == 1 and u.anim_state != "DEATH":
			team1_count += 1
	if team1_count >= 40:
		_show_toast("⚠️ Đã đạt giới hạn 40 quân bên ta!")
		return
	if _sw_gold < cost:
		_show_toast("⚠️ Không đủ Vàng! Cần %d Vàng (Hiện có %d Vàng)." % [cost, _sw_gold])
		return

	_sw_gold -= cost
	SoundEngine.play_sfx("ui_click")
	var sl: int = team1_count % BattleSimulation.NUM_SUB_LANES
	var sx: float = BattleSimulation.BASTION1_X + 20.0

	if unit_type == "miner":
		var miner: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", sx, sl, false, {
			ContentDB.SOCKET_MAIN_WEAPON: "wpn_aethel_blade",
			ContentDB.SOCKET_OFFHAND: "off_none",
			ContentDB.SOCKET_HELMET: "hlm_none",
			ContentDB.SOCKET_CHEST_ARMOR: "arm_light_tunic",
			ContentDB.SOCKET_PAULDRON: "pld_none",
			ContentDB.SOCKET_BACK_CAPE: "cpe_none"
		})
		if miner != null:
			miner.unit_role = "miner"
			miner.unit_scale = 0.84
			miner.move_speed = 215.0
	elif unit_type == "sword":
		var sw: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", sx, sl, false, {
			ContentDB.SOCKET_MAIN_WEAPON: "wpn_aethel_blade",
			ContentDB.SOCKET_OFFHAND: "off_aegis_buckler",
			ContentDB.SOCKET_HELMET: "hlm_vanguard_visor",
			ContentDB.SOCKET_CHEST_ARMOR: "arm_aethel_cuirass",
			ContentDB.SOCKET_PAULDRON: "pld_steel_spaulders",
			ContentDB.SOCKET_BACK_CAPE: "cpe_wind_scarf"
		})
		if sw != null:
			sw.unit_role = "fighter"
			sw.unit_scale = 0.96
			sw.move_speed = 235.0
	elif unit_type == "spearton":
		var sp: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", sx, sl, false, {
			ContentDB.SOCKET_MAIN_WEAPON: "wpn_thunder_halberd",
			ContentDB.SOCKET_OFFHAND: "off_royal_tower",
			ContentDB.SOCKET_HELMET: "hlm_spartan_crest",
			ContentDB.SOCKET_CHEST_ARMOR: "arm_royal_plate",
			ContentDB.SOCKET_PAULDRON: "pld_dragon_wings",
			ContentDB.SOCKET_BACK_CAPE: "cpe_royal_mantle"
		})
		if sp != null:
			sp.unit_role = "fighter"
			sp.unit_scale = 1.08
			sp.max_hp = 680.0
			sp.hp = 680.0
			sp.damage = 54.0
			sp.armor_reduction = 0.38
	elif unit_type == "champion":
		var ch: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", sx, sl, false, _build_loadout_from_indices())
		if ch != null:
			ch.unit_role = "fighter"
			ch.unit_scale = 1.24
			ch.max_hp = 920.0
			ch.hp = 920.0
			ch.damage = 78.0
			ch.armor_reduction = 0.42

func _try_possess_unit_at_screen_pos(screen_pos: Vector2) -> void:
	var view_offset: Vector2 = Vector2(640.0, 360.0) - cam_pos
	var world_click: Vector2 = screen_pos - view_offset
	var best_u: BattleSimulation.SimUnit = null
	var best_dist: float = 75.0
	for u in sim.active_units:
		if u.active and u.team == 1 and u.anim_state != "DEATH":
			var u_pos := Vector2(u.x, GROUND_Y + u.lane_y_offset - 42.0 * u.unit_scale)
			var d: float = u_pos.distance_to(world_click)
			if d < best_dist:
				best_dist = d
				best_u = u
	if best_u != null:
		_possess_unit(best_u)

func _cycle_or_toggle_possession() -> void:
	var candidates: Array[BattleSimulation.SimUnit] = []
	for u in sim.active_units:
		if u.active and u.team == 1 and u.anim_state != "DEATH" and u.unit_role != "miner":
			candidates.append(u)
	if candidates.is_empty():
		for u in sim.active_units:
			if u.active and u.team == 1 and u.anim_state != "DEATH":
				candidates.append(u)
	if candidates.is_empty():
		return
	var cur_idx: int = candidates.find(player_unit)
	var next_u: BattleSimulation.SimUnit = candidates[(cur_idx + 1) % candidates.size()]
	_possess_unit(next_u)

func _possess_unit(u: BattleSimulation.SimUnit) -> void:
	if player_unit != null:
		player_unit.is_player_controlled = false
		player_unit.ai_enabled = true
	player_unit = u
	player_unit.is_player_controlled = true
	player_unit.ai_enabled = false
	SoundEngine.play_sfx("ui_click")
	_spawn_floating_text(Vector2(u.x, GROUND_Y + u.lane_y_offset - 88.0), "🎮 NHẬP VAI!", Color(1.0, 0.92, 0.25))

func _release_possessed_unit() -> void:
	if player_unit != null:
		player_unit.is_player_controlled = false
		player_unit.ai_enabled = true
		player_unit = null
		SoundEngine.play_sfx("ui_click")

func _open_modal(modal_id: String) -> void:
	active_modal = modal_id
	for k in _modals.keys():
		(_modals[k] as Control).visible = (k == modal_id)
	if modal_id == "build":
		_refresh_build_rows_ui()

func _show_toast(msg: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = msg
	_toast_panel.visible = true
	_toast_timer = 3.5

# --- 1. HUD CĂN CỨ (Clash of Clans Peripheral Layout over Live Fullscreen Scene) ---
func _build_base_hud() -> void:
	_hud_base_root = Control.new()
	_hud_base_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_base_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_hud_base_root)

	# Top-Left: Profile Square + Cyan Level Badge 12 + Name "Aethel" + Trophy Square
	var btn_prof := _make_icon_square_button("shield", "Hồ sơ", Vector2(22, 20), Vector2(82, 88))
	btn_prof.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_show_toast("Hồ sơ Chiến Binh Aethel · Cấp 12 (Chuyển sang Đấu 1v1 để điều khiển trực tiếp).")
	)
	_hud_base_root.add_child(btn_prof)

	var lvl_badge := PanelContainer.new()
	lvl_badge.position = Vector2(14, 12)
	lvl_badge.size = Vector2(36, 30)
	lvl_badge.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.13, 0.73, 0.88), Color(0.08, 0.21, 0.27), Color.BLACK, 7, 2, 2, 4, 2))
	_hud_base_root.add_child(lvl_badge)
	var lbl_lvl := Label.new()
	lbl_lvl.text = "12"
	lbl_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_lvl, 17, BastionUI.COL_CREAM_TEXT, 4)
	lvl_badge.add_child(lbl_lvl)

	var lbl_name := Label.new()
	lbl_name.text = "Aethel"
	lbl_name.position = Vector2(114, 34)
	BastionUI.style_display_label(lbl_name, 24, BastionUI.COL_CREAM_TEXT, 6)
	_hud_base_root.add_child(lbl_name)

	var btn_trophy := _make_icon_square_button("trophy", "Thành tích", Vector2(22, 118), Vector2(82, 82))
	btn_trophy.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("events")
	)
	_hud_base_root.add_child(btn_trophy)

	# Top-Right: Stacked Resource Pills (Gold 1 250 & Gems 80) matching ref_coc_hud.png
	_hud_base_root.add_child(_make_resource_pill(Vector2(1030, 22), "1 250", "coin"))
	_hud_base_root.add_child(_make_resource_pill(Vector2(1030, 66), "80", "gem"))

	# Right-Middle: Shop Square Button with Red Notification Badge
	var btn_shop := _make_icon_square_button("chest", "Cửa hàng", Vector2(1174, 320), Vector2(84, 86), "3")
	btn_shop.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("shop")
	)
	_hud_base_root.add_child(btn_shop)

	# Bottom-Left: Large Golden "CHIẾN ĐẤU" Button + Compact Event Tray (ref_coc_events.png)
	var btn_battle := _make_main_gold_button("sword", "Chiến đấu", Vector2(22, 578), Vector2(132, 118))
	btn_battle.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("battle")
	)
	_hud_base_root.add_child(btn_battle)

	var tray_panel := PanelContainer.new()
	tray_panel.position = Vector2(168, 616)
	tray_panel.size = Vector2(124, 78)
	tray_panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.14, 0.20, 0.11, 0.82), Color(0.18, 0.20, 0.12), Color.BLACK, 10, 2, 3, 6, 6))
	_hud_base_root.add_child(tray_panel)

	var tray_hbox := HBoxContainer.new()
	tray_hbox.add_theme_constant_override("separation", 6)
	tray_panel.add_child(tray_hbox)

	var btn_ev := Button.new()
	btn_ev.custom_minimum_size = Vector2(64, 62)
	BastionUI.apply_clash_button_style(btn_ev, "stone", 12)
	var cal_icon := BastionUI.VectorIcon.new("calendar", Vector2(46, 46))
	cal_icon.position = Vector2(9, 8)
	btn_ev.add_child(cal_icon)
	btn_ev.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("events")
	)
	tray_hbox.add_child(btn_ev)

	var btn_arrow := Button.new()
	btn_arrow.text = "›"
	btn_arrow.custom_minimum_size = Vector2(36, 62)
	BastionUI.apply_clash_button_style(btn_arrow, "stone_tab", 26)
	btn_arrow.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("events")
	)
	tray_hbox.add_child(btn_arrow)

	# Bottom-Right: Square "Đội hình" + Large Golden "PHÁT TRIỂN" Button
	var btn_army := _make_icon_square_button("shield", "Đội hình", Vector2(1030, 610), Vector2(86, 86))
	btn_army.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("army")
	)
	_hud_base_root.add_child(btn_army)

	var btn_build := _make_main_gold_button("hammer", "Phát triển", Vector2(1126, 578), Vector2(132, 118))
	btn_build.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("build")
	)
	_hud_base_root.add_child(btn_build)

# --- 2. HUD GIAO CHIẾN NGANG (Clash Royale Tactile Action Cards + Clear Battlefield) ---
func _build_battle_hud() -> void:
	_hud_battle_root = Control.new()
	_hud_battle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_battle_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_hud_battle_root)

	# Top-Left: Player Citadel & Hero HP Bar
	var p_card := PanelContainer.new()
	p_card.position = Vector2(16, 12)
	p_card.size = Vector2(330, 58)
	p_card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.16, 0.34, 0.62, 0.92), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 10, 6))
	_hud_battle_root.add_child(p_card)

	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 4)
	p_card.add_child(p_vbox)

	_lbl_player_hp = Label.new()
	_lbl_player_hp.text = "Hiệp Sĩ Aethel: 340 / 340 HP"
	BastionUI.style_display_label(_lbl_player_hp, 15, BastionUI.COL_CREAM_TEXT, 4)
	p_vbox.add_child(_lbl_player_hp)

	var p_bar_bg := ColorRect.new()
	p_bar_bg.custom_minimum_size = Vector2(306, 14)
	p_bar_bg.color = Color(0.12, 0.10, 0.08)
	p_vbox.add_child(p_bar_bg)

	_bar_player_fill = ColorRect.new()
	_bar_player_fill.position = Vector2(2, 2)
	_bar_player_fill.size = Vector2(302, 10)
	_bar_player_fill.color = Color(0.42, 0.88, 0.24)
	p_bar_bg.add_child(_bar_player_fill)

	# Top-Center: Quick Mode Bar (Về Căn Cứ | Đổi Trang Bị 6 Khe | Phòng Thử Kỹ Thuật)
	var center_bar := HBoxContainer.new()
	center_bar.position = Vector2(362, 12)
	center_bar.size = Vector2(556, 48)
	center_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	center_bar.add_theme_constant_override("separation", 8)
	_hud_battle_root.add_child(center_bar)

	var btn_to_base := Button.new()
	btn_to_base.text = "⚔️ Trận Stick War (Thủ Nhà)"
	BastionUI.apply_clash_button_style(btn_to_base, "green", 14)
	btn_to_base.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("")
		_switch_hud_context("STICK_WAR")
	)
	center_bar.add_child(btn_to_base)

	var btn_to_gear := Button.new()
	btn_to_gear.text = "Trang Bị (6 Khe)"
	BastionUI.apply_clash_button_style(btn_to_gear, "gold", 14)
	btn_to_gear.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("build" if active_modal != "build" else "")
	)
	center_bar.add_child(btn_to_gear)

	var btn_to_lab := Button.new()
	btn_to_lab.text = "Phòng Thử & Benchmark"
	BastionUI.apply_clash_button_style(btn_to_lab, "blue", 14)
	btn_to_lab.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("")
		_switch_hud_context("LAB" if hud_context != "LAB" else "BATTLE")
	)
	center_bar.add_child(btn_to_lab)

	# Top-Right: Enemy Orc Fortress & AI HP Bar
	var e_card := PanelContainer.new()
	e_card.position = Vector2(934, 12)
	e_card.size = Vector2(330, 58)
	e_card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.42, 0.22, 0.56, 0.92), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 10, 6))
	_hud_battle_root.add_child(e_card)

	var e_vbox := VBoxContainer.new()
	e_vbox.add_theme_constant_override("separation", 4)
	e_card.add_child(e_vbox)

	_lbl_ai_hp = Label.new()
	_lbl_ai_hp.text = "Chiến Binh Orc: 545 / 545 HP"
	_lbl_ai_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	BastionUI.style_display_label(_lbl_ai_hp, 15, BastionUI.COL_CREAM_TEXT, 4)
	e_vbox.add_child(_lbl_ai_hp)

	var e_bar_bg := ColorRect.new()
	e_bar_bg.custom_minimum_size = Vector2(306, 14)
	e_bar_bg.color = Color(0.12, 0.10, 0.08)
	e_vbox.add_child(e_bar_bg)

	_bar_ai_fill = ColorRect.new()
	_bar_ai_fill.position = Vector2(2, 2)
	_bar_ai_fill.size = Vector2(302, 10)
	_bar_ai_fill.color = Color(0.95, 0.32, 0.30)
	e_bar_bg.add_child(_bar_ai_fill)

	# Bottom-Center: Clash Royale Portrait Action Cards (96x112 tactile cards)
	var deck_tray := PanelContainer.new()
	deck_tray.position = Vector2(330, 594)
	deck_tray.size = Vector2(620, 118)
	deck_tray.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.36, 0.25, 0.18, 0.92), BastionUI.COL_BORDER_DARK, Color.BLACK, 12, 3, 5, 10, 6))
	_hud_battle_root.add_child(deck_tray)

	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 10)
	deck_tray.add_child(cards_row)

	var card_defs: Array[Array] = [
		["sword", "Chém Combo", "Phím J", "gold", func() -> void: sim.player_queued_attack = 1],
		["cleaver", "Đột Kích", "Phím L", "gold", func() -> void: sim.player_queued_attack = 2],
		["shield", "Đỡ / Parry", "Giữ K", "blue", func() -> void: _trigger_player_anim_preview("BLOCK_HIT")],
		["hammer", "6 Trang Bị", "Đổi đồ", "stone", func() -> void: _open_modal("build" if active_modal != "build" else "")],
		["trophy", "Đấu Lại", "Phím R", "green", func() -> void: _setup_1v1_duel()]
	]

	for cd in card_defs:
		var card_btn := _make_clash_action_card(str(cd[0]), str(cd[1]), str(cd[2]), str(cd[3]))
		var cb: Callable = cd[4]
		card_btn.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			cb.call()
		)
		cards_row.add_child(card_btn)

# --- 3. PHÒNG THỬ KỸ THUẬT (6 Animation Triggers, 12 Bones, Slow-Mo, 300-Unit Benchmark) ---
func _build_lab_hud() -> void:
	_hud_lab_root = Control.new()
	_hud_lab_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_lab_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_lab_root.visible = false
	_ui_layer.add_child(_hud_lab_root)

	# Left Technical Drawer: 6 Animation Triggers + Rig/LOD Controls
	var lab_panel := PanelContainer.new()
	lab_panel.position = Vector2(16, 80)
	lab_panel.size = Vector2(280, 495)
	lab_panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.40, 0.28, 0.20, 0.94), BastionUI.COL_BORDER_DARK, Color.BLACK, 12, 3, 5, 10, 8))
	_hud_lab_root.add_child(lab_panel)

	var lvbox := VBoxContainer.new()
	lvbox.add_theme_constant_override("separation", 6)
	lab_panel.add_child(lvbox)

	var lbl_t := Label.new()
	lbl_t.text = "PHÒNG THỬ KỸ THUẬT"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_t, 17, BastionUI.COL_GOLD_TEXT, 5)
	lvbox.add_child(lbl_t)

	for i in range(ANIM_ORDER.size()):
		var st_code: String = ANIM_ORDER[i]
		var btn_a := Button.new()
		btn_a.text = "%d. Anim: %s" % [i + 1, st_code]
		BastionUI.apply_clash_button_style(btn_a, "row_tan", 14)
		btn_a.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			_trigger_player_anim_preview(st_code)
		)
		lvbox.add_child(btn_a)

	var btn_bones := Button.new()
	btn_bones.text = "Bật/Tắt 12 Khớp Xương (B)"
	BastionUI.apply_clash_button_style(btn_bones, "stone", 14)
	btn_bones.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		show_debug_bones = not show_debug_bones
	)
	lvbox.add_child(btn_bones)

	var btn_lod := Button.new()
	btn_lod.text = "Chế Độ Đông Quân: Batched Atlas"
	BastionUI.apply_clash_button_style(btn_lod, "green", 13)
	btn_lod.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		use_batched_atlas_lod = not use_batched_atlas_lod
		btn_lod.text = "Chế Độ Đông Quân: Batched Atlas" if use_batched_atlas_lod else "Chế Độ Đông Quân: Full Vector"
	)
	lvbox.add_child(btn_lod)

	var tier_row := HBoxContainer.new()
	tier_row.add_theme_constant_override("separation", 4)
	lvbox.add_child(tier_row)
	for t_cnt in [30, 100, 200, 300]:
		var b_t := Button.new()
		b_t.text = str(t_cnt)
		b_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		BastionUI.apply_clash_button_style(b_t, "blue", 14)
		var count_val: int = t_cnt
		b_t.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			_spawn_mass_battle(count_val)
		)
		tier_row.add_child(b_t)

	var btn_run_bench := Button.new()
	btn_run_bench.text = "Chạy Benchmark 3 Lần [F3]"
	BastionUI.apply_clash_button_style(btn_run_bench, "gold", 15)
	btn_run_bench.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_start_benchmark_suite()
	)
	lvbox.add_child(btn_run_bench)

	# Top-Right Telemetry Box (Only visible inside Lab Mode)
	var perf_panel := PanelContainer.new()
	perf_panel.position = Vector2(934, 80)
	perf_panel.size = Vector2(330, 195)
	perf_panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.18, 0.14, 0.11, 0.92), BastionUI.COL_BORDER_DARK, Color.BLACK, 10, 2, 4, 10, 8))
	_hud_lab_root.add_child(perf_panel)

	_lbl_perf = Label.new()
	BastionUI.style_display_label(_lbl_perf, 13, BastionUI.COL_CREAM_TEXT, 3)
	perf_panel.add_child(_lbl_perf)

	_panel_bench_report = PanelContainer.new()
	_panel_bench_report.position = Vector2(308, 80)
	_panel_bench_report.size = Vector2(614, 210)
	_panel_bench_report.visible = false
	_panel_bench_report.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.24, 0.17, 0.12, 0.96), Color(0.96, 0.76, 0.22), Color.BLACK, 12, 3, 5, 12, 8))
	_hud_lab_root.add_child(_panel_bench_report)

	_lbl_bench_report = Label.new()
	BastionUI.style_display_label(_lbl_bench_report, 12, BastionUI.COL_CREAM_TEXT, 3)
	_panel_bench_report.add_child(_lbl_bench_report)

# --- 4. PANEL PHẢI: PHÁT TRIỂN / TRANG BỊ (Matches ref_coc_build.png & clash-layout-v2.html) ---
func _build_right_equipment_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(716, 10)
	panel.size = Vector2(554, 700)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.40, 0.27, 0.20), BastionUI.COL_BORDER_DARK, Color.BLACK, 8, 4, 6, 0, 0))
	_ui_layer.add_child(panel)
	_modals["build"] = panel

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	panel.add_child(root_vbox)

	# Stone Header (#81786D -> #5C554F)
	var head := _make_modal_stone_header("Trang bị & Anh hùng", true)
	root_vbox.add_child(head)

	# Scrollable List Area
	var list_margin := MarginContainer.new()
	list_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_margin.add_theme_constant_override("margin_left", 10)
	list_margin.add_theme_constant_override("margin_right", 10)
	list_margin.add_theme_constant_override("margin_top", 6)
	list_margin.add_theme_constant_override("margin_bottom", 6)
	root_vbox.add_child(list_margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_margin.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 7)
	scroll.add_child(list_vbox)

	list_vbox.add_child(_make_group_divider("Đề xuất nâng cấp · 6 Khe Trang Bị (Bấm để đổi)"))

	var socket_meta: Array[Array] = [
		[ContentDB.SOCKET_MAIN_WEAPON, "sword", "1. Vũ Khí Chính"],
		[ContentDB.SOCKET_OFFHAND, "shield", "2. Tay Phụ / Khiên"],
		[ContentDB.SOCKET_HELMET, "helm", "3. Mũ Giáp"],
		[ContentDB.SOCKET_CHEST_ARMOR, "armor", "4. Giáp Ngực"],
		[ContentDB.SOCKET_PAULDRON, "pauldron", "5. Giáp Vai"],
		[ContentDB.SOCKET_BACK_CAPE, "cape", "6. Áo Choàng"]
	]

	for sm in socket_meta:
		var sk: String = str(sm[0])
		var icon_id: String = str(sm[1])
		var slot_title: String = str(sm[2])
		var row_btn := Button.new()
		row_btn.custom_minimum_size = Vector2(510, 74)
		BastionUI.apply_clash_button_style(row_btn, "row_tan", 16)
		row_btn.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			_cycle_socket_item(sk)
		)
		list_vbox.add_child(row_btn)

		var thumb := PanelContainer.new()
		thumb.position = Vector2(8, 7)
		thumb.size = Vector2(58, 58)
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.36, 0.25, 0.18), Color(0.24, 0.16, 0.10), Color.BLACK, 8, 2, 2, 3, 3))
		row_btn.add_child(thumb)
		var item_preview_ctrl := Control.new()
		item_preview_ctrl.custom_minimum_size = Vector2(52, 52)
		item_preview_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_preview_ctrl.draw.connect(func() -> void:
			var items_arr: Array[String] = ContentDB.get_items_for_socket(sk)
			var cur_idx: int = int(_socket_indices[sk]) % items_arr.size()
			var cur_id: String = items_arr[cur_idx]
			if cur_id == "off_none" or cur_id == "hlm_none" or cur_id == "pld_none" or cur_id == "cpe_none":
				item_preview_ctrl.draw_circle(Vector2(26, 26), 14.0, Color(0.24, 0.18, 0.14, 0.65))
			else:
				StickmanRig2D.draw_equipment_preview(item_preview_ctrl, cur_id, Rect2(2, 2, 48, 48))
		)
		thumb.add_child(item_preview_ctrl)

		var lbl_item := Label.new()
		lbl_item.position = Vector2(78, 8)
		lbl_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		BastionUI.style_display_label(lbl_item, 18, BastionUI.COL_CREAM_TEXT, 5)
		row_btn.add_child(lbl_item)

		var lbl_sub := Label.new()
		lbl_sub.position = Vector2(78, 38)
		lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		BastionUI.style_display_label(lbl_sub, 13, Color(0.95, 0.88, 0.76), 3)
		row_btn.add_child(lbl_sub)

		var lbl_right := Label.new()
		lbl_right.position = Vector2(350, 14)
		lbl_right.size = Vector2(150, 48)
		lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		BastionUI.style_display_label(lbl_right, 16, BastionUI.COL_GOLD_TEXT, 4)
		row_btn.add_child(lbl_right)

		_build_row_Refs[sk] = {"title": lbl_item, "sub": lbl_sub, "right": lbl_right, "slot": slot_title, "preview": item_preview_ctrl}

	list_vbox.add_child(_make_group_divider("Trang bị khác (Mẫu điều kiện mở khóa)"))

	var locked_row := Button.new()
	locked_row.custom_minimum_size = Vector2(510, 68)
	BastionUI.apply_clash_button_style(locked_row, "stone_tab", 16)
	locked_row.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_show_toast("Áo Choàng Hoàng Gia Cấp 3: Cần nâng cấp Pháo Đài lên Cấp 3 (Mở ở Milestone 3).")
	)
	list_vbox.add_child(locked_row)

	var lbl_lock := Label.new()
	lbl_lock.text = "Áo Choàng Tinh Thạch Cấp 3          Cần Cấp 3 [Khóa]"
	lbl_lock.position = Vector2(18, 20)
	BastionUI.style_display_label(lbl_lock, 16, Color(0.85, 0.82, 0.78), 4)
	locked_row.add_child(lbl_lock)

	# Before -> After Upgrade Comparison Banner
	_lbl_compare_sheet = Label.new()
	_lbl_compare_sheet.text = "Bấm vào bất kỳ hàng nào để đổi trang bị và xem so sánh chỉ số Trước → Sau."
	_lbl_compare_sheet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_compare_sheet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_compare_sheet.custom_minimum_size = Vector2(520, 38)
	BastionUI.style_display_label(_lbl_compare_sheet, 13, BastionUI.COL_GOLD_TEXT, 4)
	root_vbox.add_child(_lbl_compare_sheet)

	# Bottom 4-Tab Bar (Công trình | Quân | Trang bị | Sinh vật)
	var btabs := HBoxContainer.new()
	btabs.custom_minimum_size = Vector2(554, 78)
	btabs.add_theme_constant_override("separation", 4)
	root_vbox.add_child(btabs)

	var tab_defs: Array[Array] = [
		["hammer", "Công trình (M2)", "stone_tab", func() -> void: _show_toast("Tab Công trình sẽ mở ở Milestone 2 (Kinh tế & Pháo đài).")],
		["sword", "Quân (1/1)", "stone_tab", func() -> void: _open_modal("army")],
		["shield", "Trang bị (6/6)", "gold", func() -> void: pass],
		["dragon", "Sinh vật (0/1)", "stone_tab", func() -> void: _open_modal("army")]
	]
	for td in tab_defs:
		var tb := Button.new()
		tb.text = str(td[1])
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		BastionUI.apply_clash_button_style(tb, str(td[2]), 14)
		var cb: Callable = td[3]
		tb.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			cb.call()
		)
		btabs.add_child(tb)

func _refresh_build_rows_ui() -> void:
	if _build_row_Refs.is_empty():
		return
	var costs: Array[int] = [240, 180, 120, 320, 160, 140]
	var c_idx: int = 0
	for sk in _build_row_Refs.keys():
		var ref: Dictionary = _build_row_Refs[sk]
		var items: Array[String] = ContentDB.get_items_for_socket(sk)
		var idx: int = int(_socket_indices[sk]) % items.size()
		var item_data: Dictionary = ContentDB.EQUIPMENT[items[idx]]
		var clean_name: String = str(item_data["name"]).split("(")[0].strip_edges()
		(ref["title"] as Label).text = clean_name
		(ref["sub"] as Label).text = "%s · Mẫu %d/%d" % [str(ref["slot"]), idx + 1, items.size()]
		(ref["right"] as Label).text = "Đổi mẫu (%d/%d)\n%d Vàng" % [idx + 1, items.size(), costs[c_idx % costs.size()]]
		if ref.has("preview") and ref["preview"] != null:
			(ref["preview"] as Control).queue_redraw()
		c_idx += 1

# --- 5. MODAL CHIẾN ĐẤU (Wood Tabs + 2 Large Artwork Mode Cards matching ref_coc_battle.png) ---
func _build_battle_modal() -> void:
	var modal := _make_fullscreen_wood_modal("Chiến đấu")
	_modals["battle"] = modal
	var body: VBoxContainer = modal.get_meta("body") as VBoxContainer

	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 10)
	body.add_child(tabs_row)

	var t1 := Button.new()
	t1.text = "Đấu Trường 1v1"
	BastionUI.apply_clash_button_style(t1, "gold", 18)
	tabs_row.add_child(t1)

	var t2 := Button.new()
	t2.text = "Phòng Thử Kỹ Thuật (Rig / Benchmark)"
	BastionUI.apply_clash_button_style(t2, "wood_tab", 18)
	t2.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("")
		_switch_hud_context("LAB")
	)
	tabs_row.add_child(t2)

	var cards_grid := HBoxContainer.new()
	cards_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_grid.add_theme_constant_override("separation", 22)
	body.add_child(cards_grid)

	cards_grid.add_child(_make_battle_mode_card(
		"Đấu Trường 1v1",
		"Hiệp Sĩ Thành Trì vs Chiến Binh Orc · Đủ 6 khe trang bị, 6 animation & Phản đòn Parry",
		"Vào Trận Ngay",
		"green",
		Color(0.14, 0.34, 0.58),
		func() -> void:
			_open_modal("")
			_switch_hud_context("BATTLE")
	))

	cards_grid.add_child(_make_battle_mode_card(
		"Phòng Thử & Benchmark",
		"Kiểm tra 12 khớp xương, 6 animation cốt lõi và đo hiệu năng 30 / 100 / 200 / 300 quân",
		"Mở Phòng Thử",
		"blue",
		Color(0.36, 0.20, 0.48),
		func() -> void:
			_open_modal("")
			_switch_hud_context("LAB")
	))

# --- 6. MODAL ĐỘI HÌNH & PREVIEW RỒNG LAM (Matches clash-layout-v2.html #army) ---
func _build_army_modal() -> void:
	var modal := _make_fullscreen_wood_modal("Đội hình & Hình khối Nhân vật")
	_modals["army"] = modal
	var body: VBoxContainer = modal.get_meta("body") as VBoxContainer

	body.add_child(_make_group_divider("Chuẩn hình khối Clash Royale · Phân biệt rõ phe Thành Trì, Orc và Rồng Lam"))

	var packs_row := HBoxContainer.new()
	packs_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	packs_row.add_theme_constant_override("separation", 18)
	body.add_child(packs_row)

	packs_row.add_child(_make_unit_pack_card(
		"Hiệp Sĩ Thành Trì",
		"Tiền tuyến · Đang dùng (M1)",
		"Đổi 6 Trang Bị",
		Color(0.18, 0.46, 0.84),
		0,
		func() -> void: _open_modal("build")
	))

	packs_row.add_child(_make_unit_pack_card(
		"Chiến Binh Orc",
		"Cận chiến · Đối thủ AI (M1)",
		"Đấu Thử 1v1",
		Color(0.46, 0.24, 0.62),
		1,
		func() -> void:
			_open_modal("")
			_switch_hud_context("BATTLE")
	))

	packs_row.add_child(_make_unit_pack_card(
		"Rồng Lam Tinh Thạch",
		"Quân bay · Concept Preview",
		"Xem Sự Kiện Rồng",
		Color(0.14, 0.56, 0.72),
		2,
		func() -> void: _open_modal("events")
	))

# --- 7. MODAL CỬA HÀNG (Offer Packs matching clash-layout-v2.html #shop) ---
func _build_shop_modal() -> void:
	var modal := _make_fullscreen_wood_modal("Cửa hàng Pháo Đài")
	_modals["shop"] = modal
	var body: VBoxContainer = modal.get_meta("body") as VBoxContainer

	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 10)
	body.add_child(tabs_row)
	for t_name in ["Nổi bật", "Ngoại hình", "Vật phẩm"]:
		var tb := Button.new()
		tb.text = t_name
		BastionUI.apply_clash_button_style(tb, "gold" if t_name == "Nổi bật" else "wood_tab", 17)
		tb.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			_show_toast("Đang xem tab " + t_name + " (Mẫu bố cục gói Bastion Forge 2.0, chưa mở giao dịch thật).")
		)
		tabs_row.add_child(tb)

	body.add_child(_make_group_divider("Bộ Sưu Tập Pháo Đài · Thiết kế gói minh họa (Không trừ tiền thật)"))

	var offers_row := HBoxContainer.new()
	offers_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offers_row.add_theme_constant_override("separation", 18)
	body.add_child(offers_row)

	var offer_defs: Array[Array] = [
		["Áo Choàng Đại Tướng", "Ngoại hình · Khe 6", "40 Tinh thạch", ContentDB.SOCKET_BACK_CAPE, 2, 10],
		["Khiên Sư Tử Hoàng Gia", "Trang bị · Khe 2", "60 Tinh thạch", ContentDB.SOCKET_OFFHAND, 3, 11],
		["Đại Đao Hỏa Long", "Vũ khí · Khe 1", "Xem & Trang bị", ContentDB.SOCKET_MAIN_WEAPON, 1, 12]
	]

	for od in offer_defs:
		var sk: String = str(od[3])
		var target_idx: int = int(od[4])
		var art_k: int = int(od[5])
		offers_row.add_child(_make_unit_pack_card(
			str(od[0]),
			str(od[1]),
			str(od[2]),
			Color(0.86, 0.52, 0.14),
			art_k,
			func() -> void:
				_socket_indices[sk] = target_idx
				_cycle_socket_item(sk)
				_show_toast("Đã thử gắn [" + str(od[0]) + "] lên Hiệp Sĩ (Bản mẫu không thu phí).")
		))

# --- 8. MODAL SỰ KIỆN (Event Hub matching clash-layout-v2.html #events) ---
func _build_events_modal() -> void:
	var modal := _make_fullscreen_wood_modal("Trung Tâm Sự Kiện")
	_modals["events"] = modal
	var body: VBoxContainer = modal.get_meta("body") as VBoxContainer

	# Event Hero Banner with Dragon Artwork + Progress Bar
	var hero_panel := PanelContainer.new()
	hero_panel.custom_minimum_size = Vector2(1140, 165)
	hero_panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.20, 0.28, 0.48), BastionUI.COL_BORDER_DARK, Color.BLACK, 12, 3, 5, 18, 14))
	body.add_child(hero_panel)

	var hero_hbox := HBoxContainer.new()
	hero_hbox.add_theme_constant_override("separation", 20)
	hero_panel.add_child(hero_hbox)

	var hero_left := VBoxContainer.new()
	hero_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_left.add_theme_constant_override("separation", 8)
	hero_hbox.add_child(hero_left)

	var lbl_ev_title := Label.new()
	lbl_ev_title.text = "LỄ HỘI RỒNG LAM TINH THẠCH"
	BastionUI.style_display_label(lbl_ev_title, 26, BastionUI.COL_GOLD_TEXT, 6)
	hero_left.add_child(lbl_ev_title)

	var lbl_ev_sub := Label.new()
	lbl_ev_sub.text = "Đề xuất Event Hub Bastion Forge 2.0 · Dữ liệu minh họa · Tiến độ mốc thưởng: 60%"
	BastionUI.style_display_label(lbl_ev_sub, 15, BastionUI.COL_CREAM_TEXT, 4)
	hero_left.add_child(lbl_ev_sub)

	var prog_bg := ColorRect.new()
	prog_bg.custom_minimum_size = Vector2(680, 18)
	prog_bg.color = Color(0.14, 0.11, 0.10)
	hero_left.add_child(prog_bg)
	var prog_fill := ColorRect.new()
	prog_fill.position = Vector2(2, 2)
	prog_fill.size = Vector2(420, 14)
	prog_fill.color = Color(0.56, 0.86, 0.24)
	prog_bg.add_child(prog_fill)

	_dragon_preview_ctrl = Control.new()
	_dragon_preview_ctrl.custom_minimum_size = Vector2(240, 136)
	_dragon_preview_ctrl.draw.connect(func() -> void:
		if _tex_dragon_sheet != null:
			var frame_idx: int = int(floor(_time_elapsed * 6.0)) % 4
			var fw: float = float(_tex_dragon_sheet.get_width()) / 4.0
			var fh: float = float(_tex_dragon_sheet.get_height())
			_dragon_preview_ctrl.draw_texture_rect_region(
				_tex_dragon_sheet,
				Rect2(10, 0, 220, 136),
				Rect2(float(frame_idx) * fw, 0.0, fw, fh)
			)
	)
	hero_hbox.add_child(_dragon_preview_ctrl)

	body.add_child(_make_group_divider("Nhiệm vụ Sự kiện (Đọc theo hàng: Mục tiêu → Tiến độ → Thưởng → Hành động)"))

	body.add_child(_make_event_task_row(
		"Hoàn thành hiệp đấu 1v1 trong Đấu Trường",
		"Tiến độ: 3 / 5  ·  Thưởng mẫu: 100 Vàng",
		"Đi tới",
		"green",
		func() -> void:
			_open_modal("")
			_switch_hud_context("BATTLE")
	))

	var btn_claim_ref := _make_event_task_row(
		"Thử nghiệm đổi 6 khe trang bị cho Hiệp Sĩ Aethel",
		"Tiến độ: 1 / 1 (Hoàn tất)  ·  Thưởng mẫu: 20 Tinh thạch",
		"Nhận mẫu",
		"gold",
		func() -> void:
			_show_toast("Đã nhận thưởng mẫu! (Chỉ đổi trạng thái giao diện mẫu, không cộng tiền ngầm).")
	)
	body.add_child(btn_claim_ref)

func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.position = Vector2(280, 642)
	_toast_panel.size = Vector2(720, 54)
	_toast_panel.visible = false
	_toast_panel.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.19, 0.15, 0.12, 0.95), Color(0.84, 0.67, 0.40), Color.BLACK, 10, 2, 4, 14, 8))
	_ui_layer.add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(_toast_label, 15, BastionUI.COL_CREAM_TEXT, 4)
	_toast_panel.add_child(_toast_label)

# ============================================================================
# UI COMPONENT BUILDER HELPERS
# ============================================================================

func _make_icon_square_button(icon_id: String, label_text: String, pos: Vector2, sz: Vector2, badge: String = "") -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	BastionUI.apply_clash_button_style(btn, "stone", 13)

	var icon := BastionUI.VectorIcon.new(icon_id, Vector2(44, 44), badge)
	icon.position = Vector2((sz.x - 44.0) * 0.5, 6.0)
	btn.add_child(icon)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(2, sz.y - 26.0)
	lbl.size = Vector2(sz.x - 4.0, 22.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl, 13, BastionUI.COL_CREAM_TEXT, 4)
	btn.add_child(lbl)
	return btn

func _make_main_gold_button(icon_id: String, label_text: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	BastionUI.apply_clash_button_style(btn, "gold", 18)

	var icon := BastionUI.VectorIcon.new(icon_id, Vector2(64, 64))
	icon.position = Vector2((sz.x - 64.0) * 0.5, 8.0)
	btn.add_child(icon)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(4, sz.y - 36.0)
	lbl.size = Vector2(sz.x - 8.0, 28.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl, 19, BastionUI.COL_CREAM_TEXT, 5)
	btn.add_child(lbl)
	return btn

func _make_resource_pill(pos: Vector2, amount_text: String, icon_id: String) -> Control:
	var pill := PanelContainer.new()
	pill.position = pos
	pill.size = Vector2(226, 36)
	pill.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.12, 0.20, 0.10, 0.80), Color(0.14, 0.18, 0.10), Color.BLACK, 9, 2, 2, 10, 2))

	var lbl := Label.new()
	lbl.text = amount_text + "      "
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	BastionUI.style_display_label(lbl, 19, BastionUI.COL_CREAM_TEXT, 5)
	pill.add_child(lbl)

	var icon := BastionUI.VectorIcon.new(icon_id, Vector2(42, 42))
	icon.position = Vector2(188, -4)
	pill.add_child(icon)
	return pill

func _make_clash_action_card(icon_id: String, title_txt: String, key_txt: String, preset: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 102)
	BastionUI.apply_clash_button_style(btn, preset, 14)

	var icon := BastionUI.VectorIcon.new(icon_id, Vector2(48, 48))
	icon.position = Vector2(31, 14)
	btn.add_child(icon)

	var badge := PanelContainer.new()
	badge.position = Vector2(6, 5)
	badge.size = Vector2(56, 20)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.16, 0.12, 0.09, 0.90), Color(0.95, 0.78, 0.25), Color.BLACK, 5, 1, 1, 4, 1))
	btn.add_child(badge)

	var lbl_k := Label.new()
	lbl_k.text = key_txt
	lbl_k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_k, 11, BastionUI.COL_GOLD_TEXT, 3)
	badge.add_child(lbl_k)

	var lbl_t := Label.new()
	lbl_t.text = title_txt
	lbl_t.position = Vector2(4, 68)
	lbl_t.size = Vector2(102, 24)
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_t, 14, BastionUI.COL_CREAM_TEXT, 4)
	btn.add_child(lbl_t)
	return btn

func _make_modal_stone_header(title_text: String, show_filter: bool = false) -> PanelContainer:
	var head := PanelContainer.new()
	head.custom_minimum_size = Vector2(0, 66)
	head.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.50, 0.46, 0.42), Color(0.19, 0.14, 0.11), Color.BLACK, 6, 2, 4, 16, 8))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	head.add_child(hbox)

	if show_filter:
		var btn_f := Button.new()
		btn_f.text = "☷"
		btn_f.custom_minimum_size = Vector2(46, 44)
		BastionUI.apply_clash_button_style(btn_f, "stone_tab", 18)
		btn_f.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			_show_toast("Bộ lọc trang bị theo nhóm (Đang hiển thị toàn bộ 6 khe trang bị).")
		)
		hbox.add_child(btn_f)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(46, 44)
		hbox.add_child(spacer)

	var lbl := Label.new()
	lbl.text = title_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BastionUI.style_display_label(lbl, 24, BastionUI.COL_CREAM_TEXT, 6)
	hbox.add_child(lbl)

	var btn_close := Button.new()
	btn_close.text = "X"
	btn_close.custom_minimum_size = Vector2(46, 46)
	BastionUI.apply_clash_button_style(btn_close, "red_close", 22)
	btn_close.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_open_modal("")
	)
	hbox.add_child(btn_close)
	return head

func _make_fullscreen_wood_modal(title_text: String) -> PanelContainer:
	var modal := PanelContainer.new()
	modal.position = Vector2(24, 18)
	modal.size = Vector2(1232, 684)
	modal.visible = false
	modal.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.48, 0.32, 0.22), BastionUI.COL_BORDER_DARK, Color.BLACK, 14, 4, 7, 0, 0))
	_ui_layer.add_child(modal)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	modal.add_child(root_vbox)

	root_vbox.add_child(_make_modal_stone_header(title_text, false))

	var body_margin := MarginContainer.new()
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 22)
	body_margin.add_theme_constant_override("margin_right", 22)
	body_margin.add_theme_constant_override("margin_top", 14)
	body_margin.add_theme_constant_override("margin_bottom", 18)
	root_vbox.add_child(body_margin)

	var body_vbox := VBoxContainer.new()
	body_vbox.name = "BodyVBox"
	body_vbox.add_theme_constant_override("separation", 12)
	body_margin.add_child(body_vbox)
	modal.set_meta("body", body_vbox)
	return modal

func _make_group_divider(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.28, 0.19, 0.13, 0.85), Color(0.22, 0.15, 0.10), Color.BLACK, 6, 1, 1, 8, 5))
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl, 15, Color(0.88, 0.78, 0.68), 4)
	p.add_child(lbl)
	return p

func _make_battle_mode_card(title_txt: String, desc_txt: String, cta_txt: String, cta_preset: String, bg_col: Color, on_click: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(bg_col, Color(0.28, 0.20, 0.15), Color.BLACK, 14, 4, 6, 18, 18))

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	if _tex_battlefield != null:
		var tex_rect := TextureRect.new()
		tex_rect.texture = _tex_battlefield
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(0, 260)
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(tex_rect)

	var lbl_t := Label.new()
	lbl_t.text = title_txt
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_t, 28, BastionUI.COL_CREAM_TEXT, 6)
	vbox.add_child(lbl_t)

	var lbl_d := Label.new()
	lbl_d.text = desc_txt
	lbl_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BastionUI.style_display_label(lbl_d, 14, Color(0.92, 0.90, 0.84), 4)
	vbox.add_child(lbl_d)

	var btn := Button.new()
	btn.text = cta_txt
	btn.custom_minimum_size = Vector2(0, 56)
	BastionUI.apply_clash_button_style(btn, cta_preset, 22)
	btn.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		on_click.call()
	)
	vbox.add_child(btn)
	return card

func _make_unit_pack_card(title_txt: String, role_txt: String, cta_txt: String, banner_col: Color, art_kind: int, on_click: Callable) -> PanelContainer:
	var pack := PanelContainer.new()
	pack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.92, 0.62, 0.14), Color(0.30, 0.19, 0.12), Color.BLACK, 13, 3, 5, 0, 0))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	pack.add_child(vbox)

	var top_head := PanelContainer.new()
	top_head.custom_minimum_size = Vector2(0, 54)
	top_head.add_theme_stylebox_override("panel", BastionUI.make_stylebox(banner_col, Color(0.24, 0.15, 0.10), Color.BLACK, 10, 2, 3, 8, 8))
	vbox.add_child(top_head)

	var lbl_h := Label.new()
	lbl_h.text = title_txt
	lbl_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_h, 21, BastionUI.COL_CREAM_TEXT, 5)
	top_head.add_child(lbl_h)

	var art_box := Control.new()
	art_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_box.custom_minimum_size = Vector2(220, 210)
	art_box.draw.connect(func() -> void:
		var c: Vector2 = art_box.size * 0.5
		art_box.draw_rect(Rect2(c - Vector2(95, 95), Vector2(190, 190)), Color(0.22, 0.16, 0.12, 0.45), true)
		if art_kind == 2 and _tex_dragon_sheet != null:
			var fw: float = float(_tex_dragon_sheet.get_width()) / 4.0
			var fh: float = float(_tex_dragon_sheet.get_height())
			art_box.draw_texture_rect_region(_tex_dragon_sheet, Rect2(c - Vector2(95, 75), Vector2(190, 150)), Rect2(0, 0, fw, fh))
		elif art_kind >= 10:
			# Verified 3D-painted item sprites directly from StickmanRig2D Unified Modular Atlas
			# art_kind 10 = Áo Choàng Đại Tướng (cpe_royal_crimson)
			# art_kind 11 = Khiên Sư Tử Hoàng Gia (off_solar_aegis)
			# art_kind 12 = Đại Đao Hỏa Long (wpn_sunfire_greatsword)
			var item_id_preview: String = "cpe_royal_crimson"
			if art_kind == 11:
				item_id_preview = "off_solar_aegis"
			elif art_kind == 12:
				item_id_preview = "wpn_sunfire_greatsword"
			StickmanRig2D.draw_equipment_preview(art_box, item_id_preview, Rect2(c - Vector2(84, 82), Vector2(168, 164)))
		else:
			var dummy := BattleSimulation.SimUnit.new()
			dummy.team = 2 if art_kind == 1 else 1
			dummy.archetype_id = "abyssal_challenger" if art_kind == 1 else "vanguard_hero"
			dummy.unit_scale = 1.45
			dummy.facing = -1.0 if art_kind == 1 else 1.0
			dummy.loadout = ContentDB.MONSTERS["abyssal_challenger"]["default_loadout"].duplicate() if art_kind == 1 else _build_loadout_from_indices()
			rig.draw_character(art_box, dummy, c + Vector2(0, 58), false, false)
	)
	vbox.add_child(art_box)

	var lbl_r := Label.new()
	lbl_r.text = role_txt
	lbl_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_r, 18, BastionUI.COL_CREAM_TEXT, 5)
	vbox.add_child(lbl_r)

	var btn := Button.new()
	btn.text = cta_txt
	btn.custom_minimum_size = Vector2(0, 52)
	BastionUI.apply_clash_button_style(btn, "gold", 20)
	btn.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		on_click.call()
	)
	vbox.add_child(btn)
	return pack

func _make_event_task_row(title_txt: String, sub_txt: String, btn_txt: String, preset: String, on_click: Callable) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 78)
	row.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.64, 0.49, 0.36), Color(0.29, 0.20, 0.15), Color.BLACK, 9, 2, 3, 14, 10))

	var hbox := HBoxContainer.new()
	row.add_child(hbox)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var lbl_t := Label.new()
	lbl_t.text = title_txt
	BastionUI.style_display_label(lbl_t, 19, BastionUI.COL_CREAM_TEXT, 5)
	vbox.add_child(lbl_t)

	var lbl_s := Label.new()
	lbl_s.text = sub_txt
	BastionUI.style_display_label(lbl_s, 14, Color(0.96, 0.88, 0.78), 3)
	vbox.add_child(lbl_s)

	var btn := Button.new()
	btn.text = btn_txt
	btn.custom_minimum_size = Vector2(148, 52)
	BastionUI.apply_clash_button_style(btn, preset, 18)
	btn.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		on_click.call()
		if btn_txt == "Nhận mẫu":
			btn.text = "Đã nhận ✓"
			btn.disabled = true
	)
	hbox.add_child(btn)
	return row

func _update_ui_hud(delta: float) -> void:
	if arena_mode == 3 and _hud_stickwar_root != null and _hud_stickwar_root.visible:
		var miners_cnt: int = 0
		var fighters_cnt: int = 0
		var orcs_cnt: int = 0
		for u in sim.active_units:
			if u.active and u.anim_state != "DEATH":
				if u.team == 1:
					if u.unit_role == "miner":
						miners_cnt += 1
					else:
						fighters_cnt += 1
				elif u.team == 2:
					orcs_cnt += 1
		if _lbl_sw_economy != null:
			_lbl_sw_economy.text = "💰 Vàng: %d  |  ⛏️ Thợ: %d  |  ⚔️ Quân: %d/40  |  👹 Orc: %d  |  🌊 Đợt %d (%ds)" % [
				_sw_gold, miners_cnt, miners_cnt + fighters_cnt, orcs_cnt, _sw_wave, int(ceil(maxf(0.0, _sw_wave_timer)))
			]
		if _lbl_sw_bastion1 != null:
			_lbl_sw_bastion1.text = "🏰 Thành Trì Ta: %d / %d HP" % [int(ceil(sim.bastion1_hp)), int(round(sim.bastion1_max_hp))]
		if _bar_sw_bastion1 != null:
			_bar_sw_bastion1.size.x = 370.0 * clampf(sim.bastion1_hp / maxf(1.0, sim.bastion1_max_hp), 0.0, 1.0)
		if _lbl_sw_bastion2 != null:
			_lbl_sw_bastion2.text = "🗿 Tượng Địch Orc: %d / %d HP" % [int(ceil(sim.bastion2_hp)), int(round(sim.bastion2_max_hp))]
		if _bar_sw_bastion2 != null:
			_bar_sw_bastion2.size.x = 370.0 * clampf(sim.bastion2_hp / maxf(1.0, sim.bastion2_max_hp), 0.0, 1.0)
		if _lbl_sw_possess != null:
			if player_unit != null and player_unit.active and player_unit.anim_state != "DEATH":
				var r_name: String = "Thợ Mỏ" if player_unit.unit_role == "miner" else "Chiến Binh Thành Trì"
				_lbl_sw_possess.text = "🎮 ĐANG NHẬP VAI: %s (%d/%d HP) · [A/D] Di chuyển · [J] Chém · [L] Đột kích · [K] Đỡ/Parry · [ESC] Thoát" % [
					r_name, int(ceil(player_unit.hp)), int(round(player_unit.max_hp))
				]
			else:
				_lbl_sw_possess.text = "💡 Click chuột vào bất kỳ lính nào (hoặc bấm [Tab]) để NHẬP VAI điều khiển trực tiếp · Dùng [A/D] hoặc [←/→] để lia Camera"

	if player_unit != null and _lbl_player_hp != null:
		_lbl_player_hp.text = "Hiệp Sĩ Aethel: %d / %d HP [%s]" % [
			int(ceil(player_unit.hp)), int(round(player_unit.max_hp)), player_unit.anim_state
		]
		if _bar_player_fill != null:
			_bar_player_fill.size.x = 302.0 * clampf(player_unit.hp / maxf(1.0, player_unit.max_hp), 0.0, 1.0)

	if ai_unit != null and _lbl_ai_hp != null:
		_lbl_ai_hp.text = "Chiến Binh Orc: %d / %d HP [%s]" % [
			int(ceil(ai_unit.hp)), int(round(ai_unit.max_hp)), ai_unit.anim_state
		]
		if _bar_ai_fill != null:
			_bar_ai_fill.size.x = 302.0 * clampf(ai_unit.hp / maxf(1.0, ai_unit.max_hp), 0.0, 1.0)

	# Auto-respawn 1v1 duel after KO (unless holding DEATH pose during video recording)
	if arena_mode == 0 and hud_context == "BATTLE" and _video_mode == "" and player_unit != null and ai_unit != null:
		if (player_unit.anim_state == "DEATH" and player_unit.anim_time >= 1.38) or (ai_unit.anim_state == "DEATH" and ai_unit.anim_time >= 1.38):
			_setup_1v1_duel()

	var frame_ms_inst: float = maxf(0.1, delta * 1000.0)
	_fps_window.append(frame_ms_inst)
	if _fps_window.size() > 180:
		_fps_window.pop_front()

	if _lbl_perf != null and (sim.tick_count % 4 <= 1 or _video_mode != ""):
		var sorted_ms: Array[float] = _fps_window.duplicate()
		sorted_ms.sort()
		var n_win: int = max(1, sorted_ms.size())
		var sum_ms: float = 0.0
		for ms_val in sorted_ms:
			sum_ms += ms_val
		var avg_ms: float = sum_ms / float(n_win)
		var avg_win_fps: float = 1000.0 / maxf(0.1, avg_ms)
		# True 1% Low Average FPS = 1000 / mean(slowest 1% of frame times)
		var k_1pct: int = max(1, int(ceil(float(n_win) * 0.01)))
		var sum_worst_ms: float = 0.0
		for w_idx in range(n_win - k_1pct, n_win):
			sum_worst_ms += sorted_ms[w_idx]
		var low_1pct_fps: float = 1000.0 / maxf(0.1, sum_worst_ms / float(k_1pct))
		var vp_rid: RID = get_viewport().get_viewport_rid()
		var gpu_now_ms: float = RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
		var n_active: int = sim.active_units.size()
		var dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var ram_mb: float = float(OS.get_static_memory_usage()) / 1048576.0
		_lbl_perf.text = "HIỆU NĂNG THỜI GIAN THỰC (Godot 4.7.2)\n• Mô phỏng: %d | Trong cam: %d | Đang đánh: %d\n• Avg FPS: %.1f  |  1%% Low Avg: %.1f FPS\n• Frame Time: %.2f ms  |  GPU: %.2f ms\n• CPU Sim (60Hz): %.2f ms  |  CPU Render: %.2f ms\n• Draw Calls: %d  |  RAM: %.1f MB" % [
			n_active, _last_visible_units, _last_engaged_units,
			avg_win_fps, low_1pct_fps,
			avg_ms, gpu_now_ms, _last_sim_ms, _last_render_ms, dc, ram_mb
		]

# ============================================================================
# CHẶNG C: TIME-BASED STATISTICAL BENCHMARK (10s WARMUP + 60s SAMPLE x 3 RUNS)
# ============================================================================

func _start_benchmark_suite() -> void:
	_bench_running = true
	_bench_iter_idx = 0
	_bench_tier_idx = 0
	var warmup_s: float = BENCH_WARMUP_SEC
	var sample_s: float = BENCH_SAMPLE_SEC
	_active_bench_tiers = [30, 100, 200, 300]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--warmup="):
			warmup_s = maxf(1.0, float(arg.split("=")[1]))
		elif arg.begins_with("--sample="):
			sample_s = maxf(2.0, float(arg.split("=")[1]))
		elif arg.begins_with("--tiers="):
			_active_bench_tiers.clear()
			for part in arg.split("=")[1].split(","):
				if part.strip_edges().is_valid_int():
					_active_bench_tiers.append(int(part.strip_edges()))
	set_meta("warmup_s", warmup_s)
	set_meta("sample_s", sample_s)

	var existing_tiers: Dictionary = {}
	if FileAccess.file_exists("res://milestone1_benchmark_v3_60s.json"):
		var f_prev := FileAccess.open("res://milestone1_benchmark_v3_60s.json", FileAccess.READ)
		if f_prev != null:
			var parsed: Variant = JSON.parse_string(f_prev.get_as_text())
			f_prev.close()
			if parsed is Dictionary and (parsed as Dictionary).has("tiers"):
				existing_tiers = (parsed as Dictionary)["tiers"]
	for t_erase in _active_bench_tiers:
		existing_tiers.erase(str(t_erase))

	_bench_results = {
		"meta": {
			"engine": "Godot v4.7.2.stable.official.ed1daf0bf",
			"renderer": "gl_compatibility (OpenGL 3.3)",
			"gpu": RenderingServer.get_video_adapter_name(),
			"cpu": OS.get_processor_name(),
			"resolution": "1280x720",
			"seed": 20261024,
			"iterations_per_tier": BENCH_ITERATIONS,
			"warmup_seconds": warmup_s,
			"sample_seconds": sample_s,
			"1pct_low_definition": "1000.0 / mean(slowest_1pct_frame_ms); p99_fps = 1000.0 / p99_frame_ms; gpu_ms sampled every frame"
		},
		"tiers": existing_tiers
	}
	show_debug_bones = false
	use_batched_atlas_lod = true
	time_scale = 1.0
	_start_next_benchmark_run()

func _start_next_benchmark_run() -> void:
	_bench_elapsed_sec = 0.0
	_bench_frame_ms_samples.clear()
	_bench_sim_ms_samples.clear()
	_bench_render_ms_samples.clear()
	_bench_rs_cpu_ms_samples.clear()
	_bench_gpu_ms_samples.clear()
	_bench_draw_calls_samples.clear()
	_bench_vis_units_samples.clear()
	_bench_engaged_units_samples.clear()
	seed(20261024 + _bench_iter_idx * 100 + _bench_tier_idx)
	_spawn_mass_battle(_active_bench_tiers[_bench_tier_idx])

func _step_benchmark(delta: float) -> void:
	var warmup_s: float = float(get_meta("warmup_s", BENCH_WARMUP_SEC))
	var sample_s: float = float(get_meta("sample_s", BENCH_SAMPLE_SEC))
	_bench_elapsed_sec += delta

	if _bench_elapsed_sec > warmup_s:
		var vp_rid: RID = get_viewport().get_viewport_rid()
		_bench_frame_ms_samples.append(maxf(0.05, delta * 1000.0))
		_bench_sim_ms_samples.append(_last_sim_ms)
		_bench_render_ms_samples.append(_last_render_ms)
		_bench_rs_cpu_ms_samples.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid))
		_bench_gpu_ms_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		_bench_draw_calls_samples.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		_bench_vis_units_samples.append(_last_visible_units)
		_bench_engaged_units_samples.append(_last_engaged_units)

	if _bench_elapsed_sec >= (warmup_s + sample_s):
		var tier_units: int = _active_bench_tiers[_bench_tier_idx]
		var tier_key: String = str(tier_units)
		var tiers_dict: Dictionary = _bench_results["tiers"]
		if not tiers_dict.has(tier_key):
			tiers_dict[tier_key] = {"runs": []}
		var run_metrics: Dictionary = _compute_single_run_metrics(tier_units, _bench_iter_idx + 1)
		(tiers_dict[tier_key]["runs"] as Array).append(run_metrics)
		print("  -> [Run %d/%d | Sim %d | Vis %d..%d (Avg %.1f) | Eng %.1f] Avg %.1f FPS | 1%% Low Avg %.1f FPS | p99 FPS %.1f | Frame %.2f ms (p95 %.2f / p99 %.2f) | Sim %.2f ms | Render %.2f ms | GPU Avg %.2f ms (p99 %.2f) | DC %d | Samples %d" % [
			_bench_iter_idx + 1, BENCH_ITERATIONS, tier_units,
			int(run_metrics["visible_units_min"]), int(run_metrics["visible_units_max"]), float(run_metrics["visible_units_avg"]),
			float(run_metrics["engaged_units_avg"]),
			float(run_metrics["avg_fps"]), float(run_metrics["fps_1pct_low_avg"]), float(run_metrics["fps_p99_threshold"]),
			float(run_metrics["avg_frame_ms"]), float(run_metrics["p95_frame_ms"]), float(run_metrics["p99_frame_ms"]),
			float(run_metrics["cpu_sim_ms"]), float(run_metrics["cpu_rig_render_ms"]),
			float(run_metrics["avg_gpu_ms"]), float(run_metrics["p99_gpu_ms"]),
			int(run_metrics["draw_calls_2d"]), int(run_metrics["sample_frames"])
		])

		_bench_iter_idx += 1
		if _bench_iter_idx < BENCH_ITERATIONS:
			_start_next_benchmark_run()
		else:
			_finalize_tier_aggregate(tier_units)
			_bench_iter_idx = 0
			_bench_tier_idx += 1
			if _bench_tier_idx < _active_bench_tiers.size():
				_start_next_benchmark_run()
			else:
				_finish_benchmark_suite()

func _compute_single_run_metrics(unit_count: int, run_idx: int) -> Dictionary:
	var n: int = max(1, _bench_frame_ms_samples.size())
	var sum_frame_ms: float = 0.0
	var sum_sim_ms: float = 0.0
	var sum_ren_ms: float = 0.0
	var sum_rs_cpu_ms: float = 0.0
	var sum_gpu_ms: float = 0.0
	var sum_dc: int = 0
	var sum_vis: int = 0
	var min_vis: int = unit_count
	var max_vis: int = 0
	var sum_eng: int = 0

	var ms_sorted: Array[float] = _bench_frame_ms_samples.duplicate()
	ms_sorted.sort()
	var gpu_sorted: Array[float] = _bench_gpu_ms_samples.duplicate()
	gpu_sorted.sort()

	for i in range(n):
		sum_frame_ms += _bench_frame_ms_samples[i]
		sum_sim_ms += _bench_sim_ms_samples[i]
		sum_ren_ms += _bench_render_ms_samples[i]
		sum_rs_cpu_ms += _bench_rs_cpu_ms_samples[i]
		sum_gpu_ms += _bench_gpu_ms_samples[i]
		sum_dc += _bench_draw_calls_samples[i]
		var v_i: int = _bench_vis_units_samples[i]
		sum_vis += v_i
		if v_i < min_vis:
			min_vis = v_i
		if v_i > max_vis:
			max_vis = v_i
		sum_eng += _bench_engaged_units_samples[i]

	var avg_frame_ms: float = sum_frame_ms / float(n)
	var idx_p95: int = clampi(int(floor(float(n) * 0.95)), 0, n - 1)
	var idx_p99: int = clampi(int(floor(float(n) * 0.99)), 0, n - 1)
	var p95_ms: float = ms_sorted[idx_p95]
	var p99_ms: float = ms_sorted[idx_p99]
	var max_ms: float = ms_sorted[n - 1]

	# True 1% Low Average FPS = 1000 / mean(slowest 1% of frames)
	var k_1pct: int = max(1, int(ceil(float(n) * 0.01)))
	var sum_worst_1pct_ms: float = 0.0
	for w_idx in range(n - k_1pct, n):
		sum_worst_1pct_ms += ms_sorted[w_idx]
	var worst_1pct_mean_ms: float = sum_worst_1pct_ms / float(k_1pct)

	return {
		"run": run_idx,
		"units": unit_count,
		"total_sim_units": sim.active_units.size(),
		"visible_units": int(round(float(sum_vis) / float(n))),
		"visible_units_min": min_vis,
		"visible_units_avg": snappedf(float(sum_vis) / float(n), 0.1),
		"visible_units_max": max_vis,
		"engaged_units_avg": snappedf(float(sum_eng) / float(n), 0.1),
		"sample_frames": n,
		"sampled_duration_sec": snappedf(sum_frame_ms / 1000.0, 0.05),
		"avg_fps": snappedf(1000.0 / maxf(0.05, avg_frame_ms), 0.1),
		"fps_1pct_low_avg": snappedf(1000.0 / maxf(0.05, worst_1pct_mean_ms), 0.1),
		"fps_p99_threshold": snappedf(1000.0 / maxf(0.05, p99_ms), 0.1),
		"min_fps": snappedf(1000.0 / maxf(0.05, max_ms), 0.1),
		"avg_frame_ms": snappedf(avg_frame_ms, 0.02),
		"p95_frame_ms": snappedf(p95_ms, 0.02),
		"p99_frame_ms": snappedf(p99_ms, 0.02),
		"worst_1pct_mean_ms": snappedf(worst_1pct_mean_ms, 0.02),
		"cpu_sim_ms": snappedf(sum_sim_ms / float(n), 0.02),
		"cpu_rig_render_ms": snappedf(sum_ren_ms / float(n), 0.02),
		"rs_cpu_ms": snappedf(sum_rs_cpu_ms / float(n), 0.02),
		"avg_gpu_ms": snappedf(sum_gpu_ms / float(n), 0.02),
		"p95_gpu_ms": snappedf(gpu_sorted[idx_p95], 0.02),
		"p99_gpu_ms": snappedf(gpu_sorted[idx_p99], 0.02),
		"draw_calls_2d": int(round(float(sum_dc) / float(n))),
		"ram_mb": snappedf(float(OS.get_static_memory_usage()) / 1048576.0, 0.1)
	}

func _finalize_tier_aggregate(unit_count: int) -> void:
	var tier_dict: Dictionary = _bench_results["tiers"][str(unit_count)]
	var runs: Array = tier_dict["runs"]
	var k_count: int = runs.size()
	var keys: Array[String] = [
		"avg_fps", "fps_1pct_low_avg", "fps_p99_threshold", "min_fps",
		"avg_frame_ms", "p95_frame_ms", "p99_frame_ms", "worst_1pct_mean_ms",
		"cpu_sim_ms", "cpu_rig_render_ms", "rs_cpu_ms",
		"avg_gpu_ms", "p95_gpu_ms", "p99_gpu_ms",
		"draw_calls_2d", "ram_mb", "visible_units", "visible_units_min",
		"visible_units_avg", "visible_units_max", "engaged_units_avg", "sample_frames"
	]
	for k in keys:
		var s: float = 0.0
		for r in runs:
			s += float((r as Dictionary).get(k, 0.0))
		if k == "draw_calls_2d" or k == "visible_units" or k == "visible_units_min" or k == "visible_units_max" or k == "sample_frames":
			tier_dict[k] = int(round(s / float(k_count)))
		else:
			tier_dict[k] = snappedf(s / float(k_count), 0.01)

	print("=== [TỔNG HỢP %d QUÂN (TB 3 LẦN x 60s)] Avg %.1f FPS | 1%% Low Avg %.1f FPS | p99 FPS %.1f | Frame %.2f ms (p95: %.2f, p99: %.2f) | Sim %.2f ms | Render %.2f ms | GPU %.2f ms (p95: %.2f, p99: %.2f) | DrawCalls %d | RAM %.1f MB ===" % [
		unit_count,
		float(tier_dict["avg_fps"]), float(tier_dict["fps_1pct_low_avg"]), float(tier_dict["fps_p99_threshold"]),
		float(tier_dict["avg_frame_ms"]), float(tier_dict["p95_frame_ms"]), float(tier_dict["p99_frame_ms"]),
		float(tier_dict["cpu_sim_ms"]), float(tier_dict["cpu_rig_render_ms"]),
		float(tier_dict["avg_gpu_ms"]), float(tier_dict["p95_gpu_ms"]), float(tier_dict["p99_gpu_ms"]),
		int(tier_dict["draw_calls_2d"]), float(tier_dict["ram_mb"])
	])
	var partial_file := FileAccess.open("res://milestone1_benchmark_v3_60s.json", FileAccess.WRITE)
	if partial_file != null:
		partial_file.store_string(JSON.stringify(_bench_results, "\t"))
		partial_file.close()

func _finish_benchmark_suite() -> void:
	_bench_running = false
	var file := FileAccess.open("res://milestone1_benchmark_v3_60s.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_bench_results, "\t"))
		file.close()

	var lines: PackedStringArray = PackedStringArray()
	lines.append("KẾT QUẢ BENCHMARK 60 GIÂY x 3 LẦN LẶP (Unified 3D Modular Atlas):")
	for tier in _active_bench_tiers:
		if not _bench_results["tiers"].has(str(tier)):
			continue
		var d: Dictionary = _bench_results["tiers"][str(tier)]
		lines.append("• %d Quân: Avg %.1f FPS | 1%% Low Avg %.1f | p99 FPS %.1f | Frame %.2fms | Sim %.2fms | Render %.2fms | GPU %.2fms | DC %d" % [
			tier, float(d["avg_fps"]), float(d["fps_1pct_low_avg"]), float(d["fps_p99_threshold"]),
			float(d["avg_frame_ms"]), float(d["cpu_sim_ms"]), float(d["cpu_rig_render_ms"]),
			float(d["avg_gpu_ms"]), int(d["draw_calls_2d"])
		])

	if _panel_bench_report != null and _lbl_bench_report != null:
		_lbl_bench_report.text = "\n".join(lines)
		_panel_bench_report.visible = true

	if _bench_cli_mode:
		sim.clear_all_units()
		get_tree().quit(0)

# ============================================================================
# AUTOMATED VISUAL SHOWCASE, ITEM AUDIT & VIDEO RECORDING
# ============================================================================

func _step_showcase(delta: float) -> void:
	_showcase_timer += delta
	if _showcase_step == 0 and _showcase_timer > 0.35:
		# 1. HUD Căn Cứ
		_save_viewport_png("res://bf2_01_base_hud.png")
		_open_modal("build")
		_cycle_socket_item(ContentDB.SOCKET_MAIN_WEAPON)
		_showcase_step = 1
	elif _showcase_step == 1 and _showcase_timer > 0.70:
		# 2. Panel Phải: Phát Triển / Trang Bị 6 Khe (có icon vật phẩm 3D thực tế)
		_save_viewport_png("res://bf2_02_build_panel.png")
		_open_modal("battle")
		_showcase_step = 2
	elif _showcase_step == 2 and _showcase_timer > 1.05:
		# 3. Modal Chiến Đấu
		_save_viewport_png("res://bf2_03_battle_modal.png")
		_open_modal("shop")
		_showcase_step = 3
	elif _showcase_step == 3 and _showcase_timer > 1.40:
		# 4. Modal Cửa Hàng (Đã sửa Đại Đao Hỏa Long hiển thị đúng thanh đại đao rực lửa!)
		_save_viewport_png("res://bf2_04_shop_modal.png")
		_open_modal("events")
		_showcase_step = 4
	elif _showcase_step == 4 and _showcase_timer > 1.75:
		# 5. Modal Sự Kiện
		_save_viewport_png("res://bf2_05_events_modal.png")
		_open_modal("army")
		_showcase_step = 5
	elif _showcase_step == 5 and _showcase_timer > 2.10:
		# 6. Modal Đội Hình & Hình Khối Nhân Vật 3D
		_save_viewport_png("res://bf2_06_army_modal.png")
		_open_modal("")
		_switch_hud_context("BATTLE")
		if player_unit != null and ai_unit != null:
			player_unit.x = 885.0
			player_unit.prev_x = 885.0
			ai_unit.x = 965.0
			ai_unit.prev_x = 965.0
			sim.force_unit_animation(player_unit, "ATTACK_1")
			player_unit.anim_time = 0.21
			sim.force_unit_animation(ai_unit, "BLOCK_HIT")
			_on_combat_event("PARRY", Vector2(925.0, GROUND_Y - 54.0), 18, "PHẢN ĐÒN HOÀN HẢO! -18", Color(1.0, 0.92, 0.28))
		_showcase_step = 6
	elif _showcase_step == 6 and _showcase_timer > 2.45:
		# 7. Cảnh Giao Chiến Ngang 1v1
		_save_viewport_png("res://bf2_07_duel_1v1_clash.png")
		_switch_hud_context("LAB")
		use_batched_atlas_lod = true
		_spawn_mass_battle(300)
		_showcase_step = 7
	elif _showcase_step == 7 and _showcase_timer > 2.65:
		_fps_window.clear()
		_showcase_step = 8
	elif _showcase_step == 8 and _showcase_timer > 3.60:
		# 8. Phòng Thử Kỹ Thuật & 300 Quân Giao Chiến Đa Làn (Mỗi quân mang trang bị riêng + VFX/Damage/Tử vong)
		_save_viewport_png("res://bf2_08_lab_300_units.png")
		_open_modal("")
		_hud_base_root.visible = false
		_hud_battle_root.visible = false
		_hud_lab_root.visible = false
		_showcase_step = 85
	elif _showcase_step == 85 and _showcase_timer > 3.80:
		# 8b. Cảnh 300 Quân Tắt Toàn Bộ Overlay Kỹ Thuật (Đọc rõ 8 làn chiều sâu, cự ly đội hình & tuyến đầu giao chiến)
		_save_viewport_png("res://bf3_02_crowd_300_clean_view.png")
		_build_6anims_and_sockets_showcase_overlay()
		_showcase_step = 9
	elif _showcase_step == 9 and _showcase_timer > 4.10:
		# 9. Bảng Kiểm Chứng 6 Animation, 6 Khe Trang Bị & 12 Khớp Xương
		_save_viewport_png("res://bf2_09_6anims_and_sockets_strip.png")
		_build_closeup_character_showcase_overlay()
		_showcase_step = 10
	elif _showcase_step == 10 and _showcase_timer > 4.45:
		# 10. Ảnh Cận Cảnh Nhân Vật 3D In-Engine (Điểm 1: Khối, chất liệu, biểu cảm & khớp nền)
		_save_viewport_png("res://bf3_01_character_closeup_in_engine.png")
		_build_full_item_atlas_audit_overlay()
		_showcase_step = 11
	elif _showcase_step == 11 and _showcase_timer > 4.80:
		# 11. Bảng Kiểm Tra Toàn Bộ Vật Phẩm & Vùng Cắt Atlas (Điểm 2)
		_save_viewport_png("res://bf3_03_item_atlas_verification.png")
		sim.clear_all_units()
		get_tree().quit(0)
	elif _showcase_step == 100 and _showcase_timer > 1.35:
		cam_pos.x = 760.0
		_save_viewport_png("res://bf3_04_stick_war_base_defense.png")
		sim.clear_all_units()
		get_tree().quit(0)

func _step_video_recording(delta: float) -> void:
	_video_timer += delta
	if _video_mode == "1v1":
		# 15-second choreographed 1v1 & close-up animation showcase (with Clean No-Overlay segment 4.2s..12.6s):
		# 0.0..4.2s (HUD ON): RUN approach, ATTACK_1 clash, BLOCK_HIT parry, Live 6-Socket Upgrade
		# 4.2..12.6s (CLEAN VIEW - Technical/HUD Overlays Hidden): Clear movement, ATTACK_1/2, BLOCK_HIT, hit reaction, and full DEATH collapse (8.6s..12.8s)
		# 12.6..15.0s (HUD ON): Respawn & round 2 clash
		var clean_view_1v1: bool = (_video_timer >= 4.2 and _video_timer < 12.6)
		if _hud_battle_root != null:
			_hud_battle_root.visible = not clean_view_1v1

		# Keep 1v1 fighters cleanly separated side-by-side so their bodies/weapons never overlap
		if player_unit != null and ai_unit != null and ai_unit.anim_state != "DEATH":
			if ai_unit.x - player_unit.x < 88.0:
				var mid: float = (player_unit.x + ai_unit.x) * 0.5
				player_unit.x = mid - 44.0
				ai_unit.x = mid + 44.0

		if _video_timer >= 2.8 and _video_timer < 2.8 + delta * 1.5:
			_socket_indices[ContentDB.SOCKET_MAIN_WEAPON] = 1
			_socket_indices[ContentDB.SOCKET_OFFHAND] = 2
			_socket_indices[ContentDB.SOCKET_HELMET] = 3
			_socket_indices[ContentDB.SOCKET_CHEST_ARMOR] = 2
			_socket_indices[ContentDB.SOCKET_PAULDRON] = 2
			_socket_indices[ContentDB.SOCKET_BACK_CAPE] = 2
			if player_unit != null:
				player_unit.loadout = _build_loadout_from_indices()
				sim.recalculate_unit_stats(player_unit, true)
				_on_combat_event("PARRY", Vector2(player_unit.x, GROUND_Y - 70.0), 0, "NÂNG CẤP ĐỦ 6 TRANG BỊ!", Color(1.0, 0.90, 0.25))
		elif _video_timer >= 5.2 and _video_timer < 5.2 + delta * 1.5 and player_unit != null:
			player_unit.is_blocking = true
			player_unit.block_start_time = float(sim.tick_count) * BattleSimulation.FIXED_DT
			player_unit.anim_state = "BLOCK_HIT"
			player_unit.anim_time = 0.0
			player_unit.anim_duration = 0.65
		elif _video_timer >= 8.5 and _video_timer < 8.5 + delta * 1.5 and ai_unit != null and ai_unit.anim_state != "DEATH":
			if player_unit != null:
				sim.force_unit_animation(player_unit, "ATTACK_2")
			ai_unit.hp = 0.0
			sim.return_if_dead(ai_unit, 1.0, GROUND_Y)
		# Hold the Orc's DEATH pose until 12.8s so the death collapse & dropped weapon are 100% clear
		if _video_timer >= 8.6 and _video_timer < 12.8 and ai_unit != null and ai_unit.anim_state == "DEATH":
			ai_unit.anim_time = minf(ai_unit.anim_time, 1.15)
		elif _video_timer >= 13.0 and _video_timer < 13.0 + delta * 1.5:
			_setup_1v1_duel()
			if player_unit != null:
				player_unit.ai_enabled = true
				player_unit.is_player_controlled = false
		if _video_timer >= 15.0:
			sim.clear_all_units()
			get_tree().quit(0)
	elif _video_mode == "300":
		# 15-second 300-unit mass battle recording:
		# 0.0..4.5s (LAB OVERLAY ON): Shows 300 simulated / 300 visible telemetry & 8-lane formation
		# 4.5..12.5s (CLEAN BATTLEFIELD VIEW - All Overlays Hidden): Clear 300-unit combat, frontline DEATHs, and rank-2 soldiers stepping forward to replace the fallen frontline!
		# 12.5..15.0s (LAB OVERLAY ON): Final telemetry check
		var clean_view_300: bool = (_video_timer >= 4.5 and _video_timer < 12.5)
		if _hud_lab_root != null:
			_hud_lab_root.visible = not clean_view_300
		if _hud_battle_root != null:
			_hud_battle_root.visible = not clean_view_300
		cam_pos.x = 1190.0

		# At t=5.4s, 7.8s, and 10.2s during the clean window, trigger decisive frontline kills across alternating lanes
		# so the viewer clearly sees frontline soldiers fall (DEATH) and Rank-2 allies immediately advance (RUN -> ATTACK_1) to replace them!
		for wave_idx in range(3):
			var t_wave: float = 5.4 + float(wave_idx) * 2.4
			if _video_timer >= t_wave and _video_timer < t_wave + delta * 1.4:
				for u in sim.active_units:
					if u.active and u.lane_rank == 0 and u.anim_state != "DEATH" and ((u.sub_lane + wave_idx) % 2 == 0):
						var victim_team: int = 2 if (u.sub_lane % 4 < 2) else 1
						if u.team == victim_team:
							u.hp = 0.0
							sim.return_if_dead(u, -u.facing, GROUND_Y + u.lane_y_offset)

		if _video_timer >= 15.0:
			sim.clear_all_units()
			get_tree().quit(0)

func _build_closeup_character_showcase_overlay() -> void:
	sim.clear_all_units()
	for i in range(MAX_PARTICLES):
		_particles[i]["active"] = false
	for i in range(MAX_FLOATING_TEXTS):
		_floating_texts[i]["active"] = false
	for i in range(MAX_SHOCK_RINGS):
		_shock_rings[i]["active"] = false
	for child in _ui_layer.get_children():
		if child is Control:
			(child as Control).visible = false

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(overlay)

	var top_banner := PanelContainer.new()
	top_banner.position = Vector2(140, 14)
	top_banner.size = Vector2(1000, 52)
	top_banner.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.24, 0.16, 0.11, 0.92), BastionUI.COL_BORDER_DARK, Color.BLACK, 12, 3, 4, 14, 8))
	overlay.add_child(top_banner)

	var lbl := Label.new()
	lbl.text = "CẬN CẢNH NHÂN VẬT 3D TRONG ENGINE (2.4x Zoom trên nền Chiến Trường · Khối, Chất Liệu & Biểu Cảm)"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl, 18, BastionUI.COL_GOLD_TEXT, 5)
	top_banner.add_child(lbl)

	var stage := Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.draw.connect(func() -> void:
		var wpns: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_MAIN_WEAPON)
		var offs: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_OFFHAND)
		var hlms: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_HELMET)
		var arms: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_CHEST_ARMOR)
		var plds: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_PAULDRON)
		var cpes: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_BACK_CAPE)

		# 1. Left: Vanguard Knight (Starter Blue-Silver-Gold)
		var u1 := BattleSimulation.SimUnit.new()
		u1.team = 1
		u1.archetype_id = "vanguard_hero"
		u1.unit_scale = 2.25
		u1.facing = 1.0
		u1.anim_state = "IDLE"
		u1.anim_time = 0.25
		u1.loadout = ContentDB.UNITS["vanguard_hero"]["default_loadout"].duplicate()
		rig.draw_character(stage, u1, Vector2(220, 545), false, false)

		# 2. Center-Left: Grand Marshal Knight (Sunfire Greatsword + Lion Shield + Crimson Cape + Battle Cry)
		var u2 := BattleSimulation.SimUnit.new()
		u2.team = 1
		u2.archetype_id = "vanguard_hero"
		u2.unit_scale = 2.35
		u2.facing = 1.0
		u2.anim_state = "ATTACK_1"
		u2.anim_duration = 0.45
		u2.anim_time = 0.22
		u2.loadout = {
			ContentDB.SOCKET_MAIN_WEAPON: wpns[1 % wpns.size()],
			ContentDB.SOCKET_OFFHAND: offs[3 % offs.size()],
			ContentDB.SOCKET_HELMET: hlms[2 % hlms.size()],
			ContentDB.SOCKET_CHEST_ARMOR: arms[2 % arms.size()],
			ContentDB.SOCKET_PAULDRON: plds[2 % plds.size()],
			ContentDB.SOCKET_BACK_CAPE: cpes[2 % cpes.size()]
		}
		rig.draw_character(stage, u2, Vector2(540, 545), false, false)

		# 3. Center-Right: Orc Warrior (Blocking / Gritted Wince + Spiked Purple Armor + Tusks)
		var u3 := BattleSimulation.SimUnit.new()
		u3.team = 2
		u3.archetype_id = "abyssal_challenger"
		u3.unit_scale = 2.35
		u3.facing = -1.0
		u3.anim_state = "BLOCK_HIT"
		u3.is_blocking = true
		u3.anim_duration = 0.50
		u3.anim_time = 0.20
		u3.loadout = ContentDB.MONSTERS["abyssal_challenger"]["default_loadout"].duplicate()
		rig.draw_character(stage, u3, Vector2(820, 545), false, false)

		# 4. Right: Frostbite Halo Knight / Orc Heavy Reaver
		var u4 := BattleSimulation.SimUnit.new()
		u4.team = 2
		u4.archetype_id = "abyssal_challenger"
		u4.unit_scale = 2.25
		u4.facing = -1.0
		u4.anim_state = "ATTACK_2"
		u4.anim_duration = 0.48
		u4.anim_time = 0.25
		u4.loadout = {
			ContentDB.SOCKET_MAIN_WEAPON: wpns[3 % wpns.size()],
			ContentDB.SOCKET_OFFHAND: offs[2 % offs.size()],
			ContentDB.SOCKET_HELMET: hlms[3 % hlms.size()],
			ContentDB.SOCKET_CHEST_ARMOR: arms[1 % arms.size()],
			ContentDB.SOCKET_PAULDRON: plds[2 % plds.size()],
			ContentDB.SOCKET_BACK_CAPE: cpes[3 % cpes.size()]
		}
		rig.draw_character(stage, u4, Vector2(1090, 545), false, false)
	)
	overlay.add_child(stage)

func _build_full_item_atlas_audit_overlay() -> void:
	for child in _ui_layer.get_children():
		if child is Control:
			(child as Control).visible = false

	var sheet := PanelContainer.new()
	sheet.position = Vector2(16, 12)
	sheet.size = Vector2(1248, 696)
	sheet.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.30, 0.20, 0.14, 0.97), BastionUI.COL_BORDER_DARK, Color.BLACK, 14, 4, 6, 16, 12))
	_ui_layer.add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	sheet.add_child(vbox)

	var lbl_t := Label.new()
	lbl_t.text = "ĐIỂM 2: BẢNG KIỂM CHỨNG TOÀN BỘ VẬT PHẨM 3D & VÙNG CẮT ATLAS (0 LỖI LỆCH CROP)"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_t, 19, BastionUI.COL_GOLD_TEXT, 5)
	vbox.add_child(lbl_t)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var audit_items: Array[Array] = [
		["wpn_aethel_blade", "Kiếm Tinh Thạch", "Khe 1 · Trường Kiếm"],
		["wpn_crimson_greatsword", "Đại Đao Hỏa Long", "Khe 1 · Đại Đao"],
		["wpn_obsidian_reaver", "Trường Kiếm Băng Tinh", "Khe 1 · Kiếm Băng"],
		["wpn_thunder_halberd", "Chiến Kích Lôi Đình", "Khe 1 · Kích Cán Dài (Riêng)"],
		["off_royal_tower", "Khiên Sư Tử Hoàng Gia", "Khe 2 · Khiên Tháp"],

		["off_aegis_buckler", "Khiên Tinh Thạch", "Khe 2 · Khiên Hiệp Sĩ"],
		["off_parry_dagger", "Song Đao Phản Đòn", "Khe 2 · 2 Đoản Đao Chéo"],
		["hlm_vanguard_visor", "Mũ Hiệp Sĩ Tiên Phong", "Khe 3 · Mũ Lông Lam"],
		["hlm_spartan_crest", "Mũ Chiến Thần Bờm Đỏ", "Khe 3 · Mũ Bờm Đỏ"],
		["hlm_abyss_horns", "Vương Miện Sừng Ma", "Khe 3 · Mũ 2 Sừng Cong"],

		["arm_aethel_cuirass", "Giáp Tinh Thạch", "Khe 4 · Giáp Bạc Lam"],
		["arm_royal_plate", "Chiến Giáp Hoàng Kim", "Khe 4 · Giáp Vàng Đỏ"],
		["arm_light_tunic", "Giáp Đai Nhẹ", "Khe 4 · Giáp Da Chiến Binh"],
		["pld_steel_spaulders", "Giáp Vai Hiệp Sĩ", "Khe 5 · Giáp Vai Thép"],
		["pld_dragon_wings", "Giáp Vai Cánh Rồng", "Khe 5 · Giáp Vai Vàng"],

		["cpe_wind_scarf", "Khăn Choàng Gió Lam", "Khe 6 · Áo Choàng Lam"],
		["cpe_royal_mantle", "Áo Choàng Đại Tướng", "Khe 6 · Áo Choàng Đỏ"],
		["cpe_aether_halo", "Vòng Thánh Quang", "Khe 6 · Hào Quang Vàng"],
		["head_orc", "Đầu & Mũ Sừng Orc", "Bộ Phận 3D Phe Orc"],
		["torso_orc", "Giáp Ngực Tím Orc", "Bộ Phận 3D Phe Orc"]
	]

	for entry in audit_items:
		var item_key: String = str(entry[0])
		var item_title: String = str(entry[1])
		var item_sub: String = str(entry[2])

		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.56, 0.42, 0.30), Color(0.24, 0.16, 0.11), Color.BLACK, 9, 2, 3, 6, 4))
		grid.add_child(cell)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)

		var lh := Label.new()
		lh.text = item_title
		lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		BastionUI.style_display_label(lh, 13, BastionUI.COL_CREAM_TEXT, 4)
		cv.add_child(lh)

		var icon_box := Control.new()
		icon_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_box.draw.connect(func() -> void:
			var r_rect: Rect2 = StickmanRig2D.get_item_atlas_rect(item_key)
			icon_box.draw_rect(Rect2(Vector2(icon_box.size.x * 0.5 - 48, 2), Vector2(96, icon_box.size.y - 4)), Color(0.22, 0.15, 0.10, 0.55), true)
			StickmanRig2D.draw_equipment_preview(icon_box, item_key, Rect2(Vector2(icon_box.size.x * 0.5 - 44, 4), Vector2(88, icon_box.size.y - 8)))
			var f: Font = ThemeDB.fallback_font
			icon_box.draw_string(f, Vector2(6, icon_box.size.y - 4), "[%d,%d %dx%d]" % [int(r_rect.position.x), int(r_rect.position.y), int(r_rect.size.x), int(r_rect.size.y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.82, 0.72))
		)
		cv.add_child(icon_box)

		var ls := Label.new()
		ls.text = item_sub + " (" + item_key + ")"
		ls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		BastionUI.style_display_label(ls, 10, BastionUI.COL_GOLD_TEXT, 3)
		cv.add_child(ls)

func _build_6anims_and_sockets_showcase_overlay() -> void:
	var sheet := PanelContainer.new()
	sheet.position = Vector2(16, 14)
	sheet.size = Vector2(1248, 692)
	sheet.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.32, 0.22, 0.15, 0.96), BastionUI.COL_BORDER_DARK, Color.BLACK, 14, 4, 6, 18, 14))
	_ui_layer.add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	sheet.add_child(vbox)

	var lbl_title := Label.new()
	lbl_title.text = "CHẶNG A: BẢNG KIỂM CHỨNG 6 ANIMATION CỐT LÕI · 6 KHE TRANG BỊ MODULAR · KHUNG XƯƠNG 12 KHỚP"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	BastionUI.style_display_label(lbl_title, 20, BastionUI.COL_GOLD_TEXT, 5)
	vbox.add_child(lbl_title)

	# Row 1: 6 Core Animations
	var row_anims := HBoxContainer.new()
	row_anims.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row_anims.add_theme_constant_override("separation", 10)
	vbox.add_child(row_anims)

	var anim_times: Array[float] = [0.25, 0.18, 0.21, 0.27, 0.20, 0.62]
	var anim_titles: Array[String] = [
		"1. IDLE (Thở/Giữ thế)",
		"2. RUN (Chạy nghiêng thân)",
		"3. ATTACK_1 (Chém Bổ)",
		"4. ATTACK_2 (Đâm Hất)",
		"5. BLOCK_HIT (Đỡ Khiên)",
		"6. DEATH (Ngã & Rơi Kiếm)"
	]
	for idx in range(6):
		var a_state: String = ANIM_ORDER[idx]
		var a_time: float = anim_times[idx]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.68, 0.54, 0.41), Color(0.28, 0.19, 0.14), Color.BLACK, 10, 2, 3, 6, 6))
		row_anims.add_child(card)

		var c_vbox := VBoxContainer.new()
		card.add_child(c_vbox)
		var l_head := Label.new()
		l_head.text = anim_titles[idx]
		l_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		BastionUI.style_display_label(l_head, 13, BastionUI.COL_CREAM_TEXT, 4)
		c_vbox.add_child(l_head)

		var canvas_ctrl := Control.new()
		canvas_ctrl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		canvas_ctrl.draw.connect(func() -> void:
			var u := BattleSimulation.SimUnit.new()
			u.team = 1
			u.archetype_id = "vanguard_hero"
			u.unit_scale = 1.28
			u.facing = 1.0
			u.anim_state = a_state
			u.anim_duration = 0.45 if (a_state == "ATTACK_1" or a_state == "ATTACK_2") else (1.40 if a_state == "DEATH" else 0.50)
			u.anim_time = a_time
			u.is_blocking = (a_state == "BLOCK_HIT")
			u.dropped_weapon_y = 26.0 if a_state == "DEATH" else 0.0
			u.dropped_weapon_rot = 1.45 if a_state == "DEATH" else 0.0
			u.loadout = ContentDB.UNITS["vanguard_hero"]["default_loadout"].duplicate()
			rig.draw_character(canvas_ctrl, u, Vector2(canvas_ctrl.size.x * 0.48, canvas_ctrl.size.y * 0.78), false, false)
		)
		c_vbox.add_child(canvas_ctrl)

	# Row 2: 5 Modular Socket Variations & 12-Bone Debug Proof
	var row_sockets := HBoxContainer.new()
	row_sockets.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row_sockets.add_theme_constant_override("separation", 10)
	vbox.add_child(row_sockets)

	var wpns: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_MAIN_WEAPON)
	var offs: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_OFFHAND)
	var hlms: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_HELMET)
	var arms: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_CHEST_ARMOR)
	var plds: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_PAULDRON)
	var cpes: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_BACK_CAPE)

	var socket_cards: Array[Dictionary] = [
		{
			"title": "Bộ A: Hiệp Sĩ Khởi Đầu",
			"sub": "Kiếm Aethel + Khiên Gỗ + Áo Choàng Lam",
			"team": 1, "bones": false,
			"loadout": ContentDB.UNITS["vanguard_hero"]["default_loadout"].duplicate()
		},
		{
			"title": "Bộ B: Đại Tướng Hỏa Long",
			"sub": "Đại Đao Hỏa Long + Khiên Sư Tử + Choàng Đỏ",
			"team": 1, "bones": false,
			"loadout": {
				ContentDB.SOCKET_MAIN_WEAPON: wpns[1 % wpns.size()],
				ContentDB.SOCKET_OFFHAND: offs[3 % offs.size()],
				ContentDB.SOCKET_HELMET: hlms[2 % hlms.size()],
				ContentDB.SOCKET_CHEST_ARMOR: arms[2 % arms.size()],
				ContentDB.SOCKET_PAULDRON: plds[2 % plds.size()],
				ContentDB.SOCKET_BACK_CAPE: cpes[2 % cpes.size()]
			}
		},
		{
			"title": "Bộ C: Chiến Thần Băng Tinh",
			"sub": "Trường Kiếm Băng + Song Đao + Hào Quang",
			"team": 1, "bones": false,
			"loadout": {
				ContentDB.SOCKET_MAIN_WEAPON: wpns[2 % wpns.size()],
				ContentDB.SOCKET_OFFHAND: offs[2 % offs.size()],
				ContentDB.SOCKET_HELMET: hlms[3 % hlms.size()],
				ContentDB.SOCKET_CHEST_ARMOR: arms[1 % arms.size()],
				ContentDB.SOCKET_PAULDRON: plds[1 % plds.size()],
				ContentDB.SOCKET_BACK_CAPE: cpes[3 % cpes.size()]
			}
		},
		{
			"title": "Kiểm Chứng 12 Khớp Xương (FK)",
			"sub": "Hiển thị trực tiếp 12 Bone + 6 Socket",
			"team": 1, "bones": true,
			"loadout": ContentDB.UNITS["vanguard_hero"]["default_loadout"].duplicate()
		},
		{
			"title": "Phe Địch: Chiến Binh Orc",
			"sub": "Da Xanh + Nanh Trắng + Giáp Tím Sắt",
			"team": 2, "bones": false,
			"loadout": ContentDB.MONSTERS["abyssal_challenger"]["default_loadout"].duplicate()
		}
	]

	for sc in socket_cards:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", BastionUI.make_stylebox(Color(0.58, 0.44, 0.32), Color(0.26, 0.18, 0.13), Color.BLACK, 10, 2, 3, 6, 6))
		row_sockets.add_child(card)

		var c_vbox := VBoxContainer.new()
		card.add_child(c_vbox)
		var l_head := Label.new()
		l_head.text = str(sc["title"])
		l_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		BastionUI.style_display_label(l_head, 14, BastionUI.COL_GOLD_TEXT, 4)
		c_vbox.add_child(l_head)

		var canvas_ctrl := Control.new()
		canvas_ctrl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var ld: Dictionary = sc["loadout"]
		var tm: int = int(sc["team"])
		var b_flag: bool = bool(sc["bones"])
		canvas_ctrl.draw.connect(func() -> void:
			var u := BattleSimulation.SimUnit.new()
			u.team = tm
			u.archetype_id = "abyssal_challenger" if tm == 2 else "vanguard_hero"
			u.unit_scale = 1.32
			u.facing = -1.0 if tm == 2 else 1.0
			u.anim_state = "IDLE"
			u.anim_time = 0.20
			u.loadout = ld
			rig.draw_character(canvas_ctrl, u, Vector2(canvas_ctrl.size.x * 0.50, canvas_ctrl.size.y * 0.80), b_flag, false)
		)
		c_vbox.add_child(canvas_ctrl)

		var l_sub := Label.new()
		l_sub.text = str(sc["sub"])
		l_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		BastionUI.style_display_label(l_sub, 11, BastionUI.COL_CREAM_TEXT, 3)
		c_vbox.add_child(l_sub)

func _save_viewport_png(path: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("Saved screenshot: ", path)
