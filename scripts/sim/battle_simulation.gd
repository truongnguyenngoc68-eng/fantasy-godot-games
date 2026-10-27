extends RefCounted
class_name BattleSimulation

# ============================================================================
# DECOUPLED SIMULATION ENGINE (Fixed Timestep 60Hz + FixedPool + Sorted 1D Sweep)
# Completely separated from Rendering/UI. Supports 1v1 Duel, Animation Showcase,
# and 30/100/200/300 Animated Unit Mass Combat Benchmarks.
# ============================================================================

const FIXED_DT: float = 1.0 / 60.0
const MAX_POOL_UNITS: int = 350
const NUM_SUB_LANES: int = 8

signal combat_event(event_type: String, world_pos: Vector2, value: int, text: String, color: Color)
signal sfx_requested(sfx_name: String)
signal gold_deposited(team: int, amount: int, world_pos: Vector2)

class SimUnit extends RefCounted:
	var pool_id: int = 0
	var active: bool = false
	var team: int = 1
	var archetype_id: String = "vanguard_hero"
	var is_player_controlled: bool = false
	var ai_enabled: bool = true

	# Spatial & Kinematics
	var x: float = 400.0
	var prev_x: float = 400.0
	var sub_lane: int = 1 # 0, 1, 2
	var lane_y_offset: float = 0.0
	var facing: float = 1.0
	var vx: float = 0.0

	# Computed Stats (Base + 6 Equipment Sockets)
	var max_hp: float = 320.0
	var hp: float = 320.0
	var damage: float = 34.0
	var move_speed: float = 210.0
	var attack_range: float = 78.0
	var attack_speed_mult: float = 1.0
	var armor_reduction: float = 0.15
	var block_reduction: float = 0.65
	var unit_scale: float = 1.0

	# 6-Socket Modular Equipment Loadout
	var loadout: Dictionary = {}
	var body_color: Color = Color(0.13, 0.16, 0.24)
	var limb_highlight: Color = Color(0.24, 0.30, 0.44)
	var eye_color: Color = Color(0.25, 0.92, 1.0)

	# 6 Core Animation States: IDLE, RUN, ATTACK_1, ATTACK_2, BLOCK_HIT, DEATH
	var anim_state: String = "IDLE"
	var anim_time: float = 0.0
	var anim_duration: float = 0.5
	var is_blocking: bool = false
	var block_start_time: float = 0.0
	var attack_hit_applied: bool = false
	var combo_index: int = 0
	var combo_window_timer: float = 0.0
	var attack_cooldown: float = 0.0

	# Hit Reaction & Secondary Motion
	var hit_flash_timer: float = 0.0
	var hit_recoil_impulse: float = 0.0
	var cape_wave_phase: float = 0.0
	var dropped_weapon_y: float = 0.0
	var dropped_weapon_rot: float = 0.0

	# AI internal state
	var ai_action_lock: float = 0.0
	var target_unit: SimUnit = null
	var lane_rank: int = 0
	var unit_ahead: SimUnit = null
	var unit_role: String = "fighter" # "miner" or "fighter"
	var gold_carried: int = 0
	var mine_timer: float = 0.0

var _unit_pool: Array[SimUnit] = []
var active_units: Array[SimUnit] = []

# Frontline Cache: _frontline_team1[sub_lane] -> Array of up to 6 leading SimUnits
var _frontline_team1: Array = []
var _frontline_team2: Array = []

var tick_count: int = 0
var hitstop_timer: float = 0.0
var arena_min_x: float = 160.0
var arena_max_x: float = 2240.0

# Stick War Base-Defense / Tug-of-War Mode State
var stick_war_mode: bool = false
var team1_stance: int = 2 # 0 = GARRISON (Đồn trú), 1 = DEFEND (Thủ nhà), 2 = ATTACK (Tấn công)
var bastion1_hp: float = 2500.0
var bastion1_max_hp: float = 2500.0
var bastion2_hp: float = 2500.0
var bastion2_max_hp: float = 2500.0
const BASTION1_X: float = 270.0
const BASTION2_X: float = 2130.0
const GOLD_MINE1_X: float = 490.0
const DEFEND_LINE_X: float = 780.0

# Player Input State (populated by Input/UI controller)
var player_move_dir: float = 0.0
var player_block_held: bool = false
var player_queued_attack: int = 0 # 0 = none, 1 = normal combo, 2 = heavy lunge

func _init() -> void:
	for s in range(NUM_SUB_LANES):
		_frontline_team1.append([])
		_frontline_team2.append([])
	for i in range(MAX_POOL_UNITS):
		var u := SimUnit.new()
		u.pool_id = i
		_unit_pool.append(u)

