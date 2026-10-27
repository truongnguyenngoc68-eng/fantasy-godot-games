extends Node2D

# ============================================================================
# MILESTONE 1 PLAYABLE ARENA, 6-SOCKET CUSTOMIZER & 30/100/200/300 BENCHMARK
# Engine: Godot 4.7.2 Stable (gl_compatibility)
# Scope: Milestone 1 ONLY (12-Bone Stickman, 6 Sockets, 6 Core Animations,
#        1v1 Player vs AI Duel, Combat VFX/SFX, and Real Animated Benchmark)
# ============================================================================

const GROUND_Y: float = 525.0
const ARENA_WIDTH: float = 2400.0

var sim: BattleSimulation = BattleSimulation.new()
var rig: StickmanRig2D = StickmanRig2D.new()

var player_unit: BattleSimulation.SimUnit = null
var ai_unit: BattleSimulation.SimUnit = null

# Fixed-Timestep Accumulator
var _accumulator: float = 0.0
var time_scale: float = 1.0
var show_debug_bones: bool = false
var lod_simplified_in_mass: bool = false

# Arena Modes: 0 = 1v1 Duel, 1 = Equipment & 12-Bone Inspector, 2 = Mass Benchmark
var arena_mode: int = 0

# Camera2D state (Deadzone + Look-Ahead + Bounds + Screen Shake)
var cam_pos: Vector2 = Vector2(960.0, 360.0)
var cam_zoom: float = 1.0
var shake_trauma: float = 0.0
var _time_elapsed: float = 0.0

# 6-Socket Equipment Indices for Live Customizer
var _socket_indices: Dictionary = {
	ContentDB.SOCKET_MAIN_WEAPON: 0,
	ContentDB.SOCKET_OFFHAND: 0,
	ContentDB.SOCKET_HELMET: 0,
	ContentDB.SOCKET_CHEST_ARMOR: 0,
	ContentDB.SOCKET_PAULDRON: 0,
	ContentDB.SOCKET_BACK_CAPE: 0,
}
var _socket_buttons: Dictionary = {}

# Pooled Combat VFX (FixedPool - Zero runtime allocation during combat)
const MAX_PARTICLES: int = 180
const MAX_FLOATING_TEXTS: int = 64
const MAX_SHOCK_RINGS: int = 24

var _particles: Array[Dictionary] = []
var _floating_texts: Array[Dictionary] = []
var _shock_rings: Array[Dictionary] = []

# Telemetry & Benchmark State
var _last_sim_ms: float = 0.0
var _last_render_ms: float = 0.0
var _fps_window: Array[float] = []

const BENCH_TIERS: Array[int] = [30, 100, 200, 300]
var _bench_running: bool = false
var _bench_cli_mode: bool = false
var _bench_tier_idx: int = 0
var _bench_frame_in_tier: int = 0
var _bench_warmup_frames: int = 25
var _bench_sample_frames: int = 120
var _bench_frame_ms_samples: Array[float] = []
var _bench_sim_ms_samples: Array[float] = []
var _bench_render_ms_samples: Array[float] = []
var _bench_draw_calls_samples: Array[int] = []
var _bench_results: Dictionary = {}

# Automated Screenshot Showcase State
var _showcase_mode: bool = false
var _showcase_step: int = 0
var _showcase_timer: float = 0.0

# UI References
var _ui_layer: CanvasLayer = null
var _lbl_player_hp: Label = null
var _bar_player_hp: ColorRect = null
var _lbl_ai_hp: Label = null
var _bar_ai_hp: ColorRect = null
var _lbl_banner: Label = null
var _lbl_perf: Label = null
var _lbl_stats_summary: Label = null
var _panel_customizer: PanelContainer = null
var _lbl_bench_report: Label = null
var _panel_bench_report: PanelContainer = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.11))
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)

	_init_vfx_pools()
	sim.combat_event.connect(_on_combat_event)
	sim.sfx_requested.connect(func(sfx_id: String) -> void: SoundEngine.play_sfx(sfx_id))
	_build_ui()
	_setup_1v1_duel()

	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if ("--run-benchmark" in args) or ("--run-benchmark" in user_args):
		_bench_cli_mode = true
		_start_benchmark_suite()
	elif ("--capture-showcase" in args) or ("--capture-showcase" in user_args):
		_showcase_mode = true
		_showcase_step = 0
		_showcase_timer = 0.0

func _exit_tree() -> void:
	if sim != null:
		sim.clear_all_units()
	player_unit = null
	ai_unit = null

func _init_vfx_pools() -> void:
	for i in range(MAX_PARTICLES):
		_particles.append({
			"active": false,
			"pos": Vector2.ZERO,
			"vel": Vector2.ZERO,
			"col": Color.WHITE,
			"size": 4.0,
			"life": 0.0,
			"max_life": 0.4
		})
	for i in range(MAX_FLOATING_TEXTS):
		_floating_texts.append({
			"active": false,
			"pos": Vector2.ZERO,
			"vel": Vector2.ZERO,
			"text": "",
			"col": Color.WHITE,
			"life": 0.0,
			"max_life": 0.75
		})
	for i in range(MAX_SHOCK_RINGS):
		_shock_rings.append({
			"active": false,
			"pos": Vector2.ZERO,
			"radius": 8.0,
			"max_radius": 72.0,
			"col": Color.WHITE,
			"life": 0.0,
			"max_life": 0.28
		})

# ============================================================================
# SCENE MODES: 1v1 DUEL, 6-SOCKET INSPECTOR, 30/100/200/300 UNIT SPAWNER
# ============================================================================

