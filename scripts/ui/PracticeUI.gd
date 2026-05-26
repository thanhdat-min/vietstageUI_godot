extends Control
class_name PracticeUI

@onready var font_reg: Font = load("res://assets/fonts/Inter-Regular.ttf")
@onready var font_bold: Font = load("res://assets/fonts/Inter-SemiBold.ttf")

signal practice_finished(result: Dictionary)
signal practice_cancelled

# ── Colour palette ──────────────────────────────────────────────────────────
const WOOD_DARK  := Color("281006") # Mahogany Canvas
const WOOD_PANEL := Color("402011") # Burnt Sienna
const BRASS      := Color("faae33") # Curry Yellow
const BRASS_DIM  := Color("823513") # Spiced Orange
const JADE       := Color("faae33") # Curry Yellow
const SON_RED    := Color("d1255c") # Chili Red
const CREAM      := Color("ffffff") # Crisp White
const MUTED      := Color("9f531b") # Cinnamon Brown / Muted
const SUCCESS    := Color("faae33") # Curry Yellow
const STAR_GOLD  := Color("f0c840")

# ── Session state ───────────────────────────────────────────────────────────
var lesson: Dictionary = {}
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var accuracy: float = 0.0
var rhythm_accuracy: float = 0.0
var pitch_accuracy: float = 0.0
var tone_accuracy: float = 0.0
var active: bool = false

# ── Core HUD nodes ──────────────────────────────────────────────────────────
var top_title: Label
var timer_label: Label
var rhythm_lane: PanelContainer
var note_layer: Control
var hit_flash: ColorRect
var feedback_label: Label
var score_label: Label
var combo_label: Label
var stars_label: Label
var pitch_bar: ProgressBar
var rhythm_bar: ProgressBar
var tone_bar: ProgressBar
var accuracy_label: Label
var pitch_hint: Label
var progress_bar: ProgressBar
var pause_button: Button

# ── Compact mobile HUD nodes ────────────────────────────────────────────────
var compact_hud: PanelContainer
var compact_score_lbl: Label
var compact_combo_lbl: Label
var compact_acc_lbl: Label
var compact_stars_lbl: Label


# ── Enhanced nodes ──────────────────────────────────────────────────────────
var breath_panel: PanelContainer     # sáo trúc only
var breath_bar: ProgressBar
var breath_label: Label
var waveform_strip: Control          # animated waveform below lane
var pitch_arrow: Control             # visual pitch arrow
var accuracy_ring: Control           # live accuracy ring overlay on hit zone
var _waveform_phase: float = 0.0
var _ring_angle: float = 0.0
var _ring_color: Color = BRASS

# ── Breath simulation ────────────────────────────────────────────────────────
var breath_level: float = 0.5

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	hide()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

func _process(delta: float) -> void:
	if not active:
		return
	# Animate waveform strip
	_waveform_phase += delta * 4.2
	if is_instance_valid(waveform_strip):
		waveform_strip.queue_redraw()
	# Animate accuracy ring
	_ring_angle += delta * 90.0
	if is_instance_valid(accuracy_ring):
		accuracy_ring.queue_redraw()

# ─── Public API ─────────────────────────────────────────────────────────────
func start_practice(new_lesson: Dictionary = {}) -> void:
	lesson = new_lesson
	score = 0
	combo = 0
	max_combo = 0
	accuracy = 0.0
	rhythm_accuracy = 0.0
	pitch_accuracy = 0.0
	tone_accuracy = 0.0
	active = true
	show()
	var instrument: String = lesson.get("instrument", "dan_tranh")
	top_title.text = "%s  —  %s  —  %s" % [
		lesson.get("title", "Chế độ Luyện tập"),
		_instrument_title(instrument),
		_difficulty_title(lesson.get("difficulty", "Beginner"))
	]
	timer_label.text = "00:00"
	feedback_label.text = "Get Ready"
	feedback_label.modulate = BRASS
	progress_bar.value = 0
	_update_score_panel()
	_update_accuracy_meters(0, 0, 0)
	_clear_notes()
	for i in range(8):
		_spawn_note(i)
	# Show/hide breath meter based on instrument
	if is_instance_valid(breath_panel):
		breath_panel.visible = (instrument == "sao_truc")

