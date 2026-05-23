extends CharacterBody2D
class_name VirtualArtist

signal demonstration_started(instrument: String, technique: String)
signal demonstration_finished(instrument: String, technique: String)

const BRASS := Color("d7a84a")
const JADE := Color("1f9a8a")
const SON_RED := Color("8d2f22")
const CREAM := Color("f4dfb8")
const WOOD := Color("5a3422")
const WOOD_DARK := Color("24130d")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual_root: Node2D = $Visuals
@onready var body_sprite: Sprite2D = $Visuals/Body
@onready var instrument_sprite: Sprite2D = $Visuals/Instrument
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var speech_bubble: Label = $SpeechBubble

var current_instrument: String = ""
var current_technique: String = ""
var is_playing: bool = false
var beat_index: int = 0
var lesson_context: Dictionary = {}

var anim_tween: Tween
var hand_tween: Tween
var beat_tween: Tween
var bubble_tween: Tween

var stage_aura: Line2D
var instrument_model: Node2D
var left_hand: Polygon2D
var right_hand: Polygon2D
var beat_orbs: Array[Polygon2D] = []
var technique_label: Label
var posture_label: Label

var instrument_profiles: Dictionary = {
	"dan_tranh": {
		"display": "Dan Tranh",
		"idle": "Sit upright. Relax shoulders. Right hand ready to pluck.",
		"techniques": {
			"pluck": "Watch the right hand strike each string on the beat.",
			"vibrato": "Watch the left hand press and release for a soft wave.",
			"tremolo": "Keep the wrist loose for fast repeated plucks."
		}
	},
	"sao_truc": {
		"display": "Sao Truc",
		"idle": "Lift the flute level. Keep breath steady before the attack.",
		"techniques": {
			"blow": "Start with a clean breath attack, then hold the tone.",
			"sustain": "Keep the airflow even until the release.",
			"release": "Release softly without dropping the pitch."
		}
	}
}

func _ready() -> void:
	_build_artist_ui()
	speech_bubble.hide()
	instrument_sprite.hide()
	body_sprite.modulate = Color(1.0, 0.94, 0.86, 1.0)
	equip_instrument("dan_tranh")

func equip_instrument(instrument_name: String) -> void:
	current_instrument = instrument_name
	current_technique = ""
	beat_index = 0
	_reset_motion()
	_draw_instrument_model(instrument_name)
	_update_labels()
	_set_beat_orbs(false)
	play_animation("idle_" + instrument_name)
	var profile: Dictionary = instrument_profiles.get(instrument_name, {}) as Dictionary
	var message: String = profile.get("idle", "Ready for the next lesson.")
	give_feedback(true, message, 2.4)

func set_lesson_context(lesson: Dictionary) -> void:
	lesson_context = lesson
	var title: String = lesson.get("title", "")
	if title != "":
		technique_label.text = title

func demonstrate_technique(technique_name: String, audio_stream: AudioStream = null) -> void:
	if current_instrument == "":
		equip_instrument("dan_tranh")

	current_technique = technique_name
	is_playing = true
	beat_index = 0
	_update_labels()
	_set_beat_orbs(true)
	_start_stage_pulse()
	play_animation("play_" + current_instrument + "_" + technique_name)
	_play_procedural_demo(technique_name)

	if audio_stream != null:
		audio_player.stream = audio_stream
		audio_player.play()

	var prompt: String = _technique_prompt(technique_name)
	give_feedback(true, prompt, 3.1)
	demonstration_started.emit(current_instrument, technique_name)

func stop_demonstration() -> void:
	var finished_technique: String = current_technique
	audio_player.stop()
	is_playing = false
	current_technique = ""
	beat_index = 0
	_set_beat_orbs(false)
	_reset_motion()
	play_animation("idle_" + current_instrument if current_instrument != "" else "idle")
	_update_labels()
	demonstration_finished.emit(current_instrument, finished_technique)

func give_feedback(is_good: bool, custom_text: String = "", duration: float = 3.0) -> void:
	if bubble_tween:
		bubble_tween.kill()

	speech_bubble.show()
	speech_bubble.text = custom_text if custom_text != "" else ("Great job!" if is_good else "Let's try that phrase again.")
	speech_bubble.modulate = CREAM if custom_text != "" else (JADE if is_good else SON_RED)
	speech_bubble.scale = Vector2(0.96, 0.96)

	bubble_tween = create_tween()
	bubble_tween.tween_property(speech_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bubble_tween.tween_interval(duration)
	bubble_tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.2)
	bubble_tween.tween_callback(func():
		speech_bubble.hide()
		speech_bubble.modulate.a = 1.0
	)