func _setup_1v1_duel() -> void:
	arena_mode = 0
	sim.clear_all_units()
	var custom_loadout: Dictionary = _build_loadout_from_indices()
	player_unit = sim.spawn_unit(1, "vanguard_hero", 760.0, 1, true, custom_loadout)
	ai_unit = sim.spawn_unit(2, "abyssal_challenger", 1120.0, 1, false, {})
	player_unit.facing = 1.0
	ai_unit.facing = -1.0
	cam_pos = Vector2(940.0, 360.0)
	_update_stats_summary_label()
	if _lbl_banner != null:
		_lbl_banner.text = "⚔️ ĐẤU 1v1: CHIẾN BINH AETHEL (Bạn) vs HẮC KỴ SĨ VỰC THẲM (AI)"

func _setup_inspector_mode() -> void:
	arena_mode = 1
	sim.clear_all_units()
	var custom_loadout: Dictionary = _build_loadout_from_indices()
	player_unit = sim.spawn_unit(1, "vanguard_hero", 850.0, 1, true, custom_loadout)
	ai_unit = sim.spawn_unit(2, "abyssal_challenger", 1070.0, 1, false, {})
	ai_unit.ai_enabled = false
	player_unit.facing = 1.0
	ai_unit.facing = -1.0
	show_debug_bones = true
	_update_stats_summary_label()
	if _lbl_banner != null:
		_lbl_banner.text = "🎨 PHÒNG THỬ 6 KHE TRANG BỊ, 12 KHỚP XƯƠNG & 6 ANIMATION CỐT LÕI"

func _spawn_mass_battle(unit_count: int) -> void:
	arena_mode = 2
	sim.clear_all_units()
	player_unit = null
	ai_unit = null

	var half: int = unit_count / 2
	var weapons: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_MAIN_WEAPON)
	var offhands: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_OFFHAND)
	var helmets: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_HELMET)
	var armors: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_CHEST_ARMOR)
	var pauldrons: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_PAULDRON)
	var capes: Array[String] = ContentDB.get_items_for_socket(ContentDB.SOCKET_BACK_CAPE)

	for i in range(half):
		var sub_lane: int = i % 3
		var x1: float = 240.0 + float(i) * (640.0 / maxf(1.0, float(half)))
		var loadout1: Dictionary = {
			ContentDB.SOCKET_MAIN_WEAPON: weapons[i % weapons.size()],
			ContentDB.SOCKET_OFFHAND: offhands[i % offhands.size()],
			ContentDB.SOCKET_HELMET: helmets[(i + 1) % helmets.size()],
			ContentDB.SOCKET_CHEST_ARMOR: armors[(i + 1) % armors.size()],
			ContentDB.SOCKET_PAULDRON: pauldrons[i % pauldrons.size()],
			ContentDB.SOCKET_BACK_CAPE: capes[(i + 2) % capes.size()],
		}
		var u1: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", x1, sub_lane, false, loadout1)
		if u1 != null:
			u1.anim_time = float(i % 12) * 0.05

		var x2: float = 2160.0 - float(i) * (640.0 / maxf(1.0, float(half)))
		var loadout2: Dictionary = {
			ContentDB.SOCKET_MAIN_WEAPON: weapons[(i + 2) % weapons.size()],
			ContentDB.SOCKET_OFFHAND: offhands[(i + 1) % offhands.size()],
			ContentDB.SOCKET_HELMET: helmets[(i + 3) % helmets.size()],
			ContentDB.SOCKET_CHEST_ARMOR: armors[(i + 2) % armors.size()],
			ContentDB.SOCKET_PAULDRON: pauldrons[(i + 2) % pauldrons.size()],
			ContentDB.SOCKET_BACK_CAPE: capes[(i + 1) % capes.size()],
		}
		var u2: BattleSimulation.SimUnit = sim.spawn_unit(2, "abyssal_challenger", x2, sub_lane, false, loadout2)
		if u2 != null:
			u2.anim_time = float((i + 5) % 12) * 0.05

	if _lbl_banner != null:
		_lbl_banner.text = "📊 BENCHMARK THỰC TẾ: %d ĐƠN VỊ STICKMAN 12 KHỚP ĐANG GIAO CHIẾN (%dv%d)" % [unit_count, half, half]

func _build_loadout_from_indices() -> Dictionary:
	var result: Dictionary = {}
	for socket_key in _socket_indices.keys():
		var item_ids: Array[String] = ContentDB.get_items_for_socket(socket_key)
		var idx: int = int(_socket_indices[socket_key]) % item_ids.size()
		result[socket_key] = item_ids[idx]
	return result

func _apply_loadout_to_player() -> void:
	var custom_loadout: Dictionary = _build_loadout_from_indices()
	if player_unit != null and player_unit.active:
		var hp_ratio: float = player_unit.hp / maxf(1.0, player_unit.max_hp)
		player_unit.loadout = custom_loadout
		sim.recalculate_unit_stats(player_unit, false)
		player_unit.hp = clampf(player_unit.max_hp * hp_ratio, 1.0, player_unit.max_hp)
	_update_stats_summary_label()

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

	if _bench_running:
		_step_benchmark(delta)
	elif _showcase_mode:
		_step_showcase(delta)

	queue_redraw()