func update_practice_tick(
		elapsed: float, total: float,
		event_name: String, pitch_diff_cents: float,
		rolling_accuracy: float, breath: float = -1.0) -> void:
	if not active:
		return
	progress_bar.value = clamp((elapsed / max(total, 0.1)) * 100.0, 0.0, 100.0)
	timer_label.text = _format_time(elapsed)
	update_pitch(pitch_diff_cents)
	update_accuracy(rolling_accuracy)
	if breath >= 0.0:
		_update_breath(breath)
	match event_name:
		"Perfect":
			score += 125
			combo += 1
			show_feedback("Perfect", true)
			_hit_flash_anim(BRASS)
		"Good":
			score += 80
			combo += 1
			show_feedback("Good", true)
			_hit_flash_anim(JADE)
		"Late":
			score += 35
			combo = 0
			show_feedback("Late", false)
			_hit_flash_anim(SON_RED)
		"Miss":
			combo = 0
			show_feedback("Miss", false)
			_hit_flash_anim(SON_RED)
		_:
			pass
	max_combo = max(max_combo, combo)
	rhythm_accuracy = clamp(rolling_accuracy + randf_range(-4, 4), 0, 100)
	pitch_accuracy  = clamp(100.0 - abs(pitch_diff_cents) * 1.2, 0, 100)
	tone_accuracy   = clamp((rhythm_accuracy + pitch_accuracy) * 0.5 + randf_range(-5, 5), 0, 100)
	_update_accuracy_meters(pitch_accuracy, rhythm_accuracy, tone_accuracy)
	_update_score_panel()
	# Update ring colour
	_ring_color = SUCCESS if rolling_accuracy >= 80.0 else (BRASS if rolling_accuracy >= 55.0 else SON_RED)

func finish_practice() -> Dictionary:
	active = false
	hide()
	var final_accuracy: int = int(round((pitch_accuracy + rhythm_accuracy + tone_accuracy) / 3.0))
	var stars: int = 1
	if final_accuracy >= 88:
		stars = 3
	elif final_accuracy >= 70:
		stars = 2
	var result: Dictionary = {
		"lesson":      lesson,
		"score":       score,
		"accuracy":    final_accuracy,
		"rhythm":      int(rhythm_accuracy),
		"pitch":       int(pitch_accuracy),
		"tone":        int(tone_accuracy),
		"max_combo":   max_combo,
		"stars":       stars,
		"xp_awarded":  80 + stars * 45,
		"badge":       "Steady Rhythm" if stars >= 2 else "Practice Logged"
	}
	practice_finished.emit(result)
	return result

func stop_practice() -> void:
	active = false
	hide()
	practice_cancelled.emit()

func update_pitch(pitch_diff_cents: float) -> void:
	var mapped_value: float = clamp(50.0 + pitch_diff_cents, 0.0, 100.0)
	pitch_bar.value = mapped_value
	if abs(pitch_diff_cents) < 10:
		pitch_hint.text = "▲ Đúng nốt"
		pitch_hint.modulate = JADE
	elif pitch_diff_cents < 0:
		pitch_hint.text = "▼ Thấp (Flat)"
		pitch_hint.modulate = BRASS
	else:
		pitch_hint.text = "▲ Cao (Sharp)"
		pitch_hint.modulate = SON_RED
	# Update pitch arrow
	if is_instance_valid(pitch_arrow):
		pitch_arrow.set_meta("diff", pitch_diff_cents)
		pitch_arrow.queue_redraw()

