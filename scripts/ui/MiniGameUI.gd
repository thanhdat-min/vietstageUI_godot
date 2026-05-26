extends Control
class_name MiniGameUI

@onready var font_reg: Font = load("res://assets/fonts/Inter-Regular.ttf")
@onready var font_bold: Font = load("res://assets/fonts/Inter-SemiBold.ttf")

signal minigame_finished(result: Dictionary)
signal minigame_cancelled

# ── Colour palette (matches project theme) ─────────────────────────────────
const WOOD_DARK  := Color("140926") # Deep dark purple
const WOOD_PANEL := Color("251245") # Royal purple card
const BRASS      := Color("a44dfa") # Vibrant purple
const BRASS_DIM  := Color("5d2b9d") # Royal violet dim
const JADE       := Color("00ebd6") # Neon turquoise
const SON_RED    := Color("ff3366") # Neon pink/red
const CREAM      := Color("f5f2ff") # Creamy soft white
const MUTED      := Color("8f7fa6") # Cool purple-grey
const SHADOW     := Color(0.04, 0.02, 0.07, 0.85)
const STAR_GOLD  := Color("ffd214")
const SUCCESS    := Color("00ebd6")

# ── Mini-game types ─────────────────────────────────────────────────────────
enum MiniType { RHYTHM_MATCH, NOTE_QUIZ, MELODY_COMPLETION }

# ── State ───────────────────────────────────────────────────────────────────
var current_type: int = MiniType.RHYTHM_MATCH
var active: bool = false
var score: int = 0
var max_score: int = 0
var hits: int = 0
var misses: int = 0
var current_question: int = 0
var total_questions: int = 5
var run_id: int = 0

# ── Common nodes ────────────────────────────────────────────────────────────
var overlay: ColorRect
var header_panel: PanelContainer
var header_title: Label
var header_score: Label
var header_timer: Label
var content_area: Control
var footer_panel: PanelContainer
var pause_btn: Button
var _timer_elapsed: float = 0.0
var _timer_total: float = 30.0

# ── Rhythm Match nodes ───────────────────────────────────────────────────────
var rm_lane: Control
var rm_note_layer: Control
var rm_hit_zone: ColorRect
var rm_hit_label: Label
var rm_combo: int = 0
var rm_combo_label: Label
var rm_beat_timer: float = 0.0
var rm_beat_interval: float = 0.9
var rm_notes: Array = []
var rm_note_speed: float = 280.0
var rm_in_progress: bool = false

# ── Note Quiz nodes ──────────────────────────────────────────────────────────
var nq_question_label: Label
var nq_options: Array = []
var nq_feedback: Label
var nq_answered: bool = false
var _nq_data: Array = [
	{"q": "Nốt nào là nốt ĐÔ trong thang âm ngũ cung?", "options": ["Đô", "Rê", "Mi", "Sol"], "answer": 0},
	{"q": "Đàn Tranh có bao nhiêu dây?", "options": ["12 dây", "16 dây", "21 dây", "9 dây"], "answer": 1},
	{"q": "Sáo Trúc thổi theo kỹ thuật nào?", "options": ["Pizzicato", "Legato breath", "Vibrato tay", "Staccato"], "answer": 1},
	{"q": "Nhịp 2/4 có mấy phách mỗi ô nhịp?", "options": ["4", "3", "2", "6"], "answer": 2},
	{"q": "Ký hiệu nào biểu thị 'nhẹ nhàng' trong nhạc cụ?", "options": ["Forte (f)", "Piano (p)", "Mezzo (m)", "Sforzando"], "answer": 1},
	{"q": "Đàn Bầu có bao nhiêu dây?", "options": ["2", "4", "1", "6"], "answer": 2},
	{"q": "Trống Cơm dùng trong thể loại nhạc nào?", "options": ["Nhạc Jazz", "Nhạc dân tộc", "Nhạc rock", "Nhạc cổ điển TBN"], "answer": 1},
]

# ── Melody Completion nodes ──────────────────────────────────────────────────
var mc_sequence: Array = []
var mc_blanks: Array = []
var mc_user_answers: Array = []
var mc_note_buttons: Array = []
var mc_slot_labels: Array = []
var mc_feedback: Label
var mc_submit_btn: Button
var mc_current_slot: int = 0
var _mc_sequences: Array = [
	{"notes": ["Đô", "Rê", "Mi", "Sol", "La"], "blanks": [1, 3]},
	{"notes": ["Sol", "La", "Đô", "Rê", "Mi"], "blanks": [0, 2, 4]},
	{"notes": ["Mi", "Sol", "La", "Đô", "Rê"], "blanks": [2, 4]},
	{"notes": ["La", "Sol", "Mi", "Rê", "Đô"], "blanks": [1, 3]},
	{"notes": ["Rê", "Mi", "Sol", "La", "Đô"], "blanks": [0, 4]},
]
var _mc_index: int = 0
var _mc_completed: bool = false

