extends RefCounted
class_name StickmanRig2D

# ============================================================================
# HIGH-CRAFT 12-BONE MODULAR FANTASY STICKMAN SKELETAL RIG & RENDERER
# Solves 12 articulated bone transforms + 6 equipment attachment sockets and
# renders sculpted, cel-shaded fantasy stickman limbs, armor, capes, and
# multi-layered weapon slash ribbons.
# ============================================================================

const BONE_NAMES: Array[String] = [
	"1.Hip", "2.LowerSpine", "3.UpperChest", "4.Head",
	"5.UpperArm_L", "6.Forearm_L", "7.UpperArm_R", "8.Forearm_R",
	"9.Thigh_L", "10.Shin_L", "11.Thigh_R", "12.Shin_R"
]

# Solved world/local positions of the 12 bones for the current unit
var bone_start: PackedVector2Array = PackedVector2Array()
var bone_end: PackedVector2Array = PackedVector2Array()
var bone_angle: PackedFloat32Array = PackedFloat32Array()

# Pre-allocated polygon scratch buffers (Eliminates thousands of per-frame heap allocations)
var _quad_buf: PackedVector2Array = PackedVector2Array()
var _hex_buf: PackedVector2Array = PackedVector2Array()

func _init() -> void:
	bone_start.resize(12)
	bone_end.resize(12)
	bone_angle.resize(12)
	_quad_buf.resize(4)
	_hex_buf.resize(6)

