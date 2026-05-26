extends Control
class_name GameShellUI

@onready var font_reg: Font = load("res://assets/fonts/Inter-Regular.ttf")
@onready var font_bold: Font = load("res://assets/fonts/Inter-SemiBold.ttf")

# ── Signals ─────────────────────────────────────────────────────────────────
signal request_enter_room
signal request_start_demo(lesson: Dictionary)
signal request_start_practice(lesson: Dictionary)
signal request_back_to_room
signal request_replay_practice(lesson: Dictionary)
signal request_next_lesson
signal request_start_minigame(type: int)

# ── Colour palette ───────────────────────────────────────────────────────────
const WOOD_DARK   := Color("281006") # Mahogany Canvas
const WOOD_PANEL  := Color("402011") # Burnt Sienna
const BRASS       := Color("faae33") # Curry Yellow
const BRASS_DIM   := Color("823513") # Spiced Orange
const JADE        := Color("faae33") # Curry Yellow
const SON_RED     := Color("d1255c") # Chili Red
const CREAM       := Color("ffffff") # Crisp White
const MUTED       := Color("9f531b") # Cinnamon Brown / Muted
const SHADOW      := Color(0.03, 0.02, 0.015, 0.78)
const STAR_GOLD   := Color("f0c840")
const SUCCESS     := Color("3ec97a")
const STREAK_ORG  := Color("e87c28")
const LOCKED_GREY := Color("4a4035")

# ── Gamification state ───────────────────────────────────────────────────────
var gamification: Dictionary = {
	"xp":            640,
	"level":         5,
	"xp_to_next":    1000,
	"weekly_score":  12840,
	"streak_days":   6,
	"practice_time": 4800,     # seconds total
	"badges":        ["First Rhythm", "Dan Tranh Novice", "Three Day Streak"],
	"accuracy_history": [72.0, 68.0, 75.0, 80.0, 84.0, 79.0, 88.0],
	"lessons_done":  7,
	"lessons_total": 12,
}

# ── Layout ───────────────────────────────────────────────────────────────────
var current_lesson: Dictionary = {}
var root: Control
var desktop_mode: bool = true

# ── Screen nodes ─────────────────────────────────────────────────────────────
var dashboard:         Control
var lesson_panel:      PanelContainer
var result_panel:      PanelContainer
var hud_top:           PanelContainer
var room_helper:       PanelContainer
var mobile_nav:        PanelContainer
var login_overlay:     Control
var progress_screen:   Control
var audio_lib_screen:  Control
var daily_challenge:   Control

# ── Dashboard sub-nodes ──────────────────────────────────────────────────────
var xp_bar:            ProgressBar
var xp_label:          Label
var title_label:       Label
var lesson_list:       VBoxContainer
var leaderboard_list:  VBoxContainer
var badges_grid:       GridContainer
var dashboard_scroll:  ScrollContainer
var dashboard_main:    VBoxContainer
var dashboard_cards:   GridContainer
var dashboard_lower:   GridContainer
var daily_challenge_main: GridContainer
var login_card:        PanelContainer

# ── Simply Guitar roadmap variables ──────────────────────────────────────────
var all_lessons:           Array = []
var selected_instrument:   String = "dan_tranh"
var current_dashboard_tab: String = "courses"
var roadmap_scroll:        ScrollContainer
var roadmap_row:           HBoxContainer
var left_nav_bar:          PanelContainer
var tab_btn_courses:       Button
var tab_btn_library:       Button
var tab_btn_games:         Button
var tab_btn_room:          Button
var inst_selector_row:     HBoxContainer
var dashboard_games_panel: PanelContainer
var games_vbox:            VBoxContainer

# ── Result sub-nodes ─────────────────────────────────────────────────────────
var result_title:     Label
var result_breakdown: Label
var result_xp:        Label

# ═══════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_gamification()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	# Show login on first run
	_show_login()

func configure(data: Dictionary) -> void:
	gamification.merge(data, true)
	_refresh_gamification()

# ─── Screen Routing ──────────────────────────────────────────────────────────
func _hide_all() -> void:
	login_overlay.hide()
	dashboard.hide()
	lesson_panel.hide()
	result_panel.hide()
	hud_top.hide()
	room_helper.hide()
	progress_screen.hide()
	audio_lib_screen.hide()
	daily_challenge.hide()

func _show_login() -> void:
	_hide_all()
	login_overlay.show()

func show_dashboard() -> void:
	_hide_all()
	dashboard.show()
	_sync_mobile_nav()
	_refresh_gamification()

func show_room_hud() -> void:
	_hide_all()
	hud_top.show()
	room_helper.show()
	_sync_mobile_nav()

func show_lesson_panel(instrument: String, lessons: Array) -> void:
	show_room_hud()
	lesson_panel.show()
	title_label.text = _instrument_title(instrument) + " — Lessons"
	for child in lesson_list.get_children():
		child.queue_free()
	for lesson in lessons:
		lesson_list.add_child(_make_lesson_card(lesson))

func hide_lesson_panel() -> void:
	lesson_panel.hide()

func show_result(result: Dictionary, updated_gamification: Dictionary) -> void:
	current_lesson = result.get("lesson", current_lesson)
	configure(updated_gamification)
	_hide_all()
	result_panel.show()
	_sync_mobile_nav()
	var stars: int = int(result.get("stars", 1))
	result_title.text = "Lesson Complete  " + _stars_unicode(stars)
	result_breakdown.text = "Accuracy %d%%   Rhythm %d%%   Pitch %d%%   Tone %d%%   Max Combo %d" % [
		int(result.get("accuracy", 0)),
		int(result.get("rhythm", 0)),
		int(result.get("pitch", 0)),
		int(result.get("tone", 0)),
		int(result.get("max_combo", 0))
	]
	result_xp.text = "+%d XP  —  Badge: %s" % [int(result.get("xp_awarded", 0)), result.get("badge", "Progress saved")]

func show_progress() -> void:
	_hide_all()
	progress_screen.show()
	_refresh_progress_screen()
	_sync_mobile_nav()

func show_audio_library() -> void:
	_hide_all()
	audio_lib_screen.show()
	_sync_mobile_nav()

func show_daily_challenge() -> void:
	_hide_all()
	daily_challenge.show()
	_refresh_daily_challenge()
	_sync_mobile_nav()

# ═══════════════════════════════════════════════════════════════════════════
# BUILD – Full UI tree
# ═══════════════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	root = Control.new()
	root.name = "GameShellRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Order matters for z-stacking
	_build_dashboard_screen()
	_build_room_hud()
	_build_room_helper()
	_build_lesson_panel()
	_build_result_panel()
	_build_mobile_nav()
	_build_progress_screen()
	_build_audio_library()
	_build_daily_challenge()
	_build_login_overlay()   # topmost