# ═══════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_shell()
	hide()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

func _process(delta: float) -> void:
	if not active:
		return
	_timer_elapsed += delta
	var remaining: float = max(0.0, _timer_total - _timer_elapsed)
	header_timer.text = "%02d:%02d" % [int(remaining) / 60, int(remaining) % 60]
	if _timer_elapsed >= _timer_total:
		_finish_game()
		return
	# Rhythm Match – note spawning & movement
	if current_type == MiniType.RHYTHM_MATCH and rm_in_progress:
		rm_beat_timer += delta
		if rm_beat_timer >= rm_beat_interval:
			rm_beat_timer = 0.0
			_rm_spawn_note()
		_rm_move_notes(delta)

# ─── Public API ─────────────────────────────────────────────────────────────
func start_minigame(type: int, difficulty: String = "Beginner") -> void:
	current_type = type
	score = 0
	max_score = 0
	hits = 0
	misses = 0
	current_question = 0
	_timer_elapsed = 0.0
	active = true
	run_id += 1
	_update_header_type()
	_timer_total = 45.0 if difficulty == "Advanced" else (35.0 if difficulty == "Intermediate" else 30.0)
	rm_combo = 0
	rm_notes.clear()
	rm_in_progress = false
	rm_beat_timer = 0.0
	_mc_index = 0
	_mc_completed = false
	for n in rm_note_layer.get_children():
		n.queue_free()
	_clear_content()
	match type:
		MiniType.RHYTHM_MATCH:
			_build_rhythm_match()
			rm_in_progress = true
			max_score = 10 * 100
		MiniType.NOTE_QUIZ:
			_build_note_quiz()
			max_score = total_questions * 100
		MiniType.MELODY_COMPLETION:
			_build_melody_completion()
			max_score = _mc_sequences.size() * 100
	show()

func stop_minigame() -> void:
	active = false
	rm_in_progress = false
	hide()
	minigame_cancelled.emit()

# ─── Shell ──────────────────────────────────────────────────────────────────
func _build_shell() -> void:
	overlay = ColorRect.new()
	overlay.name = "MiniGameOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = SHADOW
	add_child(overlay)

	# Header
	header_panel = PanelContainer.new()
	header_panel.name = "MiniHeader"
	header_panel.anchor_left = 0.0
	header_panel.anchor_top = 0.0
	header_panel.anchor_right = 1.0
	header_panel.anchor_bottom = 0.0
	header_panel.offset_left = 24
	header_panel.offset_top = 20
	header_panel.offset_right = -24
	header_panel.offset_bottom = 78
	header_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.05, 0.035, 0.97), BRASS, 10))
	add_child(header_panel)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 14)
	header_panel.add_child(hrow)
	var type_icon := _label("🎵", 22, BRASS)
	type_icon.custom_minimum_size = Vector2(32, 0)
	hrow.add_child(type_icon)
	header_title = _label("Mini-game", 22, CREAM)
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(header_title)
	header_score = _label("Score: 0", 20, BRASS)
	hrow.add_child(header_score)
	header_timer = _label("00:30", 20, JADE)
	header_timer.custom_minimum_size = Vector2(72, 0)
	header_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hrow.add_child(header_timer)
	pause_btn = _button("✕ Exit", WOOD_PANEL, CREAM)
	pause_btn.pressed.connect(stop_minigame)
	hrow.add_child(pause_btn)

	# Content
	content_area = Control.new()
	content_area.name = "ContentArea"
	content_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_area.offset_top = 88
	content_area.offset_bottom = -78
	add_child(content_area)

	# Footer
	footer_panel = PanelContainer.new()
	footer_panel.name = "MiniFooter"
	footer_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.offset_left = 24
	footer_panel.offset_right = -24
	footer_panel.offset_top = -68
	footer_panel.offset_bottom = -16
	footer_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.04, 0.03, 0.94), BRASS_DIM, 10))
	add_child(footer_panel)

	# Rhythm note layer (persistent, hidden behind content)
	rm_note_layer = Control.new()
	rm_note_layer.name = "_RhythmNoteLayer"
	rm_note_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	rm_note_layer.clip_contents = true
	rm_note_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rm_note_layer)

func _clear_content() -> void:
	for child in content_area.get_children():
		child.queue_free()
	for child in footer_panel.get_children():
		child.queue_free()
	# Clear rhythm notes
	for child in rm_note_layer.get_children():
		child.queue_free()
	rm_notes.clear()
	nq_options.clear()
	mc_note_buttons.clear()
	mc_slot_labels.clear()

