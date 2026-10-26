class_name PuzzleTile
extends TextureButton

signal tile_pressed(number: int)
signal slide_completed(number: int)

var number: int = 0
var slide_tween: Tween = null

# These methods may be called before the tile enters the scene tree.
func set_text(new_number: int) -> void:
	number = new_number
	var label: Label = $Number/Label
	label.text = str(number)

func set_sprite(new_frame: int, grid_size: int, tile_size: float) -> void:
	var sprite: Sprite2D = $Sprite
	update_size(grid_size, tile_size)
	sprite.hframes = grid_size
	sprite.vframes = grid_size
	sprite.frame = new_frame

func update_size(grid_size: int, tile_size: float) -> void:
	var new_size: Vector2 = Vector2(tile_size, tile_size)
	var number_control: Control = $Number
	var number_background: ColorRect = $Number/ColorRect
	var label: Label = $Number/Label
	var panel: Panel = $Panel
	var sprite: Sprite2D = $Sprite
	size = new_size
	number_control.size = new_size
	number_background.size = new_size
	label.size = new_size
	panel.size = new_size
	sprite.scale = grid_size * (new_size / sprite.texture.get_size())

func set_sprite_texture(texture: Texture2D) -> void:
	var sprite: Sprite2D = $Sprite
	sprite.texture = texture

func slide_to(new_position: Vector2, duration: float) -> void:
	stop_slide()
	slide_tween = create_tween()
	slide_tween.tween_property(self, "position", new_position, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	slide_tween.finished.connect(_on_slide_finished)

# Cancellation deliberately does not emit completion; the board resets its counters.
func stop_slide() -> void:
	if slide_tween != null:
		slide_tween.kill()
		slide_tween = null

func set_number_visible(state: bool) -> void:
	var number_control: Control = $Number
	number_control.visible = state

func _on_Tile_pressed() -> void:
	tile_pressed.emit(number)

func _on_slide_finished() -> void:
	slide_tween = null
	slide_completed.emit(number)
