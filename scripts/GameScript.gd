extends Node2D
var client:NakamaClient
var session:NakamaSession
var socket:NakamaSocket
var current_match:NakamaRTAPI.Match
var scheme = "http"
var host = "voipi.fi"
var port = 7350
var server_key = "defaultkey"
var deviceKey = OS.get_unique_id()
var connected_opponents:Dictionary
var players:Dictionary

func _ready():
	_nakama_client_setup()
	
func _nakama_client_setup():
	client = Nakama.create_client(server_key, host, port, scheme)
	session = yield(client.authenticate_device_async(deviceKey),"completed")
	_nakama_socket_setup()
	
func _nakama_socket_setup():
	socket = Nakama.create_socket_from(client)
	socket.connect("connected", self, "_on_socket_connected")
	socket.connect("closed", self, "_on_socket_closed")
	socket.connect("received_error", self, "_on_socket_error")
	socket.connect("received_match_presence",self,"_on_match_presence")
	socket.connect("received_match_state",self,"_on_match_state")
	yield(socket.connect_async(session), "completed")
	print("Done")

func _on_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		if p.user_id != session.user_id:
			connected_opponents[p.user_id] = p
			var x = $Player.duplicate()
			x.npc = true;
			players[p.user_id] = x;
			add_child(x)
			print("added new player")
	for p in p_presence.leaves:
		connected_opponents.erase(p.user_id)
		var x= players[p.user_id]
		players.erase((p.user_id));
		remove_child(x)
	print(connected_opponents)
func _nakama_match_setup():
	current_match = yield(socket.create_match_async(),"completed")
	if current_match.is_exception():
		print("An error occured: %s" % current_match)
		return
	print('New Match created with ID: %s' % current_match.match_id)
	OS.clipboard = current_match.match_id
	$MatchIDLabel.text='Match ID: '+ current_match.match_id
	
func _nakama_match_join():
	var match_id = $JoinDialog/joinDialogTextEdit.text
	$JoinDialog.hide()
	current_match = yield(socket.join_match_async(match_id),"completed")
	if current_match.is_exception():
		print("An error occured while joining match: %s" % current_match)
		$MatchIDLabel.text="Error Occured while joining match, please try again."
		return
	for presence in current_match.presences:
		print("User ID: %s Username: %s" % [presence.user_id,presence.username])
		$MatchIDLabel.text="Match connected!"
		connected_opponents[presence.user_id] = presence
		var x = $Player.duplicate()
		x.npc = true;
		players[presence.user_id] = x;
		add_child(x)
		print("added new player")
	
func _on_socket_connected():
	print("Socket connected.")
	_nakama_match_setup()
	
func _on_socket_closed():
	print("Socket closed.")
	
func _on_socket_error(err):
	printerr("Socket error %s" % err)

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.is_action_pressed("custom_joinmatch"):
				$JoinDialog.popup()
			elif event.scancode == KEY_ENTER:
				_nakama_match_join()
	
func _on_joinDialogButton_pressed():
	_nakama_match_join()
func send_socket_message(message):
	var op_code=1
	if session and current_match:
		var state = {"user_id":session.user_id,"data":message}
		socket.send_match_state_async(current_match.match_id,op_code,JSON.print(state))
func _on_match_state(p_state:NakamaRTAPI.MatchData):
	var data=parse_json(p_state.data)
	print(data)
	if players[data["user_id"]]:
		var pl = players[data["user_id"]]
		pl.get_node("PlayerAnimationSprite").flip_h=data['data']['flip_h']
		pl.get_node("PlayerAnimationSprite").animation = data['data']['animation']
		pl.position = Vector2(data["data"]["position"]["x"],data["data"]["position"]["y"])
	#players[data['user_id']].move(data['data'])