func _update_header_type() -> void:
	match current_type:
		MiniType.RHYTHM_MATCH:
			header_title.text = "Rhythm Match  •  Nhịp Điệu"
			header_timer.modulate = JADE
		MiniType.NOTE_QUIZ:
			header_title.text = "Note Quiz  •  Nhận Biết Nốt"
			header_timer.modulate = BRASS
		MiniType.MELODY_COMPLETION:
			header_title.text = "Melody Completion  •  Hoàn Thiện Giai Điệu"
			header_timer.modulate = SON_RED

# ═══════════════════════════════════════════════════════════════════════════
# RHYTHM MATCH
# ═══════════════════════════════════════════════════════════════════════════
func _build_rhythm_match() -> void:
	# Instructions
	var inst := _label("Nhấn SPACE hoặc chạm màn hình khi nốt nhạc đi qua vùng HIT!", 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	inst.set_anchors_preset(Control.PRESET_TOP_WIDE)
	inst.offset_top = 12
	inst.offset_bottom = 46
	content_area.add_child(inst)

	# Lane background
	rm_lane = PanelContainer.new()
	rm_lane.name = "RhythmLane"
	rm_lane.set_anchors_preset(Control.PRESET_CENTER)
	rm_lane.custom_minimum_size = Vector2(680, 160)
	rm_lane.offset_left = -340
	rm_lane.offset_top = -80
	rm_lane.offset_right = 340
	rm_lane.offset_bottom = 80
	rm_lane.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.03, 0.02, 0.96), BRASS_DIM, 10))
	content_area.add_child(rm_lane)

	# Hit zone (fixed at 1/4 from left)
	rm_hit_zone = ColorRect.new()
	rm_hit_zone.name = "HitZone"
	rm_hit_zone.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	rm_hit_zone.custom_minimum_size = Vector2(14, 140)
	rm_hit_zone.offset_left = 156
	rm_hit_zone.offset_top = -70
	rm_hit_zone.offset_right = 170
	rm_hit_zone.offset_bottom = 70
	rm_hit_zone.color = Color(BRASS, 0.55)
	rm_lane.add_child(rm_hit_zone)

	# Lane divider lines
	var lane_deco := Control.new()
	lane_deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	lane_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rm_lane.add_child(lane_deco)

	# Combo display
	rm_combo_label = _label("Combo x0", 20, JADE, HORIZONTAL_ALIGNMENT_CENTER)
	rm_combo_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rm_combo_label.offset_top = -100
	rm_combo_label.offset_bottom = -64
	content_area.add_child(rm_combo_label)

	# Hit feedback
	rm_hit_label = _label("", 32, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	rm_hit_label.set_anchors_preset(Control.PRESET_CENTER)
	rm_hit_label.offset_left = -160
	rm_hit_label.offset_top = -80
	rm_hit_label.offset_right = 160
	rm_hit_label.offset_bottom = -40
	content_area.add_child(rm_hit_label)

	# Footer: stats
	var frow := HBoxContainer.new()
	frow.alignment = BoxContainer.ALIGNMENT_CENTER
	frow.add_theme_constant_override("separation", 48)
	footer_panel.add_child(frow)
	frow.add_child(_label("Hits: 0", 17, SUCCESS))
	frow.add_child(_label("Misses: 0", 17, SON_RED))
	frow.add_child(_label("Press SPACE or TAP to hit!", 15, MUTED))

	# Set up keyboard/touch input handler
	set_process_unhandled_input(true)

func _rm_spawn_note() -> void:
	var is_strong := rm_notes.size() % 4 == 0
	var note_node := ColorRect.new()
	note_node.size = Vector2(28 if is_strong else 20, 28 if is_strong else 20)
	note_node.color = BRASS if is_strong else JADE
	# Position relative to rm_note_layer (full screen)
	var lane_rect := rm_lane.get_global_rect()
	var start_x := lane_rect.end.x + 20.0
	var center_y := lane_rect.position.y + lane_rect.size.y * 0.5 - note_node.size.y * 0.5
	note_node.position = Vector2(start_x, center_y)
	rm_note_layer.add_child(note_node)
	rm_notes.append({"node": note_node, "hit": false, "x_start": start_x})

func _rm_move_notes(delta: float) -> void:
	var lane_rect := rm_lane.get_global_rect()
	var hit_x := lane_rect.position.x + 163.0
	var remove_indices: Array = []
	for i in range(rm_notes.size()):
		var note_data: Dictionary = rm_notes[i]
		if not is_instance_valid(note_data["node"]):
			remove_indices.append(i)
			continue
		var n: ColorRect = note_data["node"]
		n.position.x -= rm_note_speed * delta
		# Auto-miss if passed hit zone without interaction
		if n.position.x < hit_x - 60.0 and not note_data["hit"]:
			note_data["hit"] = true
			misses += 1
			rm_combo = 0
			_rm_show_hit("Miss!", false)
			_update_footer_stats()
		if n.position.x < -100.0:
			remove_indices.append(i)
			n.queue_free()
	# Remove in reverse order to keep indices valid
	for i in range(remove_indices.size() - 1, -1, -1):
		rm_notes.remove_at(remove_indices[i])

func _rm_attempt_hit() -> void:
	if not active or current_type != MiniType.RHYTHM_MATCH:
		return
	var lane_rect := rm_lane.get_global_rect()
	var hit_x := lane_rect.position.x + 163.0
	var best_dist := 9999.0
	var best_note: Dictionary = {}
	for note_data in rm_notes:
		if note_data["hit"]:
			continue
		if not is_instance_valid(note_data["node"]):
			continue
		var n: ColorRect = note_data["node"]
		var dist: float = abs(n.position.x - hit_x)
		if dist < best_dist:
			best_dist = dist
			best_note = note_data
	if best_note.is_empty():
		misses += 1
		rm_combo = 0
		_rm_show_hit("Empty!", false)
		_update_footer_stats()
		return
	best_note["hit"] = true
	if best_dist < 40.0:
		score += 125
		hits += 1
		rm_combo += 1
		_rm_show_hit("Perfect!" if best_dist < 18.0 else "Good!", true)
	elif best_dist < 80.0:
		score += 60
		hits += 1
		rm_combo += 1
		_rm_show_hit("Late", false)
	else:
		misses += 1
		rm_combo = 0
		_rm_show_hit("Miss!", false)
	_update_footer_stats()
	header_score.text = "Score: %d" % score

func _rm_show_hit(text: String, positive: bool) -> void:
	rm_hit_label.text = text
	rm_hit_label.modulate = BRASS if text == "Perfect!" else (SUCCESS if positive else SON_RED)
	rm_combo_label.text = "Combo x%d" % rm_combo
	var tw := create_tween()
	rm_hit_label.scale = Vector2(1.3, 1.3)
	tw.tween_property(rm_hit_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

	# Flash hit zone
	rm_hit_zone.color = Color(BRASS if positive else SON_RED, 0.9)
	var tw2 := create_tween()
	tw2.tween_property(rm_hit_zone, "color", Color(BRASS, 0.45), 0.22)

func _unhandled_input(event: InputEvent) -> void:
	if not active or current_type != MiniType.RHYTHM_MATCH:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_rm_attempt_hit()
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch and event.pressed:
		_rm_attempt_hit()

func _update_footer_stats() -> void:
	if footer_panel.get_child_count() == 0:
		return
	var frow := footer_panel.get_child(0)
	if frow is HBoxContainer and frow.get_child_count() >= 2:
		if frow.get_child(0) is Label:
			frow.get_child(0).text = "Hits: %d" % hits
		if frow.get_child(1) is Label:
			frow.get_child(1).text = "Misses: %d" % misses

# ═══════════════════════════════════════════════════════════════════════════
# NOTE QUIZ
# ═══════════════════════════════════════════════════════════════════════════
func _build_note_quiz() -> void:
	_nq_data.shuffle()
	total_questions = min(5, _nq_data.size())
	current_question = 0

	# Question panel
	var q_panel := PanelContainer.new()
	q_panel.set_anchors_preset(Control.PRESET_CENTER)
	q_panel.custom_minimum_size = Vector2(640, 340)
	q_panel.offset_left = -320
	q_panel.offset_top = -170
	q_panel.offset_right = 320
	q_panel.offset_bottom = 170
	q_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.97), BRASS, 12))
	content_area.add_child(q_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	q_panel.add_child(vbox)

	# Progress indicator
	var prog_row := HBoxContainer.new()
	prog_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_row.add_theme_constant_override("separation", 8)
	vbox.add_child(prog_row)
	for i in range(total_questions):
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 18)
		dot.add_theme_color_override("font_color", BRASS if i == 0 else MUTED)
		prog_row.add_child(dot)

	# Question label
	nq_question_label = _label("", 20, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	nq_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nq_question_label.custom_minimum_size = Vector2(580, 58)
	vbox.add_child(nq_question_label)

	# Options grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)
	nq_options.clear()
	for i in range(4):
		var btn := _button("", WOOD_PANEL, CREAM)
		btn.custom_minimum_size = Vector2(270, 52)
		btn.add_theme_font_size_override("font_size", 17)
		var idx := i
		btn.pressed.connect(func(): _nq_answer(idx))
		grid.add_child(btn)
		nq_options.append(btn)

	# Feedback
	nq_feedback = _label("", 22, JADE, HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(nq_feedback)

	# Footer: Next question button
	var frow := HBoxContainer.new()
	frow.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_panel.add_child(frow)
	var next_btn := _button("Câu tiếp theo →", BRASS, WOOD_DARK)
	next_btn.add_theme_font_size_override("font_size", 17)
	next_btn.pressed.connect(_nq_next)
	frow.add_child(next_btn)
	frow.add_child(_label("  Câu %d / %d" % [current_question + 1, total_questions], 16, MUTED))

	_nq_load_question()

func _nq_load_question() -> void:
	if current_question >= _nq_data.size():
		_finish_game()
		return
	var q: Dictionary = _nq_data[current_question]
	nq_question_label.text = q["q"]
	nq_feedback.text = ""
	nq_answered = false
	for i in range(nq_options.size()):
		nq_options[i].text = q["options"][i]
		nq_options[i].disabled = false
		nq_options[i].add_theme_stylebox_override("normal", _panel_style(WOOD_PANEL, WOOD_PANEL.lightened(0.18), 8))
		nq_options[i].add_theme_color_override("font_color", CREAM)

func _nq_answer(idx: int) -> void:
	if nq_answered:
		return
	nq_answered = true
	var q: Dictionary = _nq_data[current_question]
	var correct: int = q["answer"]
	for i in range(nq_options.size()):
		nq_options[i].disabled = true
		if i == correct:
			nq_options[i].add_theme_stylebox_override("normal", _panel_style(SUCCESS, SUCCESS, 8))
			nq_options[i].add_theme_color_override("font_color", WOOD_DARK)
		elif i == idx and idx != correct:
			nq_options[i].add_theme_stylebox_override("normal", _panel_style(SON_RED, SON_RED, 8))
	if idx == correct:
		score += 100
		hits += 1
		nq_feedback.text = "✓ Chính xác!"
		nq_feedback.modulate = SUCCESS
	else:
		misses += 1
		nq_feedback.text = "✗ Đáp án đúng: %s" % q["options"][correct]
		nq_feedback.modulate = SON_RED
	header_score.text = "Score: %d" % score
	var tw := create_tween()
	nq_feedback.scale = Vector2(1.2, 1.2)
	tw.tween_property(nq_feedback, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _nq_next() -> void:
	if not nq_answered:
		return
	current_question += 1
	if current_question >= total_questions:
		_finish_game()
		return
	# Update progress dots
	var q_panel := content_area.get_child(0)
	if q_panel and q_panel.get_child_count() > 0:
		var vb := q_panel.get_child(0)
		if vb and vb.get_child_count() > 0:
			var prog := vb.get_child(0)
			if prog is HBoxContainer:
				for i in range(prog.get_child_count()):
					if prog.get_child(i) is Label:
						prog.get_child(i).add_theme_color_override("font_color", BRASS if i <= current_question else MUTED)
	_nq_load_question()
	# Update footer counter
	if footer_panel.get_child_count() > 0:
		var frow := footer_panel.get_child(0)
		if frow is HBoxContainer and frow.get_child_count() >= 2:
			if frow.get_child(1) is Label:
				frow.get_child(1).text = "  Câu %d / %d" % [current_question + 1, total_questions]

# ═══════════════════════════════════════════════════════════════════════════
# MELODY COMPLETION
# ═══════════════════════════════════════════════════════════════════════════
func _build_melody_completion() -> void:
	_mc_sequences.shuffle()
	_mc_index = 0
	_mc_completed = false
	_mc_load_round()

	# Footer instructions
	var frow := HBoxContainer.new()
	frow.alignment = BoxContainer.ALIGNMENT_CENTER
	frow.add_theme_constant_override("separation", 14)
	footer_panel.add_child(frow)
	mc_submit_btn = _button("✓ Xác nhận", BRASS, WOOD_DARK)
	mc_submit_btn.add_theme_font_size_override("font_size", 17)
	mc_submit_btn.pressed.connect(_mc_submit)
	frow.add_child(mc_submit_btn)
	var reset_btn := _button("↺ Thử lại", WOOD_PANEL, CREAM)
	reset_btn.pressed.connect(_mc_reset_round)
	frow.add_child(reset_btn)
	frow.add_child(_label("Chọn nốt nhạc còn thiếu theo thứ tự", 15, MUTED))

func _mc_load_round() -> void:
	for c in content_area.get_children():
		c.queue_free()
	mc_slot_labels.clear()
	mc_note_buttons.clear()
	mc_user_answers.clear()
	mc_current_slot = 0

	if _mc_index >= _mc_sequences.size():
		_finish_game()
		return

	var seq_data: Dictionary = _mc_sequences[_mc_index]
	mc_sequence = seq_data["notes"]
	mc_blanks = seq_data["blanks"]
	mc_user_answers.resize(mc_blanks.size())
	for i in range(mc_blanks.size()):
		mc_user_answers[i] = ""

	# Round header
	var round_lbl := _label("Bài %d / %d  —  Điền nốt còn thiếu vào ô trống" % [_mc_index + 1, _mc_sequences.size()], 19, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	round_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	round_lbl.offset_top = 14
	round_lbl.offset_bottom = 48
	content_area.add_child(round_lbl)

	# Melody slots
	var slots_container := HBoxContainer.new()
	slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_container.add_theme_constant_override("separation", 10)
	slots_container.set_anchors_preset(Control.PRESET_CENTER)
	slots_container.offset_top = -60
	slots_container.offset_bottom = 20
	slots_container.offset_left = -400
	slots_container.offset_right = 400
	content_area.add_child(slots_container)

	var blank_idx := 0
	for i in range(mc_sequence.size()):
		var slot_panel := PanelContainer.new()
		var is_blank := mc_blanks.has(i)
		slot_panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.12, 0.065, 0.045, 0.96) if not is_blank else Color(0.06, 0.03, 0.02, 0.96),
			BRASS if not is_blank else BRASS_DIM,
			8
		))
		slot_panel.custom_minimum_size = Vector2(80, 80)
		slots_container.add_child(slot_panel)
		var slot_vbox := VBoxContainer.new()
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_panel.add_child(slot_vbox)
		var num_lbl := _label(str(i + 1), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		slot_vbox.add_child(num_lbl)
		var note_lbl := Label.new()
		note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note_lbl.add_theme_font_size_override("font_size", 22)
		if is_blank:
			note_lbl.text = "?"
			note_lbl.add_theme_color_override("font_color", BRASS_DIM)
			mc_slot_labels.append(note_lbl)
		else:
			note_lbl.text = mc_sequence[i]
			note_lbl.add_theme_color_override("font_color", CREAM)
		slot_vbox.add_child(note_lbl)
		if is_blank:
			blank_idx += 1

	# Available notes palette
	var palette_lbl := _label("Chọn nốt:", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	palette_lbl.set_anchors_preset(Control.PRESET_CENTER)
	palette_lbl.offset_top = 40
	palette_lbl.offset_bottom = 70
	palette_lbl.offset_left = -200
	palette_lbl.offset_right = 200
	content_area.add_child(palette_lbl)

	var palette := HBoxContainer.new()
	palette.alignment = BoxContainer.ALIGNMENT_CENTER
	palette.add_theme_constant_override("separation", 12)
	palette.set_anchors_preset(Control.PRESET_CENTER)
	palette.offset_top = 72
	palette.offset_bottom = 120
	palette.offset_left = -400
	palette.offset_right = 400
	content_area.add_child(palette)

	var all_notes := ["Đô", "Rê", "Mi", "Sol", "La"]
	for note_str in all_notes:
		var nbtn := _button(note_str, WOOD_PANEL, CREAM)
		nbtn.add_theme_font_size_override("font_size", 18)
		nbtn.custom_minimum_size = Vector2(74, 52)
		var n: String = note_str
		nbtn.pressed.connect(func(): _mc_pick_note(n))
		palette.add_child(nbtn)
		mc_note_buttons.append(nbtn)

	# Feedback
	mc_feedback = _label("", 22, JADE, HORIZONTAL_ALIGNMENT_CENTER)
	mc_feedback.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mc_feedback.offset_top = -140
	mc_feedback.offset_bottom = -100
	content_area.add_child(mc_feedback)

func _mc_pick_note(note: String) -> void:
	if mc_current_slot >= mc_blanks.size():
		return
	mc_user_answers[mc_current_slot] = note
	if mc_current_slot < mc_slot_labels.size():
		mc_slot_labels[mc_current_slot].text = note
		mc_slot_labels[mc_current_slot].add_theme_color_override("font_color", CREAM)
		# Style the slot as filled
		var slot_panel: PanelContainer = mc_slot_labels[mc_current_slot].get_parent().get_parent()
		if slot_panel:
			slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.09, 0.055, 0.96), BRASS, 8))
	mc_current_slot += 1
	if mc_current_slot >= mc_blanks.size():
		mc_feedback.text = "Nhấn 'Xác nhận' để kiểm tra!"
		mc_feedback.modulate = BRASS

