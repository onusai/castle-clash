extends Control


@onready var ChatInput = $VBoxContainer/LineEdit
@onready var ChatLog = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var ChatScroll = $VBoxContainer/ScrollContainer
@onready var ChatBG = $BG

var ChatMsgScene: PackedScene = preload("res://scenes/chat_msg.tscn")

var chat_open = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("chat_sent", chat_sent)
	#ChatInput.hide()


func chat_sent(text):
	add_msg.rpc(text)

@rpc("any_peer", "call_local", "reliable")
func add_msg(text):
	var msg = ChatMsgScene.instantiate()
	msg.text = text
	ChatLog.add_child(msg)
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	ChatScroll.ensure_control_visible(msg)

#[color=cyan][Host][/color] [color=orange]Onusai[/color][color=gray]:[/color] hey!
func _on_line_edit_text_submitted(text):
	if text == "":
		close()
		return
	
	ChatInput.text = ""
	var msg = ""
	if multiplayer.is_server():
		msg += "[color=cyan][Host][/color] "
	msg += "[color=orange]" + Game.get_local_player().name + "[/color][color=gray]:[/color] " + text
	Events.emit_signal("chat_sent", msg)
	close()


func _input(event: InputEvent):
	if event.is_action_pressed("key_enter"):
		if !chat_open:
			open()
			accept_event()
	elif event.is_action_pressed("key_esc"):
		if chat_open:
			close()
			accept_event()

func open():
	Game.is_ui_open = true
	ChatInput.show()
	ChatInput.grab_focus()
	chat_open = true
	ChatBG.show()
	

func close():
	ChatInput.hide()
	chat_open = false
	Game.is_ui_open = false
	ChatBG.hide()
