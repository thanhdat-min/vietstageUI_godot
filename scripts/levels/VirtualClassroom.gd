extends Node2D
class_name VirtualClassroom

enum FlowState { LOGIN, EXPLORE, LESSON_SELECT, ARTIST_DEMO, PRACTICE, RESULT, MINIGAME, PROGRESS, AUDIO_LIB, DAILY }

@onready var learner: Learner                  = $Learner
@onready var virtual_artist: VirtualArtist     = $VirtualArtist
@onready var dan_tranh_station: InstrumentStation = $InstrumentStation_DanTranh
@onready var dan_bau_station: InstrumentStation   = $InstrumentStation_DanBau
@onready var sao_truc_station: InstrumentStation  = $InstrumentStation_SaoTruc
@onready var trong_station: InstrumentStation     = $InstrumentStation_Trong
@onready var camera: Camera2D                  = $Learner/Camera2D
@onready var shell_ui: GameShellUI             = $CanvasLayer/GameShellUI
@onready var practice_ui: PracticeUI           = $CanvasLayer/PracticeUI
@onready var minigame_ui: Control              = $CanvasLayer/MiniGameUI

var state: int = FlowState.LOGIN
var current_lesson: Dictionary = {}
var practice_run_id: int = 0

var gamification: Dictionary = {
	"xp":               640,
	"level":            5,
	"xp_to_next":       1000,
	"weekly_score":     12840,
	"streak_days":      6,
	"practice_time":    4800,
	"badges":           ["First Rhythm", "Dan Tranh Novice", "Three Day Streak"],
	"accuracy_history": [72.0, 68.0, 75.0, 80.0, 84.0, 79.0, 88.0],
	"lessons_done":     7,
	"lessons_total":    12,
}