func _poll_player_input() -> void:
	var dir: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir += 1.0
	sim.player_move_dir = dir
	sim.player_block_held = Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if arena_mode == 2 and dir != 0.0:
		cam_pos.x = clampf(cam_pos.x + dir * 520.0 * get_process_delta_time(), 640.0, ARENA_WIDTH - 640.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_J or k == KEY_SPACE:
			sim.player_queued_attack = 1
		elif k == KEY_L or k == KEY_E:
			sim.player_queued_attack = 2
		elif k == KEY_R:
			_setup_1v1_duel()
		elif k == KEY_B:
			show_debug_bones = not show_debug_bones
		elif k == KEY_F3:
			_start_benchmark_suite()
		elif k >= KEY_1 and k <= KEY_6:
			var states: Array[String] = ["IDLE", "RUN", "ATTACK_1", "ATTACK_2", "BLOCK_HIT", "DEATH"]
			_trigger_player_anim_preview(states[k - KEY_1])
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and event.position.y > 90.0 and event.position.y < 610.0 and event.position.x > 310.0:
			sim.player_queued_attack = 1

func _trigger_player_anim_preview(state_name: String) -> void:
	if player_unit == null or not player_unit.active:
		_setup_1v1_duel()
	if player_unit.anim_state == "DEATH" and state_name != "DEATH":
		player_unit.hp = player_unit.max_hp
	sim.force_unit_animation(player_unit, state_name)

func _update_camera(dt: float) -> void:
	var target_x: float = cam_pos.x
	if arena_mode == 0 and player_unit != null and ai_unit != null:
		var mid_x: float = (player_unit.x + ai_unit.x) * 0.5
		var look_ahead: float = player_unit.facing * 35.0
		target_x = clampf(mid_x + look_ahead, 640.0, ARENA_WIDTH - 640.0)
	elif arena_mode == 1:
		target_x = 960.0
	elif arena_mode == 2 and _bench_running:
		target_x = 1200.0 + sin(_time_elapsed * 0.65) * 220.0

	cam_pos.x = lerpf(cam_pos.x, target_x, clampf(dt * 6.5, 0.0, 1.0))
	cam_pos.y = 360.0

	if shake_trauma > 0.0:
		shake_trauma = maxf(0.0, shake_trauma - dt * 2.8)

# ============================================================================
# POOLED COMBAT VFX & FLOATING NUMBERS
# ============================================================================

func _on_combat_event(event_type: String, world_pos: Vector2, _value: int, text: String, color: Color) -> void:
	# Reduce particle density automatically when 100+ units are fighting so VFX never chokes frame time
	var mass_crowd: bool = sim.active_units.size() > 60
	if not mass_crowd or (sim.tick_count % 3 == 0):
		_spawn_floating_text(world_pos + Vector2(0.0, -18.0), text, color)

	var spark_count: int = 3 if mass_crowd else (14 if event_type == "PARRY" else 9)
	for i in range(spark_count):
		var angle: float = -PI * 0.85 + float(i) / float(max(1, spark_count - 1)) * (PI * 0.70)
		var speed: float = 140.0 + float((i * 53) % 190)
		_spawn_particle(world_pos, Vector2.from_angle(angle) * speed, color, 4.2 if event_type != "PARRY" else 5.5)

	if event_type == "PARRY" or event_type == "HIT":
		if not mass_crowd:
			_spawn_shock_ring(world_pos, 82.0 if event_type == "PARRY" else 48.0, color)
		if sim.active_units.size() <= 4:
			shake_trauma = minf(1.0, shake_trauma + (0.55 if event_type == "PARRY" else 0.28))

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
			ft["vel"] = Vector2(0.0, -68.0)
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
# CUSTOM PARALLAX ENVIRONMENT + 12-BONE RIG + VFX RENDERING
# ============================================================================

func _draw() -> void:
	var render_t0: int = Time.get_ticks_usec()

	var shake_offset := Vector2.ZERO
	if shake_trauma > 0.01:
		var mag: float = shake_trauma * shake_trauma * 11.0
		shake_offset = Vector2(sin(_time_elapsed * 67.0) * mag, cos(_time_elapsed * 53.0) * mag)

	var view_offset: Vector2 = Vector2(640.0, 360.0) - cam_pos + shake_offset

	_draw_parallax_environment(view_offset)

	# Interpolate between prev_x and x for silky rendering
	var alpha: float = clampf(_accumulator / BattleSimulation.FIXED_DT, 0.0, 1.0)
	var units: Array[BattleSimulation.SimUnit] = sim.active_units
	var n_units: int = units.size()

	# Draw back-to-front by sub_lane (0 = back, 1 = mid, 2 = front)
	for sub in range(3):
		for i in range(n_units):
			var u: BattleSimulation.SimUnit = units[i]
			if not u.active or u.sub_lane != sub:
				continue
			var interp_x: float = lerpf(u.prev_x, u.x, alpha)
			var screen_x: float = interp_x + view_offset.x
			# Frustum cull offscreen units only if outside viewport margin (during benchmark all 300 are inside arena)
			if screen_x < -120.0 or screen_x > 1400.0:
				continue
			var world_pos := Vector2(interp_x, GROUND_Y + u.lane_y_offset) + view_offset
			var use_crowd_lod: bool = lod_simplified_in_mass or (n_units >= 100)
			rig.draw_character(self, u, world_pos, show_debug_bones, use_crowd_lod)

			# Overhead mini HP bar when damaged in 1v1 or small fights
			if n_units <= 30 and u.hp < u.max_hp and u.hp > 0.0:
				var bar_pos: Vector2 = world_pos + Vector2(-26.0, -108.0 * u.unit_scale)
				draw_rect(Rect2(bar_pos, Vector2(52.0, 6.0)), Color(0.08, 0.09, 0.14, 0.85), true)
				var ratio: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
				var hp_col: Color = Color(0.22, 0.92, 0.52) if u.team == 1 else Color(1.0, 0.32, 0.36)
				draw_rect(Rect2(bar_pos + Vector2(1, 1), Vector2(50.0 * ratio, 4.0)), hp_col, true)

	_draw_combat_vfx(view_offset)

	var render_t1: int = Time.get_ticks_usec()
	_last_render_ms = float(render_t1 - render_t0) / 1000.0

func _draw_parallax_environment(view_offset: Vector2) -> void:
	# 1. Twilight Sky Gradient Bands
	draw_rect(Rect2(0, 0, 1280, 190), Color(0.05, 0.07, 0.15), true)
	draw_rect(Rect2(0, 190, 1280, 160), Color(0.09, 0.11, 0.22), true)
	draw_rect(Rect2(0, 350, 1280, 185), Color(0.14, 0.14, 0.26), true)

	# Glowing Aether Moon & Halo
	var moon_pos := Vector2(980.0 + view_offset.x * 0.08, 135.0)
	draw_circle(moon_pos, 68.0, Color(0.32, 0.65, 1.0, 0.12))
	draw_circle(moon_pos, 42.0, Color(0.55, 0.85, 1.0, 0.24))
	draw_circle(moon_pos, 26.0, Color(0.88, 0.96, 1.0, 0.92))

	# 2. Far Parallax Crystalline Mountains (0.20x parallax)
	var px_far: float = view_offset.x * 0.20
	for i in range(-1, 7):
		var base_x: float = float(i) * 320.0 + px_far
		var m_poly := PackedVector2Array([
			Vector2(base_x - 140.0, GROUND_Y),
			Vector2(base_x + 40.0, 210.0 + float((i * 37) % 55)),
			Vector2(base_x + 240.0, GROUND_Y)
		])
		draw_colored_polygon(m_poly, Color(0.08, 0.10, 0.19))

	# 3. Midground Ancient Aethel Bastion Pillars & Glowing Monoliths (0.50x parallax)
	var px_mid: float = view_offset.x * 0.50
	for i in range(-1, 9):
		var col_x: float = float(i) * 260.0 + px_mid
		draw_rect(Rect2(col_x, 285.0, 34.0, GROUND_Y - 285.0), Color(0.12, 0.15, 0.25), true)
		draw_rect(Rect2(col_x - 6.0, 275.0, 46.0, 12.0), Color(0.18, 0.22, 0.35), true)
		# Glowing rune strip on pillar
		var pulse: float = 0.55 + 0.35 * sin(_time_elapsed * 2.5 + float(i))
		draw_rect(Rect2(col_x + 13.0, 320.0, 8.0, 95.0), Color(0.22, 0.85, 1.0, pulse * 0.45), true)

	# 4. Foreground Battle Ground & Stone Road (1.0x world space)
	draw_rect(Rect2(0, GROUND_Y - 22.0, 1280, 240.0), Color(0.11, 0.13, 0.19), true)
	draw_rect(Rect2(0, GROUND_Y - 22.0, 1280, 6.0), Color(0.26, 0.34, 0.48), true)
	draw_rect(Rect2(0, GROUND_Y + 26.0, 1280, 190.0), Color(0.07, 0.08, 0.13), true)

	# Stone paving slabs & sub-lane guide lines
	for i in range(0, 36):
		var slab_x: float = float(i) * 72.0 + view_offset.x
		if slab_x >= -80.0 and slab_x <= 1360.0:
			draw_line(Vector2(slab_x, GROUND_Y - 18.0), Vector2(slab_x - 24.0, GROUND_Y + 26.0), Color(0.16, 0.20, 0.29), 2.0)

	# Left Dawn Bastion Banner & Right Abyssal Obelisk in World Space
	var left_keep_x: float = 210.0 + view_offset.x
	if left_keep_x > -200.0 and left_keep_x < 1400.0:
		draw_rect(Rect2(left_keep_x - 24.0, GROUND_Y - 165.0, 48.0, 165.0), Color(0.18, 0.26, 0.42), true)
		draw_circle(Vector2(left_keep_x, GROUND_Y - 130.0), 16.0, Color(0.25, 0.90, 1.0, 0.85))

	var right_keep_x: float = 2190.0 + view_offset.x
	if right_keep_x > -200.0 and right_keep_x < 1400.0:
		draw_rect(Rect2(right_keep_x - 24.0, GROUND_Y - 165.0, 48.0, 165.0), Color(0.28, 0.14, 0.22), true)
		draw_circle(Vector2(right_keep_x, GROUND_Y - 130.0), 16.0, Color(1.0, 0.25, 0.35, 0.85))

func _draw_combat_vfx(view_offset: Vector2) -> void:
	for i in range(MAX_SHOCK_RINGS):
		var sr: Dictionary = _shock_rings[i]
		if sr["active"]:
			var p: float = float(sr["life"]) / float(sr["max_life"])
			var r: float = lerpf(10.0, float(sr["max_radius"]), p)
			var c: Color = sr["col"]
			c.a = (1.0 - p) * 0.75
			draw_arc((sr["pos"] as Vector2) + view_offset, r, 0.0, TAU, 24, c, 3.2)

	for i in range(MAX_PARTICLES):
		var pt: Dictionary = _particles[i]
		if pt["active"]:
			var p: float = float(pt["life"]) / float(pt["max_life"])
			var c: Color = pt["col"]
			c.a = 1.0 - p
			draw_circle((pt["pos"] as Vector2) + view_offset, float(pt["size"]) * (1.0 - p * 0.5), c)

	var font: Font = ThemeDB.fallback_font
	for i in range(MAX_FLOATING_TEXTS):
		var ft: Dictionary = _floating_texts[i]
		if ft["active"]:
			var p: float = float(ft["life"]) / float(ft["max_life"])
			var c: Color = ft["col"]
			c.a = 1.0 - p * p
			var pos: Vector2 = (ft["pos"] as Vector2) + view_offset
			draw_string(font, pos + Vector2(1, 1), str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 17, Color(0, 0, 0, c.a))
			draw_string(font, pos, str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 17, c)

# ============================================================================
# AUTOMATED BENCHMARK HARNESS (30 / 100 / 200 / 300 ANIMATED 12-BONE UNITS)
# ============================================================================

func _start_benchmark_suite() -> void:
	_bench_running = true
	_bench_tier_idx = 0
	_bench_frame_in_tier = 0
	_bench_results.clear()
	show_debug_bones = false
	time_scale = 1.0
	_start_benchmark_tier(BENCH_TIERS[0])

func _start_benchmark_tier(unit_count: int) -> void:
	_bench_frame_in_tier = 0
	_bench_frame_ms_samples.clear()
	_bench_sim_ms_samples.clear()
	_bench_render_ms_samples.clear()
	_bench_draw_calls_samples.clear()
	_spawn_mass_battle(unit_count)

func _step_benchmark(delta: float) -> void:
	_bench_frame_in_tier += 1
	if _bench_frame_in_tier > _bench_warmup_frames:
		_bench_frame_ms_samples.append(delta * 1000.0)
		_bench_sim_ms_samples.append(_last_sim_ms)
		_bench_render_ms_samples.append(_last_render_ms)
		_bench_draw_calls_samples.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))

	if _bench_frame_in_tier >= (_bench_warmup_frames + _bench_sample_frames):
		var tier_units: int = BENCH_TIERS[_bench_tier_idx]
		_bench_results[str(tier_units)] = _compute_tier_metrics(tier_units)
		_bench_tier_idx += 1
		if _bench_tier_idx < BENCH_TIERS.size():
			_start_benchmark_tier(BENCH_TIERS[_bench_tier_idx])
		else:
			_finish_benchmark_suite()