# ═══════════════════════════════════════════════════════════════════════════
# LOGIN / REGISTER OVERLAY
# ═══════════════════════════════════════════════════════════════════════════
func _build_login_overlay() -> void:
	login_overlay = Control.new()
	login_overlay.name = "LoginOverlay"
	login_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(login_overlay)

	# Full-screen dark backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("140c0a")
	login_overlay.add_child(bg)

	# Decorative arcs and Bronze Drum (Vietnamese motif) background
	var deco := Control.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		var w := deco.size.x
		var h := deco.size.y
		
		# Center Bronze Drum Motif
		var center := Vector2(w * 0.5, h * 0.5)
		draw_circle(center, 240.0, Color(0.1, 0.05, 0.035, 0.42))
		draw_arc(center, 240.0, 0.0, TAU, 72, Color(BRASS, 0.05), 2.0)
		draw_arc(center, 200.0, 0.0, TAU, 64, Color(BRASS, 0.04), 1.5)
		draw_arc(center, 150.0, 0.0, TAU, 56, Color(BRASS, 0.06), 1.0)
		draw_arc(center, 90.0,  0.0, TAU, 36, Color(BRASS, 0.09), 2.0)
		
		# Center starburst rays
		for i in range(12):
			var angle := float(i) * TAU / 12.0
			draw_line(center, center + Vector2.RIGHT.rotated(angle) * 76.0, Color(BRASS, 0.09), 2.2)

		# Traditional outer ring orbits
		for i in range(4):
			draw_arc(center, 300.0 + i * 80.0, PI * 0.7, PI * 2.3, 80,
				Color(BRASS, 0.02 + i * 0.008), 2.0)
				
		# Corner ornaments
		draw_arc(Vector2(0, 0), 160.0, 0, PI * 0.5, 36, Color(BRASS, 0.16), 2.0)
		draw_arc(Vector2(w, 0), 160.0, PI * 0.5, PI, 36, Color(JADE, 0.14), 2.0)
		draw_arc(Vector2(0, h), 160.0, -PI * 0.5, 0, 36, Color(JADE, 0.14), 2.0)
		draw_arc(Vector2(w, h), 160.0, PI, PI * 1.5, 36, Color(BRASS, 0.16), 2.0)
	)
	login_overlay.add_child(deco)

	# Centre card (translucent glassmorphism style)
	var card := PanelContainer.new()
	card.name = "LoginCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(480, 560)
	card.offset_left   = -240
	card.offset_top    = -280
	card.offset_right  = 240
	card.offset_bottom = 280
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.03, 0.94), BRASS, 16))
	login_overlay.add_child(card)

	# Add proper margins/padding inside the card using MarginContainer
	var margin_container := MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 36)
	margin_container.add_theme_constant_override("margin_right", 36)
	margin_container.add_theme_constant_override("margin_top", 36)
	margin_container.add_theme_constant_override("margin_bottom", 36)
	card.add_child(margin_container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin_container.add_child(vbox)

	# Logo / title
	vbox.add_child(_label("🎵  VietStage", 36, BRASS, HORIZONTAL_ALIGNMENT_CENTER))
	vbox.add_child(_label("Nghệ Sĩ Ảo — Học Nhạc Cụ Dân Tộc", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	vbox.add_child(_hsep())

	# Segmented tab control background capsule
	var tab_bg := PanelContainer.new()
	tab_bg.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.03, 0.02, 0.8), Color(0.25, 0.16, 0.09), 8))
	vbox.add_child(tab_bg)

	# Tab row: Login | Register
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 4)
	tab_bg.add_child(tab_row)
	
	var login_tab  := _tab_button("Đăng nhập",  true)
	var reg_tab    := _tab_button("Đăng ký",    false)
	tab_row.add_child(login_tab)
	tab_row.add_child(reg_tab)

	# Form container (switches between login / register)
	var form_stack := Control.new()
	form_stack.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(form_stack)

	var login_form  := _build_login_form()
	var reg_form    := _build_register_form()
	login_form.set_anchors_preset(Control.PRESET_FULL_RECT)
	reg_form.set_anchors_preset(Control.PRESET_FULL_RECT)
	form_stack.add_child(login_form)
	form_stack.add_child(reg_form)
	reg_form.hide()

	login_tab.pressed.connect(func():
		login_form.show()
		reg_form.hide()
		login_tab.add_theme_stylebox_override("normal", _panel_style(BRASS, BRASS, 6))
		login_tab.add_theme_color_override("font_color", WOOD_DARK)
		var empty_style := StyleBoxEmpty.new()
		reg_tab.add_theme_stylebox_override("normal", empty_style)
		reg_tab.add_theme_color_override("font_color", CREAM)
	)
	reg_tab.pressed.connect(func():
		reg_form.show()
		login_form.hide()
		reg_tab.add_theme_stylebox_override("normal", _panel_style(BRASS, BRASS, 6))
		reg_tab.add_theme_color_override("font_color", WOOD_DARK)
		var empty_style := StyleBoxEmpty.new()
		login_tab.add_theme_stylebox_override("normal", empty_style)
		login_tab.add_theme_color_override("font_color", CREAM)
	)

	vbox.add_child(_hsep())
	vbox.add_child(_label("Hoặc chơi ngay không cần tài khoản:", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var guest_btn := _button("▶  Chơi Thử (Guest)", JADE, WOOD_DARK)
	guest_btn.add_theme_font_size_override("font_size", 17)
	guest_btn.custom_minimum_size = Vector2(0, 48)
	guest_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guest_btn.pressed.connect(func():
		login_overlay.hide()
		show_dashboard()
	)
	vbox.add_child(guest_btn)

func _build_login_form() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_child(_label("Tên đăng nhập", 14, MUTED))
	var user_edit := _line_edit("Nhập tên người dùng...")
	vbox.add_child(user_edit)
	vbox.add_child(_label("Mật khẩu", 14, MUTED))
	var pass_edit := _line_edit("••••••••")
	pass_edit.secret = true
	vbox.add_child(pass_edit)
	var login_btn := _button("→  Đăng nhập", BRASS, WOOD_DARK)
	login_btn.add_theme_font_size_override("font_size", 17)
	login_btn.custom_minimum_size = Vector2(0, 48)
	login_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_btn.pressed.connect(func():
		login_overlay.hide()
		show_dashboard()
	)
	vbox.add_child(login_btn)
	return vbox

func _build_register_form() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(_label("Họ và tên", 14, MUTED))
	vbox.add_child(_line_edit("Nguyễn Văn A..."))
	vbox.add_child(_label("Email", 14, MUTED))
	vbox.add_child(_line_edit("example@email.com"))
	vbox.add_child(_label("Mật khẩu", 14, MUTED))
	var pw := _line_edit("Tối thiểu 8 ký tự")
	pw.secret = true
	vbox.add_child(pw)
	vbox.add_child(_label("Nhạc cụ quan tâm", 14, MUTED))
	var opt := OptionButton.new()
	opt.add_item("Đàn Tranh")
	opt.add_item("Sáo Trúc")
	opt.add_item("Đàn Bầu")
	opt.add_item("Trống")
	opt.add_theme_color_override("font_color", CREAM)
	opt.custom_minimum_size = Vector2(0, 42)
	vbox.add_child(opt)
	var reg_btn := _button("✓  Tạo tài khoản", JADE, WOOD_DARK)
	reg_btn.add_theme_font_size_override("font_size", 17)
	reg_btn.custom_minimum_size = Vector2(0, 48)
	reg_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reg_btn.pressed.connect(func():
		login_overlay.hide()
		show_dashboard()
	)
	vbox.add_child(reg_btn)
	return vbox

# ═══════════════════════════════════════════════════════════════════════════
# HOME DASHBOARD (enhanced)
# ═══════════════════════════════════════════════════════════════════════════
func _build_dashboard_screen() -> void:
	dashboard = Control.new()
	dashboard.name = "HomeDashboard"
	dashboard.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dashboard)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = SHADOW
	dashboard.add_child(shade)

	# ── Left slim navigation (LeftNav) ──
	left_nav_bar = PanelContainer.new()
	left_nav_bar.name = "LeftNavBar"
	left_nav_bar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_nav_bar.offset_left = 0
	left_nav_bar.offset_top = 0
	left_nav_bar.offset_right = 104
	left_nav_bar.offset_bottom = 0
	left_nav_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.05, 0.035, 0.98), Color(0.25, 0.16, 0.09), 0))
	dashboard.add_child(left_nav_bar)

	var nav_margin := MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_top", 24)
	nav_margin.add_theme_constant_override("margin_bottom", 24)
	nav_margin.add_theme_constant_override("margin_left", 8)
	nav_margin.add_theme_constant_override("margin_right", 8)
	left_nav_bar.add_child(nav_margin)

	var nav_vbox := VBoxContainer.new()
	nav_vbox.add_theme_constant_override("separation", 18)
	nav_margin.add_child(nav_vbox)

	# App Logo
	var app_logo := _label("🎋\nVietStage", 14, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	if font_bold:
		app_logo.add_theme_font_override("font", font_bold)
	nav_vbox.add_child(app_logo)
	
	var nav_sep := _hsep()
	nav_vbox.add_child(nav_sep)

	# Button creation helpers for left nav
	var act_style := _panel_style(CREAM, BRASS, 12)
	var inact_style := StyleBoxEmpty.new()

	# Courses tab button
	tab_btn_courses = Button.new()
	tab_btn_courses.custom_minimum_size = Vector2(88, 76)
	tab_btn_courses.add_theme_stylebox_override("normal", act_style)
	tab_btn_courses.add_theme_stylebox_override("hover", _panel_style(Color(CREAM, 0.08), Color(BRASS, 0.25), 12))
	tab_btn_courses.pressed.connect(func(): _on_tab_pressed("courses"))
	var btn_vbox := VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_btn_courses.add_child(btn_vbox)
	
	var icon1 := _label("🎓", 22, WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	var lbl1 := _label("Khóa học", 11, WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	btn_vbox.add_child(icon1)
	btn_vbox.add_child(lbl1)
	nav_vbox.add_child(tab_btn_courses)

	# Songs/Library tab button
	tab_btn_library = Button.new()
	tab_btn_library.custom_minimum_size = Vector2(88, 76)
	tab_btn_library.add_theme_stylebox_override("normal", inact_style)
	tab_btn_library.add_theme_stylebox_override("hover", _panel_style(Color(CREAM, 0.08), Color(BRASS, 0.25), 12))
	tab_btn_library.pressed.connect(func(): _on_tab_pressed("library"))
	var btn_vbox2 := VBoxContainer.new()
	btn_vbox2.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox2.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_btn_library.add_child(btn_vbox2)
	
	var icon2 := _label("🎵", 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	var lbl2 := _label("Thư viện", 11, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	btn_vbox2.add_child(icon2)
	btn_vbox2.add_child(lbl2)
	nav_vbox.add_child(tab_btn_library)

	# Games tab button
	tab_btn_games = Button.new()
	tab_btn_games.custom_minimum_size = Vector2(88, 76)
	tab_btn_games.add_theme_stylebox_override("normal", inact_style)
	tab_btn_games.add_theme_stylebox_override("hover", _panel_style(Color(CREAM, 0.08), Color(BRASS, 0.25), 12))
	tab_btn_games.pressed.connect(func(): _on_tab_pressed("games"))
	var btn_vbox3 := VBoxContainer.new()
	btn_vbox3.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox3.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_btn_games.add_child(btn_vbox3)
	
	var icon3 := _label("🎮", 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	var lbl3 := _label("Trò chơi", 11, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	btn_vbox3.add_child(icon3)
	btn_vbox3.add_child(lbl3)
	nav_vbox.add_child(tab_btn_games)

	# Spacer
	var nav_spacer := Control.new()
	nav_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_vbox.add_child(nav_spacer)

	# Room tab button (Play)
	tab_btn_room = Button.new()
	tab_btn_room.custom_minimum_size = Vector2(88, 76)
	tab_btn_room.add_theme_stylebox_override("normal", inact_style)
	tab_btn_room.add_theme_stylebox_override("hover", _panel_style(Color(CREAM, 0.08), Color(BRASS, 0.25), 12))
	tab_btn_room.pressed.connect(func(): request_enter_room.emit())
	var btn_vbox4 := VBoxContainer.new()
	btn_vbox4.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox4.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_btn_room.add_child(btn_vbox4)
	
	var icon4 := _label("🏫", 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	var lbl4 := _label("Phòng 2.5D", 11, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	btn_vbox4.add_child(icon4)
	btn_vbox4.add_child(lbl4)
	nav_vbox.add_child(tab_btn_room)

	# ── Main content dashboard container ──
	dashboard_scroll = ScrollContainer.new()
	dashboard_scroll.name = "DashboardScroll"
	dashboard_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	dashboard_scroll.offset_left = 124
	dashboard_scroll.offset_top = 20
	dashboard_scroll.offset_right = -24
	dashboard_scroll.offset_bottom = -20
	dashboard.add_child(dashboard_scroll)

	dashboard_main = VBoxContainer.new()
	dashboard_main.name = "DashboardMain"
	dashboard_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_main.add_theme_constant_override("separation", 16)
	dashboard_scroll.add_child(dashboard_main)
	var main = dashboard_main

	# ── Top Bar ──
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	main.add_child(top_bar)

	var hamburger_btn := _label("☰", 26, BRASS)
	top_bar.add_child(hamburger_btn)

	var dtitle_lbl := _label("VietStage", 24, CREAM)
	if font_bold:
		dtitle_lbl.add_theme_font_override("font", font_bold)
	top_bar.add_child(dtitle_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Level Badge (Pill button)
	var level_badge := PanelContainer.new()
	level_badge.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.08, 0.06, 0.9), BRASS_DIM, 1080))
	var lb_margin := MarginContainer.new()
	lb_margin.add_theme_constant_override("margin_left", 14)
	lb_margin.add_theme_constant_override("margin_right", 14)
	lb_margin.add_theme_constant_override("margin_top", 4)
	lb_margin.add_theme_constant_override("margin_bottom", 4)
	level_badge.add_child(lb_margin)
	var level_lbl := _label("👤 Cấp độ " + str(int(gamification.get("level", 5))), 13, BRASS)
	lb_margin.add_child(level_lbl)
	top_bar.add_child(level_badge)

	# Flame Streak Badge
	var streak_badge := PanelContainer.new()
	streak_badge.add_theme_stylebox_override("panel", _panel_style(Color(0.22, 0.1, 0.04, 0.9), STREAK_ORG, 1080))
	var sb_margin := MarginContainer.new()
	sb_margin.add_theme_constant_override("margin_left", 14)
	sb_margin.add_theme_constant_override("margin_right", 14)
	sb_margin.add_theme_constant_override("margin_top", 4)
	sb_margin.add_theme_constant_override("margin_bottom", 4)
	streak_badge.add_child(sb_margin)
	var streak_lbl := _label("🔥 " + str(int(gamification.get("streak_days", 6))) + " ngày", 13, STREAK_ORG)
	sb_margin.add_child(streak_lbl)
	top_bar.add_child(streak_badge)

	# ── Instrument Category Selector (like Simply Guitar categories) ──
	inst_selector_row = HBoxContainer.new()
	inst_selector_row.add_theme_constant_override("separation", 10)
	main.add_child(inst_selector_row)

	var insts := [
		["🎋 Đàn Tranh", "dan_tranh"],
		["🎋 Sáo Trúc", "sao_truc"],
		["🎻 Đàn Bầu", "dan_bau"],
		["🥁 Trống", "trong"],
	]
	for item in insts:
		var ibtn := _button(item[0], WOOD_PANEL, CREAM)
		ibtn.custom_minimum_size = Vector2(110, 36)
		ibtn.add_theme_font_size_override("font_size", 13)
		ibtn.add_theme_stylebox_override("normal", _panel_style(WOOD_PANEL, BRASS_DIM, 1080))
		var code: String = item[1]
		ibtn.pressed.connect(func():
			selected_instrument = code
			# update active style for instrument buttons
			for child in inst_selector_row.get_children():
				if child is Button:
					(child as Button).add_theme_stylebox_override("normal", _panel_style(WOOD_PANEL, BRASS_DIM, 1080))
					(child as Button).add_theme_color_override("font_color", CREAM)
			ibtn.add_theme_stylebox_override("normal", _panel_style(BRASS, BRASS, 1080))
			ibtn.add_theme_color_override("font_color", WOOD_DARK)
			_refresh_roadmap()
		)
		inst_selector_row.add_child(ibtn)

	# Default active instrument style
	if inst_selector_row.get_child_count() > 0:
		var first_btn := inst_selector_row.get_child(0) as Button
		first_btn.add_theme_stylebox_override("normal", _panel_style(BRASS, BRASS, 1080))
		first_btn.add_theme_color_override("font_color", WOOD_DARK)

	# ── Horizontal Scrolling Roadmap ──
	roadmap_scroll = ScrollContainer.new()
	roadmap_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roadmap_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roadmap_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(roadmap_scroll)

	roadmap_row = HBoxContainer.new()
	roadmap_row.add_theme_constant_override("separation", 0)
	roadmap_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roadmap_scroll.add_child(roadmap_row)

	# ── Mini-Games Dashboard Panel (hidden by default) ──
	dashboard_games_panel = PanelContainer.new()
	dashboard_games_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_games_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_games_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	main.add_child(dashboard_games_panel)
	dashboard_games_panel.hide()

	games_vbox = VBoxContainer.new()
	games_vbox.add_theme_constant_override("separation", 16)
	games_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_games_panel.add_child(games_vbox)

	games_vbox.add_child(_label("🎲  Trò chơi luyện tập", 22, BRASS))

	var games_grid := GridContainer.new()
	games_grid.columns = 3
	games_grid.add_theme_constant_override("h_separation", 16)
	games_grid.add_theme_constant_override("v_separation", 16)
	games_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	games_vbox.add_child(games_grid)

	var game_list := [
		["🥁 Khớp Nhịp Điệu", "Luyện phản xạ gõ theo nốt nhạc chạy trên làn đường.", 0, Color("faae33")],
		["🎵 Trắc Nghiệm Nốt", "Nhận diện nhanh cao độ của các nốt nhạc dân tộc.", 1, Color("faae33")],
		["🎼 Điền Giai Điệu", "Sắp xếp nốt nhạc để hoàn chỉnh giai điệu dân ca.", 2, Color("faae33")]
	]
	for g in game_list:
		var gcard := PanelContainer.new()
		gcard.custom_minimum_size = Vector2(250, 180)
		gcard.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.06, 0.04, 0.95), Color(0.25, 0.16, 0.09), 16))
		games_grid.add_child(gcard)

		var gmargin := MarginContainer.new()
		gmargin.add_theme_constant_override("margin_left", 14)
		gmargin.add_theme_constant_override("margin_right", 14)
		gmargin.add_theme_constant_override("margin_top", 14)
		gmargin.add_theme_constant_override("margin_bottom", 14)
		gcard.add_child(gmargin)

		var gbox := VBoxContainer.new()
		gbox.add_theme_constant_override("separation", 10)
		gmargin.add_child(gbox)

		gbox.add_child(_label(g[0], 18, CREAM))
		var desc := _label(g[1], 12, MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		gbox.add_child(desc)

		var gbtn := _button("CHƠI NGAY", BRASS, WOOD_DARK)
		gbtn.custom_minimum_size = Vector2(0, 36)
		gbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t: int = g[2]
		gbtn.pressed.connect(func(): request_start_minigame.emit(t))
		gbox.add_child(gbtn)

	_refresh_roadmap()

# ═══════════════════════════════════════════════════════════════════════════
# ROOM HUD
# ═══════════════════════════════════════════════════════════════════════════
func _build_room_hud() -> void:
	hud_top = PanelContainer.new()
	hud_top.name = "RoomTopHUD"
	_set_top_bar_rect()
	# Glassmorphism panel with gold border
	hud_top.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.03, 0.02, 0.82), BRASS, 10))
	root.add_child(hud_top)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	hud_top.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var room_title := _label("🎵  Phòng học nhạc VietStage", 22, BRASS)
	room_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(room_title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var home_btn := _room_nav_button("🏠  Trang chủ", show_dashboard)
	row.add_child(home_btn)
	var prog_btn := _room_nav_button("📊  Tiến trình", show_progress)
	row.add_child(prog_btn)
	var lb_btn := _room_nav_button("🏆  Bảng xếp hạng", show_dashboard)
	row.add_child(lb_btn)

func _build_room_helper() -> void:
	room_helper = PanelContainer.new()
	room_helper.name = "RoomHelperPanel"
	room_helper.anchor_left   = 0.0
	room_helper.anchor_top    = 1.0
	room_helper.anchor_right  = 0.0
	room_helper.anchor_bottom = 1.0
	room_helper.offset_left   = 20
	room_helper.offset_top    = -180
	room_helper.offset_right  = 360
	room_helper.offset_bottom = -24
	room_helper.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.03, 0.02, 0.88), JADE, 12))
	root.add_child(room_helper)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	room_helper.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	box.add_child(_label("🏫  Khám phá phòng học", 18, JADE))
	box.add_child(_label("Chọn nhạc cụ phát sáng để bắt đầu luyện tập.", 13, CREAM))

	box.add_child(_hsep())

	var control_box := VBoxContainer.new()
	control_box.add_theme_constant_override("separation", 4)
	box.add_child(control_box)

	control_box.add_child(_label("🎮  Di chuyển: WASD / Phím mũi tên", 13, MUTED))
	control_box.add_child(_label("⚡  Tương tác: E / Space / Chạm", 13, BRASS))