func _mc_reset_round() -> void:
	mc_current_slot = 0
	for i in range(mc_user_answers.size()):
		mc_user_answers[i] = ""
	for lbl in mc_slot_labels:
		if is_instance_valid(lbl):
			lbl.text = "?"
			lbl.add_theme_color_override("font_color", BRASS_DIM)
			var slot_panel: PanelContainer = lbl.get_parent().get_parent()
			if slot_panel:
				slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.03, 0.02, 0.96), BRASS_DIM, 8))
	mc_feedback.text = ""

func _mc_submit() -> void:
	if mc_current_slot < mc_blanks.size():
		mc_feedback.text = "Điền đủ tất cả ô trống trước!"
		mc_feedback.modulate = SON_RED
		return
	var all_correct := true
	for i in range(mc_blanks.size()):
		var blank_pos: int = mc_blanks[i]
		var expected: String = mc_sequence[blank_pos]
		var given: String = mc_user_answers[i]
		var lbl: Label = mc_slot_labels[i]
		if given == expected:
			if is_instance_valid(lbl):
				lbl.add_theme_color_override("font_color", SUCCESS)
		else:
			all_correct = false
			if is_instance_valid(lbl):
				lbl.text = given + "✗"
				lbl.add_theme_color_override("font_color", SON_RED)
	if all_correct:
		score += 100
		hits += 1
		mc_feedback.text = "✓ Hoàn hảo! Giai điệu chính xác!"
		mc_feedback.modulate = SUCCESS
	else:
		misses += 1
		mc_feedback.text = "✗ Chưa đúng. Xem lại nốt đánh dấu đỏ."
		mc_feedback.modulate = SON_RED
	header_score.text = "Score: %d" % score
	await get_tree().create_timer(1.6).timeout
	_mc_index += 1
	if _mc_index >= _mc_sequences.size():
		_finish_game()
	else:
		_mc_load_round()