func _compute_tier_metrics(unit_count: int) -> Dictionary:
	var n: int = max(1, _bench_frame_ms_samples.size())
	var sum_frame_ms: float = 0.0
	var sum_sim_ms: float = 0.0
	var sum_ren_ms: float = 0.0
	var sum_dc: int = 0
	var fps_list: Array[float] = []

	for i in range(n):
		var f_ms: float = maxf(0.1, _bench_frame_ms_samples[i])
		sum_frame_ms += f_ms
		sum_sim_ms += _bench_sim_ms_samples[i]
		sum_ren_ms += _bench_render_ms_samples[i]
		sum_dc += _bench_draw_calls_samples[i]
		fps_list.append(1000.0 / f_ms)

	fps_list.sort()
	var idx_1pct: int = clampi(int(floor(float(n) * 0.01)), 0, n - 1)
	var low_1pct_fps: float = fps_list[idx_1pct]
	var avg_frame_ms: float = sum_frame_ms / float(n)
	var avg_fps: float = 1000.0 / maxf(0.1, avg_frame_ms)
	var vp_rid: RID = get_viewport().get_viewport_rid()
	var gpu_ms: float = RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
	var rs_cpu_ms: float = RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
	var ram_mb: float = float(OS.get_static_memory_usage()) / 1048576.0

	return {
		"units": unit_count,
		"bones_solved_per_frame": unit_count * 12,
		"avg_fps": snappedf(avg_fps, 0.1),
		"low_1pct_fps": snappedf(low_1pct_fps, 0.1),
		"avg_frame_ms": snappedf(avg_frame_ms, 0.01),
		"cpu_sim_ms": snappedf(sum_sim_ms / float(n), 0.01),
		"cpu_rig_render_ms": snappedf(sum_ren_ms / float(n), 0.01),
		"rs_cpu_ms": snappedf(rs_cpu_ms, 0.01),
		"gpu_ms": snappedf(gpu_ms, 0.01),
		"draw_calls_2d": int(round(float(sum_dc) / float(n))),
		"ram_mb": snappedf(ram_mb, 0.1)
	}

