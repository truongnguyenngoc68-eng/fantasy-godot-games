extends Node

# ============================================================================
# PROCEDURAL COMBAT SOUND ENGINE (Zero External Dependencies, Polyphony Capped)
# ============================================================================

var _player: AudioStreamPlayer
var _sample_rate: float = 22050.0
var _last_play_ms: Dictionary = {}
var muted: bool = false

func _ready() -> void:
	var all_args: PackedStringArray = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if DisplayServer.get_name() == "headless" or ("--capture-showcase" in all_args) or ("--capture-stick-war" in all_args) or ("--capture-cat-city" in all_args) or ("--run-benchmark" in all_args) or ("--record-video-1v1" in all_args) or ("--record-video-300" in all_args):
		muted = true
		return
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_rate
	gen.buffer_length = 0.18
	_player.stream = gen
	_player.volume_db = -9.0
	add_child(_player)
	_player.play()

func shutdown() -> void:
	muted = true
	if _player != null:
		_player.stop()
		_player.stream = null
		if _player.get_parent() != null:
			_player.get_parent().remove_child(_player)
		_player.free()
		_player = null

func _exit_tree() -> void:
	shutdown()

func play_sfx(sfx_id: String) -> void:
	if muted or _player == null or not _player.playing:
		return
	var now: int = Time.get_ticks_msec()
	var prev: int = int(_last_play_ms.get(sfx_id, 0))
	if now - prev < 60:
		return
	_last_play_ms[sfx_id] = now

	match sfx_id:
		"whoosh":
			_synthesize(280.0, 110.0, 0.065, 0.22, true)
		"slash_hit":
			_synthesize(220.0, 75.0, 0.075, 0.38, true)
		"heavy_cleave":
			_synthesize(160.0, 48.0, 0.115, 0.48, true)
		"shield_block":
			_synthesize(420.0, 180.0, 0.065, 0.34, true)
		"parry_clang":
			_synthesize(980.0, 1420.0, 0.095, 0.40, false)
		"death":
			_synthesize(175.0, 52.0, 0.150, 0.38, true)
		"footstep":
			_synthesize(115.0, 65.0, 0.028, 0.14, true)
		"ui_click":
			_synthesize(640.0, 860.0, 0.032, 0.22, false)

func _synthesize(f_start: float, f_end: float, duration: float, amp: float, noise_mix: bool) -> void:
	var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var avail: int = pb.get_frames_available()
	var frames: int = mini(int(duration * _sample_rate), avail)
	if frames <= 0:
		return
	var phase: float = 0.0
	for i in range(frames):
		var t: float = float(i) / float(frames)
		var freq: float = lerpf(f_start, f_end, t)
		phase += freq / _sample_rate
		var env: float = (1.0 - t) * (1.0 - t) * amp
		var s: float = sin(phase * TAU) * env
		if noise_mix:
			s += randf_range(-0.55, 0.55) * env
		pb.push_frame(Vector2(s, s))