func clear_all_units() -> void:
	hitstop_timer = 0.0
	for i in range(active_units.size()):
		var u: SimUnit = active_units[i]
		u.active = false
		u.target_unit = null
		u.unit_ahead = null
		if not _unit_pool.has(u):
			_unit_pool.append(u)
	active_units.clear()
	for s in range(NUM_SUB_LANES):
		(_frontline_team1[s] as Array).clear()
		(_frontline_team2[s] as Array).clear()

func spawn_unit(
	team: int,
	archetype_id: String,
	spawn_x: float,
	p_sub_lane: int = 1,
	is_player: bool = false,
	custom_loadout: Dictionary = {}
) -> SimUnit:
	if _unit_pool.is_empty():
		return null
	var u: SimUnit = _unit_pool.pop_back()
	u.active = true
	u.team = team
	u.archetype_id = archetype_id
	u.is_player_controlled = is_player
	u.ai_enabled = not is_player
	u.x = spawn_x
	u.prev_x = spawn_x
	u.sub_lane = clampi(p_sub_lane, 0, NUM_SUB_LANES - 1)
	var lane_t: float = float(u.sub_lane) / float(max(1, NUM_SUB_LANES - 1))
	u.lane_y_offset = lerpf(-96.0, 86.0, lane_t) + randf_range(-4.0, 4.0)
	if is_player:
		u.lane_y_offset = 0.0
	u.facing = 1.0 if team == 1 else -1.0
	u.vx = 0.0

	var arch: Dictionary = ContentDB.UNITS.get(archetype_id, ContentDB.MONSTERS.get(archetype_id, ContentDB.UNITS["vanguard_hero"]))
	u.body_color = arch["body_color"]
	u.limb_highlight = arch["limb_highlight"]
	u.eye_color = arch["eye_color"]
	u.unit_scale = float(arch.get("scale", 1.0))

	u.loadout = (arch["default_loadout"] as Dictionary).duplicate()
	for k in custom_loadout.keys():
		u.loadout[k] = custom_loadout[k]

	recalculate_unit_stats(u, true)

	u.anim_state = "IDLE"
	u.anim_time = randf_range(0.0, 1.2)
	u.anim_duration = 1.0
	u.is_blocking = false
	u.attack_hit_applied = false
	u.combo_index = 0
	u.combo_window_timer = 0.0
	u.attack_cooldown = 0.0
	u.hit_flash_timer = 0.0
	u.hit_recoil_impulse = 0.0
	u.cape_wave_phase = randf_range(0.0, TAU)
	u.dropped_weapon_y = 0.0
	u.dropped_weapon_rot = 0.0
	u.target_unit = null
	u.unit_role = "fighter"
	u.gold_carried = 0
	u.mine_timer = 0.0

	active_units.append(u)
	return u

func recalculate_unit_stats(u: SimUnit, full_heal: bool = false) -> void:
	var arch: Dictionary = ContentDB.UNITS.get(u.archetype_id, ContentDB.MONSTERS.get(u.archetype_id, ContentDB.UNITS["vanguard_hero"]))
	var wpn: Dictionary = ContentDB.EQUIPMENT.get(str(u.loadout.get(ContentDB.SOCKET_MAIN_WEAPON, "wpn_aethel_blade")), {})
	var off: Dictionary = ContentDB.EQUIPMENT.get(str(u.loadout.get(ContentDB.SOCKET_OFFHAND, "off_none")), {})
	var hlm: Dictionary = ContentDB.EQUIPMENT.get(str(u.loadout.get(ContentDB.SOCKET_HELMET, "hlm_none")), {})
	var arm: Dictionary = ContentDB.EQUIPMENT.get(str(u.loadout.get(ContentDB.SOCKET_CHEST_ARMOR, "arm_light_tunic")), {})
	var pld: Dictionary = ContentDB.EQUIPMENT.get(str(u.loadout.get(ContentDB.SOCKET_PAULDRON, "pld_none")), {})
	var cpe: Dictionary = ContentDB.EQUIPMENT.get(str(u.loadout.get(ContentDB.SOCKET_BACK_CAPE, "cpe_none")), {})

	var bonus_hp: float = float(off.get("hp_bonus", 0.0)) + float(hlm.get("hp_bonus", 0.0)) + float(arm.get("hp_bonus", 0.0)) + float(pld.get("hp_bonus", 0.0))
	u.max_hp = float(arch["base_hp"]) + bonus_hp
	if full_heal:
		u.hp = u.max_hp
	else:
		u.hp = clampf(u.hp, 1.0, u.max_hp)

	u.damage = float(arch["base_damage"]) + float(wpn.get("damage_bonus", 0.0))
	u.attack_range = float(arch["attack_range"]) + float(wpn.get("reach_bonus", 0.0))
	u.attack_speed_mult = float(wpn.get("speed_mult", 1.0))
	u.move_speed = float(arch["base_speed"]) + float(cpe.get("speed_bonus", 0.0))
	u.armor_reduction = clampf(float(arm.get("armor_reduction", 0.05)), 0.0, 0.60)
	u.block_reduction = clampf(float(off.get("block_reduction", 0.40)), 0.25, 0.85)