func _finish_benchmark_suite() -> void:
	_bench_running = false
	var file := FileAccess.open("res://milestone1_benchmark.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_bench_results, "\t"))
		file.close()

	var summary_lines: PackedStringArray = PackedStringArray()
	summary_lines.append("📊 KẾT QUẢ BENCHMARK THỰC TẾ (12-BONE STICKMAN + 6 SOCKETS + COMBAT):")
	for tier in BENCH_TIERS:
		var r: Dictionary = _bench_results.get(str(tier), {})
		if not r.is_empty():
			var line: String = "• %d Quân (%d khớp): Avg %.1f FPS | 1%% Low %.1f FPS | Frame %.2f ms | Sim %.2f ms | RigDraw %.2f ms | DrawCalls %d | RAM %.1f MB" % [
				int(r["units"]), int(r["bones_solved_per_frame"]),
				float(r["avg_fps"]), float(r["low_1pct_fps"]),
				float(r["avg_frame_ms"]), float(r["cpu_sim_ms"]),
				float(r["cpu_rig_render_ms"]), int(r["draw_calls_2d"]), float(r["ram_mb"])
			]
			summary_lines.append(line)
			print(line)

	if _panel_bench_report != null and _lbl_bench_report != null:
		_lbl_bench_report.text = "\n".join(summary_lines)
		_panel_bench_report.visible = true

	if _bench_cli_mode:
		sim.clear_all_units()
		get_tree().quit(0)

# ============================================================================
# AUTOMATED VISUAL SHOWCASE SCREENSHOT CAPTURE (--capture-showcase)
# ============================================================================

func _step_showcase(delta: float) -> void:
	_showcase_timer += delta
	if _showcase_step == 0 and _showcase_timer > 0.45:
		# Trigger an active sword clash between Player and AI in 1v1 Duel
		if player_unit != null and ai_unit != null:
			player_unit.x = 890.0
			player_unit.prev_x = 890.0
			ai_unit.x = 955.0
			ai_unit.prev_x = 955.0
			sim.force_unit_animation(player_unit, "ATTACK_1")
			player_unit.anim_time = 0.21
			sim.force_unit_animation(ai_unit, "BLOCK_HIT")
			_on_combat_event("PARRY", Vector2(922.0, GROUND_Y - 52.0), 18, "⚡ PHẢN ĐÒN HOÀN HẢO! -18", Color(0.35, 0.98, 1.0))
		_showcase_step = 1
	elif _showcase_step == 1 and _showcase_timer > 0.65:
		_save_viewport_png("res://m1_duel_gameplay.png")
		# Switch to Inspector Mode with 12-bone debug overlay and heavy equipment
		_socket_indices[ContentDB.SOCKET_MAIN_WEAPON] = 1
		_socket_indices[ContentDB.SOCKET_OFFHAND] = 1
		_socket_indices[ContentDB.SOCKET_HELMET] = 1
		_socket_indices[ContentDB.SOCKET_CHEST_ARMOR] = 1
		_socket_indices[ContentDB.SOCKET_PAULDRON] = 1
		_socket_indices[ContentDB.SOCKET_BACK_CAPE] = 1
		_refresh_socket_button_texts()
		_setup_inspector_mode()
		sim.force_unit_animation(player_unit, "ATTACK_2")
		player_unit.anim_time = 0.30
		_showcase_step = 2
	elif _showcase_step == 2 and _showcase_timer > 1.05:
		_save_viewport_png("res://m1_equipment_and_bones.png")
		show_debug_bones = false
		_spawn_mass_battle(300)
		cam_pos.x = 1200.0
		_showcase_step = 3
	elif _showcase_step == 3 and _showcase_timer > 1.85:
		_save_viewport_png("res://m1_benchmark_300_units.png")
		sim.clear_all_units()
		get_tree().quit(0)

func _save_viewport_png(path: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("Saved screenshot: ", path)

# ============================================================================
# POLISHED MILESTONE 1 TEST & CUSTOMIZER UI
# ============================================================================

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	# --- TOP BAR: Mode Switcher + 1v1 Health Bars ---
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(14, 10)
	top_panel.size = Vector2(1252, 76)
	_style_panel(top_panel, Color(0.06, 0.08, 0.14, 0.90), Color(0.24, 0.56, 0.88, 0.75))
	_ui_layer.add_child(top_panel)

	var top_vbox := VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 6)
	top_panel.add_child(top_vbox)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	top_vbox.add_child(mode_row)

	var btn_duel := _make_button("⚔️ 1. Đấu 1v1 (Player vs AI)", Color(0.14, 0.36, 0.62))
	btn_duel.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		show_debug_bones = false
		_setup_1v1_duel()
	)
	mode_row.add_child(btn_duel)

	var btn_inspect := _make_button("🎨 2. Thử 6 Khe Trang Bị & 12 Khớp Xương", Color(0.18, 0.32, 0.48))
	btn_inspect.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_setup_inspector_mode()
	)
	mode_row.add_child(btn_inspect)

	var btn_bench := _make_button("📊 3. Chạy Benchmark 30/100/200/300 Quân [F3]", Color(0.46, 0.22, 0.58))
	btn_bench.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_start_benchmark_suite()
	)
	mode_row.add_child(btn_bench)

	var btn_bones := _make_button("🦴 Bật/Tắt 12 Khớp (B)", Color(0.16, 0.24, 0.34))
	btn_bones.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		show_debug_bones = not show_debug_bones
	)
	mode_row.add_child(btn_bones)

	var btn_slow := _make_button("🐢 Slow-Mo 0.25x", Color(0.16, 0.24, 0.34))
	btn_slow.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		time_scale = 0.25 if time_scale > 0.5 else 1.0
		btn_slow.text = "⚡ Tốc Độ 1.0x" if time_scale < 0.5 else "🐢 Slow-Mo 0.25x"
	)
	mode_row.add_child(btn_slow)

	var btn_reset := _make_button("🔄 Đặt Lại (R)", Color(0.22, 0.28, 0.38))
	btn_reset.pressed.connect(func() -> void:
		SoundEngine.play_sfx("ui_click")
		_setup_1v1_duel()
	)
	mode_row.add_child(btn_reset)

	# Second row in top bar: Player HP | Banner | AI HP
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 14)
	top_vbox.add_child(hp_row)

	_lbl_player_hp = Label.new()
	_lbl_player_hp.text = "🛡️ BẠN (Aethel Vanguard): 320 / 320 HP"
	_lbl_player_hp.custom_minimum_size = Vector2(290, 22)
	_lbl_player_hp.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	hp_row.add_child(_lbl_player_hp)

	_lbl_banner = Label.new()
	_lbl_banner.text = "⚔️ ĐẤU 1v1: CHIẾN BINH AETHEL vs HẮC KỴ SĨ VỰC THẲM"
	_lbl_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_banner.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	hp_row.add_child(_lbl_banner)

	_lbl_ai_hp = Label.new()
	_lbl_ai_hp.text = "💀 AI ĐỐI THỦ (Abyssal Knight): 360 / 360 HP"
	_lbl_ai_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_ai_hp.custom_minimum_size = Vector2(310, 22)
	_lbl_ai_hp.add_theme_color_override("font_color", Color(1.0, 0.48, 0.52))
	hp_row.add_child(_lbl_ai_hp)

	# --- LEFT PANEL: 6-Socket Modular Equipment Customizer ---
	_panel_customizer = PanelContainer.new()
	_panel_customizer.position = Vector2(14, 96)
	_panel_customizer.size = Vector2(288, 340)
	_style_panel(_panel_customizer, Color(0.06, 0.08, 0.14, 0.88), Color(0.22, 0.48, 0.76, 0.65))
	_ui_layer.add_child(_panel_customizer)

	var cust_vbox := VBoxContainer.new()
	cust_vbox.add_theme_constant_override("separation", 6)
	_panel_customizer.add_child(cust_vbox)

	var lbl_cust_title := Label.new()
	lbl_cust_title.text = "🛡️ 6 VỊ TRÍ GẮN TRANG BỊ (MODULAR)"
	lbl_cust_title.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0))
	cust_vbox.add_child(lbl_cust_title)

	var socket_labels: Dictionary = {
		ContentDB.SOCKET_MAIN_WEAPON: "1. Vũ Khí Chính",
		ContentDB.SOCKET_OFFHAND: "2. Tay Phụ / Khiên",
		ContentDB.SOCKET_HELMET: "3. Mũ Giáp",
		ContentDB.SOCKET_CHEST_ARMOR: "4. Giáp Ngực",
		ContentDB.SOCKET_PAULDRON: "5. Giáp Vai",
		ContentDB.SOCKET_BACK_CAPE: "6. Áo Choàng / Hào Quang"
	}

	for socket_key in socket_labels.keys():
		var btn := _make_button("", Color(0.12, 0.18, 0.28))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var sk: String = socket_key
		btn.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			var items: Array[String] = ContentDB.get_items_for_socket(sk)
			_socket_indices[sk] = (int(_socket_indices[sk]) + 1) % items.size()
			_refresh_socket_button_texts()
			_apply_loadout_to_player()
		)
		cust_vbox.add_child(btn)
		_socket_buttons[socket_key] = btn

	_lbl_stats_summary = Label.new()
	_lbl_stats_summary.add_theme_font_size_override("font_size", 13)
	_lbl_stats_summary.add_theme_color_override("font_color", Color(0.82, 0.92, 0.98))
	cust_vbox.add_child(_lbl_stats_summary)

	_refresh_socket_button_texts()

	# --- TOP-RIGHT PANEL: Live Performance Telemetry ---
	var perf_panel := PanelContainer.new()
	perf_panel.position = Vector2(956, 96)
	perf_panel.size = Vector2(310, 178)
	_style_panel(perf_panel, Color(0.05, 0.07, 0.12, 0.88), Color(0.25, 0.75, 0.58, 0.65))
	_ui_layer.add_child(perf_panel)

	_lbl_perf = Label.new()
	_lbl_perf.add_theme_font_size_override("font_size", 13)
	_lbl_perf.add_theme_color_override("font_color", Color(0.75, 0.98, 0.85))
	perf_panel.add_child(_lbl_perf)

	# --- CENTER-RIGHT BENCHMARK SUMMARY MODAL (Shown when F3 Benchmark completes) ---
	_panel_bench_report = PanelContainer.new()
	_panel_bench_report.position = Vector2(316, 96)
	_panel_bench_report.size = Vector2(628, 150)
	_panel_bench_report.visible = false
	_style_panel(_panel_bench_report, Color(0.05, 0.07, 0.14, 0.94), Color(0.95, 0.75, 0.25, 0.85))
	_ui_layer.add_child(_panel_bench_report)

	_lbl_bench_report = Label.new()
	_lbl_bench_report.add_theme_font_size_override("font_size", 12)
	_lbl_bench_report.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78))
	_panel_bench_report.add_child(_lbl_bench_report)

	# --- BOTTOM BAR: 6 Core Animations & Combat Controls ---
	var bot_panel := PanelContainer.new()
	bot_panel.position = Vector2(14, 618)
	bot_panel.size = Vector2(1252, 92)
	_style_panel(bot_panel, Color(0.06, 0.08, 0.14, 0.92), Color(0.24, 0.56, 0.88, 0.75))
	_ui_layer.add_child(bot_panel)

	var bot_vbox := VBoxContainer.new()
	bot_vbox.add_theme_constant_override("separation", 6)
	bot_panel.add_child(bot_vbox)

	var anim_row := HBoxContainer.new()
	anim_row.add_theme_constant_override("separation", 8)
	bot_vbox.add_child(anim_row)

	var anim_buttons: Array[Array] = [
		["IDLE", "1. IDLE (Thở Chiến Đấu)"],
		["RUN", "2. RUN (Chạy Phối Hợp)"],
		["ATTACK_1", "3. ATTACK_1 (Chém Bổ) [J/Space]"],
		["ATTACK_2", "4. ATTACK_2 (Đột Kích Trảm) [L/E]"],
		["BLOCK_HIT", "5. BLOCK_HIT (Đỡ / Parry) [K/Shift]"],
		["DEATH", "6. DEATH (Gục Ngã & Rơi Kiếm)"]
	]
	for pair in anim_buttons:
		var st_code: String = pair[0]
		var btn_a := _make_button(pair[1], Color(0.15, 0.25, 0.42))
		btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_a.pressed.connect(func() -> void:
			SoundEngine.play_sfx("ui_click")
			_trigger_player_anim_preview(st_code)
		)
		anim_row.add_child(btn_a)

	var lbl_controls := Label.new()
	lbl_controls.text = "🎮 ĐIỀU KHIỂN: [A / D] hoặc [⬅️ / ➡️] Di chuyển  |  [J / Space / Click Trái] Chém Combo 2 Đòn  |  [L / E] Đột Kích Trảm  |  [K / Shift / Click Phải] Giơ Khiên Đỡ & Canh Parry (<0.2s)  |  [Phím 1..6] Xem 6 Animation"
	lbl_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_controls.add_theme_font_size_override("font_size", 13)
	lbl_controls.add_theme_color_override("font_color", Color(0.76, 0.88, 1.0))
	bot_vbox.add_child(lbl_controls)

