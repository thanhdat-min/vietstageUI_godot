extends CharacterBody2D
class_name Learner

@export var speed: float = 200.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var avatar_root: Node2D
var body_poly: Polygon2D
var head_poly: Polygon2D
var shadow_poly: Polygon2D

func _ready() -> void:
	sprite.hide()
	_build_avatar()

func _physics_process(delta: float):
	# Get standard input (WASD or Arrow keys)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Convert standard Cartesian input to Isometric movement vector
	var iso_dir = cartesian_to_isometric(input_dir).normalized()
	
	if input_dir.length() > 0:
		velocity = iso_dir * speed
		play_walk_animation(input_dir)
	else:
		velocity = Vector2.ZERO
		play_idle_animation()

	move_and_slide()

# Function to convert 2D Cartesian coordinates to Isometric coordinates
func cartesian_to_isometric(cartesian: Vector2) -> Vector2:
	# Standard isometric transformation: X axis goes down-right, Y axis goes down-left
	var iso_x = cartesian.x - cartesian.y
	var iso_y = (cartesian.x + cartesian.y) * 0.5
	return Vector2(iso_x, iso_y)

func play_walk_animation(input_dir: Vector2):
	# In a full game, you'd choose the animation based on the isometric direction
	# e.g., walk_up_right, walk_down_left, etc.
	if animation_player.has_animation("walk"):
		animation_player.play("walk")

func play_idle_animation():
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func _build_avatar() -> void:
	avatar_root = Node2D.new()
	avatar_root.name = "LearnerAvatar"
	avatar_root.position = Vector2(0, -34)
	add_child(avatar_root)

	shadow_poly = Polygon2D.new()
	shadow_poly.name = "FloorShadow"
	shadow_poly.polygon = _ellipse_points(34.0, 14.0, 28)
	shadow_poly.position = Vector2(0, 32)
	shadow_poly.color = Color(0, 0, 0, 0.32)
	shadow_poly.z_index = -2
	avatar_root.add_child(shadow_poly)

	body_poly = Polygon2D.new()
	body_poly.name = "Body"
	body_poly.polygon = PackedVector2Array([
		Vector2(0, -34), Vector2(24, -18), Vector2(22, 16),
		Vector2(0, 32), Vector2(-22, 16), Vector2(-24, -18)
	])
	body_poly.color = Color("1f9a8a")
	body_poly.z_index = 2
	avatar_root.add_child(body_poly)

	var vest := Polygon2D.new()
	vest.name = "Vest"
	vest.polygon = PackedVector2Array([
		Vector2(0, -24), Vector2(15, -12), Vector2(10, 15),
		Vector2(0, 24), Vector2(-10, 15), Vector2(-15, -12)
	])
	vest.color = Color("0f4f48")
	vest.z_index = 3
	avatar_root.add_child(vest)

	head_poly = Polygon2D.new()
	head_poly.name = "Head"
	head_poly.polygon = _ellipse_points(18.0, 20.0, 28)
	head_poly.position = Vector2(0, -48)
	head_poly.color = Color("f0c08f")
	head_poly.z_index = 4
	avatar_root.add_child(head_poly)

	var hat := Polygon2D.new()
	hat.name = "KhanDong"
	hat.polygon = _ellipse_points(23.0, 8.0, 28)
	hat.position = Vector2(0, -66)
	hat.color = Color("d7a84a")
	hat.z_index = 5
	avatar_root.add_child(hat)

	var face_line := Line2D.new()
	face_line.name = "FaceLine"
	face_line.width = 2.0
	face_line.default_color = Color("5a3422")
	face_line.points = PackedVector2Array([Vector2(-6, -47), Vector2(0, -43), Vector2(6, -47)])
	face_line.z_index = 6
	avatar_root.add_child(face_line)

func _ellipse_points(rx: float, ry: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	return points