func step_fixed(dt: float) -> void:
	tick_count += 1

	if hitstop_timer > 0.0:
		hitstop_timer = maxf(0.0, hitstop_timer - dt)
		return

	# 1. Insertion Sort active units by X coordinate -> O(N) on nearly-sorted lane
	_sort_active_units_by_x()

	# 2. Rebuild Sub-Lane Frontline Cache -> O(N)
	_rebuild_frontline_cache()

	# 3. Step all active units
	var ground_y: float = float(ContentDB.MAPS["twilight_ruins"]["ground_y"])
	for i in range(active_units.size()):
		var u: SimUnit = active_units[i]
		if not u.active:
			continue

		u.prev_x = u.x
		u.anim_time += dt
		u.cape_wave_phase += dt * (4.0 + absf(u.vx) * 0.035)

		if u.hit_flash_timer > 0.0:
			u.hit_flash_timer = maxf(0.0, u.hit_flash_timer - dt)
		if u.hit_recoil_impulse > 0.0:
			u.hit_recoil_impulse = maxf(0.0, u.hit_recoil_impulse - dt * 4.5)
		if u.attack_cooldown > 0.0:
			u.attack_cooldown = maxf(0.0, u.attack_cooldown - dt)
		if u.combo_window_timer > 0.0:
			u.combo_window_timer = maxf(0.0, u.combo_window_timer - dt)
			if u.combo_window_timer <= 0.0:
				u.combo_index = 0

		var min_bound_x: float = 590.0 if (not stick_war_mode and active_units.size() >= 20) else arena_min_x
		var max_bound_x: float = 1790.0 if (not stick_war_mode and active_units.size() >= 20) else arena_max_x

		if u.anim_state == "DEATH":
			u.vx = move_toward(u.vx, 0.0, 600.0 * dt)
			u.x = clampf(u.x + u.vx * dt, min_bound_x, max_bound_x)
			if u.anim_time < 0.45:
				u.dropped_weapon_y = minf(26.0, u.dropped_weapon_y + 95.0 * dt)
				u.dropped_weapon_rot += 9.0 * dt
			elif stick_war_mode and u.anim_time >= 1.40:
				u.active = false
				u.target_unit = null
				u.unit_ahead = null
				_unit_pool.append(u)
			elif not stick_war_mode and active_units.size() >= 20 and u.anim_time >= 1.45:
				# Continuous reinforcement from visible fortress gate zone (keeps all 300 units in camera frustum)
				u.hp = u.max_hp
				u.anim_state = "RUN"
				u.anim_time = 0.0
				u.dropped_weapon_y = 0.0
				u.dropped_weapon_rot = 0.0
				var gate_spread: float = float(u.pool_id % 10) * 14.0
				u.x = (610.0 + gate_spread) if u.team == 1 else (1770.0 - gate_spread)
				u.prev_x = u.x
			continue

		if u.is_player_controlled:
			_step_player_unit(u, dt)
		elif stick_war_mode and u.unit_role == "miner":
			_step_miner_unit(u, dt, ground_y)
		elif u.ai_enabled:
			var should_rethink: bool = ((u.pool_id + tick_count) % 6 == 0)
			_step_ai_unit(u, dt, should_rethink)

		# Resolve active attack hitbox window
		if u.anim_state == "ATTACK_1" or u.anim_state == "ATTACK_2":
			_check_melee_attack_frame(u, dt, ground_y)
			if u.anim_time >= u.anim_duration:
				u.anim_state = "IDLE"
				u.anim_time = 0.0
		elif u.anim_state == "BLOCK_HIT" and not u.is_blocking:
			if u.anim_time >= u.anim_duration:
				u.anim_state = "IDLE"
				u.anim_time = 0.0

		u.x = clampf(u.x + u.vx * dt, min_bound_x, max_bound_x)

	# Purge inactive units returned to pool in stick_war_mode
	if stick_war_mode:
		var w_idx: int = 0
		for r_idx in range(active_units.size()):
			if active_units[r_idx].active:
				active_units[w_idx] = active_units[r_idx]
				w_idx += 1
		active_units.resize(w_idx)