func update_accuracy(score_percentage: float) -> void:
	accuracy = score_percentage
	accuracy_label.text = "Độ chính xác  %d%%" % int(score_percentage)
	if is_instance_valid(compact_acc_lbl):
		compact_acc_lbl.text = "Chính xác: %d%%" % int(score_percentage)
	if is_instance_valid(compact_acc_lbl):
		compact_acc_lbl.text = "Chính xác: %d%%" % int(score_percentage)

func show_feedback(text: String, is_positive: bool) -> void:
	feedback_label.text = text
	feedback_label.modulate = BRASS if text == "Perfect" else (JADE if is_positive else SON_RED)
	var tween := create_tween()
	feedback_label.scale = Vector2(1.22, 1.22)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.16)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ─── Build HUD ──────────────────────────────────────────────────────────────
func _build_hud() -> void:
	# ── Dim overlay ──
	var shade := ColorRect.new()
	shade.name = "PracticeShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.02, 0.015, 0.34)
	add_child(shade)

	# ── Top bar ──────────────────────────────────────────────────────────────
	var top := PanelContainer.new()
	top.name = "TopBar"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left   = 18
	top.offset_top    = 14
	top.offset_right  = -18
	top.offset_bottom = 82
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.96), BRASS, 10))
	add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top.add_child(top_row)
	top_title = _label("Practice Mode", 20, CREAM)
	top_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(top_title)
	timer_label = _label("00:00", 20, BRASS)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(timer_label)
	pause_button = _button("❚❚ Pause", WOOD_PANEL, CREAM)
	pause_button.pressed.connect(stop_practice)
	top_row.add_child(pause_button)

	# ── Left panel – Accuracy meters ─────────────────────────────────────────
	var left := PanelContainer.new()
	left.name = "AccuracyMeter"
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left   = 18
	left.offset_top    = 108
	left.offset_right  = 276
	left.offset_bottom = -120
	left.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.92), Color(0.25, 0.16, 0.09), 10))
	add_child(left)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 11)
	left.add_child(left_box)

	accuracy_label = _label("Accuracy  0%", 22, BRASS)
	left_box.add_child(accuracy_label)
	left_box.add_child(_separator())

	# Pitch row with arrow
	left_box.add_child(_label("Pitch", 14, MUTED))
	pitch_bar = _meter(JADE)
	left_box.add_child(pitch_bar)
	pitch_arrow = _build_pitch_arrow()
	left_box.add_child(pitch_arrow)
	pitch_hint = _label("▲ In Tune", 14, JADE)
	left_box.add_child(pitch_hint)

	left_box.add_child(_label("Rhythm", 14, MUTED))
	rhythm_bar = _meter(BRASS)
	left_box.add_child(rhythm_bar)

	left_box.add_child(_label("Tone Quality", 14, MUTED))
	tone_bar = _meter(SON_RED)
	left_box.add_child(tone_bar)

	# ── Breath meter (sáo trúc only) ─────────────────────────────────────────
	breath_panel = PanelContainer.new()
	breath_panel.name = "BreathMeter"
	breath_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	breath_panel.offset_left   = 18
	breath_panel.offset_top    = -114
	breath_panel.offset_right  = 276
	breath_panel.offset_bottom = -20
	breath_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.92), JADE, 10))
	add_child(breath_panel)
	var breath_box := VBoxContainer.new()
	breath_box.add_theme_constant_override("separation", 6)
	breath_panel.add_child(breath_box)
	breath_box.add_child(_label("Breath (Sáo Trúc)", 15, JADE))
	breath_bar = ProgressBar.new()
	breath_bar.max_value = 100
	breath_bar.value = 50
	breath_bar.custom_minimum_size = Vector2(0, 22)
	breath_bar.show_percentage = false
	breath_bar.add_theme_stylebox_override("background", _bar_bg())
	breath_bar.add_theme_stylebox_override("fill", _bar_fill(JADE))
	breath_box.add_child(breath_bar)
	breath_label = _label("Steady", 13, JADE)
	breath_box.add_child(breath_label)
	breath_panel.visible = false

	# ── Right panel – Score ───────────────────────────────────────────────────
	var right := PanelContainer.new()
	right.name = "ScorePanel"
	right.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_left   = -262
	right.offset_top    = 108
	right.offset_right  = -18
	right.offset_bottom = -120
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.92), Color(0.25, 0.16, 0.09), 10))
	add_child(right)
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 13)
	right.add_child(score_box)
	score_label = _label("Score  0", 26, CREAM)
	score_box.add_child(score_label)
	combo_label = _label("Combo  x0", 21, JADE)
	score_box.add_child(combo_label)
	stars_label = _label("---", 30, BRASS)
	score_box.add_child(stars_label)
	score_box.add_child(_separator())
	score_box.add_child(_label("★★★  ≥ 88%", 13, MUTED))
	score_box.add_child(_label("★★     ≥ 70%", 13, MUTED))
	score_box.add_child(_label("★        < 70%", 13, MUTED))
	score_box.add_child(_label("x10 combo → bonus multiplier", 12, MUTED))

	# ── Centre – Rhythm lane ──────────────────────────────────────────────────
	rhythm_lane = PanelContainer.new()
	rhythm_lane.name = "RhythmBar"
	rhythm_lane.set_anchors_preset(Control.PRESET_CENTER)
	rhythm_lane.custom_minimum_size = Vector2(620, 146)
	rhythm_lane.offset_left   = -310
	rhythm_lane.offset_top    = -73
	rhythm_lane.offset_right  = 310
	rhythm_lane.offset_bottom = 73
	rhythm_lane.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.035, 0.025, 0.94), BRASS_DIM, 10))
	add_child(rhythm_lane)

	var lane_inner := Control.new()
	lane_inner.clip_contents = true
	lane_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	rhythm_lane.add_child(lane_inner)

	note_layer = Control.new()
	note_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	lane_inner.add_child(note_layer)

	# Hit zone with accuracy ring overlay
	hit_flash = ColorRect.new()
	hit_flash.name = "HitZone"
	hit_flash.set_anchors_preset(Control.PRESET_CENTER)
	hit_flash.custom_minimum_size = Vector2(20, 124)
	hit_flash.offset_left   = -10
	hit_flash.offset_top    = -62
	hit_flash.offset_right  = 10
	hit_flash.offset_bottom = 62
	hit_flash.color = Color(BRASS, 0.55)
	lane_inner.add_child(hit_flash)

	# Accuracy ring (drawn node around hit zone)
	accuracy_ring = _build_accuracy_ring()
	accuracy_ring.set_anchors_preset(Control.PRESET_CENTER)
	accuracy_ring.offset_left   = -42
	accuracy_ring.offset_top    = -42
	accuracy_ring.offset_right  = 42
	accuracy_ring.offset_bottom = 42
	lane_inner.add_child(accuracy_ring)

	# Waveform strip below lane
	waveform_strip = _build_waveform_strip()
	waveform_strip.set_anchors_preset(Control.PRESET_CENTER)
	waveform_strip.custom_minimum_size = Vector2(580, 38)
	waveform_strip.offset_left   = -290
	waveform_strip.offset_top    = 100
	waveform_strip.offset_right  = 290
	waveform_strip.offset_bottom = 138
	add_child(waveform_strip)

	# ── Progress bar ─────────────────────────────────────────────────────────
	progress_bar = ProgressBar.new()
	progress_bar.name = "SongProgress"
	progress_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_bar.offset_left   = 290
	progress_bar.offset_right  = -290
	progress_bar.offset_top    = -88
	progress_bar.offset_bottom = -64
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _bar_bg())
	progress_bar.add_theme_stylebox_override("fill", _bar_fill(BRASS))
	add_child(progress_bar)

	# ── Feedback label ────────────────────────────────────────────────────────
	feedback_label = _label("Ready", 36, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.name = "FeedbackLayer"
	feedback_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	feedback_label.offset_left   = 290
	feedback_label.offset_right  = -290
	feedback_label.offset_top    = -158
	feedback_label.offset_bottom = -104
	add_child(feedback_label)

	# ── Compact Mobile HUD (hidden by default) ────────────────────────────────
	compact_hud = PanelContainer.new()
	compact_hud.name = "CompactMobileHUD"
	compact_hud.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.95), Color(0.25, 0.16, 0.09), 8))
	var ch_row := HBoxContainer.new()
	ch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ch_row.add_theme_constant_override("separation", 24)
	compact_hud.add_child(ch_row)
	compact_score_lbl = _label("Điểm: 0", 16, CREAM)
	ch_row.add_child(compact_score_lbl)
	compact_combo_lbl = _label("Combo: x0", 16, JADE)
	ch_row.add_child(compact_combo_lbl)
	compact_acc_lbl = _label("Chính xác: 0%", 16, BRASS)
	ch_row.add_child(compact_acc_lbl)
	compact_stars_lbl = _label("☆☆☆", 18, STAR_GOLD)
	ch_row.add_child(compact_stars_lbl)
	add_child(compact_hud)