func _refresh_socket_button_texts() -> void:
	var prefixes: Dictionary = {
		ContentDB.SOCKET_MAIN_WEAPON: "⚔️ Vũ Khí: ",
		ContentDB.SOCKET_OFFHAND: "🛡️ Tay Phụ: ",
		ContentDB.SOCKET_HELMET: "👑 Mũ Giáp: ",
		ContentDB.SOCKET_CHEST_ARMOR: "🦺 Giáp Ngực: ",
		ContentDB.SOCKET_PAULDRON: "💠 Giáp Vai: ",
		ContentDB.SOCKET_BACK_CAPE: "🧣 Áo Choàng: "
	}
	for sk in _socket_buttons.keys():
		var items: Array[String] = ContentDB.get_items_for_socket(sk)
		var idx: int = int(_socket_indices[sk]) % items.size()
		var item_id: String = items[idx]
		var item_name: String = str(ContentDB.EQUIPMENT[item_id]["name"])
		var btn: Button = _socket_buttons[sk]
		btn.text = prefixes[sk] + item_name

func _update_stats_summary_label() -> void:
	if _lbl_stats_summary == null or player_unit == null:
		return
	_lbl_stats_summary.text = "📊 CHỈ SỐ NHÂN VẬT (Động từ 6 Socket):\n• Máu Tối Đa: %d HP   • Sát Thương: %d\n• Tốc Chạy: %d px/s  • Tầm Đánh: %d px\n• Giảm ST Giáp: %d%%   • Giảm ST Khiên: %d%%" % [
		int(round(player_unit.max_hp)),
		int(round(player_unit.damage)),
		int(round(player_unit.move_speed)),
		int(round(player_unit.attack_range)),
		int(round(player_unit.armor_reduction * 100.0)),
		int(round(player_unit.block_reduction * 100.0))
	]

