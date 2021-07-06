extends Control

export var size = 4
export var tile_size = 80
export var tile_scene: PackedScene
export var slide_duration = 0.15

var board = []
var tiles = []
var empty = Vector2()
var is_animating = false
var tiles_animating = 0

var move_count = 0
var number_visible = true
var background_texture = null

enum GAME_STATES {
	NOT_STARTED,
	STARTED,
	WON
}
var game_state = GAME_STATES.NOT_STARTED

signal game_started
signal game_won
signal moves_updated

func gen_board():
	var value = 1
	board = []
	for r in range(size):
		board.append([])
		for c in range(size):

			# choose which is empty cell
			if (value == size*size):
				board[r].append(0)
				empty = Vector2(c, r)
			else:
				board[r].append(value)

				# generate a new tile
				var tile = tile_scene.instance()
				tile.set_position(Vector2(c * tile_size, r * tile_size))
				tile.set_text(value)
				if background_texture:
					tile.set_sprite_texture(background_texture)
				tile.set_sprite(value-1, size, tile_size)
				tile.set_number_visible(number_visible)
				tile.connect("tile_pressed", self, "_on_Tile_pressed")
				tile.connect("slide_completed", self, "_on_Tile_slide_completed")
				add_child(tile)
				tiles.append(tile)

			value += 1

func is_board_solved():
	var count = 1
	for r in range(size):
		for c in range(size):
			if (board[r][c] != count):
				if r == c and c == size - 1 and board[r][c] == 0:
					return true
				else:
					return false
			count += 1
	return true

func print_board():
	print('------board------')
	for r in range(size):
		var row = ''
		for c in range(size):
			row += str(board[r][c]).pad_zeros(2) + ' '
		print(row)

func value_to_grid(value):
	for r in range(size):
		for c in range(size):
			if (board[r][c] == value):
				return Vector2(c, r)
	return null

func get_tile_by_value(value):
	for tile in tiles:
		if str(tile.number) == str(value):
			return tile
	return null

# testing
func _ready():
	tile_size = floor(get_size().x / size)
	set_size(Vector2(tile_size*size, tile_size*size))
	gen_board()

func _on_Tile_pressed(number):
	if is_animating:
		return

	# check if game is not started
	if game_state == GAME_STATES.NOT_STARTED:
		scramble_board()
		game_state = GAME_STATES.STARTED
		emit_signal('game_started')
		return
	# check if game is won
	if game_state == GAME_STATES.WON:
		game_state = GAME_STATES.STARTED
		reset_move_count()
		scramble_board()
		emit_signal('game_started')
		return


	var tile = value_to_grid(number)
	empty = value_to_grid(0)

	# if not clicked in row or column of the empty tile then return
	if (tile.x != empty.x and tile.y != empty.y):
		return

	var dir = Vector2(sign(tile.x - empty.x), sign(tile.y - empty.y))

	var start = Vector2(min(tile.x, empty.x), min(tile.y, empty.y))
	var end = Vector2(max(tile.x, empty.x), max(tile.y, empty.y))

	# for each tile in the slide
	for r in range(end.y, start.y - 1, -1):
		for c in range(end.x, start.x - 1, -1):
			if board[r][c] == 0:
				continue
			var object: TextureButton = get_tile_by_value(board[r][c])
			object.slide_to((Vector2(c, r)-dir) * tile_size, slide_duration)
			is_animating = true
			tiles_animating += 1

	# store current board state to calculat the moves made
	var old_board = board.duplicate(true)

	# clicked in same row as as empty
	if tile.y == empty.y:
		if dir.x == -1:
			board[tile.y] = slide_row(board[tile.y], 1, start.x)
		else:
			board[tile.y] = slide_row(board[tile.y], -1, end.x)

	# clicked in same column as empty
	if tile.x == empty.x:
		var col = []
		for r in range(size):
			col.append(board[r][tile.x])

		if dir.y == -1:
			col = slide_column(col, 1, start.y)
		else:
			col = slide_column(col, -1, end.y)

		for r in range(size):
			board[r][tile.x] = col[r]

	# update moves
	var moves_made = 0
	for r in range(size):
		for c in range(size):
			if old_board[r][c] != board[r][c]:
				moves_made += 1

	move_count += moves_made - 1
	emit_signal("moves_updated", move_count)

	# check win
	var is_solved = is_board_solved()
	if is_solved:
		game_state = GAME_STATES.WON
		emit_signal("game_won")