func _step_player_unit(u: SimUnit, dt: float) -> void:
	# Cannot override an active attack swing midway except near recovery
	var in_attack: bool = (u.anim_state == "ATTACK_1" or u.anim_state == "ATTACK_2")
	var in_hit_stun: bool = (u.anim_state == "BLOCK_HIT" and not u.is_blocking)

	if in_hit_stun:
		u.vx = move_toward(u.vx, 0.0, 750.0 * dt)
		player_queued_attack = 0
		return

	if in_attack:
		# Lunge velocity during early strike phase of ATTACK_2
		if u.anim_state == "ATTACK_2" and u.anim_time < u.anim_duration * 0.45:
			u.vx = u.facing * u.move_speed * 1.15
		else:
			u.vx = move_toward(u.vx, 0.0, 900.0 * dt)
		return

	# Check Block / Guard input
	if player_block_held:
		if not u.is_blocking:
			u.is_blocking = true
			u.block_start_time = float(tick_count) * FIXED_DT
			u.anim_state = "BLOCK_HIT"
			u.anim_time = 0.0
			u.anim_duration = 999.0
		u.vx = player_move_dir * (u.move_speed * 0.35)
		if absf(player_move_dir) > 0.05:
			u.facing = signf(player_move_dir)
		player_queued_attack = 0
		return
	elif u.is_blocking:
		u.is_blocking = false
		u.anim_state = "IDLE"
		u.anim_time = 0.0

	# Check Queued Attack input
	if player_queued_attack > 0 and u.attack_cooldown <= 0.0:
		var req: int = player_queued_attack
		player_queued_attack = 0
		if req == 2 or u.combo_index == 1:
			_start_unit_attack(u, "ATTACK_2")
			u.combo_index = 0
		else:
			_start_unit_attack(u, "ATTACK_1")
			u.combo_index = 1
			u.combo_window_timer = 0.85
		return

	# Normal Movement / Idle
	if absf(player_move_dir) > 0.05:
		u.facing = signf(player_move_dir)
		u.vx = u.facing * u.move_speed
		if u.anim_state != "RUN":
			u.anim_state = "RUN"
			u.anim_time = 0.0
	else:
		u.vx = move_toward(u.vx, 0.0, 1200.0 * dt)
		if u.anim_state != "IDLE":
			u.anim_state = "IDLE"
			u.anim_time = 0.0

func _step_miner_unit(u: SimUnit, dt: float, ground_y: float) -> void:
	# Stick War Miner Loop: Garrison inside Bastion OR Mine Crystal -> Carry Gold Sack -> Deposit at Bastion
	if u.team == 1 and team1_stance == 0:
		# GARRISON / RETREAT: Run back inside Left Bastion
		var gar_x: float = BASTION1_X - 10.0
		if absf(u.x - gar_x) > 10.0:
			u.facing = -1.0 if u.x > gar_x else 1.0
			u.vx = u.facing * u.move_speed
			if u.anim_state != "RUN":
				u.anim_state = "RUN"
				u.anim_time = 0.0
		else:
			u.vx = 0.0
			u.facing = 1.0
			if u.anim_state != "IDLE":
				u.anim_state = "IDLE"
				u.anim_time = 0.0
		return

	if u.gold_carried <= 0:
		var mine_x: float = GOLD_MINE1_X + float(u.pool_id % 4) * 28.0
		if absf(u.x - mine_x) > 12.0:
			u.facing = 1.0 if mine_x >= u.x else -1.0
			u.vx = u.facing * u.move_speed
			if u.anim_state != "RUN":
				u.anim_state = "RUN"
				u.anim_time = 0.0
		else:
			u.vx = 0.0
			u.facing = 1.0
			u.mine_timer += dt
			if u.anim_state != "ATTACK_1":
				_start_unit_attack(u, "ATTACK_1")
			if u.mine_timer >= 2.0:
				u.mine_timer = 0.0
				u.gold_carried = 45
				sfx_requested.emit("parry_clang")
				combat_event.emit("MINE", Vector2(u.x, ground_y + u.lane_y_offset - 54.0), 45, "⛏️ Đầy Vàng!", Color(1.0, 0.90, 0.25))
	else:
		var drop_x: float = BASTION1_X + 20.0
		if absf(u.x - drop_x) > 14.0:
			u.facing = -1.0 if drop_x < u.x else 1.0
			u.vx = u.facing * (u.move_speed * 0.92)
			if u.anim_state != "RUN":
				u.anim_state = "RUN"
				u.anim_time = 0.0
		else:
			u.vx = 0.0
			var amt: int = u.gold_carried
			u.gold_carried = 0
			u.anim_state = "IDLE"
			u.anim_time = 0.0
			gold_deposited.emit(u.team, amt, Vector2(u.x, ground_y + u.lane_y_offset - 64.0))

