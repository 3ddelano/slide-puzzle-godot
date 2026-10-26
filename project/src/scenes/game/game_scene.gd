class_name GameScene
extends Control

const PuzzleBoard = preload("res://src/scenes/board/board.gd")

var is_started: bool = false
var game_won: bool = false
var start_epoch: int = 0
var current_epoch: int = 0
var settings_open: bool = false
var board_was_processing: bool = true

@onready var board: PuzzleBoard = $MarginContainer/VBoxContainer/GameView/Board
@onready var overlay: Control = $MarginContainer/VBoxContainer/GameView/StartOverlay
@onready var overlay_text: Label = $MarginContainer/VBoxContainer/GameView/StartOverlay/TextOverlay
@onready var move_value: Label = $MarginContainer/VBoxContainer/StatsView/HBoxContainer/Moves/MoveValue
@onready var timer_value: Label = $MarginContainer/VBoxContainer/StatsView/HBoxContainer/Time/TimeValue
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	overlay.visible = true

func _process(_delta: float) -> void:
	if is_started:
		current_epoch = Time.get_ticks_msec()
		var time_since_game_start: int = current_epoch - start_epoch
		timer_value.text = str(int(time_since_game_start / 1000.0)) + "s"
	elif not game_won:
		timer_value.text = "0s"

func _on_Board_game_started() -> void:
	start_epoch = Time.get_ticks_msec()
	overlay.visible = false
	is_started = true
	game_won = false

func _on_Board_game_won() -> void:
	overlay_text.text = "Nice Work!\n Click to play again"
	overlay.visible = true
	is_started = false
	game_won = true

func _on_RestartButton_pressed() -> void:
	if not is_started:
		return
	board.reset_move_count()
	board.scramble_board()
	board.game_state = PuzzleBoard.GAME_STATES.STARTED
	start_epoch = Time.get_ticks_msec()
	is_started = true
	game_won = false

func _on_Board_moves_updated(move_count: int) -> void:
	move_value.text = str(move_count)

func _on_SettingsScreen_board_size_update(new_size: int) -> void:
	board.update_size(new_size)
	overlay_text.text = "Click to start"
	overlay.visible = true
	is_started = false
	game_won = false
	timer_value.text = "0s"

func _on_SettingsScreen_show_numbers_update(state: bool) -> void:
	board.set_tile_numbers(state)

func _on_SettingsButton_pressed() -> void:
	if not settings_open:
		board_was_processing = board.is_processing()
		settings_open = true
		board.set_process(false)
	anim_player.play("show_settings")

func _on_SettingsScreen_hide_settings() -> void:
	anim_player.play_backwards("show_settings")
	if settings_open:
		board.set_process(board_was_processing)
		settings_open = false

func _on_SettingsScreen_background_update(texture: ImageTexture) -> void:
	board.update_background_texture(texture)
