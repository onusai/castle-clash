extends CharacterBody2D


const SPEED = 1200.0
var fall_acc = 0

@export var damage = 10

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2

var from_pid

func _ready():
	direction = Vector2(1,0).rotated(rotation)
	

func _physics_process(delta):
	
	velocity = SPEED * direction
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta * fall_acc
	
	fall_acc += 1

	look_at(global_position + velocity)
	
	move_and_slide()
	for i in range(get_slide_collision_count() - 1):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("map"):
			queue_free()
	
	if global_position.y > 2000:
		queue_free()
		await get_tree().create_timer(2000).timeout