# Solves the 12-bone Forward Kinematics hierarchy for any unit & animation state
func solve_12_bones(
	root_pos: Vector2,
	facing: float,
	s: float,
	anim_state: String,
	anim_time: float,
	anim_duration: float,
	recoil_impulse: float
) -> void:
	var t_norm: float = clampf(anim_time / maxf(0.01, anim_duration), 0.0, 1.0)

	# Local joint angles (in radians, where 0 = straight down for limbs, -PI/2 = straight up for spine)
	var hip_offset := Vector2(0.0, -44.0 * s)
	var spine_lean: float = 0.08
	var chest_lean: float = 0.10
	var head_tilt: float = 0.04

	var uarm_l: float = 0.35
	var farm_l: float = -0.55
	var uarm_r: float = -0.25
	var farm_r: float = -0.65

	var thigh_l: float = -0.22
	var shin_l: float = 0.25
	var thigh_r: float = 0.24
	var shin_r: float = 0.18

	match anim_state:
		"IDLE":
			var breath: float = sin(anim_time * 3.6)
			hip_offset.y = (-44.0 + breath * 1.8) * s
			spine_lean = 0.08 + breath * 0.03
			chest_lean = 0.12 + breath * 0.04
			head_tilt = 0.05 - breath * 0.03
			uarm_l = 0.42 + breath * 0.05
			farm_l = -0.68
			uarm_r = -0.30 - breath * 0.06
			farm_r = -0.78 + breath * 0.05
			thigh_l = -0.24
			shin_l = 0.26
			thigh_r = 0.26
			shin_r = 0.20

		"RUN":
			var cycle: float = anim_time * 11.5
			var s_wave: float = sin(cycle)
			var c_wave: float = cos(cycle)
			hip_offset.y = (-42.0 - absf(c_wave) * 4.5) * s
			hip_offset.x = facing * 3.0 * s
			spine_lean = 0.32 + absf(s_wave) * 0.06
			chest_lean = 0.38 + absf(s_wave) * 0.08
			head_tilt = 0.14

			thigh_r = s_wave * 0.78
			shin_r = maxf(0.10, -c_wave * 0.85 + 0.38)
			thigh_l = -s_wave * 0.78
			shin_l = maxf(0.10, c_wave * 0.85 + 0.38)

			uarm_r = -s_wave * 0.62 - 0.15
			farm_r = -0.95 - s_wave * 0.20
			uarm_l = s_wave * 0.58 + 0.25
			farm_l = -0.85

		"ATTACK_1":
			# 3-Phase Overhead Diagonal Cleave: Anticipation (0..0.32) -> Strike (0.32..0.58) -> Recovery (0.58..1.0)
			if t_norm < 0.32:
				var p: float = smoothstep(0.0, 0.32, t_norm)
				hip_offset.x = lerpf(0.0, -6.0 * s * facing, p)
				hip_offset.y = (-44.0 + p * 3.0) * s
				spine_lean = lerpf(0.08, -0.28, p)
				chest_lean = lerpf(0.10, -0.38, p)
				uarm_r = lerpf(-0.30, -2.35, p)
				farm_r = lerpf(-0.78, -0.45, p)
				uarm_l = lerpf(0.42, -0.20, p)
				thigh_r = lerpf(0.26, 0.45, p)
				thigh_l = lerpf(-0.24, -0.42, p)
			elif t_norm < 0.58:
				var p: float = smoothstep(0.32, 0.58, t_norm)
				hip_offset.x = lerpf(-6.0 * s * facing, 14.0 * s * facing, p)
				hip_offset.y = (-41.0 + p * 4.0) * s
				spine_lean = lerpf(-0.28, 0.46, p)
				chest_lean = lerpf(-0.38, 0.58, p)
				uarm_r = lerpf(-2.35, 0.85, p)
				farm_r = lerpf(-0.45, 0.18, p)
				uarm_l = lerpf(-0.20, -0.65, p)
				thigh_r = lerpf(0.45, 0.68, p)
				shin_r = lerpf(0.25, 0.52, p)
				thigh_l = lerpf(-0.42, -0.58, p)
			else:
				var p: float = smoothstep(0.58, 1.0, t_norm)
				hip_offset.x = lerpf(14.0 * s * facing, 0.0, p)
				hip_offset.y = lerpf(-37.0 * s, -44.0 * s, p)
				spine_lean = lerpf(0.46, 0.08, p)
				chest_lean = lerpf(0.58, 0.12, p)
				uarm_r = lerpf(0.85, -0.30, p)
				farm_r = lerpf(0.18, -0.78, p)
				uarm_l = lerpf(-0.65, 0.42, p)
				thigh_r = lerpf(0.68, 0.26, p)
				shin_r = lerpf(0.52, 0.20, p)
				thigh_l = lerpf(-0.58, -0.24, p)

		"ATTACK_2":
			# Heavy Low-Crouch Lunge & Rising Fang Cleave
			if t_norm < 0.28:
				var p: float = smoothstep(0.0, 0.28, t_norm)
				hip_offset.x = lerpf(0.0, -10.0 * s * facing, p)
				hip_offset.y = lerpf(-44.0 * s, -35.0 * s, p)
				spine_lean = lerpf(0.10, 0.42, p)
				chest_lean = lerpf(0.12, 0.50, p)
				uarm_r = lerpf(-0.30, 0.95, p)
				farm_r = lerpf(-0.78, 0.35, p)
				thigh_r = lerpf(0.26, -0.35, p)
				thigh_l = lerpf(-0.24, 0.55, p)
			elif t_norm < 0.56:
				var p: float = smoothstep(0.28, 0.56, t_norm)
				hip_offset.x = lerpf(-10.0 * s * facing, 22.0 * s * facing, p)
				hip_offset.y = lerpf(-35.0 * s, -39.0 * s, p)
				spine_lean = lerpf(0.42, 0.25, p)
				chest_lean = lerpf(0.50, 0.30, p)
				uarm_r = lerpf(0.95, -1.75, p)
				farm_r = lerpf(0.35, -0.15, p)
				uarm_l = lerpf(0.30, -0.80, p)
				thigh_r = lerpf(-0.35, 0.82, p)
				shin_r = lerpf(0.20, 0.65, p)
				thigh_l = lerpf(0.55, -0.72, p)
				shin_l = 0.12
			else:
				var p: float = smoothstep(0.56, 1.0, t_norm)
				hip_offset.x = lerpf(22.0 * s * facing, 0.0, p)
				hip_offset.y = lerpf(-39.0 * s, -44.0 * s, p)
				spine_lean = lerpf(0.25, 0.08, p)
				chest_lean = lerpf(0.30, 0.12, p)
				uarm_r = lerpf(-1.75, -0.30, p)
				farm_r = lerpf(-0.15, -0.78, p)
				thigh_r = lerpf(0.82, 0.26, p)
				shin_r = lerpf(0.65, 0.20, p)
				thigh_l = lerpf(-0.72, -0.24, p)

		"BLOCK_HIT":
			# Braced Shield/Weapon Guard + Additive Hit Recoil
			hip_offset.x = -4.0 * s * facing
			hip_offset.y = -40.0 * s
			spine_lean = -0.12
			chest_lean = -0.15
			head_tilt = 0.18
			uarm_l = 0.72
			farm_l = -1.45
			uarm_r = 0.35
			farm_r = -1.35
			thigh_r = 0.48
			shin_r = 0.38
			thigh_l = -0.45
			shin_l = 0.25

		"DEATH":
			var p: float = clampf(anim_time / 0.55, 0.0, 1.0)
			var ease_p: float = 1.0 - pow(1.0 - p, 3.0)
			hip_offset.x = -18.0 * s * facing * ease_p
			hip_offset.y = lerpf(-44.0 * s, -8.0 * s, ease_p)
			spine_lean = lerpf(0.08, -1.42, ease_p)
			chest_lean = lerpf(0.10, -1.52, ease_p)
			head_tilt = lerpf(0.04, -1.65, ease_p)
			uarm_r = lerpf(-0.30, -1.35, ease_p)
			farm_r = lerpf(-0.78, -0.10, ease_p)
			uarm_l = lerpf(0.42, -1.15, ease_p)
			farm_l = lerpf(-0.68, -0.20, ease_p)
			thigh_r = lerpf(0.26, 1.15, ease_p)
			shin_r = lerpf(0.20, 0.35, ease_p)
			thigh_l = lerpf(-0.24, 0.85, ease_p)
			shin_l = lerpf(0.26, 0.50, ease_p)

	# Apply additive hit recoil impulse to upper body
	if recoil_impulse > 0.01:
		spine_lean -= recoil_impulse * 0.38
		chest_lean -= recoil_impulse * 0.48
		head_tilt -= recoil_impulse * 0.55

	# Convert local angles into world space using `facing` (+1 right, -1 left)
	var hip_world: Vector2 = root_pos + hip_offset

	# 1. BONE_HIP (Pelvis segment)
	var a_hip: float = -PI * 0.5 + spine_lean * 0.5 * facing
	var p_waist: Vector2 = hip_world + Vector2.from_angle(a_hip) * (10.0 * s)
	bone_start[0] = hip_world
	bone_end[0] = p_waist
	bone_angle[0] = a_hip

	# 2. BONE_LOWER_SPINE
	var a_spine: float = -PI * 0.5 + spine_lean * facing
	var p_mid_chest: Vector2 = p_waist + Vector2.from_angle(a_spine) * (14.0 * s)
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
	var p_head_top: Vector2 = p_neck + Vector2.from_angle(a_head) * (15.0 * s)
	bone_start[3] = p_neck
	bone_end[3] = p_head_top
	bone_angle[3] = a_head

	var shoulder_anchor: Vector2 = p_mid_chest.lerp(p_neck, 0.78)

	# 5 & 6. BONE_UPPER_ARM_L & BONE_FOREARM_L (Back/Offhand arm)
	var a_uarm_l: float = PI * 0.5 - uarm_l * facing
	var p_elbow_l: Vector2 = shoulder_anchor + Vector2.from_angle(a_uarm_l) * (17.0 * s)
	bone_start[4] = shoulder_anchor
	bone_end[4] = p_elbow_l
	bone_angle[4] = a_uarm_l

	var a_farm_l: float = a_uarm_l + farm_l * facing
	var p_hand_l: Vector2 = p_elbow_l + Vector2.from_angle(a_farm_l) * (16.0 * s)
	bone_start[5] = p_elbow_l
	bone_end[5] = p_hand_l
	bone_angle[5] = a_farm_l

	# 7 & 8. BONE_UPPER_ARM_R & BONE_FOREARM_R (Front/Weapon arm)
	var a_uarm_r: float = PI * 0.5 - uarm_r * facing
	var p_elbow_r: Vector2 = shoulder_anchor + Vector2.from_angle(a_uarm_r) * (17.5 * s)
	bone_start[6] = shoulder_anchor
	bone_end[6] = p_elbow_r
	bone_angle[6] = a_uarm_r

	var a_farm_r: float = a_uarm_r + farm_r * facing
	var p_hand_r: Vector2 = p_elbow_r + Vector2.from_angle(a_farm_r) * (16.5 * s)
	bone_start[7] = p_elbow_r
	bone_end[7] = p_hand_r
	bone_angle[7] = a_farm_r

	# 9 & 10. BONE_THIGH_L & BONE_SHIN_L (Back leg)
	var a_thigh_l: float = PI * 0.5 - thigh_l * facing
	var p_knee_l: Vector2 = hip_world + Vector2.from_angle(a_thigh_l) * (21.0 * s)
	bone_start[8] = hip_world
	bone_end[8] = p_knee_l
	bone_angle[8] = a_thigh_l

	var a_shin_l: float = a_thigh_l + shin_l * facing
	var p_foot_l: Vector2 = p_knee_l + Vector2.from_angle(a_shin_l) * (21.5 * s)
	bone_start[9] = p_knee_l
	bone_end[9] = p_foot_l
	bone_angle[9] = a_shin_l

	# 11 & 12. BONE_THIGH_R & BONE_SHIN_R (Front leg)
	var a_thigh_r: float = PI * 0.5 - thigh_r * facing
	var p_knee_r: Vector2 = hip_world + Vector2.from_angle(a_thigh_r) * (21.0 * s)
	bone_start[10] = hip_world
	bone_end[10] = p_knee_r
	bone_angle[10] = a_thigh_r

	var a_shin_r: float = a_thigh_r + shin_r * facing
	var p_foot_r: Vector2 = p_knee_r + Vector2.from_angle(a_shin_r) * (21.5 * s)
	bone_start[11] = p_knee_r
	bone_end[11] = p_foot_r
	bone_angle[11] = a_shin_r

