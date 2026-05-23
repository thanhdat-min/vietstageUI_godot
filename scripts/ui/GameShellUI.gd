extends Control
class_name GameShellUI

signal request_enter_room
signal request_start_demo(lesson: Dictionary)
signal request_start_practice(lesson: Dictionary)
signal request_back_to_room
signal request_replay_practice(lesson: Dictionary)
signal request_next_lesson

const WOOD_DARK := Color("24130d")
const WOOD_PANEL := Color("3b2318")
const BRASS := Color("d7a84a")
const BRASS_DIM := Color("9c7230")
const JADE := Color("1f9a8a")
const SON_RED := Color("8d2f22")
const CREAM := Color("f4dfb8")
const MUTED := Color("c8af83")
const SHADOW := Color(0.03, 0.02, 0.015, 0.76)

var gamification: Dictionary = {
	"xp": 640,
	"level": 5,
	"xp_to_next": 1000,
	"weekly_score": 12840,
	"streak_days": 6,
	"badges": ["First Rhythm", "Dan Tranh Novice", "Three Day Streak"]
}

var current_lesson: Dictionary = {}
var root: Control
var dashboard: Control
var lesson_panel: PanelContainer
var result_panel: PanelContainer
var hud_top: PanelContainer
var room_helper: PanelContainer
var mobile_nav: PanelContainer
var xp_bar: ProgressBar
var xp_label: Label
var title_label: Label
var lesson_list: VBoxContainer
var leaderboard_list: VBoxContainer
var badges_grid: GridContainer
var result_title: Label
var result_breakdown: Label
var result_xp: Label
var desktop_mode: bool = true

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_gamification()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	show_dashboard()

func configure(data: Dictionary) -> void:
	gamification.merge(data, true)
	_refresh_gamification()

func show_dashboard() -> void:
	dashboard.show()
	lesson_panel.hide()
	result_panel.hide()
	hud_top.hide()
	room_helper.hide()
	_sync_mobile_nav()

func show_room_hud() -> void:
	dashboard.hide()
	lesson_panel.hide()
	result_panel.hide()
	hud_top.show()
	room_helper.show()
	_sync_mobile_nav()

func show_lesson_panel(instrument: String, lessons: Array) -> void:
	show_room_hud()
	lesson_panel.show()
	title_label.text = _instrument_title(instrument) + " Lessons"
	for child in lesson_list.get_children():
		child.queue_free()
	for lesson in lessons:
		lesson_list.add_child(_make_lesson_card(lesson))

func hide_lesson_panel() -> void:
	lesson_panel.hide()

func show_result(result: Dictionary, updated_gamification: Dictionary) -> void:
	current_lesson = result.get("lesson", current_lesson)
	configure(updated_gamification)
	lesson_panel.hide()
	hud_top.hide()
	room_helper.hide()
	dashboard.hide()
	result_panel.show()
	_sync_mobile_nav()
	var stars: int = int(result.get("stars", 1))
	result_title.text = "Lesson Complete  " + _stars(stars)
	result_breakdown.text = "Accuracy %d%%   Rhythm %d%%   Pitch %d%%   Tone %d%%   Max Combo %d" % [
		int(result.get("accuracy", 0)),
		int(result.get("rhythm", 0)),
		int(result.get("pitch", 0)),
		int(result.get("tone", 0)),
		int(result.get("max_combo", 0))
	]
	result_xp.text = "+%d XP   Badge: %s" % [int(result.get("xp_awarded", 0)), result.get("badge", "Progress saved")]

