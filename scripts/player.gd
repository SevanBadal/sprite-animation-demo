extends CharacterBody2D

signal state_changed(new_state)

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
	# Add LightOccluderManager as a child
	
func set_state(new_state):
	if new_state != current_state:
		previous_state = current_state
		current_state = new_state
		ap.play(state_animations[current_state])
		emit_signal("state_changed", current_state)

func update_state(x_direction):
	if !is_on_floor():
		if velocity.y < 0:
			set_state(State.JUMP)
		else:
			set_state(State.FALL)
	else:
		if x_direction != 0:
			set_state(State.RUN)
		else:
			set_state(State.IDLE)

func was_falling():
	return previous_state == State.FALL

func _on_animation_finished(anim_name):
	if current_state == State.LAND:
		set_state(State.IDLE)

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