# ═══════════════════════════════════════════════════════════════════════════
# FINISH
# ═══════════════════════════════════════════════════════════════════════════
func _finish_game() -> void:
	if not active:
		return
	active = false
	rm_in_progress = false
	var accuracy := int(float(hits) / max(1, hits + misses) * 100.0)
	var stars := 1
	if accuracy >= 85:
		stars = 3
	elif accuracy >= 65:
		stars = 2
	var xp := 40 + stars * 30
	var result := {
		"type": current_type,
		"score": score,
		"hits": hits,
		"misses": misses,
		"accuracy": accuracy,
		"stars": stars,
		"xp_awarded": xp,
		"badge": "Rhythm Champion" if current_type == MiniType.RHYTHM_MATCH and stars == 3 else (
			"Quick Learner" if current_type == MiniType.NOTE_QUIZ and stars == 3 else (
			"Melody Master" if current_type == MiniType.MELODY_COMPLETION and stars == 3 else "Practice Logged"))
	}
	_show_result_overlay(result)

func _show_result_overlay(result: Dictionary) -> void:
	var result_panel := PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.custom_minimum_size = Vector2(520, 360)
	result_panel.offset_left = -260
	result_panel.offset_top = -180
	result_panel.offset_right = 260
	result_panel.offset_bottom = 180
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.11, 0.06, 0.04, 0.99), BRASS, 6))
	add_child(result_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	result_panel.add_child(vbox)

	var type_name: String = ["Rhythm Match", "Note Quiz", "Melody Completion"][int(result["type"])]
	vbox.add_child(_label(type_name + " – Kết thúc!", 26, BRASS, HORIZONTAL_ALIGNMENT_CENTER))

	var stars_str := ""
	for i in range(3):
		stars_str += "★" if i < int(result["stars"]) else "☆"
	var stars_lbl := _label(stars_str, 40, STAR_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(stars_lbl)

	vbox.add_child(_label("Điểm: %d   Chính xác: %d%%   Hits: %d   Misses: %d" % [
		result["score"], result["accuracy"], result["hits"], result["misses"]
	], 17, CREAM, HORIZONTAL_ALIGNMENT_CENTER))

	vbox.add_child(_label("+%d XP  –  %s" % [result["xp_awarded"], result["badge"]], 20, JADE, HORIZONTAL_ALIGNMENT_CENTER))

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var close_btn := _button("Đóng", BRASS, WOOD_DARK)
	close_btn.add_theme_font_size_override("font_size", 17)
	close_btn.pressed.connect(func():
		hide()
		minigame_finished.emit(result)
	)
	btn_row.add_child(close_btn)

	var replay_btn := _button("Chơi lại", WOOD_PANEL, CREAM)
	replay_btn.pressed.connect(func():
		result_panel.queue_free()
		start_minigame(current_type)
	)
	btn_row.add_child(replay_btn)

	# Entrance animation
	result_panel.scale = Vector2(0.8, 0.8)
	result_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(result_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(result_panel, "modulate:a", 1.0, 0.22)

# ═══════════════════════════════════════════════════════════════════════════
# STYLE HELPERS
# ═══════════════════════════════════════════════════════════════════════════
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
	button.custom_minimum_size = Vector2(120, 44)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal",  _panel_style(bg, bg.lightened(0.18), 1296))
	button.add_theme_stylebox_override("hover",   _panel_style(bg.lightened(0.1), BRASS, 1296))
	button.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.12), BRASS, 1296))
	
	# Premium hover scale animation
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.mouse_entered.connect(func():
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.15).set_trans(Tween.TRANS_SINE)
	)
	button.mouse_exited.connect(func():
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
	)
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
	# Premium modern drop shadow config
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


