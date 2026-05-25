extends Area2D
class_name InstrumentStation

signal station_interacted(instrument: String)

@export var instrument_name: String = "dan_tranh"
@export_enum("available", "in_progress", "completed", "locked") var hotspot_state: String = "available"

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_label: Label = $InteractionLabel

var ring: Line2D
var state_badge: Label
var instrument_icon: Node2D
var hover_hint: Label
var player_in_range := false
var hover := false
var pulse_tween: Tween

func _ready() -> void:
	input_pickable = true
	monitoring = true
	sprite.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	_build_hotspot_visuals()
	apply_state(hotspot_state)
	_hide_prompt()

func apply_state(new_state: String) -> void:
	hotspot_state = new_state
	var color := _state_color()
	sprite.modulate = color
	ring.default_color = Color(color, 0.85)
	state_badge.text = _state_badge_text()
	state_badge.modulate = color
	hover_hint.modulate = color
	if pulse_tween:
		pulse_tween.kill()
	if hotspot_state != "locked":
		pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(ring, "scale", Vector2(1.08, 1.08), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween.tween_property(ring, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_hotspot_visuals() -> void:
	ring = Line2D.new()
	ring.name = "HotspotRing"
	ring.width = 4.0
	ring.closed = true
	ring.z_index = -1
	add_child(ring)
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle) * 70.0, sin(angle) * 34.0))
	ring.points = points

	instrument_icon = Node2D.new()
	instrument_icon.name = "InstrumentIcon"
	instrument_icon.z_index = 2
	add_child(instrument_icon)
	_rebuild_instrument_icon()

	state_badge = Label.new()
	state_badge.name = "StateBadge"
	state_badge.offset_left = -68
	state_badge.offset_top = 44
	state_badge.offset_right = 68
	state_badge.offset_bottom = 70
	state_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_badge.add_theme_font_size_override("font_size", 13)
	add_child(state_badge)

	hover_hint = Label.new()
	hover_hint.name = "HoverHint"
	hover_hint.text = _instrument_title()
	hover_hint.offset_left = -90
	hover_hint.offset_top = -118
	hover_hint.offset_right = 90
	hover_hint.offset_bottom = -92
	hover_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_hint.add_theme_font_size_override("font_size", 16)
	hover_hint.add_theme_color_override("font_color", Color("f4dfb8"))
	add_child(hover_hint)

	interaction_label.add_theme_font_size_override("font_size", 16)
	interaction_label.add_theme_color_override("font_color", Color("f4dfb8"))

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		if not hover:
			_hide_prompt()

func _on_mouse_entered() -> void:
	hover = true
	_show_prompt()

func _on_mouse_exited() -> void:
	hover = false
	if not player_in_range:
		_hide_prompt()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()

func _try_interact() -> void:
	if hotspot_state == "locked":
		interaction_label.text = _instrument_title() + " is locked"
		return
	emit_signal("station_interacted", instrument_name)

func _show_prompt() -> void:
	interaction_label.show()
	var verb := "Open lessons"
	if hotspot_state == "completed":
		verb = "Review lessons"
	elif hotspot_state == "in_progress":
		verb = "Continue lessons"
	elif hotspot_state == "locked":
		verb = "Locked"
	interaction_label.text = "%s - %s" % [_instrument_title(), verb]

func _hide_prompt() -> void:
	interaction_label.hide()

func _state_color() -> Color:
	match hotspot_state:
		"locked":
			return Color("756b5c")
		"in_progress":
			return Color("1f9a8a")
		"completed":
			return Color("d7a84a")
		_:
			match instrument_name:
				"dan_tranh", "trong":
					return Color("d7a84a")
				_:
					return Color("1f9a8a")

func _state_badge_text() -> String:
	match hotspot_state:
		"locked":
			return "LOCKED"
		"in_progress":
			return "IN PROGRESS"
		"completed":
			return "* COMPLETE"
		_:
			return "AVAILABLE"

func _instrument_title() -> String:
	match instrument_name:
		"dan_tranh":
			return "Đàn Tranh"
		"dan_bau":
			return "Đàn Bầu"
		"sao_truc":
			return "Sáo Trúc"
		"trong":
			return "Trống"
		_:
			return instrument_name.capitalize()

func _rebuild_instrument_icon() -> void:
	for child in instrument_icon.get_children():
		child.free()
	match instrument_name:
		"sao_truc":
			_add_sao_truc_icon()
		"dan_bau":
			_add_dan_bau_icon()
		"trong":
			_add_trong_icon()
		_:
			_add_dan_tranh_icon()