# Renders the complete 12-bone character + 6 modular sockets onto `canvas`
func draw_character(
	canvas: CanvasItem,
	unit: BattleSimulation.SimUnit,
	render_pos: Vector2,
	show_debug_bones: bool = false,
	lod_simplified: bool = false
) -> void:
	var s: float = unit.unit_scale
	var facing: float = unit.facing

	solve_12_bones(
		render_pos,
		facing,
		s,
		unit.anim_state,
		unit.anim_time,
		unit.anim_duration,
		unit.hit_recoil_impulse
	)

	var body_col: Color = Color.WHITE if unit.hit_flash_timer > 0.0 else unit.body_color
	var hi_col: Color = Color.WHITE if unit.hit_flash_timer > 0.0 else unit.limb_highlight
	var rim_col: Color = unit.eye_color.darkened(0.25)

	# Ground Contact Shadow (uses quad in crowd LOD to avoid breaking polygon batching)
	if lod_simplified:
		_quad_buf[0] = render_pos + Vector2(-18.0 * s, -2.0 * s)
		_quad_buf[1] = render_pos + Vector2(18.0 * s, -2.0 * s)
		_quad_buf[2] = render_pos + Vector2(18.0 * s, 5.0 * s)
		_quad_buf[3] = render_pos + Vector2(-18.0 * s, 5.0 * s)
		canvas.draw_colored_polygon(_quad_buf, Color(0.0, 0.0, 0.0, 0.35))
	else:
		canvas.draw_circle(render_pos + Vector2(0.0, 2.0), 20.0 * s, Color(0.0, 0.0, 0.0, 0.38))

	# --- SOCKET 6: BACK CAPE / AETHER HALO (Drawn behind body) ---
	var cape_id: String = str(unit.loadout.get(ContentDB.SOCKET_BACK_CAPE, "cpe_none"))
	if cape_id != "cpe_none" and ContentDB.EQUIPMENT.has(cape_id):
		_draw_socket_back_cape(canvas, ContentDB.EQUIPMENT[cape_id], bone_end[2], bone_start[0], facing, s, unit.cape_wave_phase)

	# --- BACK LIMBS (Left Leg: Bones 9 & 10 | Left Arm: Bones 5 & 6) ---
	var back_body_col: Color = body_col.darkened(0.22)
	var back_hi_col: Color = hi_col.darkened(0.22)
	_draw_sculpted_limb(canvas, bone_start[8], bone_end[8], 5.6 * s, 4.8 * s, 3.8 * s, back_body_col, back_hi_col, rim_col, lod_simplified)
	_draw_sculpted_limb(canvas, bone_start[9], bone_end[9], 4.4 * s, 4.8 * s, 3.2 * s, back_body_col, back_hi_col, rim_col, lod_simplified)
	_draw_boot_foot(canvas, bone_end[9], bone_angle[9], facing, s * 0.92, back_hi_col)

	_draw_sculpted_limb(canvas, bone_start[4], bone_end[4], 4.6 * s, 4.0 * s, 3.2 * s, back_body_col, back_hi_col, rim_col, lod_simplified)
	_draw_sculpted_limb(canvas, bone_start[5], bone_end[5], 3.8 * s, 3.6 * s, 2.8 * s, back_body_col, back_hi_col, rim_col, lod_simplified)

	# --- TORSO & SPINE (Bones 1, 2, 3: Hip -> LowerSpine -> UpperChest) ---
	_draw_sculpted_torso(canvas, bone_start[0], bone_end[1], bone_end[2], facing, s, body_col, hi_col, rim_col)

	# --- SOCKET 4: CHEST ARMOR (Attached to LowerSpine & UpperChest) ---
	var armor_id: String = str(unit.loadout.get(ContentDB.SOCKET_CHEST_ARMOR, "arm_light_tunic"))
	if ContentDB.EQUIPMENT.has(armor_id):
		_draw_socket_chest_armor(canvas, ContentDB.EQUIPMENT[armor_id], bone_start[0], bone_end[1], bone_end[2], facing, s)

	# --- FRONT LEG (Right Leg: Bones 11 & 12) ---
	_draw_sculpted_limb(canvas, bone_start[10], bone_end[10], 6.0 * s, 5.2 * s, 4.0 * s, body_col, hi_col, rim_col, lod_simplified)
	_draw_sculpted_limb(canvas, bone_start[11], bone_end[11], 4.6 * s, 5.2 * s, 3.4 * s, body_col, hi_col, rim_col, lod_simplified)
	_draw_boot_foot(canvas, bone_end[11], bone_angle[11], facing, s, hi_col)

	# --- HEAD & SOCKET 3: HELMET (Bone 4) ---
	_draw_sculpted_head_and_helmet(canvas, unit, bone_start[3], bone_end[3], bone_angle[3], facing, s)

	# --- SOCKET 2: OFFHAND SHIELD / DAGGER (Attached to Bone 6: Forearm_L) ---
	var off_id: String = str(unit.loadout.get(ContentDB.SOCKET_OFFHAND, "off_none"))
	if off_id != "off_none" and ContentDB.EQUIPMENT.has(off_id):
		_draw_socket_offhand(canvas, ContentDB.EQUIPMENT[off_id], bone_end[5], bone_angle[5], facing, s, unit.is_blocking)

	# --- SOCKET 1: MAIN WEAPON & SLASH RIBBON (Attached to Bone 8: Forearm_R) ---
	var wpn_id: String = str(unit.loadout.get(ContentDB.SOCKET_MAIN_WEAPON, "wpn_aethel_blade"))
	if ContentDB.EQUIPMENT.has(wpn_id):
		_draw_socket_main_weapon(canvas, ContentDB.EQUIPMENT[wpn_id], unit, bone_end[7], bone_angle[7], bone_start[6], facing, s)

	# --- FRONT ARM (Right Arm: Bones 7 & 8) & SOCKET 5: PAULDRON ---
	_draw_sculpted_limb(canvas, bone_start[6], bone_end[6], 5.0 * s, 4.4 * s, 3.5 * s, body_col, hi_col, rim_col, lod_simplified)
	_draw_sculpted_limb(canvas, bone_start[7], bone_end[7], 4.2 * s, 4.0 * s, 3.2 * s, body_col, hi_col, rim_col, lod_simplified)
	canvas.draw_circle(bone_end[7], 3.8 * s, hi_col.lightened(0.15))

	var pld_id: String = str(unit.loadout.get(ContentDB.SOCKET_PAULDRON, "pld_none"))
	if pld_id != "pld_none" and ContentDB.EQUIPMENT.has(pld_id):
		_draw_socket_pauldron(canvas, ContentDB.EQUIPMENT[pld_id], bone_start[6], bone_angle[6], facing, s)

	# --- OPTIONAL 12-BONE DEBUG SKELETON OVERLAY ---
	if show_debug_bones:
		_draw_debug_skeleton(canvas, s)

