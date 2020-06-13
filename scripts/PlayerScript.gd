extends KinematicBody2D
const ACCELERATION = 512
const MAX_SPEED = 64
const FRICTION = 0.25
const GRAVITY = 200
const AIR_RESISTANCE = 0.02
const JUMP_FORCE = 200
var motion = Vector2.ZERO
var npc:bool = false;
onready var sprite = $PlayerAnimationSprite
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func move(x_input,delta):
	if x_input !=0:
		motion.x += x_input * ACCELERATION * delta
		motion.x = clamp(motion.x,-MAX_SPEED,MAX_SPEED)
		
		sprite.animation = "run"
		sprite.flip_h = x_input < 0
	motion.y += GRAVITY * delta
	if is_on_floor():
		if x_input == 0:
			sprite.animation = "idle1"
			motion.x = lerp(motion.x,0,FRICTION)
		if Input.is_action_just_pressed("ui_up"):
			motion.y = -JUMP_FORCE
	else:
		sprite.animation = "jump"
		if Input.is_action_just_released("ui_up") and motion.y < -JUMP_FORCE/2:
			motion.y = -JUMP_FORCE/2
		if x_input == 0:
			motion.x = lerp(motion.x,0,AIR_RESISTANCE)
	motion = move_and_slide(motion,Vector2.UP)
	
func _physics_process(delta):
	if(!npc):
		var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		move(x_input,delta)
		get_parent().send_socket_message({"position":{"x":position.x,"y":position.y}})

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