# ─── Enhanced visual builders ────────────────────────────────────────────────
func _build_pitch_arrow() -> Control:
	var node := Control.new()
	node.name = "PitchArrow"
	node.custom_minimum_size = Vector2(0, 28)
	node.set_meta("diff", 0.0)
	node.draw.connect(func():
		var diff: float = node.get_meta("diff", 0.0)
		var w := node.size.x
		var h := node.size.y
		var cx := w * 0.5
		var cy := h * 0.5
		# Centre line
		node.draw_line(Vector2(8, cy), Vector2(w - 8, cy), MUTED, 1.5)
		# Arrow head position
		var norm: float = clamp(diff / 50.0, -1.0, 1.0)
		var arrow_x: float = cx + norm * (w * 0.5 - 14.0)
		var color := JADE if abs(diff) < 10.0 else (SON_RED if diff > 0.0 else BRASS)
		# Draw triangle arrow
		var pts := PackedVector2Array([
			Vector2(arrow_x, cy - 10),
			Vector2(arrow_x + 8, cy + 8),
			Vector2(arrow_x - 8, cy + 8)
		])
		node.draw_colored_polygon(pts, color)
		node.draw_polyline(pts + PackedVector2Array([pts[0]]), color.lightened(0.3), 1.5)
	)
	return node

