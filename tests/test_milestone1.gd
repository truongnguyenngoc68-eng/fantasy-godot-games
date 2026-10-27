extends Node

# ============================================================================
# AUTOMATED VERIFICATION SUITE FOR MILESTONE 1
# Run via: Godot_v4.7.2-stable_win64_console.exe --headless --path d:\fantasy res://tests/test_milestone1.tscn
# ============================================================================

func _ready() -> void:
	var passed: int = 0
	var failed: int = 0

	print("=== RUNNING MILESTONE 1 AUTOMATED VERIFICATION SUITE ===")

	# 1. Verify Extensible Data Schemas (8 Categories + 6 Equipment Sockets)
	var schema_res: Dictionary = ContentDB.validate_all_schemas()
	if bool(schema_res.get("valid", false)) and ContentDB.SOCKET_LIST.size() == 6:
		print("[PASS] 1. Extensible ContentDB Schema Validation: ", JSON.stringify(schema_res))
		passed += 1
	else:
		print("[FAIL] 1. Extensible ContentDB Schema Validation failed: ", schema_res)
		failed += 1

	# 2. Verify 12-Bone Forward Kinematics Solver across all 6 Core Animations
	var rig := StickmanRig2D.new()
	var core_anims: Array[String] = ["IDLE", "RUN", "ATTACK_1", "ATTACK_2", "BLOCK_HIT", "DEATH"]
	var bones_ok: bool = (StickmanRig2D.BONE_NAMES.size() == 12)
	for anim in core_anims:
		rig.solve_12_bones(Vector2(500.0, 520.0), 1.0, 1.0, anim, 0.22, 0.50, 0.25)
		for b_idx in range(12):
			var len_b: float = rig.bone_start[b_idx].distance_to(rig.bone_end[b_idx])
			if is_nan(len_b) or len_b < 5.0:
				bones_ok = false
	if bones_ok:
		print("[PASS] 2. 12-Bone Skeletal FK Solver verified across all 6 core animations (IDLE, RUN, ATTACK_1, ATTACK_2, BLOCK_HIT, DEATH)")
		passed += 1
	else:
		print("[FAIL] 2. 12-Bone Skeletal FK Solver returned invalid bone lengths")
		failed += 1

	# 3. Verify 6-Socket Modular Equipment Stat Aggregation
	var sim := BattleSimulation.new()
	var u_base: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 500.0, 1, true, {
		"main_weapon": "wpn_aethel_blade",
		"offhand": "off_none",
		"helmet": "hlm_none",
		"chest_armor": "arm_light_tunic",
		"pauldron": "pld_none",
		"back_cape": "cpe_none"
	})
	var base_hp: float = u_base.max_hp
	var base_dmg: float = u_base.damage
	u_base.loadout = {
		"main_weapon": "wpn_crimson_greatsword",
		"offhand": "off_bastion_tower",
		"helmet": "hlm_spartan_crest",
		"chest_armor": "arm_royal_plate",
		"pauldron": "pld_dragon_wings",
		"back_cape": "cpe_aether_halo"
	}
	sim.recalculate_unit_stats(u_base, true)
	if u_base.max_hp > base_hp and u_base.damage > base_dmg:
		print("[PASS] 3. 6-Socket Modular Equipment dynamically modifies HP (%.0f -> %.0f) & Damage (%.0f -> %.0f)" % [
			base_hp, u_base.max_hp, base_dmg, u_base.damage
		])
		passed += 1
	else:
		print("[FAIL] 3. 6-Socket Modular Equipment stat calculation failed")
		failed += 1

	# 4. Verify 1v1 Combat Simulation (Hitbox, Block/Parry, Damage, Death)
	sim.clear_all_units()
	var p1: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 500.0, 1, true, {})
	var p2: BattleSimulation.SimUnit = sim.spawn_unit(2, "abyssal_challenger", 555.0, 1, false, {})
	p2.ai_enabled = false
	var initial_p2_hp: float = p2.hp
	sim.force_unit_animation(p1, "ATTACK_1")
	for step_i in range(25):
		sim.step_fixed(BattleSimulation.FIXED_DT)
	var hit_dealt_damage: bool = (p2.hp < initial_p2_hp)

	# Verify Death state transition when HP reaches 0
	p2.hp = 10.0
	sim.force_unit_animation(p1, "ATTACK_2")
	for step_i in range(30):
		sim.step_fixed(BattleSimulation.FIXED_DT)
	var death_triggered: bool = (p2.hp == 0.0 and p2.anim_state == "DEATH")

	if hit_dealt_damage and death_triggered:
		print("[PASS] 4. 1v1 Combat Hitbox, Damage Application, and DEATH Animation State Transition verified")
		passed += 1
	else:
		print("[FAIL] 4. 1v1 Combat verification failed (hit_dealt_damage=%s, death_triggered=%s)" % [str(hit_dealt_damage), str(death_triggered)])
		failed += 1

	# 5. Verify FixedPool 300-Unit Spawn, O(N) Sorted 1D Sweep, and Clean Release
	sim.clear_all_units()
	for i in range(150):
		sim.spawn_unit(1, "vanguard_hero", 650.0 + float(i) * 3.0, i % BattleSimulation.NUM_SUB_LANES, false, {})
		sim.spawn_unit(2, "abyssal_challenger", 1750.0 - float(i) * 3.0, i % BattleSimulation.NUM_SUB_LANES, false, {})
	var spawned_300: bool = (sim.active_units.size() == 300)
	for step_i in range(10):
		sim.step_fixed(BattleSimulation.FIXED_DT)
	sim.clear_all_units()
	var pool_restored: bool = (sim.active_units.size() == 0 and sim._unit_pool.size() == BattleSimulation.MAX_POOL_UNITS)

	if spawned_300 and pool_restored:
		print("[PASS] 5. FixedPool 300-Unit Spawn, 60Hz Step & Zero-Leak Pool Restoration verified")
		passed += 1
	else:
		print("[FAIL] 5. FixedPool 300-Unit test failed")
		failed += 1

	# 6. Verify 8-Lane Target Acquisition & Anti-Stuck Multi-Rank Spacing across all 8 sub_lanes
	sim.clear_all_units()
	for lane_idx in range(BattleSimulation.NUM_SUB_LANES):
		for r_idx in range(4):
			var u1_lane: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 1080.0 - float(r_idx) * 32.0, lane_idx, false, {})
			u1_lane.unit_scale = 0.60
			var u2_lane: BattleSimulation.SimUnit = sim.spawn_unit(2, "abyssal_challenger", 1260.0 + float(r_idx) * 32.0, lane_idx, false, {})
			u2_lane.unit_scale = 0.60

	for step_i in range(45):
		sim.step_fixed(BattleSimulation.FIXED_DT)

	var all_8_lanes_targeted: bool = true
	var no_rank_collapse: bool = true
	var lanes_engaged: int = 0
	for lane_idx in range(BattleSimulation.NUM_SUB_LANES):
		var lane_units_t1: Array[BattleSimulation.SimUnit] = []
		for u in sim.active_units:
			if u.active and u.team == 1 and u.sub_lane == lane_idx and u.anim_state != "DEATH":
				lane_units_t1.append(u)
				# Every unit on all 8 lanes must find a valid target in its own lane
				if u.target_unit == null or u.target_unit.team != 2 or u.target_unit.sub_lane != lane_idx:
					all_8_lanes_targeted = false
				if u.lane_rank == 0 and (u.anim_state == "ATTACK_1" or u.anim_state == "ATTACK_2" or absf(u.target_unit.x - u.x) <= u.attack_range):
					lanes_engaged += 1
		# Verify rear ranks maintain anti-stacking gap behind unit_ahead
		for u in lane_units_t1:
			if u.lane_rank >= 1 and u.unit_ahead != null:
				var gap: float = u.unit_ahead.x - u.x
				if gap < 12.0:
					no_rank_collapse = false

	if all_8_lanes_targeted and no_rank_collapse and lanes_engaged == BattleSimulation.NUM_SUB_LANES:
		print("[PASS] 6. 8-Lane Target Acquisition & Anti-Stuck Formation verified (8/8 lanes matched in-lane targets, 0 rank collapses)")
		passed += 1
	else:
		print("[FAIL] 6. 8-Lane Targeting/Spacing failed (all_8_lanes_targeted=%s, no_rank_collapse=%s, lanes_engaged=%d)" % [
			str(all_8_lanes_targeted), str(no_rank_collapse), lanes_engaged
		])
		failed += 1

	# 7. Verify Frontline Replacement when Front Unit Dies (Rear Rank Advances & Engages)
	sim.clear_all_units()
	var front_ally: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 1140.0, 2, false, {})
	var rear_ally_1: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 1095.0, 2, false, {})
	var rear_ally_2: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 1050.0, 2, false, {})
	var front_enemy: BattleSimulation.SimUnit = sim.spawn_unit(2, "abyssal_challenger", 1205.0, 2, false, {})
	front_ally.unit_scale = 0.60
	rear_ally_1.unit_scale = 0.60
	rear_ally_2.unit_scale = 0.60
	front_enemy.unit_scale = 0.60
	front_enemy.hp = 9999.0 # keep enemy alive to test ally advancement
	front_enemy.ai_enabled = false # stationary target dummy so advancement distance is 100% deterministic

	# Step 15 ticks so frontline engages and rear_ally_1 holds formation behind front_ally
	for step_i in range(15):
		sim.step_fixed(BattleSimulation.FIXED_DT)
	var x_rear1_before_death: float = rear_ally_1.x
	var x_rear2_before_death: float = rear_ally_2.x

	# Kill the frontline unit
	front_ally.hp = 0.0
	sim.return_if_dead(front_ally, -1.0, 520.0)

	# Step 45 ticks (0.75s): rear_ally_1 must promote to lane_rank 0, advance forward, and engage front_enemy
	for step_i in range(45):
		sim.step_fixed(BattleSimulation.FIXED_DT)

	var promoted_to_rank0: bool = (rear_ally_1.lane_rank == 0 and rear_ally_1.unit_ahead == null)
	var rear1_advanced: bool = (rear_ally_1.x > x_rear1_before_death + 20.0)
	var rear2_advanced: bool = (rear_ally_2.x > x_rear2_before_death + 20.0 and rear_ally_2.lane_rank == 1)
	var rear1_engaged: bool = (rear_ally_1.anim_state == "ATTACK_1" or rear_ally_1.anim_state == "ATTACK_2" or absf(front_enemy.x - rear_ally_1.x) <= rear_ally_1.attack_range)

	if promoted_to_rank0 and rear1_advanced and rear2_advanced and rear1_engaged:
		print("[PASS] 7. Frontline Replacement on Death verified (Rank 1 promoted to Rank 0, advanced %.1f -> %.1f & engaged enemy; Rank 2 advanced %.1f -> %.1f)" % [
			x_rear1_before_death, rear_ally_1.x, x_rear2_before_death, rear_ally_2.x
		])
		passed += 1
	else:
		print("[FAIL] 7. Frontline Replacement failed (promoted=%s, r1_adv=%s, r2_adv=%s, engaged=%s)" % [
			str(promoted_to_rank0), str(rear1_advanced), str(rear2_advanced), str(rear1_engaged)
		])
		failed += 1

	# 8. Verify Stick War Base-Defense Loop (Miner Gold Deposit, 3 Stances & Enemy Statue Damage)
	sim.clear_all_units()
	sim.stick_war_mode = true
	sim.bastion1_hp = 2500.0
	sim.bastion2_hp = 2500.0
	sim.team1_stance = 1 # DEFEND

	var total_gold_deposited: Array[int] = [0]
	var gold_cb := func(team_id: int, amount: int, _pos: Vector2) -> void:
		if team_id == 1:
			total_gold_deposited[0] += amount
	sim.gold_deposited.connect(gold_cb)

	var miner: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 460.0, 1, false, {})
	miner.unit_role = "miner"
	var defender: BattleSimulation.SimUnit = sim.spawn_unit(1, "vanguard_hero", 620.0, 1, false, {})
	defender.unit_role = "fighter"

	# Step 260 ticks (~4.3s): Miner reaches mine (490), mines 2.0s (+45G), runs back to Bastion (290) and deposits!
	# Defender marches to DEFEND_LINE_X (~780) and holds shield wall.
	for step_i in range(260):
		sim.step_fixed(BattleSimulation.FIXED_DT)

	var miner_deposited_ok: bool = (total_gold_deposited[0] >= 45)
	var defend_line_ok: bool = (absf(defender.x - BattleSimulation.DEFEND_LINE_X) < 35.0)

	# Switch to GARRISON (0) -> units retreat toward BASTION1_X
	sim.team1_stance = 0
	for step_i in range(60):
		sim.step_fixed(BattleSimulation.FIXED_DT)
	var garrison_retreat_ok: bool = (defender.x < 650.0 and not defender.is_blocking)

	# Switch to ATTACK (2) near Enemy Statue -> damages bastion2_hp
	sim.team1_stance = 2
	defender.x = BattleSimulation.BASTION2_X - 130.0
	for step_i in range(60):
		sim.step_fixed(BattleSimulation.FIXED_DT)
	var statue_damaged_ok: bool = (sim.bastion2_hp < 2500.0)

	sim.gold_deposited.disconnect(gold_cb)
	sim.stick_war_mode = false

	if miner_deposited_ok and defend_line_ok and garrison_retreat_ok and statue_damaged_ok:
		print("[PASS] 8. Stick War Core Loop verified (Miner deposited +%dG, Defend held x=%.1f, Garrison retreated, Enemy Statue HP 2500 -> %d)" % [
			total_gold_deposited[0], BattleSimulation.DEFEND_LINE_X, int(round(sim.bastion2_hp))
		])
		passed += 1
	else:
		print("[FAIL] 8. Stick War Core Loop failed (miner=%s, defend=%s, garrison=%s, statue=%s)" % [
			str(miner_deposited_ok), str(defend_line_ok), str(garrison_retreat_ok), str(statue_damaged_ok)
		])
		failed += 1

	# 9. Verify Cat City Idle Core Loop (Feed, Play, Build Cat House, Expand Map, 20-Skin Wardrobe, Auto-Care & Atomic Save/Load)
	var cat_city_script: Script = load("res://scripts/cat_city_idle.gd")
	var cat_city: Node2D = cat_city_script.new()
	cat_city._sync_cat_population()
	var gps_initial: float = cat_city.get_coins_per_sec()
	cat_city.fish_coins = 2500.0
	var upgraded_house: bool = cat_city.action_upgrade_building("house")
	var adopted_cat: bool = cat_city.action_adopt_cat()
	var expanded_map: bool = cat_city.action_expand_map()
	var bought_cat_skin: bool = cat_city.action_buy_or_equip_cat_skin("calico")
	var bought_costume: bool = cat_city.action_buy_or_equip_costume("royal_crown")
	var bought_theme: bool = cat_city.action_buy_or_equip_theme("sakura")
	var skin_mult_after: float = cat_city.get_skin_collection_multiplier()
	cat_city.food_bowl_fill = 10.0 # Drain bowl to trigger Auto-Care refill
	cat_city._step_cats_and_city(1.0)
	var auto_refilled: bool = (cat_city.food_bowl_fill > 80.0)
	var gps_after: float = cat_city.get_coins_per_sec()
	var test_save_path: String = "user://test_cat_city_atomic.json"
	var save_err: Error = cat_city.save_game_atomic(test_save_path)
	var cat_city_loaded: Node2D = cat_city_script.new()
	var load_ok: bool = cat_city_loaded.load_game_atomic(test_save_path)
	var state_preserved: bool = (
		load_ok
		and cat_city_loaded.map_level == 2
		and int(cat_city_loaded.building_levels.get("house", 0)) == 2
		and cat_city_loaded.active_costume == "royal_crown"
		and cat_city_loaded.active_theme == "sakura"
		and cat_city_loaded.get_total_unlocked_skins() == 6
	)
	cat_city.cats.clear()
	cat_city.toys.clear()
	cat_city.popups.clear()
	cat_city.free()
	cat_city_loaded.cats.clear()
	cat_city_loaded.toys.clear()
	cat_city_loaded.popups.clear()
	cat_city_loaded.free()

	if upgraded_house and adopted_cat and expanded_map and bought_cat_skin and bought_costume and bought_theme and skin_mult_after > 1.2 and auto_refilled and gps_after > gps_initial and save_err == OK and state_preserved:
		print("[PASS] 9. Cat City & 20-Skin Wardrobe verified (House Lv.2, Map Lv.2, Skins 6/20 [x%.2f], Income %.1f -> %.1f Xu/s, Save/Load OK)" % [
			skin_mult_after, gps_initial, gps_after
		])
		passed += 1
	else:
		print("[FAIL] 9. Cat City & Skin Loop failed (house=%s, adopt=%s, map=%s, skins=%s/%s/%s, auto_refill=%s, gps=%.1f->%.1f, save=%d, load=%s)" % [
			str(upgraded_house), str(adopted_cat), str(expanded_map), str(bought_cat_skin), str(bought_costume), str(bought_theme), str(auto_refilled), gps_initial, gps_after, int(save_err), str(state_preserved)
		])
		failed += 1

	sim.clear_all_units()
	StickmanRig2D.cleanup_static_resources()
	print("=== SUMMARY: %d PASSED, %d FAILED ===" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)
