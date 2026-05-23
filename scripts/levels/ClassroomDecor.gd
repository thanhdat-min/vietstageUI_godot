extends Node2D
class_name ClassroomDecor

const WALL := Color("1f100c")
const WALL_TRIM := Color("3a1f16")
const WOOD_DARK := Color("2b1710")
const WOOD_MID := Color("5a3422")
const WOOD_LIGHT := Color("7a4a2d")
const FLOOR_SHADOW := Color("160d0a")
const BRASS := Color("d7a84a")
const BRASS_SOFT := Color("b98435")
const JADE := Color("1f9a8a")
const SON_RED := Color("8d2f22")
const CREAM := Color("f4dfb8")
const MUTED := Color("b99c6b")

var labels: Array[Label] = []

func _ready() -> void:
	z_index = -20
	_add_labels()

func _draw() -> void:
	_draw_full_bleed_backdrop()
	_draw_back_wall()
	_draw_isometric_floor()
	_draw_center_stage()
	_draw_artist_platform()
	_draw_instrument_pedestals()
	_draw_lesson_board()
	_draw_badge_shelf()
	_draw_weekly_rank()
	_draw_walk_paths()
	_draw_foreground_depth()

func _draw_full_bleed_backdrop() -> void:
	draw_rect(Rect2(Vector2(-520, -260), Vector2(2200, 1300)), Color("110b09"))
	draw_rect(Rect2(Vector2(-520, 650), Vector2(2200, 390)), Color("090706"))
	for i in range(9):
		var alpha: float = 0.05 + i * 0.012
		draw_arc(Vector2(576, 510), 360.0 + i * 70.0, PI, TAU, 64, Color(0.9, 0.58, 0.18, alpha), 2.0)

func _draw_back_wall() -> void:
	draw_rect(Rect2(Vector2(-140, 0), Vector2(1432, 292)), WALL)
	draw_rect(Rect2(Vector2(-140, 276), Vector2(1432, 24)), WALL_TRIM)
	draw_line(Vector2(-140, 300), Vector2(1292, 300), BRASS_SOFT, 3.0)

	for i in range(10):
		var x: float = 36.0 + i * 120.0
		draw_rect(Rect2(x, 28, 72, 238), Color(0.1, 0.045, 0.032, 0.86), true)
		draw_line(Vector2(x + 4, 44), Vector2(x + 68, 246), Color(0.28, 0.13, 0.08, 0.5), 2.0)

	_draw_bronze_drum(Vector2(576, 128), 64.0)
	_draw_hanging_lantern(Vector2(228, 102), BRASS)
	_draw_hanging_lantern(Vector2(924, 102), JADE)

func _draw_isometric_floor() -> void:
	var floor: PackedVector2Array = PackedVector2Array([
		Vector2(576, 214),
		Vector2(1092, 502),
		Vector2(576, 718),
		Vector2(60, 502)
	])
	draw_colored_polygon(floor, WOOD_MID)
	draw_polyline(PackedVector2Array([floor[0], floor[1], floor[2], floor[3], floor[0]]), BRASS_SOFT, 3.0)

	for i in range(11):
		var t: float = float(i) / 10.0
		var a: Vector2 = floor[0].lerp(floor[3], t)
		var b: Vector2 = floor[1].lerp(floor[2], t)
		draw_line(a, b, Color(0.12, 0.06, 0.04, 0.42), 2.0)
		var c: Vector2 = floor[0].lerp(floor[1], t)
		var d: Vector2 = floor[3].lerp(floor[2], t)
		draw_line(c, d, Color(0.12, 0.06, 0.04, 0.42), 2.0)

	for i in range(6):
		var offset: float = i * 18.0
		draw_polyline(PackedVector2Array([
			Vector2(576, 238 + offset),
			Vector2(1016 - offset, 506),
			Vector2(576, 682 - offset),
			Vector2(136 + offset, 506),
			Vector2(576, 238 + offset)
		]), Color(0.95, 0.65, 0.25, 0.08), 1.5)

func _draw_center_stage() -> void:
	var rug: PackedVector2Array = PackedVector2Array([
		Vector2(576, 380),
		Vector2(834, 510),
		Vector2(576, 636),
		Vector2(318, 510)
	])
	draw_colored_polygon(rug, Color("6b231c"))
	draw_polyline(PackedVector2Array([rug[0], rug[1], rug[2], rug[3], rug[0]]), BRASS, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(576, 420),
		Vector2(752, 510),
		Vector2(576, 596),
		Vector2(400, 510)
	]), Color(0.15, 0.07, 0.05, 0.34))

	for i in range(4):
		var radius: float = 72.0 + i * 26.0
		draw_arc(Vector2(576, 512), radius, PI * 0.08, PI * 0.92, 36, Color(0.95, 0.68, 0.26, 0.2), 2.0)

func _draw_artist_platform() -> void:
	var platform: PackedVector2Array = PackedVector2Array([
		Vector2(660, 276),
		Vector2(812, 350),
		Vector2(660, 428),
		Vector2(508, 350)
	])
	draw_colored_polygon(platform, Color("4a291c"))
	draw_polyline(PackedVector2Array([platform[0], platform[1], platform[2], platform[3], platform[0]]), BRASS_SOFT, 3.0)
	draw_arc(Vector2(660, 362), 72.0, 0.0, TAU, 56, Color(BRASS, 0.25), 2.0)