func _build_accuracy_ring() -> Control:
	var node := Control.new()
	node.name = "AccuracyRing"
	node.draw.connect(func():
		var sz := node.size
		var cx := sz.x * 0.5
		var cy := sz.y * 0.5
		var radius: float = min(cx, cy) - 4.0
		# Background ring
		node.draw_arc(Vector2(cx, cy), radius, 0.0, TAU, 48, Color(MUTED, 0.18), 3.0)
		# Spinning arc segment
		var arc_start := deg_to_rad(_ring_angle)
		var arc_len := TAU * (accuracy / 100.0)
		node.draw_arc(Vector2(cx, cy), radius, arc_start, arc_start + arc_len, 48, Color(_ring_color, 0.72), 4.0)
		# Tick mark
		var tick_angle := arc_start
		node.draw_line(
			Vector2(cx + cos(tick_angle) * (radius - 6), cy + sin(tick_angle) * (radius - 6)),
			Vector2(cx + cos(tick_angle) * (radius + 6), cy + sin(tick_angle) * (radius + 6)),
			Color(_ring_color, 0.9), 2.5
		)
	)
	return node

func _build_waveform_strip() -> Control:
	var node := Control.new()
	node.name = "WaveformStrip"
	node.draw.connect(func():
		var w := node.size.x
		var h := node.size.y
		var cy := h * 0.5
		var amplitude := cy * 0.72
		var step := 4.0
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= w:
			var t := x / w
			var wave := sin(_waveform_phase + t * TAU * 3.0) * amplitude * sin(t * PI) \
				+ sin(_waveform_phase * 1.7 + t * TAU * 7.0) * amplitude * 0.28 * sin(t * PI)
			pts.append(Vector2(x, cy + wave))
			x += step
		if pts.size() >= 2:
			node.draw_polyline(pts, Color(BRASS, 0.38), 2.0)
		# Centre line
		node.draw_line(Vector2(0, cy), Vector2(w, cy), Color(BRASS_DIM, 0.22), 1.0)
	)
	return node