func _draw_sculpted_limb(
	canvas: CanvasItem,
	p0: Vector2,
	p1: Vector2,
	r0: float,
	r_mid: float,
	r1: float,
	base_col: Color,
	hi_col: Color,
	rim_col: Color,
	lod_simplified: bool
) -> void:
	var dir: Vector2 = (p1 - p0).normalized()
	var n := Vector2(-dir.y, dir.x)
	var mid: Vector2 = p0.lerp(p1, 0.45)

	if lod_simplified:
		_quad_buf[0] = p0 + n * r0
		_quad_buf[1] = p1 + n * r1
		_quad_buf[2] = p1 - n * r1
		_quad_buf[3] = p0 - n * r0
		canvas.draw_colored_polygon(_quad_buf, base_col)
		return

	# 6-point sculpted anatomical taper polygon (reusing _hex_buf)
	_hex_buf[0] = p0 + n * r0
	_hex_buf[1] = mid + n * r_mid
	_hex_buf[2] = p1 + n * r1
	_hex_buf[3] = p1 - n * r1
	_hex_buf[4] = mid - n * r_mid
	_hex_buf[5] = p0 - n * r0
	canvas.draw_colored_polygon(_hex_buf, base_col)

	# Inner cel-shaded highlight strip on the upper/front side
	_hex_buf[0] = p0 + n * (r0 * 0.85)
	_hex_buf[1] = mid + n * (r_mid * 0.85)
	_hex_buf[2] = p1 + n * (r1 * 0.85)
	_hex_buf[3] = p1 + n * (r1 * 0.10)
	_hex_buf[4] = mid + n * (r_mid * 0.10)
	_hex_buf[5] = p0 + n * (r0 * 0.10)
	canvas.draw_colored_polygon(_hex_buf, hi_col)
	canvas.draw_line(p0 + n * r0, p1 + n * r1, rim_col, 1.3)
	canvas.draw_circle(p0, r0 * 0.88, base_col)