func _step_ai_unit(u: SimUnit, dt: float, should_rethink: bool) -> void:
	var team_dir: float = 1.0 if u.team == 1 else -1.0
	var sc: float = clampf(u.unit_scale, 0.45, 1.25)
	u.facing = team_dir

	var in_attack: bool = (u.anim_state == "ATTACK_1" or u.anim_state == "ATTACK_2")
	var in_hit_stun: bool = (u.anim_state == "BLOCK_HIT" and not u.is_blocking)

	if in_hit_stun:
		u.vx = move_toward(u.vx, 0.0, 750.0 * dt)
		return
	if in_attack:
		var can_lunge: bool = false
		if u.anim_state == "ATTACK_2" and u.anim_time < u.anim_duration * 0.42 and u.target_unit != null and u.target_unit.active and u.target_unit.anim_state != "DEATH":
			var forward_gap: float = (u.target_unit.x - u.x) * team_dir
			can_lunge = (forward_gap > 56.0 * sc)
		if can_lunge:
			u.vx = team_dir * u.move_speed * 0.85
		else:
			u.vx = move_toward(u.vx, 0.0, 850.0 * dt)
		return

	if u.ai_action_lock > 0.0:
		u.ai_action_lock = maxf(0.0, u.ai_action_lock - dt)

	# Bounded O(1) Frontline Target Lookup
	if u.target_unit == null or not u.target_unit.active or u.target_unit.anim_state == "DEATH" or should_rethink:
		u.target_unit = _find_frontline_target(u)

	# Stick War 3-Stance Tactical Rules for Player Army (Team 1)
	if stick_war_mode and u.team == 1:
		if team1_stance == 0:
			# 0 = GARRISON / RETREAT: Retreat behind Left Bastion & heal slowly
			u.hp = minf(u.max_hp, u.hp + 14.0 * dt)
			var gar_post_x: float = BASTION1_X + 35.0 - float(u.lane_rank) * 18.0
			if u.target_unit != null and u.target_unit.x <= BASTION1_X + 125.0 and u.lane_rank == 0:
				# Enemy right at our gate -> fight at gate!
				pass
			elif absf(u.x - gar_x_clamp(gar_post_x)) > 10.0:
				u.is_blocking = false
				var dest_x: float = gar_x_clamp(gar_post_x)
				u.facing = 1.0 if dest_x >= u.x else -1.0
				u.vx = u.facing * u.move_speed
				if u.anim_state != "RUN":
					u.anim_state = "RUN"
					u.anim_time = 0.0
				return
			else:
				u.is_blocking = false
				u.vx = 0.0
				u.facing = 1.0
				if u.anim_state != "IDLE":
					u.anim_state = "IDLE"
					u.anim_time = 0.0
				return
		elif team1_stance == 1:
			# 1 = DEFEND / THỦ NHÀ: Hold shield wall at DEFEND_LINE_X (780) unless enemy enters within x <= 1060
			if u.target_unit == null or u.target_unit.x > 1060.0:
				u.is_blocking = false
				var def_post_x: float = DEFEND_LINE_X - float(u.lane_rank) * 32.0 - float(u.sub_lane % 3) * 8.0
				if absf(u.x - def_post_x) > 10.0:
					u.facing = 1.0 if def_post_x >= u.x else -1.0
					u.vx = u.facing * u.move_speed
					if u.anim_state != "RUN":
						u.anim_state = "RUN"
						u.anim_time = 0.0
				else:
					u.vx = 0.0
					u.facing = 1.0
					if u.anim_state != "IDLE":
						u.anim_state = "IDLE"
						u.anim_time = 0.0
				return

	if u.target_unit == null:
		# In Stick War Mode, when no enemy units remain on lane, march to Enemy Bastion/Statue and attack it!
		if stick_war_mode:
			var enemy_gate_x: float = (BASTION2_X - 115.0) if u.team == 1 else (BASTION1_X + 115.0)
			var gate_dist: float = (enemy_gate_x - u.x) * team_dir
			if u.lane_rank >= 1 and u.unit_ahead != null and u.unit_ahead.active and u.unit_ahead.anim_state != "DEATH":
				var min_gap: float = maxf(24.0, 34.0 * sc)
				if (u.unit_ahead.x - u.x) * team_dir < min_gap:
					u.vx = 0.0
					if u.anim_state != "IDLE":
						u.anim_state = "IDLE"
						u.anim_time = 0.0
					return
			if gate_dist <= u.attack_range * sc + 12.0 and u.lane_rank <= 1:
				u.vx = 0.0
				if u.attack_cooldown <= 0.0:
					var next_b_atk: String = "ATTACK_2" if (u.combo_index == 1) else "ATTACK_1"
					_start_unit_attack(u, next_b_atk)
					u.combo_index = 1 if next_b_atk == "ATTACK_1" else 0
				elif u.anim_state != "IDLE":
					u.anim_state = "IDLE"
					u.anim_time = 0.0
			else:
				u.vx = team_dir * u.move_speed
				if u.anim_state != "RUN":
					u.anim_state = "RUN"
					u.anim_time = 0.0
			return
		u.is_blocking = false
		u.vx = 0.0
		if u.anim_state != "IDLE":
			u.anim_state = "IDLE"
			u.anim_time = 0.0
		return

	var forward_dist: float = (u.target_unit.x - u.x) * team_dir
	var dist_x: float = absf(u.target_unit.x - u.x)

	# Smart AI defensive block reaction if opponent is mid-swing and close
	var enemy_attacking: bool = (u.target_unit.anim_state == "ATTACK_1" or u.target_unit.anim_state == "ATTACK_2")
	if u.lane_rank == 0 and enemy_attacking and dist_x <= u.target_unit.attack_range + 18.0 and u.ai_action_lock <= 0.0:
		if randf() < 0.28:
			u.is_blocking = true
			u.block_start_time = float(tick_count) * FIXED_DT
			u.anim_state = "BLOCK_HIT"
			u.anim_time = 0.0
			u.anim_duration = 0.45
			u.ai_action_lock = 0.45
			u.vx = 0.0
			return

	if u.is_blocking and u.ai_action_lock <= 0.0:
		u.is_blocking = false
		u.anim_state = "IDLE"
		u.anim_time = 0.0

	# 1. Anti-stacking formation spacing FIRST: rear ranks (lane_rank >= 1) must ALWAYS stay behind unit_ahead
	# When the frontline unit ahead dies (anim_state == "DEATH"), _rebuild_frontline_cache promotes this unit to lane_rank 0
	# so it immediately advances (RUN -> ATTACK) to replace the fallen frontline!
	if u.lane_rank >= 1 and u.unit_ahead != null and u.unit_ahead.active and u.unit_ahead.anim_state != "DEATH":
		var min_ally_gap: float = maxf(24.0, 34.0 * sc) + float((u.pool_id * 5) % 6)
		var ally_dist: float = (u.unit_ahead.x - u.x) * team_dir
		if ally_dist < min_ally_gap:
			u.vx = 0.0
			# If unit_ahead was knocked backward, gently yield backward so ranks never overlap or invert order
			var target_rear_x: float = u.unit_ahead.x - team_dir * min_ally_gap
			u.x = move_toward(u.x, target_rear_x, u.move_speed * 0.85 * dt)
			if u.anim_state != "IDLE" and not u.is_blocking:
				u.anim_state = "IDLE"
				u.anim_time = 0.0
			return

	# 2. Frontline engagement (lane_rank == 0)
	var stop_range: float = u.attack_range * sc - 2.0 + float(u.pool_id % 4) * 3.0
	var min_enemy_gap: float = 46.0 * sc
	if u.lane_rank == 0 and forward_dist <= stop_range:
		u.vx = 0.0
		if forward_dist < min_enemy_gap:
			var target_front_x: float = u.target_unit.x - team_dir * min_enemy_gap
			u.x = move_toward(u.x, target_front_x, u.move_speed * 0.75 * dt)
		if u.attack_cooldown <= 0.0:
			var next_atk: String = "ATTACK_2" if (u.combo_index == 1) else "ATTACK_1"
			_start_unit_attack(u, next_atk)
			u.combo_index = 1 if next_atk == "ATTACK_1" else 0
		elif u.anim_state != "IDLE" and not u.is_blocking:
			u.anim_state = "IDLE"
			u.anim_time = 0.0
	else:
		u.vx = team_dir * u.move_speed
		if u.anim_state != "RUN":
			u.anim_state = "RUN"
			u.anim_time = 0.0