func _room_nav_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 36)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", CREAM)
	
	# Translucent outline style with rounded corners
	var style_normal := _panel_style(Color(0.12, 0.07, 0.05, 0.6), Color(BRASS, 0.4), 6)
	btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover := _panel_style(Color(BRASS, 0.16), BRASS, 6)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	
	var style_pressed := _panel_style(Color(BRASS, 0.28), BRASS, 6)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(callback)
	return btn

# ═══════════════════════════════════════════════════════════════════════════
# LESSON PANEL
# ═══════════════════════════════════════════════════════════════════════════
func _build_lesson_panel() -> void:
	lesson_panel = PanelContainer.new()
	lesson_panel.name = "LessonSelectPanel"
	lesson_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	lesson_panel.offset_left   = -440
	lesson_panel.offset_top    = 92
	lesson_panel.offset_right  = -18
	lesson_panel.offset_bottom = -92
	lesson_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.96), BRASS, 10))
	root.add_child(lesson_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	lesson_panel.add_child(box)
	title_label = _label("Bài học", 26, BRASS)
	box.add_child(title_label)
	box.add_child(_label("Chọn bài học → Xem nghệ sĩ biểu diễn → Luyện tập.", 13, MUTED))
	
	var lesson_scroll := ScrollContainer.new()
	lesson_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(lesson_scroll)
	
	lesson_list = VBoxContainer.new()
	lesson_list.add_theme_constant_override("separation", 10)
	lesson_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_scroll.add_child(lesson_list)
	box.add_child(_hsep())

	# Mini-game row in lesson panel
	var mg_row := HBoxContainer.new()
	mg_row.add_theme_constant_override("separation", 8)
	mg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(mg_row)
	mg_row.add_child(_label("Trò chơi nhỏ:", 14, MUTED))
	var rm_btn := _button("🥁 Rhythm", JADE, WOOD_DARK)
	rm_btn.pressed.connect(func(): request_start_minigame.emit(0))
	mg_row.add_child(rm_btn)
	var nq_btn := _button("🎵 Quiz", JADE, WOOD_DARK)
	nq_btn.pressed.connect(func(): request_start_minigame.emit(1))
	mg_row.add_child(nq_btn)
	var mc_btn := _button("🎼 Melody", JADE, WOOD_DARK)
	mc_btn.pressed.connect(func(): request_start_minigame.emit(2))
	mg_row.add_child(mc_btn)

	var close := _button("← Trở về phòng", WOOD_PANEL, CREAM)
	close.pressed.connect(func():
		lesson_panel.hide()
		request_back_to_room.emit()
	)
	box.add_child(close)

# ═══════════════════════════════════════════════════════════════════════════
# RESULT PANEL
# ═══════════════════════════════════════════════════════════════════════════
func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.name = "ResultPanel"
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.custom_minimum_size = Vector2(700, 440)
	result_panel.offset_left   = -350
	result_panel.offset_top    = -220
	result_panel.offset_right  = 350
	result_panel.offset_bottom = 220
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.11, 0.06, 0.04, 0.98), BRASS, 14))
	root.add_child(result_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	result_panel.add_child(box)
	result_title = _label("Lesson Complete", 34, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_title)
	result_breakdown = _label("", 18, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_breakdown)
	result_xp = _label("", 20, JADE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_xp)
	box.add_child(_label("Stars → XP → Streak → Badge → Next Lesson", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_hsep())
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	box.add_child(actions)
	var replay := _button("↺ Replay", WOOD_PANEL, CREAM)
	replay.pressed.connect(func(): request_replay_practice.emit(current_lesson))
	actions.add_child(replay)
	var nxt := _button("→ Next Lesson", BRASS, WOOD_DARK)
	nxt.pressed.connect(func(): request_next_lesson.emit())
	actions.add_child(nxt)
	var room := _button("← Back", JADE, WOOD_DARK)
	room.pressed.connect(func():
		result_panel.hide()
		show_room_hud()
		request_back_to_room.emit()
	)
	actions.add_child(room)

# ═══════════════════════════════════════════════════════════════════════════
# PROGRESS DASHBOARD
# ═══════════════════════════════════════════════════════════════════════════
func _build_progress_screen() -> void:
	progress_screen = Control.new()
	progress_screen.name = "ProgressDashboard"
	progress_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(progress_screen)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = SHADOW
	progress_screen.add_child(shade)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24
	scroll.offset_top = 24
	scroll.offset_right = -24
	scroll.offset_bottom = -88
	progress_screen.add_child(scroll)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 18)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(main)

	# Header
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	main.add_child(hdr)
	var back_btn := _button("← Home", WOOD_PANEL, CREAM)
	back_btn.pressed.connect(show_dashboard)
	hdr.add_child(back_btn)
	var hdr_lbl := _label("📊  Progress Dashboard", 30, CREAM)
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hdr_lbl)

	# ── Accuracy trend chart (drawn) ───────────────────────────────────────────
	var chart_section := _section_panel("📈  Accuracy Trend (last 7 sessions)")
	chart_section.custom_minimum_size = Vector2(0, 180)
	main.add_child(chart_section)
	var chart := Control.new()
	chart.custom_minimum_size = Vector2(0, 150)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.name = "AccuracyChart"
	chart.draw.connect(func(): _draw_accuracy_chart(chart))
	chart_section.get_child(0).add_child(chart)

	# ── Stats row ─────────────────────────────────────────────────────────────
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 14)
	main.add_child(stats_row)

	var accuracy_history: Array = gamification.get("accuracy_history", [])
	var avg_acc := 0.0
	for a in accuracy_history:
		avg_acc += float(a)
	if accuracy_history.size() > 0:
		avg_acc /= accuracy_history.size()

	stats_row.add_child(_stat_card("🎯  Chính xác TB", "%d%%" % int(avg_acc), JADE))
	stats_row.add_child(_stat_card("⏱  Luyện tập",
		_format_minutes(int(gamification.get("practice_time", 0))), BRASS))
	stats_row.add_child(_stat_card("📚  Bài xong",
		"%d / %d" % [int(gamification.get("lessons_done", 0)), int(gamification.get("lessons_total", 1))], BRASS))
	stats_row.add_child(_stat_card("🔥  Chuỗi ngày",
		"%d ngày" % int(gamification.get("streak_days", 0)), STREAK_ORG))
	stats_row.add_child(_stat_card("⭐  Cấp độ",
		"Level %d" % int(gamification.get("level", 1)), STAR_GOLD))

	# ── XP progress ───────────────────────────────────────────────────────────
	var xp_section := _section_panel("⭐  Kinh nghiệm (XP)")
	main.add_child(xp_section)
	var xp_box := VBoxContainer.new()
	xp_box.add_theme_constant_override("separation", 8)
	xp_section.get_child(0).add_child(xp_box)
	xp_box.add_child(_label("Cấp độ %d — %d / %d XP để lên Cấp độ %d" % [
		int(gamification.get("level", 1)),
		int(gamification.get("xp", 0)),
		int(gamification.get("xp_to_next", 1000)),
		int(gamification.get("level", 1)) + 1,
	], 16, CREAM))
	var xp_pg := ProgressBar.new()
	xp_pg.max_value = max(1, int(gamification.get("xp_to_next", 1000)))
	xp_pg.value = int(gamification.get("xp", 0))
	xp_pg.custom_minimum_size = Vector2(0, 24)
	xp_pg.show_percentage = false
	xp_pg.add_theme_stylebox_override("background", _bar_bg())
	xp_pg.add_theme_stylebox_override("fill", _bar_fill(STAR_GOLD))
	xp_box.add_child(xp_pg)

	# ── Badge collection ──────────────────────────────────────────────────────
	var badge_section := _section_panel("🎖  Huy hiệu đã mở khóa")
	main.add_child(badge_section)
	var bg := GridContainer.new()
	bg.columns = 4
	bg.add_theme_constant_override("h_separation", 10)
	bg.add_theme_constant_override("v_separation", 10)
	badge_section.get_child(0).add_child(bg)
	var all_badges := [
		"First Rhythm", "Pitch Ear", "Three Day Streak", "Dan Tranh Novice",
		"Sao Truc Breath", "Cultural Explorer", "Steady Beat", "Quick Learner"
	]
	var earned: Array = gamification.get("badges", [])
	for badge in all_badges:
		var unlocked := earned.has(badge)
		var bp := PanelContainer.new()
		bp.custom_minimum_size = Vector2(140, 60)
		bp.add_theme_stylebox_override("panel", _panel_style(
			Color(0.15, 0.09, 0.055, 0.96) if unlocked else Color(0.1, 0.075, 0.06, 0.9),
			BRASS if unlocked else LOCKED_GREY, 8))
		var bl := _label(("★ " if unlocked else "○ ") + _badge_title(badge), 13,
			CREAM if unlocked else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bp.add_child(bl)
		bg.add_child(bp)

func _refresh_progress_screen() -> void:
	# Re-draw accuracy chart if it exists
	var chart := progress_screen.find_child("AccuracyChart", true, false)
	if chart:
		chart.queue_redraw()

func _draw_accuracy_chart(node: Control) -> void:
	var history: Array = gamification.get("accuracy_history", [72.0, 68.0, 75.0, 80.0, 84.0, 79.0, 88.0])
	if history.size() < 2:
		return
	var w := node.size.x
	var h := node.size.y
	var pad_l := 36.0
	var pad_r := 16.0
	var pad_t := 12.0
	var pad_b := 24.0
	var chart_w := w - pad_l - pad_r
	var chart_h := h - pad_t - pad_b

	# Grid lines at 0, 25, 50, 75, 100
	for pct in [0, 25, 50, 75, 100]:
		var y := pad_t + chart_h * (1.0 - float(pct) / 100.0)
		node.draw_line(Vector2(pad_l, y), Vector2(w - pad_r, y), Color(MUTED, 0.2), 1.0)
		node.draw_string(font_reg if font_reg else ThemeDB.fallback_font, Vector2(2, y + 5), "%d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)

	# Build polyline
	var pts := PackedVector2Array()
	var fill_pts := PackedVector2Array()
	fill_pts.append(Vector2(pad_l, pad_t + chart_h))
	for i in range(history.size()):
		var t := float(i) / float(history.size() - 1)
		var x := pad_l + t * chart_w
		var acc: float = clamp(float(history[i]), 0.0, 100.0)
		var y: float = pad_t + chart_h * (1.0 - acc / 100.0)
		pts.append(Vector2(x, y))
		fill_pts.append(Vector2(x, y))
	fill_pts.append(Vector2(pad_l + chart_w, pad_t + chart_h))

	# Fill area
	node.draw_colored_polygon(fill_pts, Color(JADE, 0.12))
	# Line
	if pts.size() >= 2:
		node.draw_polyline(pts, JADE, 2.5)
	# Dots
	for pt in pts:
		node.draw_circle(pt, 5.0, JADE)
		node.draw_arc(pt, 5.0, 0, TAU, 16, Color(CREAM, 0.7), 1.5)

	# X-axis labels
	for i in range(history.size()):
		var t := float(i) / float(history.size() - 1)
		var x := pad_l + t * chart_w
		node.draw_string(font_reg if font_reg else ThemeDB.fallback_font, Vector2(x - 8, h - 4), "S%d" % (i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)

# ═══════════════════════════════════════════════════════════════════════════
# AUDIO REFERENCE LIBRARY
# ═══════════════════════════════════════════════════════════════════════════
func _build_audio_library() -> void:
	audio_lib_screen = Control.new()
	audio_lib_screen.name = "AudioLibrary"
	audio_lib_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(audio_lib_screen)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = SHADOW
	audio_lib_screen.add_child(shade)

	var main := VBoxContainer.new()
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.offset_left = 28
	main.offset_top = 24
	main.offset_right = -28
	main.offset_bottom = -88
	main.add_theme_constant_override("separation", 16)
	audio_lib_screen.add_child(main)

	# Header
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	main.add_child(hdr)
	var back := _button("← Trang chủ", WOOD_PANEL, CREAM)
	back.pressed.connect(show_dashboard)
	hdr.add_child(back)
	var hdr_lbl := _label("🎵  Thư Viện Âm Thanh", 30, CREAM)
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hdr_lbl)
	# Horizontal Scroll wrapper for filters (Spotify/YouTube style)
	var filter_scroll := ScrollContainer.new()
	filter_scroll.custom_minimum_size = Vector2(0, 48)
	filter_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(filter_scroll)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	filter_scroll.add_child(filter_row)

	# Filter buttons inside filter_row
	for inst_name in ["Tất cả", "Đàn Tranh", "Sáo Trúc", "Đàn Bầu", "Trống"]:
		var fb := _button(inst_name, WOOD_PANEL, CREAM)
		fb.custom_minimum_size = Vector2(96, 36)
		filter_row.add_child(fb)

	# Waveform preview card
	var wf_section := _section_panel("📊  Dạng sóng")
	wf_section.custom_minimum_size = Vector2(0, 140)
	main.add_child(wf_section)
	var wf_inner := wf_section.get_child(0)
	var wf_display := Control.new()
	wf_display.name = "WaveformDisplay"
	wf_display.custom_minimum_size = Vector2(0, 100)
	wf_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wf_display.draw.connect(func(): _draw_waveform_preview(wf_display))
	wf_inner.add_child(wf_display)

	# Playback controls
	var pb_row := HBoxContainer.new()
	pb_row.add_theme_constant_override("separation", 10)
	wf_inner.add_child(pb_row)
	var play_btn := _button("▶  Play", JADE, WOOD_DARK)
	pb_row.add_child(play_btn)
	var slow_btn := _button("🐢  Chậm (0.5x)", BRASS, WOOD_DARK)
	pb_row.add_child(slow_btn)
	var stop_btn := _button("■  Stop", WOOD_PANEL, CREAM)
	pb_row.add_child(stop_btn)
	var prog_bar2 := ProgressBar.new()
	prog_bar2.max_value = 100
	prog_bar2.value = 32
	prog_bar2.custom_minimum_size = Vector2(0, 22)
	prog_bar2.show_percentage = false
	prog_bar2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_bar2.add_theme_stylebox_override("background", _bar_bg())
	prog_bar2.add_theme_stylebox_override("fill", _bar_fill(BRASS))
	pb_row.add_child(prog_bar2)
	pb_row.add_child(_label("0:32 / 1:42", 13, MUTED))

	# Audio track list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(scroll)
	var track_list := VBoxContainer.new()
	track_list.add_theme_constant_override("separation", 8)
	track_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(track_list)

	var tracks := [
		{"title": "Đàn Tranh – Basic Pluck",      "instrument": "Đàn Tranh", "duration": "1:42", "difficulty": "Beginner"},
		{"title": "Đàn Tranh – Left-hand Vibrato", "instrument": "Đàn Tranh", "duration": "2:15", "difficulty": "Intermediate"},
		{"title": "Đàn Tranh – Fast Tremolo",      "instrument": "Đàn Tranh", "duration": "1:58", "difficulty": "Advanced"},
		{"title": "Sáo Trúc – Breath Attack",       "instrument": "Sáo Trúc", "duration": "2:30", "difficulty": "Beginner"},
		{"title": "Sáo Trúc – Sustain & Release",   "instrument": "Sáo Trúc", "duration": "3:10", "difficulty": "Intermediate"},
		{"title": "Đàn Bầu – Single String Bend",  "instrument": "Đàn Bầu",  "duration": "2:44", "difficulty": "Beginner"},
		{"title": "Trống – Basic Pattern",          "instrument": "Trống",    "duration": "1:20", "difficulty": "Beginner"},
	]
	for track in tracks:
		track_list.add_child(_make_audio_track_card(track))

func _draw_waveform_preview(node: Control) -> void:
	var w := node.size.x
	var h := node.size.y
	if w == 0 or h == 0:
		return
	var cy := h * 0.5
	# Background fill
	node.draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.025, 0.02, 0.6))
	# Simulated waveform bars
	var bar_count := int(w / 5)
	for i in range(bar_count):
		var t := float(i) / float(bar_count)
		var amp := (sin(t * TAU * 4.0 + 0.5) * 0.4 + sin(t * TAU * 9.0) * 0.2 + 0.4) * cy * 0.88
		var x := float(i) * (w / float(bar_count))
		var col := JADE if t < 0.3 else (BRASS if t < 0.65 else Color(MUTED, 0.7))
		node.draw_rect(Rect2(x, cy - amp, 3.0, amp * 2.0), col)
	# Playhead
	var ph_x := w * 0.32
	node.draw_line(Vector2(ph_x, 0), Vector2(ph_x, h), Color(CREAM, 0.9), 2.0)
	node.draw_circle(Vector2(ph_x, 0), 5.0, CREAM)