func _draw_boot_foot(canvas: CanvasItem, ankle: Vector2, shin_angle: float, facing: float, s: float, col: Color) -> void:
	var tilt: float = clampf((shin_angle - PI * 0.5) * 0.25, -0.45, 0.45)
	var ux := Vector2(facing, 0.0).rotated(tilt)
	var uy := Vector2(0.0, 1.0).rotated(tilt)
	_quad_buf[0] = ankle - ux * (3.5 * s) - uy * (2.2 * s)
	_quad_buf[1] = ankle + ux * (8.5 * s) - uy * (1.2 * s)
	_quad_buf[2] = ankle + ux * (10.0 * s) + uy * (3.8 * s)
	_quad_buf[3] = ankle - ux * (4.0 * s) + uy * (3.8 * s)
	canvas.draw_colored_polygon(_quad_buf, col.darkened(0.15))

func _draw_sculpted_torso(
	canvas: CanvasItem,
	p_hip: Vector2,
	p_waist: Vector2,
	p_neck: Vector2,
	facing: float,
	s: float,
	body_col: Color,
	hi_col: Color,
	rim_col: Color
) -> void:
	var dir: Vector2 = (p_neck - p_hip).normalized()
	var n := Vector2(-dir.y, dir.x)
	var poly := PackedVector2Array([
		p_hip - n * (5.2 * s),
		p_waist - n * (6.2 * s),
		p_neck - n * (9.2 * s),
		p_neck + n * (9.2 * s),
		p_waist + n * (6.2 * s),
		p_hip + n * (5.2 * s)
	])
	canvas.draw_colored_polygon(poly, body_col)

	var chest_hi := PackedVector2Array([
		p_waist,
		p_neck,
		p_neck + n * (8.5 * s * facing),
		p_waist + n * (5.5 * s * facing)
	])
	canvas.draw_colored_polygon(chest_hi, hi_col)
	canvas.draw_line(p_waist + n * (5.5 * s * facing), p_neck + n * (8.5 * s * facing), rim_col, 1.5)

