extends CharacterBody2D

const WALK_SHEET := preload("res://assets/characters/lyra-walk-2d-v1.png")

@export var speed: float = 210.0
var movement_bounds := Rect2(72, 118, 1136, 514)

var controls_enabled: bool = true
var actor_sprite: AnimatedSprite2D


func _ready() -> void:
	_build_actor_sprite()


func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var state: ZeroDomainGameState = get_node("/root/GameState")
	velocity = direction.normalized() * speed * state.speed_multiplier()
	move_and_slide()
	position.x = clampf(position.x, movement_bounds.position.x, movement_bounds.end.x)
	position.y = clampf(position.y, movement_bounds.position.y, movement_bounds.end.y)
	_update_animation(direction)


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		actor_sprite.stop()
		actor_sprite.frame = 0


func _build_actor_sprite() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var directions := {"down": 0, "left": 1, "right": 2, "up": 3}
	var cell_size := WALK_SHEET.get_size() / 4.0
	for animation: String in directions:
		frames.add_animation(animation)
		frames.set_animation_loop(animation, true)
		frames.set_animation_speed(animation, 8.0)
		for column: int in range(4):
			var frame := AtlasTexture.new()
			frame.atlas = WALK_SHEET
			frame.region = Rect2(Vector2(column, directions[animation]) * cell_size, cell_size)
			frames.add_frame(animation, frame)
	actor_sprite = AnimatedSprite2D.new()
	actor_sprite.name = "CharacterArt"
	actor_sprite.sprite_frames = frames
	actor_sprite.animation = "down"
	actor_sprite.position = Vector2(0, -28)
	actor_sprite.scale = Vector2.ONE * (58.0 / cell_size.y)
	add_child(actor_sprite)


func _update_animation(direction: Vector2) -> void:
	if direction.is_zero_approx():
		actor_sprite.stop()
		actor_sprite.frame = 0
		return
	var next_animation: String
	if absf(direction.x) > absf(direction.y):
		next_animation = "right" if direction.x > 0.0 else "left"
	else:
		next_animation = "down" if direction.y > 0.0 else "up"
	if actor_sprite.animation != next_animation:
		actor_sprite.animation = next_animation
	actor_sprite.play()