func play_animation(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	elif anim_name.begins_with("idle"):
		_play_procedural_idle()
	elif anim_name.begins_with("play"):
		_play_procedural_demo(current_technique)

func _build_artist_ui() -> void:
	stage_aura = Line2D.new()
	stage_aura.name = "StageAura"
	stage_aura.width = 3.0
	stage_aura.closed = true
	stage_aura.default_color = Color(BRASS, 0.42)
	stage_aura.z_index = -3
	add_child(stage_aura)
	stage_aura.points = _ellipse_points(96.0, 34.0, 48)

	instrument_model = Node2D.new()
	instrument_model.name = "InstrumentModel"
	instrument_model.position = Vector2(0, -16)
	visual_root.add_child(instrument_model)

	left_hand = _circle_poly("LeftHand", 9.0, JADE)
	right_hand = _circle_poly("RightHand", 9.0, BRASS)
	left_hand.z_index = 8
	right_hand.z_index = 8
	visual_root.add_child(left_hand)
	visual_root.add_child(right_hand)

	for i in range(4):
		var orb: Polygon2D = _circle_poly("BeatOrb%d" % i, 5.0, BRASS)
		orb.position = Vector2(-42 + i * 28, -18)
		orb.modulate.a = 0.28
		add_child(orb)
		beat_orbs.append(orb)

	technique_label = _make_label("Technique Ready", 14, BRASS, HORIZONTAL_ALIGNMENT_CENTER)
	technique_label.name = "TechniqueLabel"
	technique_label.offset_left = -112
	technique_label.offset_top = -190
	technique_label.offset_right = 112
	technique_label.offset_bottom = -164
	add_child(technique_label)

	posture_label = _make_label("", 12, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	posture_label.name = "PostureLabel"
	posture_label.offset_left = -116
	posture_label.offset_top = 30
	posture_label.offset_right = 116
	posture_label.offset_bottom = 70
	add_child(posture_label)

	speech_bubble.offset_left = -132
	speech_bubble.offset_top = -252
	speech_bubble.offset_right = 132
	speech_bubble.offset_bottom = -194
	speech_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_bubble.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_bubble.add_theme_font_size_override("font_size", 13)
	speech_bubble.add_theme_color_override("font_color", CREAM)

func _draw_instrument_model(instrument_name: String) -> void:
	for child in instrument_model.get_children():
		child.free()

	if instrument_name == "sao_truc":
		_build_sao_truc_model()
	else:
		_build_dan_tranh_model()

func _build_dan_tranh_model() -> void:
	var body := Polygon2D.new()
	body.name = "DanTranhBody"
	body.polygon = PackedVector2Array([
		Vector2(-74, 0), Vector2(-48, -18), Vector2(78, -12),
		Vector2(92, 4), Vector2(54, 18), Vector2(-80, 14)
	])
	body.color = WOOD
	body.z_index = 3
	instrument_model.add_child(body)

	var rim := Line2D.new()
	rim.width = 3.0
	rim.default_color = BRASS
	rim.closed = true
	rim.points = body.polygon
	rim.z_index = 4
	instrument_model.add_child(rim)

	for i in range(7):
		var string := Line2D.new()
		string.width = 1.2
		string.default_color = Color(CREAM, 0.72)
		var y := -8 + i * 4
		string.points = PackedVector2Array([Vector2(-58, y), Vector2(70, y - 5)])
		string.z_index = 5
		instrument_model.add_child(string)

	left_hand.position = Vector2(-36, -28)
	right_hand.position = Vector2(48, -22)
	body_sprite.scale = Vector2(0.18, 0.18)

func _build_sao_truc_model() -> void:
	var flute := Line2D.new()
	flute.name = "SaoTrucBody"
	flute.width = 8.0
	flute.default_color = Color("c99b53")
	flute.points = PackedVector2Array([Vector2(-78, -10), Vector2(86, 16)])
	flute.z_index = 5
	instrument_model.add_child(flute)

	for i in range(6):
		var hole := Polygon2D.new()
		hole.polygon = _circle_points(3.2, 14)
		hole.color = WOOD_DARK
		hole.position = Vector2(-38 + i * 18, -4 + i * 2.8)
		hole.z_index = 6
		instrument_model.add_child(hole)

	left_hand.position = Vector2(-42, -24)
	right_hand.position = Vector2(38, -12)
	body_sprite.scale = Vector2(0.18, 0.18)

func _play_procedural_idle() -> void:
	_reset_motion()
	anim_tween = create_tween().set_loops()
	anim_tween.tween_property(visual_root, "position:y", -66.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	anim_tween.tween_property(visual_root, "position:y", -62.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_procedural_demo(technique_name: String) -> void:
	_reset_motion(false)
	if current_instrument == "sao_truc":
		_play_sao_truc_demo(technique_name)
	else:
		_play_dan_tranh_demo(technique_name)

func _play_dan_tranh_demo(technique_name: String) -> void:
	hand_tween = create_tween().set_loops()
	if technique_name == "vibrato":
		hand_tween.tween_property(left_hand, "position:x", -48.0, 0.16).set_trans(Tween.TRANS_SINE)
		hand_tween.tween_property(left_hand, "position:x", -32.0, 0.16).set_trans(Tween.TRANS_SINE)
		hand_tween.parallel().tween_property(right_hand, "position:y", -20.0, 0.32)
	else:
		hand_tween.tween_property(right_hand, "position:y", -38.0, 0.12).set_trans(Tween.TRANS_SINE)
		hand_tween.tween_property(right_hand, "position:y", -16.0, 0.12).set_trans(Tween.TRANS_SINE)
		hand_tween.parallel().tween_property(left_hand, "position:x", -40.0, 0.24)

	anim_tween = create_tween().set_loops()
	anim_tween.tween_property(visual_root, "rotation_degrees", 1.8, 0.28).set_trans(Tween.TRANS_SINE)
	anim_tween.tween_property(visual_root, "rotation_degrees", -1.2, 0.28).set_trans(Tween.TRANS_SINE)

func _play_sao_truc_demo(_technique_name: String) -> void:
	hand_tween = create_tween().set_loops()
	hand_tween.tween_property(left_hand, "position:y", -28.0, 0.4).set_trans(Tween.TRANS_SINE)
	hand_tween.tween_property(left_hand, "position:y", -20.0, 0.4).set_trans(Tween.TRANS_SINE)
	hand_tween.parallel().tween_property(right_hand, "position:y", -18.0, 0.8).set_trans(Tween.TRANS_SINE)

	anim_tween = create_tween().set_loops()
	anim_tween.tween_property(body_sprite, "scale", Vector2(0.185, 0.185), 0.55).set_trans(Tween.TRANS_SINE)
	anim_tween.tween_property(body_sprite, "scale", Vector2(0.18, 0.18), 0.55).set_trans(Tween.TRANS_SINE)

func _start_stage_pulse() -> void:
	if beat_tween:
		beat_tween.kill()
	beat_tween = create_tween().set_loops()
	beat_tween.tween_callback(Callable(self, "_advance_beat"))
	beat_tween.tween_property(stage_aura, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_SINE)
	beat_tween.tween_property(stage_aura, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_SINE)
	beat_tween.tween_interval(0.18)

func _advance_beat() -> void:
	if beat_orbs.is_empty():
		return
	for i in range(beat_orbs.size()):
		var orb: Polygon2D = beat_orbs[i]
		orb.modulate.a = 1.0 if i == beat_index else 0.28
		orb.scale = Vector2(1.35, 1.35) if i == beat_index else Vector2.ONE
	beat_index = (beat_index + 1) % beat_orbs.size()

func _reset_motion(reset_playing: bool = true) -> void:
	if anim_tween:
		anim_tween.kill()
	if hand_tween:
		hand_tween.kill()
	if beat_tween:
		beat_tween.kill()
	if reset_playing:
		is_playing = false
	visual_root.position = Vector2(0, -64)
	visual_root.rotation_degrees = 0.0
	body_sprite.scale = Vector2(0.18, 0.18)
	stage_aura.scale = Vector2.ONE

func _update_labels() -> void:
	var profile: Dictionary = instrument_profiles.get(current_instrument, {}) as Dictionary
	var display: String = profile.get("display", "Artist")
	var technique_text: String = "Ready"
	if current_technique != "":
		technique_text = current_technique.capitalize()
	if lesson_context.has("title") and current_technique != "":
		technique_text = lesson_context.get("title", technique_text)
	technique_label.text = "%s - %s" % [display, technique_text]
	posture_label.text = _posture_hint()

func _technique_prompt(technique_name: String) -> String:
	var profile: Dictionary = instrument_profiles.get(current_instrument, {}) as Dictionary
	var techniques: Dictionary = profile.get("techniques", {}) as Dictionary
	return techniques.get(technique_name, "Follow the motion, then repeat the phrase.")

func _posture_hint() -> String:
	if current_instrument == "sao_truc":
		return "Breath: steady attack"
	if current_technique == "vibrato":
		return "Left hand: press and release"
	return "Right hand: pluck on beat"

func _set_beat_orbs(active: bool) -> void:
	for orb in beat_orbs:
		orb.modulate.a = 0.55 if active else 0.22
		orb.scale = Vector2.ONE

func _circle_poly(name: String, radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = name
	poly.polygon = _circle_points(radius, 20)
	poly.color = color
	return poly

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _ellipse_points(rx: float, ry: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	return points

func _make_label(text: String, size: int, color: Color, align: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