func _build_ui() -> void:
	root = Control.new()
	root.name = "GameShellRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	dashboard = Control.new()
	dashboard.name = "HomeDashboard"
	dashboard.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dashboard)
	_build_dashboard()

	hud_top = PanelContainer.new()
	hud_top.name = "RoomTopHUD"
	_set_top_bar_rect()
	hud_top.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.04, 0.03, 0.86), BRASS_DIM, 8))
	root.add_child(hud_top)
	_build_room_hud()

	room_helper = PanelContainer.new()
	room_helper.name = "RoomHelperPanel"
	room_helper.anchor_left = 0.0
	room_helper.anchor_top = 1.0
	room_helper.anchor_right = 0.0
	room_helper.anchor_bottom = 1.0
	room_helper.offset_left = 18
	room_helper.offset_top = -154
	room_helper.offset_right = 330
	room_helper.offset_bottom = -24
	room_helper.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.04, 0.03, 0.82), JADE, 8))
	root.add_child(room_helper)
	_build_room_helper()

	lesson_panel = PanelContainer.new()
	lesson_panel.name = "LessonSelectPanel"
	lesson_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	lesson_panel.offset_left = -430
	lesson_panel.offset_top = 92
	lesson_panel.offset_right = -18
	lesson_panel.offset_bottom = -92
	lesson_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.94), BRASS, 8))
	root.add_child(lesson_panel)
	_build_lesson_panel()

	result_panel = PanelContainer.new()
	result_panel.name = "ResultPanel"
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.custom_minimum_size = Vector2(680, 430)
	result_panel.offset_left = -340
	result_panel.offset_top = -215
	result_panel.offset_right = 340
	result_panel.offset_bottom = 215
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.11, 0.06, 0.04, 0.97), BRASS, 8))
	root.add_child(result_panel)
	_build_result_panel()

	mobile_nav = PanelContainer.new()
	mobile_nav.name = "BottomNavigation"
	mobile_nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mobile_nav.offset_left = 12
	mobile_nav.offset_right = -12
	mobile_nav.offset_top = -78
	mobile_nav.offset_bottom = -12
	mobile_nav.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.9), Color(0.27, 0.18, 0.1), 8))
	root.add_child(mobile_nav)
	_build_mobile_nav()