func _draw_sculpted_head_and_helmet(
	canvas: CanvasItem,
	unit: BattleSimulation.SimUnit,
	p_neck: Vector2,
	p_top: Vector2,
	a_head: float,
	facing: float,
	s: float
) -> void:
	var center: Vector2 = p_neck.lerp(p_top, 0.55)
	var dir := Vector2.from_angle(a_head)
	var n := Vector2(-dir.y, dir.x) * facing

	# Sculpted angular-oval fantasy stickman head
	var head_poly := PackedVector2Array([
		center - dir * (9.5 * s) - n * (4.0 * s),
		center - n * (9.2 * s),
		center + dir * (9.5 * s) - n * (5.5 * s),
		center + dir * (10.2 * s) + n * (5.5 * s),
		center + n * (9.8 * s),
		center - dir * (9.5 * s) + n * (6.2 * s)
	])
	var b_col: Color = Color.WHITE if unit.hit_flash_timer > 0.0 else unit.body_color
	canvas.draw_colored_polygon(head_poly, b_col)
	canvas.draw_polyline(head_poly, unit.limb_highlight.lightened(0.15), 1.6 * s)

	# Fierce Glowing Almond Eye Visor
	var eye_p0: Vector2 = center + n * (2.5 * s) + dir * (1.2 * s)
	var eye_p1: Vector2 = center + n * (8.2 * s) + dir * (2.6 * s)
	canvas.draw_line(eye_p0, eye_p1, unit.eye_color, 3.0 * s)
	canvas.draw_line(eye_p0, eye_p1, Color.WHITE, 1.3 * s)

	# --- SOCKET 3: HELMET ---
	var hlm_id: String = str(unit.loadout.get(ContentDB.SOCKET_HELMET, "hlm_none"))
	if hlm_id == "hlm_none" or not ContentDB.EQUIPMENT.has(hlm_id):
		return
	var hlm: Dictionary = ContentDB.EQUIPMENT[hlm_id]
	var p_col: Color = hlm["primary_color"]
	var pl_col: Color = hlm["plume_color"]
	var style: String = str(hlm["style"])

	if style == "KNIGHT_VISOR":
		var visor := PackedVector2Array([
			center + dir * (11.5 * s) - n * (8.5 * s),
			center + dir * (12.5 * s) + n * (7.5 * s),
			center + dir * (2.0 * s) + n * (11.2 * s),
			center + dir * (3.5 * s) - n * (9.5 * s)
		])
		canvas.draw_colored_polygon(visor, p_col)
		canvas.draw_line(center + dir * (12.0 * s), center + dir * (18.0 * s) - n * (11.0 * s), pl_col, 3.8 * s)
	elif style == "SPARTAN_CREST":
		# Flowing golden crest + crimson horsehair plume
		var crest := PackedVector2Array([
			center + dir * (10.5 * s) - n * (8.0 * s),
			center + dir * (11.8 * s) + n * (8.5 * s),
			center + dir * (3.0 * s) + n * (10.2 * s),
			center + dir * (3.0 * s) - n * (9.0 * s)
		])
		canvas.draw_colored_polygon(crest, p_col)
		var wave: float = sin(unit.cape_wave_phase) * 3.5 * s
		var plume := PackedVector2Array([
			center + dir * (11.5 * s) + n * (7.0 * s),
			center + dir * (22.0 * s) + n * (2.0 * s),
			center + dir * (20.0 * s) - n * (15.0 * s) + Vector2(0, wave),
			center + dir * (6.0 * s) - n * (22.0 * s) + Vector2(0, wave * 1.4),
			center + dir * (8.0 * s) - n * (8.0 * s)
		])
		canvas.draw_colored_polygon(plume, pl_col)
	elif style == "DEMON_HORNS":
		var crown := PackedVector2Array([
			center + dir * (8.5 * s) - n * (8.0 * s),
			center + dir * (10.0 * s) + n * (9.0 * s),
			center + dir * (4.0 * s) + n * (9.5 * s),
			center + dir * (4.0 * s) - n * (8.0 * s)
		])
		canvas.draw_colored_polygon(crown, p_col)
		# Curved twin horns
		var h1 := PackedVector2Array([
			center + dir * (8.0 * s) + n * (3.0 * s),
			center + dir * (21.0 * s) + n * (11.0 * s),
			center + dir * (10.0 * s) + n * (7.5 * s)
		])
		var h2 := PackedVector2Array([
			center + dir * (8.0 * s) - n * (2.0 * s),
			center + dir * (19.0 * s) - n * (12.0 * s),
			center + dir * (9.0 * s) - n * (7.0 * s)
		])
		canvas.draw_colored_polygon(h1, pl_col)
		canvas.draw_colored_polygon(h2, pl_col.darkened(0.2))

func _draw_socket_chest_armor(
	canvas: CanvasItem,
	arm: Dictionary,
	p_hip: Vector2,
	p_waist: Vector2,
	p_neck: Vector2,
	facing: float,
	s: float
) -> void:
	var dir: Vector2 = (p_neck - p_waist).normalized()
	var n := Vector2(-dir.y, dir.x) * facing
	var p_col: Color = arm["primary_color"]
	var c_col: Color = arm["core_color"]
	var style: String = str(arm["style"])

	if style == "CUIRASS" or style == "HEAVY_PLATE":
		var plate := PackedVector2Array([
			p_waist - n * (6.8 * s),
			p_neck - n * (10.2 * s),
			p_neck + n * (10.6 * s),
			p_waist + n * (7.2 * s)
		])
		canvas.draw_colored_polygon(plate, p_col)
		canvas.draw_polyline(plate, c_col, 1.8 * s)
		if style == "HEAVY_PLATE":
			# Waist tassets
			var tasset := PackedVector2Array([
				p_waist - n * (7.5 * s),
				p_waist + n * (8.0 * s),
				p_hip + n * (9.5 * s),
				p_hip - n * (8.5 * s)
			])
			canvas.draw_colored_polygon(tasset, p_col.darkened(0.18))

	# Glowing Aethel Power Core on chest
	var core_pos: Vector2 = p_waist.lerp(p_neck, 0.58) + n * (2.5 * s)
	canvas.draw_circle(core_pos, 4.5 * s, Color(c_col.r, c_col.g, c_col.b, 0.45))
	var diamond := PackedVector2Array([
		core_pos + dir * (4.2 * s),
		core_pos + n * (3.2 * s),
		core_pos - dir * (4.2 * s),
		core_pos - n * (3.2 * s)
	])
	canvas.draw_colored_polygon(diamond, c_col.lightened(0.25))