func is_board_solvable(flat):
	var parity = 0
	var grid_width = size
	var row = 0
	var blank_row = 0
	for i in range(size*size):
		if i % grid_width == 0:
			row += 1

		if flat[i] == 0:
			blank_row = row
			continue

		for j in range(i+1, size*size):
			if flat[i] > flat[j] and flat[j] != 0:
				parity += 1

	if grid_width % 2 == 0:
		if blank_row % 2 == 0:
			return parity % 2 == 0
		else:
			return parity % 2 != 0
	else:
		return parity % 2 == 0

func scramble_board():
	reset_board()

	# generate a flat board with values 0 to size*size-1
	var temp_flat_board = []
	for i in range(size*size - 1, -1, -1):
		temp_flat_board.append(i)

	# keep shuffling until it is solvable
	randomize()
	temp_flat_board.shuffle()

	var is_solvable = is_board_solvable(temp_flat_board)
	while not is_solvable:
		randomize()
		temp_flat_board.shuffle()
		is_solvable = is_board_solvable(temp_flat_board)
	# convert flat 1d board to 2d board
	for r in range(size):
		for c in range(size):
			board[r][c] = temp_flat_board[r*size + c]
			if board[r][c] != 0:
				set_tile_position(r, c, board[r][c])
	empty = value_to_grid(0)


func reset_board():
	reset_move_count()
	board = []
	for r in range(size):
		board.append(([]))
		for c in range(size):
			board[r].append(r*size + c + 1)
			if r*size + c + 1 == size * size:
				board[r][c] = 0
			else:
				set_tile_position(r, c, board[r][c])
	empty = value_to_grid(0)

func set_tile_position(r: int, c: int, val: int):
	var object: TextureButton = get_tile_by_value(val)
	object.set_position(Vector2(c, r) * tile_size)

func _process(_delta):
	var is_pressed = true
	var dir = Vector2.ZERO
	if (Input.is_action_just_pressed("move_left")):
		dir.x = -1
	elif (Input.is_action_just_pressed("move_right")):
		dir.x = 1
	elif (Input.is_action_just_pressed("move_up")):
		dir.y = -1
	elif (Input.is_action_just_pressed("move_down")):
		dir.y = 1
	else:
		is_pressed = false
	if is_pressed:
		empty = value_to_grid(0)

		var nr = empty.y + dir.y
		var nc = empty.x + dir.x
		if (nr == -1 or nc == -1 or nr >= size or nc >= size):
			return
		var tile_pressed = board[nr][nc]
		print(tile_pressed)
		_on_Tile_pressed(tile_pressed)

func slide_row(row, dir, limiter):
	var empty_index = row.find(0)
	if dir == 1:
		# slide towards the right
		var start = row.slice(0, limiter)
		start.pop_back()
		var pre = row.slice(limiter, empty_index)
		pre.pop_back()
		var post = row.slice(empty_index, row.size())
		post.pop_front()
		return start + [0] + pre + post
	else:
		# slide towards the left
		var pre = row.slice(0, empty_index)
		pre.pop_back()
		var post = row.slice(empty_index, limiter)
		post.pop_front()
		var end = row.slice(limiter, row.size() - 1)
		end.pop_front()
		return pre + post + [0] + end

func slide_column(col, dir, limiter):
	var empty_index = col.find(0)

	if dir == 1:
		# slide down
		var start = col.slice(0, limiter)
		start.pop_back()
		var pre = col.slice(limiter, empty_index)
		pre.pop_back()
		var post = col.slice(empty_index, col.size() - 1)
		post.pop_front()

		return start + [0] + pre + post
	else:
		# slide up
		# slide towards the left
		var pre = col.slice(0, empty_index)
		pre.pop_back()
		var post = col.slice(empty_index, limiter)
		post.pop_front()
		var end = col.slice(limiter, col.size() - 1)
		end.pop_front()
		return pre + post + [0] + end

func _on_Tile_slide_completed(_number):
	tiles_animating -= 1
	if tiles_animating == 0:
		is_animating = false

func reset_move_count():
	move_count = 0
	emit_signal("moves_updated", move_count)

func set_tile_numbers(state):
	number_visible = state
	for tile in tiles:
		tile.set_number_visible(state)

func update_size(new_size):
	size = int(new_size)
	print('updating board size ', size)

	tile_size = floor(get_size().x / size)
	for tile in tiles:
		tile.queue_free()
	tiles = []
	gen_board()
	game_state = GAME_STATES.NOT_STARTED
	reset_move_count()

func update_background_texture(texture):
	background_texture = texture
	for tile in tiles:
		tile.set_sprite_texture(texture)
		tile.update_size(size, tile_size)

