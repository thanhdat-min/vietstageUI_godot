extends Control
class_name PracticeUI

signal practice_finished(result: Dictionary)
signal practice_cancelled

const WOOD_DARK := Color("24130d")
const WOOD_PANEL := Color("3b2318")
const BRASS := Color("d7a84a")
const BRASS_DIM := Color("9c7230")
const JADE := Color("1f9a8a")
const SON_RED := Color("8d2f22")
const CREAM := Color("f4dfb8")
const MUTED := Color("c8af83")

var lesson: Dictionary = {}
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var accuracy: float = 0.0
var rhythm_accuracy: float = 0.0
var pitch_accuracy: float = 0.0
var tone_accuracy: float = 0.0
var active: bool = false

var top_title: Label
var timer_label: Label
var rhythm_lane: Control
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

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	hide()

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
	top_title.text = "%s - %s - %s" % [
		lesson.get("title", "Practice Mode"),
		_instrument_title(lesson.get("instrument", "dan_tranh")),
		lesson.get("difficulty", "Beginner")
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

func update_practice_tick(elapsed: float, total: float, event_name: String, pitch_diff_cents: float, rolling_accuracy: float) -> void:
	if not active:
		return
	progress_bar.value = clamp((elapsed / max(total, 0.1)) * 100.0, 0.0, 100.0)
	timer_label.text = _format_time(elapsed)
	update_pitch(pitch_diff_cents)
	update_accuracy(rolling_accuracy)
	match event_name:
		"Perfect":
			score += 125
			combo += 1
			show_feedback("Perfect", true)
			_hit_flash(BRASS)
		"Good":
			score += 80
			combo += 1
			show_feedback("Good", true)
			_hit_flash(JADE)
		"Late":
			score += 35
			combo = 0
			show_feedback("Late", false)
			_hit_flash(SON_RED)
		"Miss":
			combo = 0
			show_feedback("Miss", false)
			_hit_flash(SON_RED)
		_:
			pass
	max_combo = max(max_combo, combo)
	rhythm_accuracy = clamp(rolling_accuracy + randf_range(-4, 4), 0, 100)
	pitch_accuracy = clamp(100.0 - abs(pitch_diff_cents) * 1.2, 0, 100)
	tone_accuracy = clamp((rhythm_accuracy + pitch_accuracy) * 0.5 + randf_range(-5, 5), 0, 100)
	_update_accuracy_meters(pitch_accuracy, rhythm_accuracy, tone_accuracy)
	_update_score_panel()

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
		"lesson": lesson,
		"score": score,
		"accuracy": final_accuracy,
		"rhythm": int(rhythm_accuracy),
		"pitch": int(pitch_accuracy),
		"tone": int(tone_accuracy),
		"max_combo": max_combo,
		"stars": stars,
		"xp_awarded": 80 + stars * 45,
		"badge": "Steady Rhythm" if stars >= 2 else "Practice Logged"
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
		pitch_hint.text = "In Tune"
		pitch_hint.modulate = JADE
	elif pitch_diff_cents < 0:
		pitch_hint.text = "Flat"
		pitch_hint.modulate = BRASS
	else:
		pitch_hint.text = "Sharp"
		pitch_hint.modulate = SON_RED

func update_accuracy(score_percentage: float) -> void:
	accuracy = score_percentage
	accuracy_label.text = "Accuracy %d%%" % int(score_percentage)

func show_feedback(text: String, is_positive: bool) -> void:
	feedback_label.text = text
	feedback_label.modulate = BRASS if text == "Perfect" else (JADE if is_positive else SON_RED)
	var tween := create_tween()
	feedback_label.scale = Vector2(1.22, 1.22)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _build_hud() -> void:
	var shade := ColorRect.new()
	shade.name = "PracticeShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.02, 0.015, 0.38)
	add_child(shade)

	var top := PanelContainer.new()
	top.name = "TopBar"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_top = 14
	top.offset_right = -18
	top.offset_bottom = 82
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.94), BRASS, 8))
	add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top.add_child(top_row)
	top_title = _label("Practice Mode", 22, CREAM)
	top_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_title)
	timer_label = _label("00:00", 20, BRASS)
	top_row.add_child(timer_label)
	pause_button = _button("Pause", WOOD_PANEL, CREAM)
	pause_button.pressed.connect(stop_practice)
	top_row.add_child(pause_button)

	var left := PanelContainer.new()
	left.name = "AccuracyMeter"
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 18
	left.offset_top = 116
	left.offset_right = 266
	left.offset_bottom = -116
	left.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.9), Color(0.25, 0.16, 0.09), 8))
	add_child(left)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 12)
	left.add_child(left_box)
	accuracy_label = _label("Accuracy 0%", 24, BRASS)
	left_box.add_child(accuracy_label)
	left_box.add_child(_label("Pitch", 15, MUTED))
	pitch_bar = _meter(JADE)
	left_box.add_child(pitch_bar)
	pitch_hint = _label("In Tune", 15, JADE)
	left_box.add_child(pitch_hint)
	left_box.add_child(_label("Rhythm", 15, MUTED))
	rhythm_bar = _meter(BRASS)
	left_box.add_child(rhythm_bar)
	left_box.add_child(_label("Tone", 15, MUTED))
	tone_bar = _meter(SON_RED)
	left_box.add_child(tone_bar)

	var right := PanelContainer.new()
	right.name = "ScorePanel"
	right.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_left = -252
	right.offset_top = 116
	right.offset_right = -18
	right.offset_bottom = -116
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.9), Color(0.25, 0.16, 0.09), 8))
	add_child(right)
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 14)
	right.add_child(score_box)
	score_label = _label("Score 0", 26, CREAM)
	score_box.add_child(score_label)
	combo_label = _label("Combo x0", 22, JADE)
	score_box.add_child(combo_label)
	stars_label = _label("---", 30, BRASS)
	score_box.add_child(stars_label)
	score_box.add_child(_label("Multiplier grows every 10 combo.", 14, MUTED))

	rhythm_lane = PanelContainer.new()
	rhythm_lane.name = "RhythmBar"
	rhythm_lane.set_anchors_preset(Control.PRESET_CENTER)
	rhythm_lane.custom_minimum_size = Vector2(620, 150)
	rhythm_lane.offset_left = -310
	rhythm_lane.offset_top = -75
	rhythm_lane.offset_right = 310
	rhythm_lane.offset_bottom = 75
	rhythm_lane.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.035, 0.025, 0.92), BRASS_DIM, 8))
	add_child(rhythm_lane)
	var lane_inner := Control.new()
	lane_inner.clip_contents = true
	rhythm_lane.add_child(lane_inner)
	note_layer = Control.new()
	note_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	lane_inner.add_child(note_layer)
	hit_flash = ColorRect.new()
	hit_flash.name = "HitZone"
	hit_flash.set_anchors_preset(Control.PRESET_CENTER)
	hit_flash.custom_minimum_size = Vector2(18, 128)
	hit_flash.offset_left = -9
	hit_flash.offset_top = -64
	hit_flash.offset_right = 9
	hit_flash.offset_bottom = 64
	hit_flash.color = Color(BRASS, 0.55)
	lane_inner.add_child(hit_flash)

	progress_bar = ProgressBar.new()
	progress_bar.name = "SongProgress"
	progress_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_bar.offset_left = 280
	progress_bar.offset_right = -280
	progress_bar.offset_top = -86
	progress_bar.offset_bottom = -62
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _bar_bg())
	progress_bar.add_theme_stylebox_override("fill", _bar_fill(BRASS))
	add_child(progress_bar)

	feedback_label = _label("Ready", 34, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.name = "FeedbackLayer"
	feedback_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	feedback_label.offset_left = 280
	feedback_label.offset_right = -280
	feedback_label.offset_top = -154
	feedback_label.offset_bottom = -106
	add_child(feedback_label)

func _spawn_note(index: int) -> void:
	var note := ColorRect.new()
	var strong: bool = index % 4 == 0
	note.color = BRASS if strong else JADE
	note.size = Vector2(26 if strong else 18, 26 if strong else 18)
	note.position = Vector2(580 + index * 92, 58)
	note_layer.add_child(note)
	var tween := note.create_tween().set_loops()
	tween.tween_property(note, "position:x", -80, 3.2 + index * 0.12).from(620 + index * 92)

func _clear_notes() -> void:
	for child in note_layer.get_children():
		child.queue_free()

func _hit_flash(color: Color) -> void:
	hit_flash.color = Color(color, 0.9)
	var tween := create_tween()
	hit_flash.scale = Vector2(1.8, 1.0)
	tween.tween_property(hit_flash, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(hit_flash, "color", Color(color, 0.45), 0.18)

func _update_accuracy_meters(pitch: float, rhythm: float, tone: float) -> void:
	pitch_bar.value = pitch
	rhythm_bar.value = rhythm
	tone_bar.value = tone

func _update_score_panel() -> void:
	score_label.text = "Score %d" % score
	combo_label.text = "Combo x%d" % combo
	var projected_stars: int = 1
	if accuracy >= 88:
		projected_stars = 3
	elif accuracy >= 70:
		projected_stars = 2
	stars_label.text = _stars(projected_stars)

func _meter(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 22)
	bar.max_value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bar_bg())
	bar.add_theme_stylebox_override("fill", _bar_fill(color))
	return bar

func _label(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, bg: Color, fg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(104, 40)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal", _panel_style(bg, bg.lightened(0.16), 8))
	button.add_theme_stylebox_override("hover", _panel_style(bg.lightened(0.1), BRASS, 8))
	button.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.12), BRASS, 8))
	return button

func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _bar_bg() -> StyleBoxFlat:
	return _panel_style(Color(0.08, 0.045, 0.035), Color(0.24, 0.15, 0.08), 8)

func _bar_fill(color: Color) -> StyleBoxFlat:
	var style := _panel_style(color, color, 8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _instrument_title(instrument: String) -> String:
	match instrument:
		"dan_tranh":
			return "Dan Tranh"
		"sao_truc":
			return "Sao Truc"
		_:
			return instrument.capitalize()

func _stars(count: int) -> String:
	var output := ""
	for i in range(3):
		output += "*" if i < count else "-"
	return output

func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