# ─── Note lane helpers ───────────────────────────────────────────────────────
func _spawn_note(index: int) -> void:
	var note := ColorRect.new()
	var strong: bool = index % 4 == 0
	note.color = BRASS if strong else JADE
	note.size = Vector2(28 if strong else 18, 28 if strong else 18)
	note.position = Vector2(580 + index * 92, 56)
	note_layer.add_child(note)
	var tween := note.create_tween().set_loops()
	tween.tween_property(note, "position:x", -80.0, 3.2 + index * 0.12).from(620.0 + index * 92)

func _clear_notes() -> void:
	for child in note_layer.get_children():
		child.queue_free()

func _hit_flash_anim(color: Color) -> void:
	hit_flash.color = Color(color, 0.9)
	var tween := create_tween()
	hit_flash.scale = Vector2(1.8, 1.0)
	tween.tween_property(hit_flash, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(hit_flash, "color", Color(color, 0.45), 0.18)

func _update_breath(level: float) -> void:
	breath_level = level
	if is_instance_valid(breath_bar):
		breath_bar.value = level * 100.0
	if is_instance_valid(breath_label):
		if level > 0.75:
			breath_label.text = "Too strong"
			breath_label.modulate = SON_RED
		elif level > 0.35:
			breath_label.text = "Ổn định ✓"
			breath_label.modulate = JADE
		else:
			breath_label.text = "Too weak"
			breath_label.modulate = BRASS

func _update_accuracy_meters(pitch: float, rhythm: float, tone: float) -> void:
	pitch_bar.value = pitch
	rhythm_bar.value = rhythm
	tone_bar.value = tone

func _update_score_panel() -> void:
	score_label.text = "Score  %d" % score
	combo_label.text = "Combo  x%d" % combo
	var projected: int = 1
	if accuracy >= 88:
		projected = 3
	elif accuracy >= 70:
		projected = 2
	stars_label.text = _stars(projected)
	
	if is_instance_valid(compact_score_lbl):
		compact_score_lbl.text = "Điểm: %d" % score
	if is_instance_valid(compact_combo_lbl):
		compact_combo_lbl.text = "Combo: x%d" % combo
	if is_instance_valid(compact_stars_lbl):
		compact_stars_lbl.text = _stars(projected)
	
	if is_instance_valid(compact_score_lbl):
		compact_score_lbl.text = "Điểm: %d" % score
	if is_instance_valid(compact_combo_lbl):
		compact_combo_lbl.text = "Combo: x%d" % combo
	if is_instance_valid(compact_stars_lbl):
		compact_stars_lbl.text = _stars(projected)

# ─── Style helpers ───────────────────────────────────────────────────────────
func _meter(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 22)
	bar.max_value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bar_bg())
	bar.add_theme_stylebox_override("fill", _bar_fill(color))
	return bar

func _separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(MUTED, 0.25))
	return sep

func _label(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if font_reg:
		label.add_theme_font_override("font", font_reg)
	return label

func _button(text: String, bg: Color, fg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 42)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal",  _panel_style(bg, bg.lightened(0.16), 1296))
	button.add_theme_stylebox_override("hover",   _panel_style(bg.lightened(0.1), BRASS, 1296))
	button.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.12), BRASS, 1296))
	return button

func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	var target_radius := radius
	if radius != 1296 and radius != 1224 and radius != 1152 and radius != 1080:
		target_radius = 6
	style.set_corner_radius_all(target_radius)
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	return style