func force_unit_animation(u: SimUnit, state_name: String) -> void:
	if u == null or not u.active:
		return
	if state_name == "ATTACK_1" or state_name == "ATTACK_2":
		_start_unit_attack(u, state_name)
	elif state_name == "BLOCK_HIT":
		u.is_blocking = true
		u.block_start_time = float(tick_count) * FIXED_DT
		u.anim_state = "BLOCK_HIT"
		u.anim_time = 0.0
		u.anim_duration = 0.65
		u.vx = 0.0
	elif state_name == "DEATH":
		u.is_blocking = false
		u.anim_state = "DEATH"
		u.anim_time = 0.0
		u.anim_duration = 1.4
		u.dropped_weapon_y = 0.0
		u.dropped_weapon_rot = 0.0
		u.vx = -u.facing * 95.0
		sfx_requested.emit("death")
	elif state_name == "RUN":
		u.is_blocking = false
		u.anim_state = "RUN"
		u.anim_time = 0.0
		u.anim_duration = 0.8
	else:
		u.is_blocking = false
		u.anim_state = "IDLE"
		u.anim_time = 0.0
		u.anim_duration = 1.0
		u.vx = 0.0

func _start_unit_attack(u: SimUnit, atk_state: String) -> void:
	u.is_blocking = false
	u.anim_state = atk_state
	u.anim_time = 0.0
	var base_dur: float = 0.44 if atk_state == "ATTACK_1" else 0.54
	u.anim_duration = base_dur / maxf(0.5, u.attack_speed_mult)
	u.attack_cooldown = u.anim_duration + 0.10
	u.attack_hit_applied = false
	if not (stick_war_mode and u.unit_role == "miner"):
		sfx_requested.emit("whoosh")