# ── Helper for badge translation ──
func _badge_title(badge_name: String) -> String:
	match badge_name:
		"Rhythm Champion": return "Quán quân nhịp điệu"
		"Quick Learner": return "Học nhanh"
		"Melody Master": return "Bậc thầy giai điệu"
		"Practice Logged": return "Đã ghi nhận luyện tập"
		_: return badge_name

func _apply_responsive_layout() -> void:
	var w: float = get_viewport().get_visible_rect().size.x
	var desktop := false # Optimized exclusively for phone/mobile
	
	# Co giãn header
	if is_instance_valid(header_panel):
		header_panel.offset_left = 16 if not desktop else 24
		header_panel.offset_right = -16 if not desktop else -24
		header_panel.offset_top = 10 if not desktop else 20
		header_panel.offset_bottom = 68 if not desktop else 78

	# Co giãn footer
	if is_instance_valid(footer_panel):
		footer_panel.offset_left = 16 if not desktop else 24
		footer_panel.offset_right = -16 if not desktop else -24
		footer_panel.offset_top = -68
		footer_panel.offset_bottom = -16

	# Co giãn làn chạy nhịp điệu (Rhythm Match)
	if is_instance_valid(rm_lane):
		var lane_w: float = min(680.0, w - 24.0)
		rm_lane.custom_minimum_size = Vector2(lane_w, 160)
		rm_lane.offset_left = -lane_w * 0.5
		rm_lane.offset_right = lane_w * 0.5
		
		# Co giãn vị trí HitZone tương thích mobile
		if is_instance_valid(rm_hit_zone):
			var hit_left: float = lane_w * 0.23
			rm_hit_zone.offset_left = hit_left
			rm_hit_zone.offset_right = hit_left + 14.0

	# Co giãn Quiz panel
	var q_panel: Node = content_area.find_child("q_panel", true, false)
	if q_panel == null and content_area.get_child_count() > 0:
		var first := content_area.get_child(0)
		if first is PanelContainer:
			q_panel = first
	if q_panel:
		var q_w: float = min(640.0, w - 24.0)
		var q_h: float = min(270.0, get_viewport().get_visible_rect().size.y - 140.0)
		(q_panel as Control).custom_minimum_size = Vector2(q_w, q_h)
		(q_panel as Control).offset_left = -q_w * 0.5
		(q_panel as Control).offset_right = q_w * 0.5
		(q_panel as Control).offset_top = -q_h * 0.5
		(q_panel as Control).offset_bottom = q_h * 0.5
		
		# Đổi số lượng cột trắc nghiệm nq_options
		var grid: Node = q_panel.find_child("GridContainer", true, false)
		if grid == null:
			for child in q_panel.get_child(0).get_children():
				if child is GridContainer:
					grid = child
					break
		if grid:
			(grid as GridContainer).columns = 1 if not desktop else 2
			for btn in nq_options:
				if is_instance_valid(btn):
					(btn as Control).custom_minimum_size = Vector2(q_w - 56.0 if not desktop else 270.0, 48.0)

	# Co giãn Melody slots
	var slots_container: Node = content_area.find_child("slots_container", true, false)
	if slots_container == null and content_area.get_child_count() > 1:
		for child in content_area.get_children():
			if child is HBoxContainer:
				slots_container = child
				break
	if slots_container:
		var slots_w: float = min(800.0, w - 20.0)
		(slots_container as Control).offset_left = -slots_w * 0.5
		(slots_container as Control).offset_right = slots_w * 0.5
		
		# Co giãn kích thước từng slot panel
		for slot in slots_container.get_children():
			if slot is PanelContainer:
				slot.custom_minimum_size = Vector2(56 if not desktop else 80, 56 if not desktop else 80)
				var vbox := slot.get_child(0)
				if vbox and vbox.get_child_count() >= 2:
					var note_lbl = vbox.get_child(1)
					if note_lbl is Label:
						note_lbl.add_theme_font_size_override("font_size", 16 if not desktop else 22)

	# Co giãn Melody options palette
	var palette: Node = content_area.find_child("palette", true, false)
	if palette == null and content_area.get_child_count() > 3:
		var cnt := 0
		for child in content_area.get_children():
			if child is HBoxContainer:
				cnt += 1
				if cnt == 2:
					palette = child
					break
	if palette:
		var pal_w: float = min(800.0, w - 20.0)
		(palette as Control).offset_left = -pal_w * 0.5
		(palette as Control).offset_right = pal_w * 0.5
		for btn in mc_note_buttons:
			if is_instance_valid(btn):
				(btn as Control).custom_minimum_size = Vector2(52 if not desktop else 74, 44 if not desktop else 52)
				(btn as Control).add_theme_font_size_override("font_size", 14 if not desktop else 18)