func _draw_socket_pauldron(
	canvas: CanvasItem,
	pld: Dictionary,
	p_shoulder: Vector2,
	a_uarm: float,
	facing: float,
	s: float
) -> void:
	var p_col: Color = pld["primary_color"]
	var t_col: Color = pld["trim_color"]
	var style: String = str(pld["style"])
	var dir := Vector2.from_angle(a_uarm)
	var n := Vector2(-dir.y, dir.x) * facing

	if style == "KNIGHT_SPAULDER":
		var sp := PackedVector2Array([
			p_shoulder - dir * (4.5 * s) - n * (6.5 * s),
			p_shoulder - dir * (3.0 * s) + n * (8.0 * s),
			p_shoulder + dir * (9.0 * s) + n * (6.0 * s),
			p_shoulder + dir * (7.0 * s) - n * (5.5 * s)
		])
		canvas.draw_colored_polygon(sp, p_col)
		canvas.draw_polyline(sp, t_col, 1.8 * s)
	elif style == "WINGED_PAULDRON":
		var wp := PackedVector2Array([
			p_shoulder - dir * (8.5 * s) - n * (11.0 * s),
			p_shoulder - dir * (3.5 * s) + n * (9.0 * s),
			p_shoulder + dir * (10.5 * s) + n * (6.5 * s),
			p_shoulder + dir * (6.0 * s) - n * (6.5 * s)
		])
		canvas.draw_colored_polygon(wp, p_col)
		canvas.draw_polyline(wp, t_col, 2.0 * s)

func _draw_socket_back_cape(
	canvas: CanvasItem,
	cpe: Dictionary,
	p_neck: Vector2,
	p_hip: Vector2,
	facing: float,
	s: float,
	wave_phase: float
) -> void:
	var p_col: Color = cpe["primary_color"]
	var s_col: Color = cpe["secondary_color"]
	var style: String = str(cpe["style"])

	if style == "AETHER_HALO":
		var halo_center: Vector2 = p_neck + Vector2(-facing * 10.0 * s, -8.0 * s)
		canvas.draw_arc(halo_center, 22.0 * s, 0.0, TAU, 24, p_col, 3.0 * s)
		canvas.draw_arc(halo_center, 17.0 * s, wave_phase, wave_phase + 3.8, 16, s_col, 2.0 * s)
		return

	var w1: float = sin(wave_phase) * 5.0 * s
	var w2: float = cos(wave_phase * 0.85) * 7.0 * s
	var len_x: float = 30.0 * s if style == "SCARF" else 38.0 * s
	var drop_y: float = 14.0 * s if style == "SCARF" else 38.0 * s

	var p0: Vector2 = p_neck + Vector2(-facing * 3.0 * s, 2.0 * s)
	var p1: Vector2 = p_neck + Vector2(-facing * len_x, drop_y * 0.45 + w1)
	var p2: Vector2 = p_hip + Vector2(-facing * (len_x * 0.85), drop_y * 0.55 + w2)
	var p3: Vector2 = p_hip + Vector2(-facing * 4.0 * s, -2.0 * s)

	var cape_poly := PackedVector2Array([p0, p1, p2, p3])
	canvas.draw_colored_polygon(cape_poly, p_col)
	canvas.draw_line(p0, p1, s_col, 2.0 * s)

func _draw_socket_offhand(
	canvas: CanvasItem,
	off: Dictionary,
	p_hand_l: Vector2,
	a_farm_l: float,
	facing: float,
	s: float,
	is_blocking: bool
) -> void:
	var p_col: Color = off["primary_color"]
	var t_col: Color = off["trim_color"]
	var style: String = str(off["style"])

	if style == "OFF_BLADE":
		var dir := Vector2.from_angle(a_farm_l)
		var n := Vector2(-dir.y, dir.x) * facing
		var tip: Vector2 = p_hand_l + dir * (28.0 * s)
		var blade := PackedVector2Array([p_hand_l - n * (2.5 * s), p_hand_l + n * (3.2 * s), tip])
		canvas.draw_colored_polygon(blade, p_col)
		canvas.draw_line(p_hand_l, tip, t_col, 1.8 * s)
		return

	# Kite Shield or Tower Shield
	var h_half: float = 16.0 * s if style == "KITE_SHIELD" else 22.0 * s
	var w_half: float = 8.0 * s if style == "KITE_SHIELD" else 10.5 * s
	var c: Vector2 = p_hand_l + Vector2(facing * 5.0 * s, 0.0)

	var shield_poly := PackedVector2Array([
		c + Vector2(-w_half, -h_half),
		c + Vector2(w_half, -h_half * 0.85),
		c + Vector2(w_half * 0.9, h_half * 0.55),
		c + Vector2(0.0, h_half * 1.15),
		c + Vector2(-w_half * 0.9, h_half * 0.55)
	])
	canvas.draw_colored_polygon(shield_poly, p_col)
	canvas.draw_polyline(shield_poly, t_col, 2.4 * s)
	canvas.draw_circle(c, 4.2 * s, t_col.lightened(0.25))

	if is_blocking:
		var aegis_col: Color = t_col
		aegis_col.a = 0.32
		canvas.draw_circle(c + Vector2(facing * 6.0 * s, 0.0), 28.0 * s, aegis_col)
		canvas.draw_arc(c + Vector2(facing * 6.0 * s, 0.0), 28.0 * s, -1.1 if facing > 0 else PI - 1.1, 1.1 if facing > 0 else PI + 1.1, 16, t_col.lightened(0.3), 3.0 * s)