var lessons: Array[Dictionary] = [
	{
		"lesson_id":       "dt_001",
		"instrument":      "dan_tranh",
		"title":           "Kỹ thuật gảy cơ bản",
		"difficulty":      "Beginner",
		"required_level":  1,
		"stars":           2,
		"is_unlocked":     true,
		"reference_audio": "res://assets/audio/dan_tranh.wav",
		"beat_map":        [0.0, 0.75, 1.5, 2.25, 3.0]
	},
	{
		"lesson_id":       "dt_002",
		"instrument":      "dan_tranh",
		"title":           "Kỹ thuật rung tay trái",
		"difficulty":      "Intermediate",
		"required_level":  5,
		"stars":           0,
		"is_unlocked":     true,
		"reference_audio": "res://assets/audio/dan_tranh.wav",
		"beat_map":        [0.0, 0.5, 1.0, 1.75, 2.5]
	},
	{
		"lesson_id":       "dt_003",
		"instrument":      "dan_tranh",
		"title":           "Chuỗi Tremolo nhanh",
		"difficulty":      "Advanced",
		"required_level":  8,
		"stars":           0,
		"is_unlocked":     false,
		"reference_audio": "res://assets/audio/dan_tranh.wav",
		"beat_map":        [0.0, 0.25, 0.5, 0.75, 1.0]
	},
	{
		"lesson_id":       "db_001",
		"instrument":      "dan_bau",
		"title":           "Nốt Đơn Đàn Bầu",
		"difficulty":      "Beginner",
		"required_level":  1,
		"stars":           0,
		"is_unlocked":     true,
		"reference_audio": "",
		"beat_map":        [0.0, 1.0, 2.0, 3.0]
	},
	{
		"lesson_id":       "db_002",
		"instrument":      "dan_bau",
		"title":           "Kỹ thuật Nhấn Vuốt",
		"difficulty":      "Intermediate",
		"required_level":  4,
		"stars":           0,
		"is_unlocked":     true,
		"reference_audio": "",
		"beat_map":        [0.0, 0.5, 1.5, 2.0, 3.0]
	},
	{
		"lesson_id":       "db_003",
		"instrument":      "dan_bau",
		"title":           "Nhấn Vuốt nâng cao",
		"difficulty":      "Advanced",
		"required_level":  7,
		"stars":           0,
		"is_unlocked":     false,
		"reference_audio": "",
		"beat_map":        [0.0, 0.3, 0.6, 0.9, 1.2, 1.5]
	},
	{
		"lesson_id":       "st_001",
		"instrument":      "sao_truc",
		"title":           "Nhịp lấy hơi cơ bản",
		"difficulty":      "Beginner",
		"required_level":  1,
		"stars":           1,
		"is_unlocked":     true,
		"reference_audio": "",
		"beat_map":        [0.0, 1.0, 2.0, 3.0]
	},
	{
		"lesson_id":       "st_002",
		"instrument":      "sao_truc",
		"title":           "Kỹ thuật ngân vang",
		"difficulty":      "Intermediate",
		"required_level":  3,
		"stars":           0,
		"is_unlocked":     true,
		"reference_audio": "",
		"beat_map":        [0.0, 1.25, 2.5, 3.75]
	},
	{
		"lesson_id":       "st_003",
		"instrument":      "sao_truc",
		"title":           "Lưỡng đơn cực nhanh",
		"difficulty":      "Advanced",
		"required_level":  6,
		"stars":           0,
		"is_unlocked":     false,
		"reference_audio": "",
		"beat_map":        [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2]
	},
	{
		"lesson_id":       "tr_001",
		"instrument":      "trong",
		"title":           "Nhịp Trống Hội",
		"difficulty":      "Beginner",
		"required_level":  1,
		"stars":           0,
		"is_unlocked":     true,
		"reference_audio": "",
		"beat_map":        [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
	},
	{
		"lesson_id":       "tr_002",
		"instrument":      "trong",
		"title":           "Điệu Trống Bông rộn rã",
		"difficulty":      "Intermediate",
		"required_level":  3,
		"stars":           0,
		"is_unlocked":     true,
		"reference_audio": "",
		"beat_map":        [0.0, 0.4, 0.8, 1.2, 1.6, 2.0]
	},
	{
		"lesson_id":       "tr_003",
		"instrument":      "trong",
		"title":           "Nhịp trống trận hào hùng",
		"difficulty":      "Advanced",
		"required_level":  7,
		"stars":           0,
		"is_unlocked":     false,
		"reference_audio": "",
		"beat_map":        [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
	}
]

# â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• 
func _ready() -> void:
	_wire_signals()
	_setup_room()
	shell_ui.configure(gamification)
	shell_ui.set_lessons(lessons)
	practice_ui.hide()
	if is_instance_valid(minigame_ui):
		minigame_ui.hide()
	# Login screen shown by GameShellUI._ready() automatically

func _wire_signals() -> void:
	# Station interactions
	dan_tranh_station.station_interacted.connect(_on_station_interacted)
	dan_bau_station.station_interacted.connect(_on_station_interacted)
	sao_truc_station.station_interacted.connect(_on_station_interacted)
	trong_station.station_interacted.connect(_on_station_interacted)

	# Shell UI navigation
	shell_ui.request_enter_room.connect(_enter_room)
	shell_ui.request_start_demo.connect(_start_artist_demo)
	shell_ui.request_start_practice.connect(_start_practice)
	shell_ui.request_back_to_room.connect(_back_to_room)
	shell_ui.request_replay_practice.connect(_start_practice)
	shell_ui.request_next_lesson.connect(_start_next_lesson)
	shell_ui.request_start_minigame.connect(_start_minigame)

	# Practice UI callbacks
	practice_ui.practice_finished.connect(_on_practice_finished)
	practice_ui.practice_cancelled.connect(_back_to_room)

	# Mini-game UI callbacks
	if is_instance_valid(minigame_ui):
		minigame_ui.minigame_finished.connect(_on_minigame_finished)
		minigame_ui.minigame_cancelled.connect(_on_minigame_cancelled)

func _setup_room() -> void:
	if camera:
		camera.enabled = true
		camera.make_current()
		camera.limit_left   = 0
		camera.limit_top    = 0
		camera.limit_right  = 1152
		camera.limit_bottom = 720
		camera.limit_smoothed = true
	virtual_artist.equip_instrument("dan_tranh")
	virtual_artist.set_lesson_context(lessons[0])
	dan_tranh_station.apply_state("in_progress")
	dan_bau_station.apply_state("available")
	sao_truc_station.apply_state("available")
	trong_station.apply_state("locked")

# â”€â”€â”€ State transitions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
func _enter_room() -> void:
	state = FlowState.EXPLORE
	if is_instance_valid(minigame_ui):
		minigame_ui.hide()
	practice_ui.hide()
	_focus_camera(Vector2(576, 456), 0.96)
	shell_ui.show_room_hud()

func _on_station_interacted(instrument: String) -> void:
	state = FlowState.LESSON_SELECT
	var station_pos := Vector2(576, 456)
	match instrument:
		"dan_tranh": station_pos = dan_tranh_station.global_position
		"dan_bau": station_pos = dan_bau_station.global_position
		"sao_truc": station_pos = sao_truc_station.global_position
		"trong": station_pos = trong_station.global_position
	_focus_camera(station_pos + Vector2(0, -24), 1.0)
	shell_ui.show_lesson_panel(instrument, _lessons_for_instrument(instrument))

func _start_artist_demo(lesson: Dictionary) -> void:
	state = FlowState.ARTIST_DEMO
	current_lesson = lesson
	shell_ui.hide_lesson_panel()
	_focus_camera(virtual_artist.global_position + Vector2(0, -40), 1.0)
	virtual_artist.equip_instrument(lesson.get("instrument", "dan_tranh"))
	virtual_artist.set_lesson_context(lesson)
	var audio_stream: AudioStream = null
	var audio_path: String = String(lesson.get("reference_audio", ""))
	if audio_path != "" and ResourceLoader.exists(audio_path):
		audio_stream = load(audio_path)
	virtual_artist.demonstrate_technique(_technique_for_lesson(lesson), audio_stream)
	virtual_artist.give_feedback(true, "Hãy nghe thử trước, sau đó đánh theo nhịp điệu.")
	await get_tree().create_timer(3.2).timeout
	if state == FlowState.ARTIST_DEMO:
		virtual_artist.stop_demonstration()
		shell_ui.show_lesson_panel(
			lesson.get("instrument", "dan_tranh"),
			_lessons_for_instrument(lesson.get("instrument", "dan_tranh"))
		)

func _start_practice(lesson: Dictionary) -> void:
	if lesson.is_empty():
		return
	state = FlowState.PRACTICE
	current_lesson = lesson
	practice_run_id += 1
	var run_id: int = practice_run_id
	shell_ui.hide_lesson_panel()
	if is_instance_valid(minigame_ui):
		minigame_ui.hide()
	virtual_artist.stop_demonstration()
	virtual_artist.give_feedback(true, "Đến lượt bạn. Hãy đánh theo nhịp điệu trên làn đường!", 2.2)
	_focus_camera(Vector2(576, 508), 0.96)
	practice_ui.start_practice(lesson)
	_run_practice_simulation(run_id)

func _run_practice_simulation(run_id: int) -> void:
	var total: float = 12.0
	var elapsed: float = 0.0
	var feedback_cycle: Array[String] = ["Perfect", "Good", "Perfect", "Late", "Good", "Perfect", "Miss", "Perfect", "Good", "Perfect"]
	var instrument: String = current_lesson.get("instrument", "dan_tranh")
	while elapsed < total and state == FlowState.PRACTICE and run_id == practice_run_id:
		await get_tree().create_timer(0.7).timeout
		if state != FlowState.PRACTICE or run_id != practice_run_id:
			return
		elapsed += 0.7
		var idx: int = int(elapsed / 0.7) % feedback_cycle.size()
		var event_name: String = feedback_cycle[idx]
		var pitch_diff: float = sin(elapsed * 1.7) * 18.0
		var rolling_accuracy: float = clamp(66.0 + elapsed * 2.2 + cos(elapsed) * 7.0, 0.0, 98.0)
		# Simulate breath for sao_truc
		var breath: float = -1.0
		if instrument == "sao_truc":
			breath = clamp(0.5 + sin(elapsed * 0.8) * 0.3 + randf_range(-0.05, 0.05), 0.1, 1.0)
		practice_ui.update_practice_tick(elapsed, total, event_name, pitch_diff, rolling_accuracy, breath)
	if state == FlowState.PRACTICE and run_id == practice_run_id:
		practice_ui.finish_practice()

func _on_practice_finished(result: Dictionary) -> void:
	state = FlowState.RESULT
	_apply_reward(result)
	_show_artist_result_feedback(result)
	shell_ui.show_result(result, gamification)

func _apply_reward(result: Dictionary) -> void:
	gamification["xp"]           = int(gamification.get("xp", 0)) + int(result.get("xp_awarded", 0))
	gamification["weekly_score"] = int(gamification.get("weekly_score", 0)) + int(result.get("score", 0))
	gamification["practice_time"] = int(gamification.get("practice_time", 0)) + 12
	if int(gamification.get("xp", 0)) >= int(gamification.get("xp_to_next", 1000)):
		gamification["xp"]    = int(gamification.get("xp", 0)) - int(gamification.get("xp_to_next", 1000))
		gamification["level"] = int(gamification.get("level", 1)) + 1
	var badge: String = String(result.get("badge", ""))
	var badge_list: Array = gamification.get("badges", [])
	if badge != "" and not badge_list.has(badge):
		badge_list.append(badge)
		gamification["badges"] = badge_list
	# Update accuracy history
	var history: Array = gamification.get("accuracy_history", [])
	history.append(float(result.get("accuracy", 0)))
	if history.size() > 10:
		history = history.slice(history.size() - 10)
	gamification["accuracy_history"] = history
	gamification["lessons_done"] = int(gamification.get("lessons_done", 0)) + 1
	# Update lesson stars
	for i in range(lessons.size()):
		var result_lesson: Dictionary = result.get("lesson", {}) as Dictionary
		if lessons[i].get("lesson_id", "") == result_lesson.get("lesson_id", ""):
			lessons[i]["stars"] = max(int(lessons[i].get("stars", 0)), int(result.get("stars", 0)))

func _back_to_room() -> void:
	state = FlowState.EXPLORE
	practice_run_id += 1
	practice_ui.hide()
	if is_instance_valid(minigame_ui):
		minigame_ui.hide()
	_focus_camera(Vector2(576, 456), 0.96)
	shell_ui.show_room_hud()

func _start_next_lesson() -> void:
	var instrument: String = current_lesson.get("instrument", "dan_tranh")
	var instrument_lessons: Array = _lessons_for_instrument(instrument)
	for lesson in instrument_lessons:
		if bool(lesson.get("is_unlocked", true)) and int(lesson.get("stars", 0)) == 0:
			_start_practice(lesson)
			return
	shell_ui.show_lesson_panel(instrument, instrument_lessons)

# â”€â”€â”€ Mini-game â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
func _start_minigame(type: int) -> void:
	if not is_instance_valid(minigame_ui):
		push_warning("VirtualClassroom: MiniGameUI node not found, cannot start minigame.")
		return
	state = FlowState.MINIGAME
	practice_ui.hide()
	shell_ui.hide_lesson_panel()
	var difficulty: String = current_lesson.get("difficulty", "Beginner")
	minigame_ui.call("start_minigame", type, difficulty)

func _on_minigame_finished(result: Dictionary) -> void:
	state = FlowState.EXPLORE
	# Award XP from mini-game
	gamification["xp"] = int(gamification.get("xp", 0)) + int(result.get("xp_awarded", 0))
	gamification["weekly_score"] = int(gamification.get("weekly_score", 0)) + int(result.get("score", 0))
	var badge: String = String(result.get("badge", ""))
	var badge_list: Array = gamification.get("badges", [])
	if badge != "" and not badge_list.has(badge):
		badge_list.append(badge)
		gamification["badges"] = badge_list
	shell_ui.configure(gamification)
	shell_ui.show_dashboard()

func _on_minigame_cancelled() -> void:
	state = FlowState.EXPLORE
	shell_ui.show_dashboard()

# â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
func _lessons_for_instrument(instrument: String) -> Array:
	return lessons.filter(func(lesson): return lesson.get("instrument", "") == instrument)

func _technique_for_lesson(lesson: Dictionary) -> String:
	var id: String = String(lesson.get("lesson_id", ""))
	if id.begins_with("st_"):
		return "blow"
	if id == "dt_002":
		return "vibrato"
	return "pluck"

func _focus_camera(target: Vector2, zoom_value: float) -> void:
	if camera == null:
		return
	var height: float = get_viewport().get_visible_rect().size.y
	var aspect_scale: float = height / 648.0
	var final_zoom: float = zoom_value * aspect_scale
	var tween := create_tween().set_parallel(true)
	tween.tween_property(camera, "global_position", target, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", Vector2(final_zoom, final_zoom), 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_artist_result_feedback(result: Dictionary) -> void:
	var stars: int = int(result.get("stars", 1))
	if stars >= 3:
		virtual_artist.give_feedback(true, "Tuyệt vời! Cả nhịp điệu và âm sắc đều rất ổn định.", 3.0)
	elif stars == 2:
		virtual_artist.give_feedback(true, "Tiến bộ rất tốt. Hãy lặp lại để hoàn thiện thời gian.", 3.0)
	else:
		virtual_artist.give_feedback(false, "Hãy chậm lại một chút và tập trung vào nhịp đầu tiên.", 3.0)