func gar_x_clamp(val: float) -> float:
	return clampf(val, 185.0, 340.0)

func _check_melee_attack_frame(u: SimUnit, _dt: float, ground_y: float) -> void:
	if u.attack_hit_applied:
		return
	var strike_ratio: float = u.anim_time / maxf(0.01, u.anim_duration)
	if strike_ratio < 0.38 or strike_ratio > 0.65:
		return

	u.attack_hit_applied = true
	if stick_war_mode and u.unit_role == "miner":
		return
	var victim: SimUnit = _find_frontline_target(u)
	if victim != null:
		var dist_x: float = (victim.x - u.x) * u.facing
		if dist_x >= -15.0 and dist_x <= u.attack_range + 16.0:
			var is_heavy: bool = (u.anim_state == "ATTACK_2")
			var mult: float = 1.38 if is_heavy else 1.0
			_apply_combat_hit(u, victim, u.damage * mult, is_heavy, ground_y)
			return

	# Stick War Mode: If at Enemy Bastion/Statue gate, apply damage directly to Enemy Bastion!
	if stick_war_mode:
		var is_heavy_b: bool = (u.anim_state == "ATTACK_2")
		var b_dmg: float = u.damage * (1.35 if is_heavy_b else 1.0)
		if u.team == 1 and u.x >= BASTION2_X - 180.0 and bastion2_hp > 0.0:
			bastion2_hp = maxf(0.0, bastion2_hp - b_dmg)
			sfx_requested.emit("heavy_cleave" if is_heavy_b else "slash_hit")
			combat_event.emit("HIT", Vector2(BASTION2_X - 80.0, ground_y - 90.0), int(round(b_dmg)), "💥 Tượng Địch -%d" % int(round(b_dmg)), Color(1.0, 0.85, 0.22))
		elif u.team == 2 and u.x <= BASTION1_X + 180.0 and bastion1_hp > 0.0:
			bastion1_hp = maxf(0.0, bastion1_hp - b_dmg)
			sfx_requested.emit("heavy_cleave" if is_heavy_b else "slash_hit")
			combat_event.emit("HIT", Vector2(BASTION1_X + 80.0, ground_y - 90.0), int(round(b_dmg)), "⚠️ Thành Trì -%d" % int(round(b_dmg)), Color(1.0, 0.35, 0.30))

func _apply_combat_hit(attacker: SimUnit, victim: SimUnit, raw_dmg: float, is_heavy: bool, ground_y: float) -> void:
	var hit_pos := Vector2(victim.x, ground_y + victim.lane_y_offset - 54.0)
	var final_dmg: float = raw_dmg * (1.0 - victim.armor_reduction)

	if victim.is_blocking and (victim.facing != attacker.facing):
		var block_age: float = float(tick_count) * FIXED_DT - victim.block_start_time
		var is_perfect_parry: bool = (block_age <= 0.20)
		if is_perfect_parry:
			final_dmg *= 0.12
			victim.hit_recoil_impulse = 0.35
			attacker.hit_recoil_impulse = 0.85
			attacker.attack_cooldown += 0.35
			sfx_requested.emit("parry_clang")
			combat_event.emit("PARRY", hit_pos, int(round(final_dmg)), "PHẢN ĐÒN! -%d" % int(round(final_dmg)), Color(0.30, 0.96, 1.0))
		else:
			final_dmg *= (1.0 - victim.block_reduction)
			victim.hit_recoil_impulse = 0.55
			var block_kb: float = 14.0 if active_units.size() <= 2 else (3.0 * victim.unit_scale)
			victim.x = clampf(victim.x + attacker.facing * block_kb, arena_min_x, arena_max_x)
			sfx_requested.emit("shield_block")
			combat_event.emit("BLOCK", hit_pos, int(round(final_dmg)), "ĐỠ ĐÒN -%d" % int(round(final_dmg)), Color(0.78, 0.88, 1.0))
	else:
		victim.hp -= final_dmg
		victim.hit_flash_timer = 0.12
		victim.hit_recoil_impulse = 1.0 if is_heavy else 0.72
		var kb: float = (34.0 if is_heavy else 16.0) if active_units.size() <= 2 else ((6.0 if is_heavy else 3.5) * victim.unit_scale)
		victim.x = clampf(victim.x + attacker.facing * kb, arena_min_x, arena_max_x)

		# Brief interrupt into BLOCK_HIT flinch if victim was idle/running
		if victim.hp > 0.0 and (victim.anim_state == "IDLE" or victim.anim_state == "RUN"):
			victim.anim_state = "BLOCK_HIT"
			victim.is_blocking = false
			victim.anim_time = 0.0
			victim.anim_duration = 0.24

		if active_units.size() <= 4 and is_heavy:
			hitstop_timer = 0.042

		sfx_requested.emit("heavy_cleave" if is_heavy else "slash_hit")
		var col: Color = Color(1.0, 0.88, 0.22) if is_heavy else Color(1.0, 0.42, 0.38)
		var label: String = "💥 -%d" % int(round(final_dmg)) if is_heavy else "-%d" % int(round(final_dmg))
		combat_event.emit("HIT", hit_pos, int(round(final_dmg)), label, col)
		return_if_dead(victim, attacker.facing, ground_y)
		return

	victim.hp -= final_dmg
	return_if_dead(victim, attacker.facing, ground_y)