func _make_audio_track_card(track: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.95), Color(0.26, 0.17, 0.1), 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	# Play icon
	var play_icon := _button("▶", JADE, WOOD_DARK)
	play_icon.custom_minimum_size = Vector2(40, 40)
	row.add_child(play_icon)
	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	info.add_child(_label(track.get("title", ""), 17, CREAM))
	info.add_child(_label("%s  •  %s" % [track.get("instrument", ""), track.get("difficulty", "")], 13, MUTED))
	# Duration
	row.add_child(_label(track.get("duration", ""), 15, BRASS))
	# Slow-motion button
	var slow := _button("🐢 0.5x", WOOD_PANEL, CREAM)
	slow.custom_minimum_size = Vector2(80, 40)
	row.add_child(slow)
	return panel

# ═══════════════════════════════════════════════════════════════════════════
# DAILY CHALLENGE
# ═══════════════════════════════════════════════════════════════════════════
func _build_daily_challenge() -> void:
	daily_challenge = Control.new()
	daily_challenge.name = "DailyChallenge"
	daily_challenge.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(daily_challenge)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = SHADOW
	daily_challenge.add_child(shade)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 28
	scroll.offset_top = 24
	scroll.offset_right = -28
	scroll.offset_bottom = -88
	daily_challenge.add_child(scroll)

	daily_challenge_main = GridContainer.new()
	daily_challenge_main.name = "DailyChallengeGrid"
	daily_challenge_main.columns = 2
	daily_challenge_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily_challenge_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	daily_challenge_main.add_theme_constant_override("h_separation", 18)
	daily_challenge_main.add_theme_constant_override("v_separation", 18)
	scroll.add_child(daily_challenge_main)
	var main = daily_challenge_main

	# ── Left column ───────────────────────────────────────────────────────────
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 16)
	left_col.custom_minimum_size = Vector2(390, 0)
	main.add_child(left_col)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	left_col.add_child(hdr)
	var back := _button("← Trang chủ", WOOD_PANEL, CREAM)
	back.pressed.connect(show_dashboard)
	hdr.add_child(back)
	left_col.add_child(_label("⚡  Daily Challenge", 30, BRASS))

	# Streak section
	var streak_panel := PanelContainer.new()
	streak_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.08, 0.02, 0.96), STREAK_ORG, 10))
	left_col.add_child(streak_panel)
	var sp_box := VBoxContainer.new()
	sp_box.add_theme_constant_override("separation", 8)
	streak_panel.add_child(sp_box)
	sp_box.add_child(_label("🔥  Streak Hiện Tại", 18, STREAK_ORG))
	var streak_days: int = int(gamification.get("streak_days", 0))
	sp_box.add_child(_label("%d ngày liên tiếp" % streak_days, 32, CREAM))
	sp_box.add_child(_label("Luyện tập mỗi ngày để duy trì streak!", 14, MUTED))

	# Streak calendar
	sp_box.add_child(_label("Tuần này:", 14, MUTED))
	var cal_row := HBoxContainer.new()
	cal_row.add_theme_constant_override("separation", 6)
	sp_box.add_child(cal_row)
	var days := ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
	for i in range(7):
		var day_box := PanelContainer.new()
		day_box.custom_minimum_size = Vector2(38, 44)
		var done := (i < streak_days % 7)
		day_box.add_theme_stylebox_override("panel", _panel_style(
			Color(0.22, 0.12, 0.05, 0.9) if done else Color(0.08, 0.045, 0.035, 0.7),
			STREAK_ORG if done else MUTED, 6))
		var dv := VBoxContainer.new()
		dv.alignment = BoxContainer.ALIGNMENT_CENTER
		day_box.add_child(dv)
		dv.add_child(_label("🔥" if done else "○", 14, STREAK_ORG if done else MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		dv.add_child(_label(days[i], 11, CREAM if done else MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		cal_row.add_child(day_box)

	# Today's task
	var task_section := _section_panel("📋  Nhiệm vụ hôm nay")
	left_col.add_child(task_section)
	var tasks := [
		{"title": "Luyện tập nhịp đều 60s", "reward": "120 XP", "done": true},
		{"title": "Hoàn thành 1 bài Đàn Tranh", "reward": "80 XP", "done": false},
		{"title": "Đạt accuracy ≥ 75%", "reward": "50 XP + Badge", "done": false},
	]
	var task_box := VBoxContainer.new()
	task_box.add_theme_constant_override("separation", 8)
	task_section.get_child(0).add_child(task_box)
	for task in tasks:
		var t_row := HBoxContainer.new()
		t_row.add_theme_constant_override("separation", 10)
		var done: bool = task.get("done", false)
		var icon_lbl := _label("✓" if done else "○", 18, SUCCESS if done else MUTED)
		icon_lbl.custom_minimum_size = Vector2(22, 0)
		t_row.add_child(icon_lbl)
		var t_info := VBoxContainer.new()
		t_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_row.add_child(t_info)
		t_info.add_child(_label(task.get("title", ""), 15, CREAM if not done else MUTED))
		t_info.add_child(_label("Reward: %s" % task.get("reward", ""), 12, JADE))
		task_box.add_child(t_row)

	var claim_btn := _button("▶  Bắt đầu Challenge", BRASS, WOOD_DARK)
	claim_btn.add_theme_font_size_override("font_size", 16)
	claim_btn.custom_minimum_size = Vector2(0, 46)
	claim_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_btn.pressed.connect(func(): request_enter_room.emit())
	left_col.add_child(claim_btn)

	# ── Right column: Leaderboard ─────────────────────────────────────────────
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 14)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(right_col)

	right_col.add_child(_label("🏅  Leaderboard Hôm Nay", 24, CREAM))
	var lb_panel := _section_panel("Top học viên")
	lb_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(lb_panel)
	var lb_box := VBoxContainer.new()
	lb_box.add_theme_constant_override("separation", 10)
	lb_panel.get_child(0).add_child(lb_box)

	var lb_rows := [
		["1", "🥇", "Minh Anh",   "Đàn Tranh", "18,420", "9 ngày"],
		["2", "🥈", "Gia Bảo",    "Sáo Trúc",  "16,980", "8 ngày"],
		["3", "🥉", "Linh Chi",   "Đàn Tranh", "15,110", "7 ngày"],
		["4", "  ", "Thanh Tâm",  "Đàn Bầu",   "13,850", "5 ngày"],
		["5", "  ", "Quốc Hùng",  "Trống",      "12,990", "4 ngày"],
		["─", "👤", "Bạn",        "Đàn Tranh", str(int(gamification.get("weekly_score", 0))),
			str(int(gamification.get("streak_days", 0))) + " ngày"],
	]
	for i in range(lb_rows.size()):
		var r: Array = lb_rows[i]
		var is_me := (i == lb_rows.size() - 1)
		var r_panel := PanelContainer.new()
		r_panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.14, 0.08, 0.05, 0.96) if is_me else Color(0.1, 0.055, 0.035, 0.9),
			BRASS if is_me else Color(0.25, 0.16, 0.09), 8))
		var r_row := HBoxContainer.new()
		r_row.add_theme_constant_override("separation", 10)
		r_panel.add_child(r_row)
		r_row.add_child(_label("%s %s" % [r[0], r[1]], 15, BRASS if is_me else MUTED))
		var r_info := VBoxContainer.new()
		r_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_row.add_child(r_info)
		r_info.add_child(_label(r[2], 16, CREAM if is_me else CREAM))
		r_info.add_child(_label(r[3], 12, MUTED))
		r_row.add_child(_label("%s pts" % r[4], 15, JADE if is_me else BRASS))
		r_row.add_child(_label("🔥 %s" % r[5], 13, STREAK_ORG))
		lb_box.add_child(r_panel)

