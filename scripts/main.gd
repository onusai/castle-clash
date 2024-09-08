extends Node2D

@export var PlayerScene: PackedScene

func _ready():
	Events.connect("spawn_player", spawn_player)

func spawn_player(p_id):
	var player = PlayerScene.instantiate()
	
	player.p_id  = p_id
	player.name = str(p_id)
	
	$Players.add_child(player)
	