func return_if_dead(victim: SimUnit, knock_dir: float, ground_y: float) -> void:
	if victim.hp <= 0.0 and victim.anim_state != "DEATH":
		victim.hp = 0.0
		victim.is_blocking = false
		victim.anim_state = "DEATH"
		victim.anim_time = 0.0
		victim.anim_duration = 1.4
		victim.vx = knock_dir * 120.0
		victim.dropped_weapon_y = 0.0
		victim.dropped_weapon_rot = 0.0
		sfx_requested.emit("death")
		combat_event.emit("DEATH", Vector2(victim.x, ground_y - 70.0), 0, "HẠ GỤC!", Color(1.0, 0.30, 0.30))

# ============================================================================
# O(N) SORTED 1D SWEEP & BOUNDED FRONTLINE CACHE (Prevents O(N^2) Choke Point)
# ============================================================================

func _sort_active_units_by_x() -> void:
	var n: int = active_units.size()
	for i in range(1, n):
		var key_unit: SimUnit = active_units[i]
		var key_x: float = key_unit.x
		var j: int = i - 1
		while j >= 0 and active_units[j].x > key_x:
			active_units[j + 1] = active_units[j]
			j -= 1
		active_units[j + 1] = key_unit

func _rebuild_frontline_cache() -> void:
	var last_t1: Array[SimUnit] = []
	var last_t2: Array[SimUnit] = []
	var count_t1: Array[int] = []
	var count_t2: Array[int] = []
	for s in range(NUM_SUB_LANES):
		(_frontline_team1[s] as Array).clear()
		(_frontline_team2[s] as Array).clear()
		last_t1.append(null)
		last_t2.append(null)
		count_t1.append(0)
		count_t2.append(0)

	# Team 1 advances right -> leading units have highest X (iterate backward)
	var n: int = active_units.size()
	for i in range(n - 1, -1, -1):
		var u: SimUnit = active_units[i]
		if u.active and u.team == 1 and u.anim_state != "DEATH":
			var sl: int = u.sub_lane
			if stick_war_mode and u.unit_role == "miner":
				u.lane_rank = 0
				u.unit_ahead = null
				# Expose ungarrisoned miners to enemy targeting if no fighters protect them
				if team1_stance != 0 and (_frontline_team1[sl] as Array).is_empty():
					(_frontline_team1[sl] as Array).append(u)
				continue
			u.lane_rank = count_t1[sl]
			u.unit_ahead = last_t1[sl]
			last_t1[sl] = u
			count_t1[sl] += 1
			var arr: Array = _frontline_team1[sl]
			if arr.size() < 6:
				arr.append(u)

	# Team 2 advances left -> leading units have lowest X (iterate forward)
	for i in range(n):
		var u: SimUnit = active_units[i]
		if u.active and u.team == 2 and u.anim_state != "DEATH":
			var sl: int = u.sub_lane
			u.lane_rank = count_t2[sl]
			u.unit_ahead = last_t2[sl]
			last_t2[sl] = u
			count_t2[sl] += 1
			var arr: Array = _frontline_team2[sl]
			if arr.size() < 6:
				arr.append(u)

func _find_frontline_target(u: SimUnit) -> SimUnit:
	var enemy_lanes: Array = _frontline_team2 if u.team == 1 else _frontline_team1
	var best: SimUnit = null
	var best_score: float = 999999.0

	# Check own sub_lane first (penalty 0), then adjacent sub_lanes only if needed
	for s in range(NUM_SUB_LANES):
		var lane_penalty: float = absf(float(s - u.sub_lane)) * 300.0
		var candidates: Array = enemy_lanes[s]
		for c_idx in range(candidates.size()):
			var cand: SimUnit = candidates[c_idx]
			var d: float = absf(cand.x - u.x) + lane_penalty
			if d < best_score:
				best_score = d
				best = cand
	return best
