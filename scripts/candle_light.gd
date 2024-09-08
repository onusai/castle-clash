extends AnimatedSprite2D

@onready var light = $PointLight2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	light.scale = lerp(light.scale, Vector2(randf_range(1, 1.25), randf_range(0.5, 1.5)), 0.1)
	light.energy = lerp(light.energy, randf_range(0.5, 1.75), 0.1)
