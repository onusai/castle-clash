extends Control

@onready var hp_bar: ProgressBar = $Control/VBoxContainer/HBoxContainer2/HPBar
@onready var arrows_label: Label = $Control/VBoxContainer/HBoxContainer/Label
func _ready():
	Events.connect("hp_changed", on_hp_changed)
	Events.arrows_changed.connect(on_arrows_changed)

func on_hp_changed(new_value):
	hp_bar.value = new_value
	hp_bar.self_modulate = hp_bar.color_ramp.sample(new_value/100.0)

func on_arrows_changed(amount):
	arrows_label.text = "x " + str(amount)