func _bar_bg() -> StyleBoxFlat:
	return _panel_style(Color(0.08, 0.045, 0.035), Color(0.24, 0.15, 0.08), 8)

func _bar_fill(color: Color) -> StyleBoxFlat:
	var style := _panel_style(color, color, 8)
	style.content_margin_left   = 0
	style.content_margin_right  = 0
	style.content_margin_top    = 0
	style.content_margin_bottom = 0
	return style

func _instrument_title(instrument: String) -> String:
	match instrument:
		"dan_tranh": return "Đàn Tranh"
		"sao_truc":  return "Sáo Trúc"
		"dan_bau":   return "Đàn Bầu"
		"trong":     return "Trống"
		_:           return instrument.capitalize()

func _stars(count: int) -> String:
	var output := ""
	for i in range(3):
		output += "★" if i < count else "☆"
	return output

func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


# ── Helper for difficulty translation ──
func _difficulty_title(diff_str: String) -> String:
	match diff_str:
		"Beginner": return "Cơ bản"
		"Intermediate": return "Trung cấp"
		"Advanced": return "Nâng cao"
		_: return diff_str

func _apply_responsive_layout() -> void:
	var sz := get_viewport().get_visible_rect().size
	var w := sz.x
	var h := sz.y
	var desktop := w >= 800
	
	var left_panel: Node = find_child("AccuracyMeter", true, false)
	var right_panel: Node = find_child("ScorePanel", true, false)
	
	# Co giãn làn chạy nhạc (rhythm lane)
	if is_instance_valid(rhythm_lane):
		var lane_w: float = min(620.0, w - 24.0)
		rhythm_lane.custom_minimum_size = Vector2(lane_w, 146)
		rhythm_lane.offset_left = -lane_w * 0.5
		rhythm_lane.offset_right = lane_w * 0.5
		
	if desktop:
		if left_panel: (left_panel as Control).show()
		if right_panel: (right_panel as Control).show()
		if is_instance_valid(compact_hud): compact_hud.hide()
		
		# Căn vị trí làn chạy nhạc ở tâm
		if is_instance_valid(rhythm_lane):
			rhythm_lane.offset_top = -73
			rhythm_lane.offset_bottom = 73
			
		if is_instance_valid(progress_bar):
			progress_bar.offset_left = 290
			progress_bar.offset_right = -290
			progress_bar.offset_top = -88
			progress_bar.offset_bottom = -64
			
		if is_instance_valid(feedback_label):
			feedback_label.offset_left = 290
			feedback_label.offset_right = -290
			feedback_label.offset_top = -158
			feedback_label.offset_bottom = -104
			
		if is_instance_valid(waveform_strip):
			waveform_strip.show()
	else:
		if left_panel: (left_panel as Control).hide()
		if right_panel: (right_panel as Control).hide()
		if is_instance_valid(compact_hud):
			compact_hud.show()
			compact_hud.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			compact_hud.offset_left = 12
			compact_hud.offset_right = -12
			compact_hud.offset_top = -168
			compact_hud.offset_bottom = -120
			
		# Di chuyển làn chạy nhạc cao hơn để nhường chỗ cho compact HUD và progress
		if is_instance_valid(rhythm_lane):
			rhythm_lane.offset_top = -140
			rhythm_lane.offset_bottom = 6
			
		if is_instance_valid(progress_bar):
			progress_bar.offset_left = 18
			progress_bar.offset_right = -18
			progress_bar.offset_top = -98
			progress_bar.offset_bottom = -82
			
		if is_instance_valid(feedback_label):
			feedback_label.offset_left = 18
			feedback_label.offset_right = -18
			feedback_label.offset_top = -236
			feedback_label.offset_bottom = -182
			
		if is_instance_valid(waveform_strip):
			waveform_strip.hide() # ẩn thanh sóng phụ để đỡ chật chội