func _draw_instrument_pedestals() -> void:
	_draw_station_base(Vector2(264, 512), BRASS, "DAN TRANH")
	_draw_station_base(Vector2(888, 512), JADE, "SAO TRUC")

func _draw_station_base(center: Vector2, accent: Color, _label_text: String) -> void:
	var base: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -48),
		center + Vector2(116, 0),
		center + Vector2(0, 56),
		center + Vector2(-116, 0)
	])
	draw_colored_polygon(base, Color(0.12, 0.065, 0.045, 0.86))
	draw_polyline(PackedVector2Array([base[0], base[1], base[2], base[3], base[0]]), accent, 3.0)
	draw_arc(center, 74.0, 0.0, TAU, 44, Color(accent, 0.18), 2.0)
	draw_arc(center, 54.0, 0.0, TAU, 44, Color(accent, 0.14), 1.5)

func _draw_lesson_board() -> void:
	var rect := Rect2(386, 42, 380, 134)
	draw_rect(rect, Color("321a13"), true)
	draw_rect(rect, BRASS, false, 3.0)
	draw_line(Vector2(416, 102), Vector2(736, 102), Color(BRASS, 0.32), 2.0)
	draw_line(Vector2(416, 134), Vector2(688, 134), Color(BRASS, 0.22), 2.0)
	_draw_bronze_drum(Vector2(576, 198), 34.0, 0.28)

func _draw_badge_shelf() -> void:
	draw_rect(Rect2(82, 166, 250, 62), Color("351d15"), true)
	draw_rect(Rect2(82, 166, 250, 62), Color(BRASS, 0.42), false, 2.0)
	draw_rect(Rect2(68, 228, 278, 18), BRASS_SOFT, true)
	for i in range(5):
		var center := Vector2(116 + i * 48, 198)
		draw_circle(center, 13, Color(0.66, 0.54, 0.32, 0.85))
		draw_arc(center, 10, 0, TAU, 24, Color(BRASS, 0.55), 1.5)

func _draw_weekly_rank() -> void:
	draw_rect(Rect2(830, 166, 242, 84), Color("351d15"), true)
	draw_rect(Rect2(830, 166, 242, 84), Color(JADE, 0.6), false, 2.5)
	for i in range(3):
		var center := Vector2(876 + i * 62, 206)
		draw_circle(center, 18, Color(0.84, 0.45, 0.19, 0.9))
		draw_arc(center, 14, 0, TAU, 26, BRASS, 1.5)

func _draw_walk_paths() -> void:
	draw_polyline(PackedVector2Array([
		Vector2(576, 572), Vector2(264, 512), Vector2(576, 382), Vector2(888, 512), Vector2(576, 572)
	]), Color(0.95, 0.69, 0.25, 0.22), 3.0)
	draw_line(Vector2(576, 572), Vector2(660, 362), Color(JADE, 0.16), 3.0)

func _draw_foreground_depth() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(60, 502), Vector2(576, 718), Vector2(1092, 502), Vector2(1152, 648), Vector2(0, 648)
	]), Color(FLOOR_SHADOW, 0.36))
	draw_line(Vector2(0, 646), Vector2(1152, 646), Color(BRASS, 0.25), 2.0)

func _draw_bronze_drum(center: Vector2, radius: float, alpha: float = 0.9) -> void:
	draw_circle(center, radius, Color(0.38, 0.16, 0.09, alpha))
	draw_arc(center, radius * 0.82, 0.0, TAU, 72, Color(BRASS, alpha), 3.0)
	draw_arc(center, radius * 0.48, 0.0, TAU, 48, Color(BRASS, alpha * 0.62), 2.0)
	for i in range(12):
		var angle: float = TAU * float(i) / 12.0
		draw_line(center, center + Vector2.RIGHT.rotated(angle) * radius * 0.72, Color(BRASS, alpha * 0.44), 1.7)

func _draw_hanging_lantern(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(0, -72), center + Vector2(0, -24), Color(BRASS, 0.45), 2.0)
	draw_circle(center, 20, Color(color, 0.72))
	draw_arc(center, 15, 0.0, TAU, 28, Color(CREAM, 0.32), 1.5)

func _add_labels() -> void:
	_add_room_label("VIRTUAL MUSIC ROOM", Vector2(456, 22), 18, BRASS)
	_add_room_label("LESSON BOARD", Vector2(438, 70), 17, CREAM)
	_add_room_label("BADGES", Vector2(104, 146), 15, MUTED)
	_add_room_label("WEEKLY RANK", Vector2(872, 146), 15, MUTED)
	_add_room_label("Dan Tranh", Vector2(220, 586), 14, BRASS)
	_add_room_label("Sao Truc", Vector2(840, 586), 14, JADE)
	_add_room_label("Tap / press E on glowing hotspots", Vector2(438, 674), 14, CREAM)

func _add_room_label(text: String, pos: Vector2, size: int, color: Color = CREAM) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.z_index = 4
	add_child(label)
	labels.append(label)