func _add_dan_bau_icon() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-50, 4), Vector2(-48, -4), Vector2(50, -8), Vector2(48, 8)
	])
	body.color = Color("5a321e")
	body.z_index = 2
	instrument_icon.add_child(body)
	
	# Gourd (bầu) - gold circle
	var gourd := Polygon2D.new()
	gourd.polygon = _circle_points(8.0, 16)
	gourd.color = Color("c89b30")
	gourd.position = Vector2(-36, -6)
	gourd.z_index = 3
	instrument_icon.add_child(gourd)
	
	# Flexible rod (cần)
	var rod := Line2D.new()
	rod.width = 3.0
	rod.default_color = Color("d7a84a")
	rod.points = PackedVector2Array([Vector2(-36, -6), Vector2(-42, -26), Vector2(-48, -28)])
	rod.z_index = 4
	instrument_icon.add_child(rod)
	
	# Single string
	var string := Line2D.new()
	string.width = 1.2
	string.default_color = Color(0.96, 0.86, 0.66, 0.9)
	string.points = PackedVector2Array([Vector2(-42, -26), Vector2(42, 0)])
	string.z_index = 5
	instrument_icon.add_child(string)

func _add_trong_icon() -> void:
	# Drum shell
	var shell := Polygon2D.new()
	shell.polygon = PackedVector2Array([
		Vector2(-32, -18), Vector2(32, -18), Vector2(28, 20), Vector2(-28, 20)
	])
	shell.color = Color("8d2f22") # rich Son Red
	shell.z_index = 2
	instrument_icon.add_child(shell)
	
	# Gold rims/hoops
	var rim_top := Line2D.new()
	rim_top.width = 3.0
	rim_top.default_color = Color("d7a84a")
	rim_top.points = PackedVector2Array([Vector2(-33, -18), Vector2(33, -18)])
	rim_top.z_index = 3
	instrument_icon.add_child(rim_top)
	
	var rim_bot := Line2D.new()
	rim_bot.width = 3.0
	rim_bot.default_color = Color("d7a84a")
	rim_bot.points = PackedVector2Array([Vector2(-29, 20), Vector2(29, 20)])
	rim_bot.z_index = 3
	instrument_icon.add_child(rim_bot)
	
	# Drum skin top (creamy leather color)
	var skin := Polygon2D.new()
	skin.polygon = PackedVector2Array([
		Vector2(-32, -18), Vector2(32, -18), Vector2(28, -26), Vector2(-28, -26)
	])
	skin.color = Color("f4dfb8") # cream
	skin.z_index = 3
	instrument_icon.add_child(skin)
	
	# Lacing lines (diagonal gold laces on red shell)
	for i in range(4):
		var lx1: float = -24.0 + i * 16.0
		var lx2: float = -20.0 + i * 13.0
		var lace := Line2D.new()
		lace.width = 1.5
		lace.default_color = Color("c89b30")
		lace.points = PackedVector2Array([Vector2(lx1, -18), Vector2(lx2, 20)])
		lace.z_index = 2
		instrument_icon.add_child(lace)

func _add_dan_tranh_icon() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-52, -10), Vector2(-34, -26), Vector2(56, -18),
		Vector2(68, 0), Vector2(38, 16), Vector2(-58, 12)
	])
	body.color = Color("6b3f25")
	body.z_index = 2
	instrument_icon.add_child(body)
	var rim := Line2D.new()
	rim.width = 2.0
	rim.default_color = Color("d7a84a")
	rim.closed = true
	rim.points = body.polygon
	rim.z_index = 3
	instrument_icon.add_child(rim)
	for i in range(5):
		var string := Line2D.new()
		string.width = 1.0
		string.default_color = Color(0.96, 0.86, 0.66, 0.78)
		var y: float = -13.0 + i * 5.0
		string.points = PackedVector2Array([Vector2(-42, y), Vector2(48, y - 5)])
		string.z_index = 4
		instrument_icon.add_child(string)

func _add_sao_truc_icon() -> void:
	var flute := Line2D.new()
	flute.width = 8.0
	flute.default_color = Color("c99b53")
	flute.points = PackedVector2Array([Vector2(-60, -18), Vector2(62, 18)])
	flute.z_index = 3
	instrument_icon.add_child(flute)
	for i in range(5):
		var hole := Polygon2D.new()
		hole.polygon = _circle_points(3.0, 14)
		hole.color = Color("24130d")
		hole.position = Vector2(-28 + i * 15, -8 + i * 4)
		hole.z_index = 4
		instrument_icon.add_child(hole)

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
