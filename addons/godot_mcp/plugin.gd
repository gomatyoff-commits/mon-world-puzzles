@tool
extends EditorPlugin
## Ouvre un serveur WebSocket local (127.0.0.1 uniquement) dans l'éditeur.
## Le serveur MCP Node.js s'y connecte et envoie des commandes JSON :
##   -> {"id": 1, "command": "get_scene_tree", "params": {...}}
##   <- {"id": 1, "ok": true, "result": {...}}   ou   {"id": 1, "ok": false, "error": "..."}

const DEFAULT_PORT := 6505
const BUFFER_SIZE := 16 * 1024 * 1024

var _server := TCPServer.new()
var _peers: Array[WebSocketPeer] = []
var _commands: RefCounted


func _enter_tree() -> void:
	_commands = preload("res://addons/godot_mcp/commands.gd").new(self)
	var port := DEFAULT_PORT
	var env_port := OS.get_environment("GODOT_MCP_PORT")
	if env_port.is_valid_int():
		port = env_port.to_int()
	var err := _server.listen(port, "127.0.0.1")
	if err != OK:
		push_error("[Godot MCP] Impossible d'écouter sur le port %d (erreur %d). Un autre éditeur Godot l'utilise peut-être." % [port, err])
		return
	print("[Godot MCP] En écoute sur ws://127.0.0.1:%d" % port)


func _exit_tree() -> void:
	for ws in _peers:
		ws.close()
	_peers.clear()
	_server.stop()
	_commands = null


func _process(_delta: float) -> void:
	if not _server.is_listening():
		return
	while _server.is_connection_available():
		var ws := WebSocketPeer.new()
		ws.inbound_buffer_size = BUFFER_SIZE
		ws.outbound_buffer_size = BUFFER_SIZE
		if ws.accept_stream(_server.take_connection()) == OK:
			_peers.append(ws)
	for ws in _peers.duplicate():
		ws.poll()
		match ws.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				while ws.get_available_packet_count() > 0:
					_on_message(ws, ws.get_packet().get_string_from_utf8())
			WebSocketPeer.STATE_CLOSED:
				_peers.erase(ws)


func _on_message(ws: WebSocketPeer, text: String) -> void:
	var msg = JSON.parse_string(text)
	if typeof(msg) != TYPE_DICTIONARY:
		ws.send_text(JSON.stringify({"id": null, "ok": false, "error": "Message JSON invalide."}))
		return
	var response := {"id": msg.get("id")}
	var result = _commands.execute(str(msg.get("command", "")), msg.get("params", {}))
	if result == null:
		response["ok"] = false
		response["error"] = "Erreur interne pendant la commande. Consulte la sortie de l'éditeur Godot (get_editor_output)."
	elif result is Dictionary and result.has("__error"):
		response["ok"] = false
		response["error"] = result["__error"]
	else:
		response["ok"] = true
		response["result"] = result
	ws.send_text(JSON.stringify(response))