func _draw_socket_main_weapon(
	canvas: CanvasItem,
	wpn: Dictionary,
	unit: BattleSimulation.SimUnit,
	p_hand_r: Vector2,
	a_farm_r: float,
	p_shoulder: Vector2,
	facing: float,
	s: float
) -> void:
	var length: float = float(wpn["length"]) * s
	var width: float = float(wpn["width"]) * s
	var b_col: Color = wpn["blade_color"]
	var g_col: Color = wpn["glow_color"]
	var h_col: Color = wpn["hilt_color"]
	var style: String = str(wpn["style"])

	var grip_pos: Vector2 = p_hand_r
	var wpn_angle: float = a_farm_r - 0.22 * facing
	if unit.anim_state == "DEATH":
		grip_pos = p_hand_r + Vector2(facing * 12.0 * s, unit.dropped_weapon_y)
		wpn_angle = unit.dropped_weapon_rot * facing

	var dir := Vector2.from_angle(wpn_angle)
	var n := Vector2(-dir.y, dir.x) * facing

	# Pommel & Crossguard
	var pommel: Vector2 = grip_pos - dir * (9.0 * s)
	canvas.draw_line(pommel, grip_pos + dir * (3.0 * s), h_col.darkened(0.25), 3.5 * s)
	canvas.draw_circle(pommel, 3.2 * s, h_col)
	var guard_l: Vector2 = grip_pos - n * (width * 1.35)
	var guard_r: Vector2 = grip_pos + n * (width * 1.35)
	canvas.draw_line(guard_l, guard_r, h_col, 3.8 * s)

	var tip: Vector2 = grip_pos + dir * length
	if style == "SPEAR_HALBERD":
		var shaft_end: Vector2 = grip_pos + dir * (length * 0.68)
		canvas.draw_line(pommel - dir * (12.0 * s), shaft_end, h_col, 3.4 * s)
		var head_poly := PackedVector2Array([
			shaft_end - n * (width * 0.45),
			shaft_end + dir * (length * 0.14) + n * (width * 1.45),
			tip,
			shaft_end + dir * (length * 0.16) - n * (width * 0.65)
		])
		canvas.draw_colored_polygon(head_poly, b_col)
		canvas.draw_line(shaft_end, tip, g_col, 2.4 * s)
	else:
		# Sculpted multi-polygon Fantasy Sword / Greatsword / Reaver
		var mid_len: float = length * 0.76
		var curve_n: float = (width * 0.55) if style == "CURVED_REAVER" else 0.0
		var blade_poly := PackedVector2Array([
			grip_pos - n * (width * 0.48),
			grip_pos + dir * mid_len - n * (width * 0.62 - curve_n),
			tip + n * curve_n,
			grip_pos + dir * (mid_len * 0.92) + n * (width * 0.55 + curve_n),
			grip_pos + n * (width * 0.48)
		])
		canvas.draw_colored_polygon(blade_poly, b_col)
		# Glowing Energy Rune Fuller along center of blade
		canvas.draw_line(grip_pos + dir * (4.0 * s), tip - dir * (5.0 * s), g_col, 2.4 * s)
		canvas.draw_line(grip_pos + dir * (6.0 * s), tip - dir * (8.0 * s), Color.WHITE, 1.1 * s)

	# --- MULTI-LAYERED SLASH RIBBON TRAIL DURING ATTACKS ---
	if unit.anim_state == "ATTACK_1" or unit.anim_state == "ATTACK_2":
		var t_norm: float = unit.anim_time / maxf(0.01, unit.anim_duration)
		if t_norm >= 0.26 and t_norm <= 0.72:
			var alpha: float = sin((t_norm - 0.26) / 0.46 * PI)
			var arc_radius: float = length + 14.0 * s
			var start_a: float = wpn_angle - 1.35 * facing
			var end_a: float = wpn_angle + 0.15 * facing
			if start_a > end_a:
				var tmp: float = start_a
				start_a = end_a
				end_a = tmp
			var ribbon_outer := Color(g_col.r, g_col.g, g_col.b, alpha * 0.65)
			var ribbon_core := Color(1.0, 1.0, 1.0, alpha * 0.85)
			canvas.draw_arc(p_shoulder, arc_radius, start_a, end_a, 18, ribbon_outer, 11.0 * s)
			canvas.draw_arc(p_shoulder, arc_radius + 3.0 * s, start_a + 0.1, end_a, 16, ribbon_core, 3.8 * s)

func _draw_debug_skeleton(canvas: CanvasItem, s: float) -> void:
	for i in range(12):
		var col: Color = Color(0.2, 1.0, 0.4) if i < 4 else (Color(0.3, 0.8, 1.0) if i < 8 else Color(1.0, 0.8, 0.2))
		canvas.draw_line(bone_start[i], bone_end[i], col, 2.2)
		canvas.draw_circle(bone_start[i], 3.2 * s, Color(1.0, 0.2, 0.5))
		canvas.draw_circle(bone_end[i], 2.6 * s, Color.WHITE)
