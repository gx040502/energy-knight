extends Node

const MENU_TRACK: AudioStream = preload("res://Sinyen/music/levelBackground.ogg")
const LEVEL_TRACK: AudioStream = preload("res://Sinyen/music/menuBackground.ogg")
const BOSS_TRACK: AudioStream = preload("res://Sinyen/music/boss.ogg")

var _player: AudioStreamPlayer
var _stashed_track: AudioStream = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	add_child(_player)


func play_track(track: AudioStream) -> void:
	if track == null:
		return
	# A direct play cancels any pending boss-track restore.
	_stashed_track = null

	if _player.stream == track and _player.playing:
		return

	_player.stream = track
	_player.play()


func push_track(track: AudioStream) -> void:
	if track == null or _player.stream == track:
		return
	# Single-depth stash: a second push overwrites rather than nesting.
	_stashed_track = _player.stream
	_player.stream = track
	_player.play()


func pop_track() -> void:
	if _stashed_track == null:
		return

	var restore: AudioStream = _stashed_track
	_stashed_track = null
	_player.stream = restore
	_player.play()


func stop() -> void:
	_player.stop()