func _refresh_daily_challenge() -> void:
	pass  # Could refresh dynamic data here

# ═══════════════════════════════════════════════════════════════════════════
# MOBILE NAV
# ═══════════════════════════════════════════════════════════════════════════
func _build_mobile_nav() -> void:
	mobile_nav = PanelContainer.new()
	mobile_nav.name = "BottomNavigation"
	mobile_nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mobile_nav.offset_left   = 12
	mobile_nav.offset_right  = -12
	mobile_nav.offset_top    = -78
	mobile_nav.offset_bottom = -12
	mobile_nav.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.045, 0.035, 0.94), Color(0.27, 0.18, 0.1), 10))
	root.add_child(mobile_nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	mobile_nav.add_child(row)
	var nav_items := [
		["🏠 Home",      func(): show_dashboard()],
		["🎮 Room",      func(): request_enter_room.emit()],
		["📊 Progress",  func(): show_progress()],
		["🎵 Library",   func(): show_audio_library()],
		["⚡ Daily",     func(): show_daily_challenge()],
	]
	for item in nav_items:
		var btn := _button(item[0], WOOD_PANEL, CREAM)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(item[1])
		row.add_child(btn)

# ═══════════════════════════════════════════════════════════════════════════
# Lesson card & dashboard helpers
# ═══════════════════════════════════════════════════════════════════════════
func _make_lesson_card(lesson: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.16, 0.09, 0.055, 0.96), Color(0.34, 0.23, 0.13), 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	# Stars
	var stars_lbl := _label(_stars_unicode(int(lesson.get("stars", 0))), 18, STAR_GOLD)
	stars_lbl.custom_minimum_size = Vector2(56, 0)
	row.add_child(stars_lbl)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var locked: bool = not bool(lesson.get("is_unlocked", true))
	info.add_child(_label(lesson.get("title", "Lesson"), 18, CREAM if not locked else MUTED))
	info.add_child(_label("%s  •  Cấp độ %d" % [_difficulty_title(lesson.get("difficulty", "Beginner")), int(lesson.get("required_level", 1))], 13, MUTED))
	var demo_btn := _button("Demo", JADE if not locked else LOCKED_GREY, WOOD_DARK)
	demo_btn.disabled = locked
	demo_btn.pressed.connect(func():
		current_lesson = lesson
		request_start_demo.emit(lesson)
	)
	row.add_child(demo_btn)
	var prac_btn := _button("Practice", BRASS if not locked else LOCKED_GREY, WOOD_DARK)
	prac_btn.disabled = locked
	prac_btn.pressed.connect(func():
		current_lesson = lesson
		request_start_practice.emit(lesson)
	)
	row.add_child(prac_btn)
	if locked:
		var lock_lbl := _label("🔒", 18, MUTED)
		row.add_child(lock_lbl)
	return panel

func _dashboard_card(title: String, body: String, accent: Color) -> PanelContainer:
	var card := _section_panel(title)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.94), accent, 10))
	card.get_child(0).add_child(_label(body, 15, CREAM))
	return card

