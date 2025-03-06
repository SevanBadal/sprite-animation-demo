extends CharacterBody2D

@export var speed = 300
@export var gravity = 30
@export var jump_force = 300

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D

enum State { IDLE, RUN, JUMP, FALL, LAND }
var current_state = State.IDLE
var previous_state = State.IDLE

var state_animations = {
	State.IDLE: "idle",
	State.RUN: "run",
	State.JUMP: "jump",
	State.FALL: "fall",
	State.LAND: "land"
}

func _ready():
	ap.animation_finished.connect(_on_animation_finished)
	

func _physics_process(delta: float) -> void:
	# Gravity
	if !is_on_floor():
		velocity.y = min(velocity.y + gravity, 1000)
	
	# Jump (no double jump)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
	
	# Horizontal movement
	var x_direction = Input.get_axis("move_left", "move_right")
	if x_direction != 0:
		sprite.flip_h = (x_direction < 0)
	velocity.x = speed * x_direction

	# Move
	move_and_slide()

	# Check if we've just landed
	if was_falling() and is_on_floor():
		set_state(State.LAND)
	else:
		update_state(x_direction)

func was_falling() -> bool:
	return previous_state == State.FALL or current_state == State.FALL

func update_state(x_direction: float):
	# If on floor
	if is_on_floor():
		if x_direction == 0:
			set_state(State.IDLE)
		else:
			set_state(State.RUN)
	else:
		if velocity.y < 0:
			set_state(State.JUMP)
		else:
			set_state(State.FALL)

func set_state(new_state: State):
	if current_state == new_state:
		return
	previous_state = current_state
	current_state = new_state
	play_animation_for_state()
	print("State changed from %s to %s" % [State.keys()[previous_state], State.keys()[current_state]])

func play_animation_for_state():
	# If we are landing, make sure not to interrupt it
	if current_state == State.LAND and ap.current_animation == "land" and ap.is_playing():
		return
	ap.play(state_animations[current_state])

func _on_animation_finished(anim_name: String):
	if anim_name == "land":
		# After landing, go to IDLE or RUN depending on input
		var x_direction = Input.get_axis("move_left", "move_right")
		set_state(State.IDLE if x_direction == 0  else State.RUN)
