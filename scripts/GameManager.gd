extends Node

var p_id = -1
var players = {}
var is_ui_open = false

func _ready() -> void:
	Events.score_changed.connect(score_changed)

func get_local_player():
	if p_id == -1:
		return {"name":"", "id":-1, "score":0}
	return players[p_id]

func score_changed(p_pid, new_value):
	pass
