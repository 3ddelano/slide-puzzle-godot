class_name PuzzleBoard
extends Control

const PuzzleTile = preload("res://src/scenes/tile/tile.gd")

@export var grid_size: int = 4
@export var tile_size: float = 80.0
@export var tile_scene: PackedScene
@export var slide_duration: float = 0.15

# Nested typed arrays are unsupported; each row is an Array[int].
var board: Array[Array] = []
var tiles: Array[PuzzleTile] = []
var empty: Vector2i = Vector2i.ZERO
var is_animating: bool = false
var tiles_animating: int = 0

var move_count: int = 0
var number_visible: bool = true
var background_texture: Texture2D = null

enum GAME_STATES {
	NOT_STARTED,
	STARTED,
	WON
}
var game_state: GAME_STATES = GAME_STATES.NOT_STARTED

signal game_started()
signal game_won()
signal moves_updated(move_count: int)

func gen_board() -> void:
	_cancel_tile_slides()
	for tile: PuzzleTile in tiles:
		remove_child(tile)
		tile.queue_free()
	tiles.clear()
	board.clear()
	for r: int in range(grid_size):
		var row: Array[int] = []
		for c: int in range(grid_size):
			var value: int = r * grid_size + c + 1
			if value == grid_size * grid_size:
				row.append(0)
				empty = Vector2i(c, r)
			else:
				row.append(value)
				var tile: PuzzleTile = tile_scene.instantiate() as PuzzleTile
				tile.position = Vector2(c, r) * tile_size
				tile.set_text(value)
				if background_texture != null:
					tile.set_sprite_texture(background_texture)
				tile.set_sprite(value - 1, grid_size, tile_size)
				tile.set_number_visible(number_visible)
				tile.tile_pressed.connect(_on_Tile_pressed)
				tile.slide_completed.connect(_on_Tile_slide_completed)
				add_child(tile)
				tiles.append(tile)
		board.append(row)

func is_board_solved() -> bool:
	for r: int in range(grid_size):
		for c: int in range(grid_size):
			var expected: int = (r * grid_size + c + 1) % (grid_size * grid_size)
			if board[r][c] != expected:
				return false
	return true

func value_to_grid(value: int) -> Vector2i:
	for r: int in range(grid_size):
		for c: int in range(grid_size):
			if board[r][c] == value:
				return Vector2i(c, r)
	return Vector2i(-1, -1)

func get_tile_by_value(value: int) -> PuzzleTile:
	for tile: PuzzleTile in tiles:
		if tile.number == value:
			return tile
	return null

func _ready() -> void:
	grid_size = maxi(2, grid_size)
	# Use the scene's Control width (320), not the old exported grid size.
	tile_size = floorf(size.x / float(grid_size))
	size = Vector2.ONE * tile_size * grid_size
	gen_board()

func _cancel_tile_slides() -> void:
	for tile: PuzzleTile in tiles:
		tile.stop_slide()
	tiles_animating = 0
	is_animating = false

func _on_Tile_pressed(number: int) -> void:
	if is_animating:
		return
	if game_state != GAME_STATES.STARTED:
		scramble_board()
		game_state = GAME_STATES.STARTED
		game_started.emit()
		return

	var clicked: Vector2i = value_to_grid(number)
	empty = value_to_grid(0)
	if number == 0 or clicked.x < 0:
		return
	if clicked.x != empty.x and clicked.y != empty.y:
		return

	var direction: Vector2i = Vector2i(signi(clicked.x - empty.x), signi(clicked.y - empty.y))
	var distance: int = absi(clicked.x - empty.x) + absi(clicked.y - empty.y)
	# Each neighbor advances into the blank once, including distant row/column clicks.
	# This avoids Godot 3's inclusive Array.slice semantics entirely.
	tiles_animating = distance
	is_animating = true
	while empty != clicked:
		var neighbor: Vector2i = empty + direction
		var value: int = board[neighbor.y][neighbor.x]
		var tile: PuzzleTile = get_tile_by_value(value)
		tile.slide_to(Vector2(empty) * tile_size, slide_duration)
		board[empty.y][empty.x] = value
		board[neighbor.y][neighbor.x] = 0
		empty = neighbor

	move_count += distance
	moves_updated.emit(move_count)
	if is_board_solved():
		game_state = GAME_STATES.WON
		game_won.emit()

func is_board_solvable(flat: Array[int]) -> bool:
	var parity: int = 0
	var blank_row: int = 0
	for i: int in range(grid_size * grid_size):
		if flat[i] == 0:
			blank_row = int(i / float(grid_size)) + 1
			continue
		for j: int in range(i + 1, grid_size * grid_size):
			if flat[i] > flat[j] and flat[j] != 0:
				parity += 1
	# Preserve the original top-based blank-row parity rule for even widths.
	if grid_size % 2 == 0:
		return parity % 2 == blank_row % 2
	return parity % 2 == 0

func scramble_board() -> void:
	reset_board()
	var flat: Array[int] = []
	for i: int in range(grid_size * grid_size):
		flat.append(i)
	while true:
		flat.shuffle()
		if not is_board_solvable(flat):
			continue
		for r: int in range(grid_size):
			for c: int in range(grid_size):
				board[r][c] = flat[r * grid_size + c]
		if not is_board_solved():
			break
	for r: int in range(grid_size):
		for c: int in range(grid_size):
			if board[r][c] != 0:
				set_tile_position(r, c, board[r][c])
	empty = value_to_grid(0)

func reset_board() -> void:
	_cancel_tile_slides()
	reset_move_count()
	board.clear()
	for r: int in range(grid_size):
		var row: Array[int] = []
		for c: int in range(grid_size):
			var value: int = (r * grid_size + c + 1) % (grid_size * grid_size)
			row.append(value)
			if value != 0:
				set_tile_position(r, c, value)
		board.append(row)
	empty = value_to_grid(0)

func set_tile_position(r: int, c: int, val: int) -> void:
	var tile: PuzzleTile = get_tile_by_value(val)
	tile.position = Vector2(c, r) * tile_size

func _process(_delta: float) -> void:
	if is_animating:
		return
	var direction: Vector2i = Vector2i.ZERO
	if Input.is_action_just_pressed("move_left"):
		direction.x = -1
	elif Input.is_action_just_pressed("move_right"):
		direction.x = 1
	elif Input.is_action_just_pressed("move_up"):
		direction.y = -1
	elif Input.is_action_just_pressed("move_down"):
		direction.y = 1
	else:
		return
	empty = value_to_grid(0)
	var neighbor: Vector2i = empty + direction
	if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= grid_size or neighbor.y >= grid_size:
		return
	_on_Tile_pressed(board[neighbor.y][neighbor.x])

func _on_Tile_slide_completed(_number: int) -> void:
	tiles_animating = maxi(0, tiles_animating - 1)
	is_animating = tiles_animating > 0

func reset_move_count() -> void:
	move_count = 0
	moves_updated.emit(move_count)

func set_tile_numbers(state: bool) -> void:
	number_visible = state
	for tile: PuzzleTile in tiles:
		tile.set_number_visible(state)

func update_size(new_size: int) -> void:
	_cancel_tile_slides()
	grid_size = maxi(2, new_size)
	tile_size = floorf(size.x / float(grid_size))
	gen_board()
	game_state = GAME_STATES.NOT_STARTED
	reset_move_count()

func update_background_texture(texture: Texture2D) -> void:
	background_texture = texture
	for tile: PuzzleTile in tiles:
		tile.set_sprite_texture(texture)
		tile.update_size(grid_size, tile_size)

