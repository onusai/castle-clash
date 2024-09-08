extends ProgressBar

@export var color_ramp: Gradient

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func hp_changed(new_value):
	value = new_value
	self_modulate = color_ramp.sample(new_value/100.0)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