func _update_ui_hud(delta: float) -> void:
	if player_unit != null and _lbl_player_hp != null:
		_lbl_player_hp.text = "🛡️ BẠN (Aethel): %d / %d HP [%s]" % [
			int(ceil(player_unit.hp)), int(round(player_unit.max_hp)), player_unit.anim_state
		]
	if ai_unit != null and _lbl_ai_hp != null:
		_lbl_ai_hp.text = "💀 AI ĐỐI THỦ: %d / %d HP [%s]" % [
			int(ceil(ai_unit.hp)), int(round(ai_unit.max_hp)), ai_unit.anim_state
		]

	# Auto-respawn 1v1 duel 2.2 seconds after a unit dies so player can duel continuously
	if arena_mode == 0 and player_unit != null and ai_unit != null:
		if (player_unit.anim_state == "DEATH" and player_unit.anim_time >= 1.35) or (ai_unit.anim_state == "DEATH" and ai_unit.anim_time >= 1.35):
			if _lbl_banner != null:
				_lbl_banner.text = "🏆 HIỆP ĐẤU KẾT THÚC! Nhấn [R] để đấu lại ngay hoặc chờ tự động hồi sinh..."
			if player_unit.anim_time >= 1.39 or ai_unit.anim_time >= 1.39:
				_setup_1v1_duel()

	# Update rolling FPS & 1% Low telemetry
	var inst_fps: float = 1.0 / maxf(0.0005, delta)
	_fps_window.append(inst_fps)
	if _fps_window.size() > 120:
		_fps_window.pop_front()

	if _lbl_perf != null and (sim.tick_count % 6 == 0):
		var sorted_fps: Array[float] = _fps_window.duplicate()
		sorted_fps.sort()
		var low_1pct: float = sorted_fps[0] if not sorted_fps.is_empty() else inst_fps
		var n_active: int = sim.active_units.size()
		var dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var ram_mb: float = float(OS.get_static_memory_usage()) / 1048576.0
		_lbl_perf.text = "⚡ HIỆU NĂNG THỜI GIAN THỰC (Godot 4.7.2)\n• Đơn vị hoạt ảnh: %d (%d khớp xương)\n• FPS: %.1f  |  1%% Low: %.1f FPS\n• Frame Time: %.2f ms\n• CPU Sim (60Hz): %.2f ms\n• CPU Rig + Draw: %.2f ms\n• 2D Draw Calls: %d  |  RAM: %.1f MB" % [
			n_active, n_active * 12,
			Engine.get_frames_per_second(), low_1pct,
			delta * 1000.0,
			_last_sim_ms,
			_last_render_ms,
			dc, ram_mb
		]

func _make_button(text: String, bg_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = bg_col.lightened(0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = bg_col.lightened(0.18)
	btn.add_theme_stylebox_override("hover", sb_hover)
	return btn

func _style_panel(panel: PanelContainer, bg_col: Color, border_col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