func _stat_card(title: String, value: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.94), color, 10))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)
	vb.add_child(_label(title, 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_label(value, 22, color, HORIZONTAL_ALIGNMENT_CENTER))
	return card

func _section_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.055, 0.035, 0.94), Color(0.31, 0.2, 0.11), 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label(title, 18, BRASS))
	return panel

func _build_leaderboard_rows() -> void:
	if leaderboard_list == null:
		return
	for child in leaderboard_list.get_children():
		child.queue_free()
	var rows := [
		["1 🥇", "Minh Anh",   "Đàn Tranh", "18,420", "9 ngày"],
		["2 🥈", "Gia Bảo",    "Sáo Trúc",  "16,980", "8 ngày"],
		["3 🥉", "Linh Chi",   "Đàn Tranh", "15,110", "7 ngày"],
		["#8 👤", "Bạn",       "Đàn Tranh",
			str(int(gamification.get("weekly_score", 0))),
			str(int(gamification.get("streak_days", 0))) + " ngày"],
	]
	for row in rows:
		leaderboard_list.add_child(_label(
			"%s  %s  —  %s  •  %s pts  •  🔥 %s" % row, 13, CREAM))

func _build_badges() -> void:
	if badges_grid == null:
		return
	for child in badges_grid.get_children():
		child.queue_free()
	var badge_names: Array[String] = [
		"First Rhythm", "Pitch Ear", "Three Day Streak",
		"Dan Tranh Novice", "Sao Truc Breath", "Cultural Explorer"
	]
	for badge in badge_names:
		var badge_list: Array = gamification.get("badges", [])
		var unlocked := badge_list.has(badge)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(118, 64)
		panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.15, 0.09, 0.055, 0.96),
			BRASS if unlocked else LOCKED_GREY, 8))
		var label := _label(("★ " if unlocked else "○ ") + _badge_title(badge), 12,
			CREAM if unlocked else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(label)
		badges_grid.add_child(panel)

func _refresh_gamification() -> void:
	if xp_bar:
		var xp_to_next: int = max(1, int(gamification.get("xp_to_next", 1000)))
		xp_bar.max_value = xp_to_next
		xp_bar.value = int(gamification.get("xp", 0))
	if xp_label:
		xp_label.text = "Lv.%d  •  %d / %d XP" % [
			int(gamification.get("level", 1)),
			int(gamification.get("xp", 0)),
			int(gamification.get("xp_to_next", 1000))
		]
	_build_leaderboard_rows()
	_build_badges()

# ═══════════════════════════════════════════════════════════════════════════
# Responsive layout
# ═══════════════════════════════════════════════════════════════════════════
func _apply_responsive_layout() -> void:
	var width: float = get_viewport().get_visible_rect().size.x
	desktop_mode = width >= 800
	_sync_mobile_nav()
	_set_top_bar_rect()
	
	# Co giãn thẻ Đăng nhập (LoginCard)
	if is_instance_valid(login_card):
		var card_w: float = min(480.0, width - 32.0)
		login_card.custom_minimum_size = Vector2(card_w, 560)
		login_card.offset_left = -card_w * 0.5
		login_card.offset_right = card_w * 0.5
		login_card.offset_top = -280
		login_card.offset_bottom = 280
		
	# Co giãn Hộp thoại Kết quả (ResultPanel)
	if is_instance_valid(result_panel):
		if desktop_mode:
			result_panel.custom_minimum_size = Vector2(700, 440)
			result_panel.offset_left = -350
			result_panel.offset_right = 350
			result_panel.offset_top = -220
			result_panel.offset_bottom = 220
		else:
			var res_w: float = min(700.0, width - 24.0)
			result_panel.custom_minimum_size = Vector2(res_w, 480)
			result_panel.offset_left = -res_w * 0.5
			result_panel.offset_right = res_w * 0.5
			result_panel.offset_top = -240
			result_panel.offset_bottom = 240

	if desktop_mode:
		lesson_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		lesson_panel.offset_left   = -440
		lesson_panel.offset_top    = 92
		lesson_panel.offset_right  = -18
		lesson_panel.offset_bottom = -92
		
		# Dashboard desktop
		if is_instance_valid(left_nav_bar):
			left_nav_bar.show()
		if is_instance_valid(dashboard_scroll):
			dashboard_scroll.offset_left = 124
			dashboard_scroll.offset_top = 20
			dashboard_scroll.offset_right = -24
			dashboard_scroll.offset_bottom = -20
		if is_instance_valid(daily_challenge_main):
			daily_challenge_main.columns = 2
	else:
		lesson_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		lesson_panel.offset_left   = 10
		lesson_panel.offset_top    = -440
		lesson_panel.offset_right  = -10
		lesson_panel.offset_bottom = -88
		
		# Dashboard mobile
		if is_instance_valid(left_nav_bar):
			left_nav_bar.hide()
		if is_instance_valid(dashboard_scroll):
			dashboard_scroll.offset_left = 18
			dashboard_scroll.offset_top = 20
			dashboard_scroll.offset_right = -18
			dashboard_scroll.offset_bottom = -88
		if is_instance_valid(daily_challenge_main):
			daily_challenge_main.columns = 1

func _set_top_bar_rect() -> void:
	if hud_top == null:
		return
	hud_top.anchor_left   = 0.0
	hud_top.anchor_top    = 0.0
	hud_top.anchor_right  = 1.0
	hud_top.anchor_bottom = 0.0
	hud_top.offset_left   = 18
	hud_top.offset_top    = 16
	hud_top.offset_right  = -18
	hud_top.offset_bottom = 76
	hud_top.custom_minimum_size = Vector2(0, 60)

func _sync_mobile_nav() -> void:
	if mobile_nav == null:
		return
	mobile_nav.visible = not desktop_mode

# ═══════════════════════════════════════════════════════════════════════════
# Style helpers
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
	button.custom_minimum_size = Vector2(110, 42)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_stylebox_override("normal",   _panel_style(bg, bg.lightened(0.18), 8))
	button.add_theme_stylebox_override("hover",    _panel_style(bg.lightened(0.1), BRASS, 8))
	button.add_theme_stylebox_override("pressed",  _panel_style(bg.darkened(0.12), BRASS, 8))
	button.add_theme_stylebox_override("disabled", _panel_style(LOCKED_GREY, LOCKED_GREY, 8))
	return button

func _tab_button(text: String, active: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 40)
	btn.add_theme_font_size_override("font_size", 15)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if active:
		btn.add_theme_stylebox_override("normal", _panel_style(BRASS, BRASS, 6))
		btn.add_theme_color_override("font_color", WOOD_DARK)
	else:
		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_color_override("font_color", CREAM)
	btn.add_theme_stylebox_override("hover",   _panel_style(Color(BRASS, 0.12), Color(BRASS, 0.25), 6))
	btn.add_theme_stylebox_override("pressed", _panel_style(Color(BRASS, 0.22), BRASS, 6))
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	return btn

func _line_edit(placeholder: String) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(0, 44)
	le.add_theme_font_size_override("font_size", 16)
	le.add_theme_color_override("font_color", CREAM)
	le.add_theme_color_override("caret_color", BRASS)
	le.add_theme_stylebox_override("normal", _panel_style(Color(0.07, 0.04, 0.03, 0.9), BRASS_DIM, 8))
	le.add_theme_stylebox_override("focus",  _panel_style(Color(0.09, 0.05, 0.035, 0.95), BRASS, 8))
	return le

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

func _hsep() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(MUTED, 0.22))
	return sep

