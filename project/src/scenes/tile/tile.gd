extends TextureButton

var number

signal tile_pressed
signal slide_completed

func set_text(new_number):
	number = new_number
	$Number/Label.text = str(number)

func set_sprite(new_frame, size, tile_size):
	var sprite = $Sprite

	update_size(size, tile_size)

	sprite.set_hframes(size)
	sprite.set_vframes(size)
	sprite.set_frame(new_frame)

func update_size(size, tile_size):
	# scale to the tile_size
	var new_size = Vector2(tile_size, tile_size)
	set_size(new_size)
	$Number.set_size(new_size)
	$Number/ColorRect.set_size(new_size)
	$Number/Label.set_size(new_size)
	$Panel.set_size(new_size)

	var to_scale = size * (new_size / $Sprite.texture.get_size())
	$Sprite.set_scale(to_scale)

func set_sprite_texture(texture):
	$Sprite.set_texture(texture)

func slide_to(new_position, duration):
	var tween = $Tween
	tween.interpolate_property(self, "rect_position", null, new_position, duration, Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()

func set_number_visible(state):
	$Number.visible = state

func _on_Tile_pressed():
	emit_signal("tile_pressed", number)

func _on_Tween_tween_completed(_object, _key):
	emit_signal("slide_completed", number)
