extends SceneTree

# ============================================================================
# CHROMA-KEY ISOMETRIC SPRITE SHEET BAKER (CELL-BORDER FLOOD-FILL RED -> ALPHA)
# Converts high-detail 5x6 Isometric City sprite sheets from D:\game\isometric-city
# into clean alpha-transparent PNGs in d:\fantasy\assets\iso_packs\
# Preserves interior red/orange building roofs, trains, lanterns & banners!
# ============================================================================

const SRC_DIR: String = "D:/game/isometric-city/public/assets/"
const DST_DIR: String = "res://assets/iso_packs/"
const COLS: int = 5
const ROWS: int = 6
const CELL_W: int = 256
const CELL_H: int = 256

const SHEETS: Array[Dictionary] = [
	{"src": "sprites_red_water_new_china.png", "dst": "iso_pack_oriental.png"},
	{"src": "sprites_red_water_new_harry.png", "dst": "iso_pack_magic.png"},
	{"src": "sprites_red_water_new_modern.png", "dst": "iso_pack_modern.png"},
	{"src": "sprites_red_water_new_farm.png", "dst": "iso_pack_farm.png"},
	{"src": "sprites_red_water_new_parks.png", "dst": "iso_pack_parks.png"},
	{"src": "mansion_alternates.png", "dst": "iso_pack_mansions.png"},
]

static func _is_chroma_red(c: Color) -> bool:
	var r: float = c.r * 255.0
	var g: float = c.g * 255.0
	var b: float = c.b * 255.0
	return r > 185.0 and g < 55.0 and b < 55.0 and (r - maxf(g, b)) > 140.0

static func _redness_score(c: Color) -> float:
	var r: float = c.r * 255.0
	var g: float = c.g * 255.0
	var b: float = c.b * 255.0
	return (r - maxf(g, b)) - (g + b) * 0.35

func _clean_cell_flood(img: Image, cx0: int, cy0: int) -> void:
	var visited := PackedByteArray()
	visited.resize(CELL_W * CELL_H)
	visited.fill(0)
	var queue: PackedInt32Array = PackedInt32Array()

	# Seed BFS from all 4 borders of the 256x256 cell
	for lx in range(CELL_W):
		for ly in [0, 1, CELL_H - 2, CELL_H - 1]:
			var c: Color = img.get_pixel(cx0 + lx, cy0 + ly)
			if _is_chroma_red(c):
				var idx: int = ly * CELL_W + lx
				if visited[idx] == 0:
					visited[idx] = 1
					queue.append(idx)
	for ly in range(CELL_H):
		for lx in [0, 1, CELL_W - 2, CELL_W - 1]:
			var c: Color = img.get_pixel(cx0 + lx, cy0 + ly)
			if _is_chroma_red(c):
				var idx: int = ly * CELL_W + lx
				if visited[idx] == 0:
					visited[idx] = 1
					queue.append(idx)

	var head: int = 0
	while head < queue.size():
		var curr: int = queue[head]
		head += 1
		var lx: int = curr % CELL_W
		var ly: int = curr / CELL_W
		img.set_pixel(cx0 + lx, cy0 + ly, Color(0, 0, 0, 0))

		# 4-connected neighbors
		if lx > 0:
			var n_idx: int = curr - 1
			if visited[n_idx] == 0 and _is_chroma_red(img.get_pixel(cx0 + lx - 1, cy0 + ly)):
				visited[n_idx] = 1
				queue.append(n_idx)
		if lx < CELL_W - 1:
			var n_idx: int = curr + 1
			if visited[n_idx] == 0 and _is_chroma_red(img.get_pixel(cx0 + lx + 1, cy0 + ly)):
				visited[n_idx] = 1
				queue.append(n_idx)
		if ly > 0:
			var n_idx: int = curr - CELL_W
			if visited[n_idx] == 0 and _is_chroma_red(img.get_pixel(cx0 + lx, cy0 + ly - 1)):
				visited[n_idx] = 1
				queue.append(n_idx)
		if ly < CELL_H - 1:
			var n_idx: int = curr + CELL_W
			if visited[n_idx] == 0 and _is_chroma_red(img.get_pixel(cx0 + lx, cy0 + ly + 1)):
				visited[n_idx] = 1
				queue.append(n_idx)

	# Feather 1-pixel halo right next to flood-filled background & clear pure #FF0000 enclosed holes
	for ly in range(CELL_H):
		for lx in range(CELL_W):
			var idx: int = ly * CELL_W + lx
			if visited[idx] == 1:
				continue
			var c: Color = img.get_pixel(cx0 + lx, cy0 + ly)
			if c.r > 0.94 and c.g < 0.06 and c.b < 0.06:
				img.set_pixel(cx0 + lx, cy0 + ly, Color(0, 0, 0, 0))
				visited[idx] = 1
				continue
			if lx > 0 and lx < CELL_W - 1 and ly > 0 and ly < CELL_H - 1:
				var touches_bg: bool = (
					visited[idx - 1] == 1 or visited[idx + 1] == 1
					or visited[idx - CELL_W] == 1 or visited[idx + CELL_W] == 1
				)
				if touches_bg:
					var score: float = _redness_score(c)
					if score > 65.0:
						var alpha: float = clampf(1.0 - (score - 65.0) / 95.0, 0.0, 0.85)
						var clean_r: float = minf(c.r, maxf(c.g, c.b) * 1.15)
						img.set_pixel(cx0 + lx, cy0 + ly, Color(clean_r, c.g, c.b, alpha))

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST_DIR))
	for item in SHEETS:
		var src_path: String = SRC_DIR + str(item["src"])
		var dst_path: String = ProjectSettings.globalize_path(DST_DIR + str(item["dst"]))
		var img := Image.new()
		var err: Error = img.load(src_path)
		if err != OK:
			var buf: PackedByteArray = FileAccess.get_file_as_bytes(src_path)
			err = img.load_jpg_from_buffer(buf)
			if err != OK:
				err = img.load_webp_from_buffer(buf)
		if err != OK:
			print("Failed to load: ", src_path)
			continue
		img.convert(Image.FORMAT_RGBA8)
		img.resize(COLS * CELL_W, ROWS * CELL_H, Image.INTERPOLATE_LANCZOS)
		for row in range(ROWS):
			for col in range(COLS):
				_clean_cell_flood(img, col * CELL_W, row * CELL_H)
		img.save_png(dst_path)
		print("Baked flood-fill isometric sheet: ", dst_path)
	quit(0)