func _instrument_title(instrument: String) -> String:
	match instrument:
		"dan_tranh": return "Đàn Tranh"
		"sao_truc":  return "Sáo Trúc"
		"dan_bau":   return "Đàn Bầu"
		"trong":     return "Trống"
		_:           return instrument.capitalize()

func _stars_unicode(count: int) -> String:
	var output := ""
	for i in range(3):
		output += "★" if i < count else "☆"
	return output

func _format_minutes(total_seconds: int) -> String:
	var h := total_seconds / 3600
	var m := (total_seconds % 3600) / 60
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%d phút" % m


# ── Helper functions for translation ──
func _badge_title(badge_name: String) -> String:
	match badge_name:
		"First Rhythm": return "Nhịp điệu đầu tiên"
		"Pitch Ear": return "Thính nhạy cao độ"
		"Three Day Streak": return "Chuỗi 3 ngày"
		"Dan Tranh Novice": return "Đàn Tranh sơ cấp"
		"Sao Truc Breath": return "Hơi thở Sáo Trúc"
		"Cultural Explorer": return "Khám phá văn hóa"
		"Steady Beat": return "Giữ nhịp ổn định"
		"Quick Learner": return "Học nhanh"
		_: return badge_name

func _difficulty_title(diff_str: String) -> String:
	match diff_str:
		"Beginner": return "Cơ bản"
		"Intermediate": return "Trung cấp"
		"Advanced": return "Nâng cao"
		_: return diff_str