func _build_dashboard() -> void:
	var shade := ColorRect.new()
	shade.name = "DashboardShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = SHADOW
	dashboard.add_child(shade)

	var sidebar := PanelContainer.new()
	sidebar.name = "ProfileSidebar"
	sidebar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sidebar.custom_minimum_size = Vector2(292, 0)
	sidebar.offset_left = 20
	sidebar.offset_top = 20
	sidebar.offset_right = 312
	sidebar.offset_bottom = -20
	sidebar.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.95), BRASS_DIM, 8))
	dashboard.add_child(sidebar)

	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 14)
	side_box.add_theme_constant_override("margin_left", 18)
	side_box.add_theme_constant_override("margin_top", 18)
	side_box.add_theme_constant_override("margin_right", 18)
	side_box.add_theme_constant_override("margin_bottom", 18)
	sidebar.add_child(side_box)
	side_box.add_child(_label("VietStage", 34, BRASS, HORIZONTAL_ALIGNMENT_LEFT))
	side_box.add_child(_label("Learner Profile", 16, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	xp_label = _label("", 18, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	side_box.add_child(xp_label)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 22)
	xp_bar.max_value = 100
	xp_bar.show_percentage = false
	xp_bar.add_theme_stylebox_override("background", _bar_bg())
	xp_bar.add_theme_stylebox_override("fill", _bar_fill(BRASS))
	side_box.add_child(xp_bar)
	side_box.add_child(_label("Daily Challenge", 18, BRASS, HORIZONTAL_ALIGNMENT_LEFT))
	side_box.add_child(_label("Keep a steady beat for 60 seconds\nReward: 120 XP + streak flame", 15, CREAM, HORIZONTAL_ALIGNMENT_LEFT))
	var enter_button := _button("Enter 2.5D Room", BRASS, WOOD_DARK)
	enter_button.pressed.connect(func(): request_enter_room.emit())
	side_box.add_child(enter_button)

	var main := VBoxContainer.new()
	main.name = "DashboardMain"
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.offset_left = 338
	main.offset_top = 34
	main.offset_right = -34
	main.offset_bottom = -34
	main.add_theme_constant_override("separation", 14)
	dashboard.add_child(main)
	var title := _label("Home Dashboard", 34, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	main.add_child(title)
	main.add_child(_label("Home -> Virtual Room -> Lesson -> Artist Demo -> Practice -> Rewards", 15, MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	main.add_child(columns)
	columns.add_child(_dashboard_card("Progress", "Dan Tranh Basics\n7 / 12 lessons\nNext: Pluck timing", JADE))
	columns.add_child(_dashboard_card("Streak", "%d days\nWeekly score %d\nRank #8" % [int(gamification.get("streak_days", 0)), int(gamification.get("weekly_score", 0))], SON_RED))
	columns.add_child(_dashboard_card("Unlocked", "3 badges\n2 room cosmetics\n1 new lesson", BRASS))

	var lower := HBoxContainer.new()
	lower.add_theme_constant_override("separation", 14)
	main.add_child(lower)
	var leaderboard := _section_panel("Leaderboard")
	leaderboard.custom_minimum_size = Vector2(346, 220)
	lower.add_child(leaderboard)
	leaderboard_list = VBoxContainer.new()
	leaderboard_list.add_theme_constant_override("separation", 8)
	leaderboard.get_child(0).add_child(leaderboard_list)
	_build_leaderboard_rows()

	var badges := _section_panel("Badge Collection")
	badges.custom_minimum_size = Vector2(402, 220)
	lower.add_child(badges)
	badges_grid = GridContainer.new()
	badges_grid.columns = 3
	badges_grid.add_theme_constant_override("h_separation", 8)
	badges_grid.add_theme_constant_override("v_separation", 8)
	badges.get_child(0).add_child(badges_grid)
	_build_badges()

func _build_room_hud() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_top.add_child(row)
	var room_title := _label("VietStage Room", 22, BRASS, HORIZONTAL_ALIGNMENT_LEFT)
	room_title.custom_minimum_size = Vector2(220, 0)
	room_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	room_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(room_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var home := _button("Home", WOOD_PANEL, CREAM)
	home.pressed.connect(show_dashboard)
	row.add_child(home)
	var leaderboard := _button("Leaderboard", WOOD_PANEL, CREAM)
	leaderboard.pressed.connect(show_dashboard)
	row.add_child(leaderboard)

func _build_room_helper() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	room_helper.add_child(box)
	box.add_child(_label("Virtual Room", 18, BRASS, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_label("Explore the isometric classroom and choose a glowing instrument station.", 13, CREAM, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_label("Move: WASD / Arrows", 13, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_label("Interact: E / Space / Tap", 13, JADE, HORIZONTAL_ALIGNMENT_LEFT))

func _build_lesson_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	lesson_panel.add_child(box)
	title_label = _label("Lessons", 26, BRASS, HORIZONTAL_ALIGNMENT_LEFT)
	box.add_child(title_label)
	box.add_child(_label("Choose a lesson, watch the virtual artist, then enter practice.", 14, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	lesson_list = VBoxContainer.new()
	lesson_list.add_theme_constant_override("separation", 10)
	box.add_child(lesson_list)
	var close := _button("Back to Room", WOOD_PANEL, CREAM)
	close.pressed.connect(func():
		lesson_panel.hide()
		request_back_to_room.emit()
	)
	box.add_child(close)

func _build_result_panel() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	result_panel.add_child(box)
	result_title = _label("Lesson Complete", 34, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_title)
	result_breakdown = _label("", 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_breakdown)
	result_xp = _label("", 20, JADE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_xp)
	var reward_loop := _label("Stars -> XP -> Streak -> Badge -> Next Lesson", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(reward_loop)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var replay := _button("Replay", WOOD_PANEL, CREAM)
	replay.pressed.connect(func(): request_replay_practice.emit(current_lesson))
	actions.add_child(replay)
	var next := _button("Next Lesson", BRASS, WOOD_DARK)
	next.pressed.connect(func(): request_next_lesson.emit())
	actions.add_child(next)
	var room := _button("Back to Room", JADE, WOOD_DARK)
	room.pressed.connect(func():
		result_panel.hide()
		show_room_hud()
		request_back_to_room.emit()
	)
	actions.add_child(room)

func _build_mobile_nav() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	mobile_nav.add_child(row)
	var home := _button("Home", WOOD_PANEL, CREAM)
	home.pressed.connect(show_dashboard)
	row.add_child(home)
	var room := _button("Room", WOOD_PANEL, CREAM)
	room.pressed.connect(func(): request_enter_room.emit())
	row.add_child(room)
	var practice := _button("Practice", WOOD_PANEL, CREAM)
	practice.pressed.connect(func():
		if not current_lesson.is_empty():
			request_start_practice.emit(current_lesson)
	)
	row.add_child(practice)
	var profile := _button("Profile", WOOD_PANEL, CREAM)
	profile.pressed.connect(show_dashboard)
	row.add_child(profile)

func _make_lesson_card(lesson: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.16, 0.09, 0.055, 0.96), Color(0.34, 0.23, 0.13), 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var locked: bool = not bool(lesson.get("is_unlocked", true))
	info.add_child(_label(lesson.get("title", "Lesson"), 19, CREAM if not locked else MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	info.add_child(_label("%s   Level %d   %s" % [lesson.get("difficulty", "Beginner"), int(lesson.get("required_level", 1)), _stars(int(lesson.get("stars", 0)))], 14, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var demo: Button = _button("Demo", JADE if not locked else Color(0.2, 0.2, 0.2), WOOD_DARK)
	demo.disabled = locked
	demo.pressed.connect(func():
		current_lesson = lesson
		request_start_demo.emit(lesson)
	)
	row.add_child(demo)
	var practice: Button = _button("Practice", BRASS if not locked else Color(0.2, 0.2, 0.2), WOOD_DARK)
	practice.disabled = locked
	practice.pressed.connect(func():
		current_lesson = lesson
		request_start_practice.emit(lesson)
	)
	row.add_child(practice)
	return panel

func _dashboard_card(title: String, body: String, accent: Color) -> PanelContainer:
	var card := _section_panel(title)
	card.custom_minimum_size = Vector2(220, 136)
	card.get_child(0).add_child(_label(body, 16, CREAM, HORIZONTAL_ALIGNMENT_LEFT))
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.93), accent, 8))
	return card

func _section_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.92), Color(0.31, 0.2, 0.11), 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label(title, 20, BRASS, HORIZONTAL_ALIGNMENT_LEFT))
	return panel

func _build_leaderboard_rows() -> void:
	if leaderboard_list == null:
		return
	for child in leaderboard_list.get_children():
		child.queue_free()
	var rows: Array = [
		["1", "Minh Anh", "Dan Tranh", "18,420", "9d"],
		["2", "Gia Bao", "Sao Truc", "16,980", "8d"],
		["3", "Linh Chi", "Dan Tranh", "15,110", "7d"],
		["8", "You", "Dan Tranh", str(gamification.get("weekly_score", 0)), str(gamification.get("streak_days", 0)) + "d"]
	]
	for row in rows:
		leaderboard_list.add_child(_label("#%s  %s  -  %s  -  %s pts  -  %s streak" % row, 14, CREAM, HORIZONTAL_ALIGNMENT_LEFT))

func _build_badges() -> void:
	if badges_grid == null:
		return
	for child in badges_grid.get_children():
		child.queue_free()
	var badge_names: Array[String] = ["First Rhythm", "Pitch Ear", "Three Day Streak", "Dan Tranh Novice", "Sao Truc Breath", "Cultural Explorer"]
	for badge in badge_names:
		var badge_list: Array = gamification.get("badges", [])
		var unlocked: bool = badge_list.has(badge)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(112, 62)
		panel.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.09, 0.055, 0.96), BRASS if unlocked else Color(0.28, 0.25, 0.2), 8))
		var label: Label = _label(("* " if unlocked else "- ") + badge, 12, CREAM if unlocked else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(label)
		badges_grid.add_child(panel)

func _refresh_gamification() -> void:
	if xp_bar:
		xp_bar.max_value = max(1, int(gamification.get("xp_to_next", 1000)))
		xp_bar.value = int(gamification.get("xp", 0))
	if xp_label:
		xp_label.text = "Level %d   %d / %d XP" % [int(gamification.get("level", 1)), int(gamification.get("xp", 0)), int(gamification.get("xp_to_next", 1000))]
	_build_leaderboard_rows()
	_build_badges()

func _apply_responsive_layout() -> void:
	var width: float = get_viewport().get_visible_rect().size.x
	desktop_mode = width >= 800
	_sync_mobile_nav()
	_set_top_bar_rect()
	if desktop_mode:
		lesson_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		lesson_panel.offset_left = -430
		lesson_panel.offset_top = 92
		lesson_panel.offset_right = -18
		lesson_panel.offset_bottom = -92
	else:
		lesson_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		lesson_panel.offset_left = 10
		lesson_panel.offset_top = -420
		lesson_panel.offset_right = -10
		lesson_panel.offset_bottom = -88

func _set_top_bar_rect() -> void:
	if hud_top == null:
		return
	hud_top.anchor_left = 0.0
	hud_top.anchor_top = 0.0
	hud_top.anchor_right = 1.0
	hud_top.anchor_bottom = 0.0
	hud_top.offset_left = 18.0
	hud_top.offset_top = 16.0
	hud_top.offset_right = -18.0
	hud_top.offset_bottom = 76.0
	hud_top.custom_minimum_size = Vector2(0, 60)

func _sync_mobile_nav() -> void:
	if mobile_nav == null:
		return
	mobile_nav.visible = not desktop_mode

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
	button.custom_minimum_size = Vector2(118, 42)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal", _panel_style(bg, bg.lightened(0.18), 8))
	button.add_theme_stylebox_override("hover", _panel_style(bg.lightened(0.1), BRASS, 8))
	button.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.12), BRASS, 8))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.16, 0.14, 0.12), Color(0.22, 0.2, 0.18), 8))
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