# ── Simply Guitar roadmap helper methods ──
func set_lessons(lessons_arr: Array) -> void:
	all_lessons = lessons_arr
	_refresh_roadmap()

func _on_tab_pressed(tab_name: String) -> void:
	current_dashboard_tab = tab_name
	
	var act_style := _panel_style(CREAM, BRASS, 12)
	var inact_style := StyleBoxEmpty.new()
	
	tab_btn_courses.add_theme_stylebox_override("normal", act_style if tab_name == "courses" else inact_style)
	tab_btn_library.add_theme_stylebox_override("normal", act_style if tab_name == "library" else inact_style)
	tab_btn_games.add_theme_stylebox_override("normal", act_style if tab_name == "games" else inact_style)
	
	# update label/icon text colors on active buttons
	if tab_btn_courses.get_child_count() > 0:
		var c_lbl1 := tab_btn_courses.get_child(0).get_child(0) as Label
		var c_lbl2 := tab_btn_courses.get_child(0).get_child(1) as Label
		c_lbl1.add_theme_color_override("font_color", WOOD_DARK if tab_name == "courses" else CREAM)
		c_lbl2.add_theme_color_override("font_color", WOOD_DARK if tab_name == "courses" else CREAM)
	
	if tab_btn_library.get_child_count() > 0:
		var l_lbl1 := tab_btn_library.get_child(0).get_child(0) as Label
		var l_lbl2 := tab_btn_library.get_child(0).get_child(1) as Label
		l_lbl1.add_theme_color_override("font_color", WOOD_DARK if tab_name == "library" else CREAM)
		l_lbl2.add_theme_color_override("font_color", WOOD_DARK if tab_name == "library" else CREAM)
	
	if tab_btn_games.get_child_count() > 0:
		var g_lbl1 := tab_btn_games.get_child(0).get_child(0) as Label
		var g_lbl2 := tab_btn_games.get_child(0).get_child(1) as Label
		g_lbl1.add_theme_color_override("font_color", WOOD_DARK if tab_name == "games" else CREAM)
		g_lbl2.add_theme_color_override("font_color", WOOD_DARK if tab_name == "games" else CREAM)
	
	if tab_name == "courses":
		inst_selector_row.show()
		roadmap_scroll.show()
		dashboard_games_panel.hide()
		audio_lib_screen.hide()
		_refresh_roadmap()
	elif tab_name == "library":
		inst_selector_row.hide()
		roadmap_scroll.hide()
		dashboard_games_panel.hide()
		show_audio_library()
	elif tab_name == "games":
		inst_selector_row.hide()
		roadmap_scroll.hide()
		audio_lib_screen.hide()
		dashboard_games_panel.show()

func _refresh_roadmap() -> void:
	if roadmap_row == null:
		return
		
	# Clear previous cards
	for child in roadmap_row.get_children():
		child.queue_free()
		
	# Filter lessons by selected_instrument
	var instrument_lessons := []
	for l in all_lessons:
		if l.get("instrument", "") == selected_instrument:
			instrument_lessons.append(l)
			
	# If no lessons (e.g. not loaded yet), load static placeholder lessons for dan_tranh
	if instrument_lessons.size() == 0:
		instrument_lessons = [
			{
				"lesson_id": "dt_001",
				"instrument": "dan_tranh",
				"title": "Kỹ thuật gảy cơ bản",
				"difficulty": "Beginner",
				"required_level": 1,
				"stars": 2,
				"is_unlocked": true,
			},
			{
				"lesson_id": "dt_002",
				"instrument": "dan_tranh",
				"title": "Kỹ thuật rung tay trái",
				"difficulty": "Intermediate",
				"required_level": 5,
				"stars": 0,
				"is_unlocked": true,
			},
			{
				"lesson_id": "dt_003",
				"instrument": "dan_tranh",
				"title": "Chuỗi Tremolo nhanh",
				"difficulty": "Advanced",
				"required_level": 8,
				"stars": 0,
				"is_unlocked": false,
			}
		]
		
	for i in range(instrument_lessons.size()):
		var lesson: Dictionary = instrument_lessons[i] as Dictionary
		var is_locked: bool = not bool(lesson.get("is_unlocked", true)) or int(lesson.get("required_level", 1)) > int(gamification.get("level", 1))
		var stars: int = int(lesson.get("stars", 0))
		
		# Create Course Card
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(380, 230)
		
		# Glowing border style for active, regular for others
		var border_color := BRASS if (stars > 0 or not is_locked) else Color(0.25, 0.16, 0.09)
		if stars == 0 and not is_locked:
			# Active current lesson has a beautiful bright Curry Yellow glowing border!
			border_color = BRASS
			card.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.09, 0.05, 0.98), BRASS, 16))
		else:
			card.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.06, 0.04, 0.95), border_color, 16))
			
		if is_locked:
			card.modulate = Color(1.0, 1.0, 1.0, 0.65) # dimmed opacity
			
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 18)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		card.add_child(margin)
		
		var main_hbox := HBoxContainer.new()
		main_hbox.add_theme_constant_override("separation", 12)
		margin.add_child(main_hbox)
		
		# Left content of card
		var left_vbox := VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_vbox.add_theme_constant_override("separation", 8)
		main_hbox.add_child(left_vbox)
		
		# Small yellow badge
		var badge_panel := PanelContainer.new()
		badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		badge_panel.add_theme_stylebox_override("panel", _panel_style(BRASS, BRASS, 1080)) # Pill shape
		var badge_margin := MarginContainer.new()
		badge_margin.add_theme_constant_override("margin_left", 8)
		badge_margin.add_theme_constant_override("margin_right", 8)
		badge_margin.add_theme_constant_override("margin_top", 2)
		badge_margin.add_theme_constant_override("margin_bottom", 2)
		badge_panel.add_child(badge_margin)
		var badge_lbl := _label("🎵 LỘ TRÌNH CHÍNH", 10, WOOD_DARK)
		badge_margin.add_child(badge_lbl)
		left_vbox.add_child(badge_panel)
		
		# Title
		var title_lbl := _label(lesson.get("title", ""), 20, CREAM)
		left_vbox.add_child(title_lbl)
		
		# Bullet points
		var desc_lbl := _label("• Kỹ năng: " + _difficulty_title(lesson.get("difficulty", "Beginner")) + "\n• Yêu cầu: Cấp độ " + str(int(lesson.get("required_level", 1))) + "\n• Thưởng: 100 XP + 🔥", 13, MUTED)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		left_vbox.add_child(desc_lbl)
		
		# Stars achieved
		var stars_row := HBoxContainer.new()
		for s in range(3):
			var star := _label("★" if s < stars else "☆", 18, STAR_GOLD if s < stars else MUTED)
			stars_row.add_child(star)
		left_vbox.add_child(stars_row)
		
		# Right content of card: Illustration & Play button
		var right_vbox := VBoxContainer.new()
		right_vbox.alignment = BoxContainer.ALIGNMENT_END
		right_vbox.add_theme_constant_override("separation", 16)
		main_hbox.add_child(right_vbox)
		
		# Instrument Graphic / Artist cutout placeholder
		var graphic := Panel.new()
		graphic.custom_minimum_size = Vector2(80, 80)
		graphic.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.1, 0.05, 0.5), Color(0,0,0,0), 8))
		var g_lbl := _label("🎋" if selected_instrument == "dan_tranh" else ("🎋" if selected_instrument == "sao_truc" else ("violin" if selected_instrument == "dan_bau" else "🥁")), 32, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
		# Draw the actual emoji or symbol cleanly
		if selected_instrument == "dan_tranh":
			g_lbl.text = "🎋"
		elif selected_instrument == "sao_truc":
			g_lbl.text = "🎋"
		elif selected_instrument == "dan_bau":
			g_lbl.text = "🎻"
		elif selected_instrument == "trong":
			g_lbl.text = "🥁"
		g_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		g_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		graphic.add_child(g_lbl)
		right_vbox.add_child(graphic)
		
		# Play button / Locked indicator
		if is_locked:
			var lock_btn := _button("🔒 KHÓA", LOCKED_GREY, CREAM)
			lock_btn.custom_minimum_size = Vector2(100, 36)
			lock_btn.disabled = true
			right_vbox.add_child(lock_btn)
		else:
			var play_btn := _button("PLAY", CREAM, WOOD_DARK)
			play_btn.custom_minimum_size = Vector2(100, 36)
			play_btn.add_theme_stylebox_override("normal", _panel_style(CREAM, CREAM, 1080)) # Pill shape
			play_btn.add_theme_stylebox_override("hover", _panel_style(BRASS, BRASS, 1080))
			play_btn.pressed.connect(func(): request_start_practice.emit(lesson))
			right_vbox.add_child(play_btn)
			
		roadmap_row.add_child(card)
		
		# Add roadmap connector line (if not last card)
		if i < instrument_lessons.size() - 1:
			var conn := Panel.new()
			conn.custom_minimum_size = Vector2(36, 6)
			conn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			conn.add_theme_stylebox_override("panel", _panel_style(BRASS_DIM if is_locked else BRASS, Color(0,0,0,0), 1080))
			roadmap_row.add_child(conn)
