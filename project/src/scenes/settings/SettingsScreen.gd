class_name SettingsScreen
extends MarginContainer

const PopupMessage = preload("res://src/scenes/ui/PopupMessage.gd")

signal board_size_update(new_size: int)
signal show_numbers_update(state: bool)
signal hide_settings()
signal background_update(texture: ImageTexture)

@onready var size_value: Label = $M/V/M/G/SizeValue
@onready var file_dialog: FileDialog = $M/FileDialog
@onready var message_popup: PopupMessage = $M/PopupMessage

func _on_SizeSlider_value_changed(value: float) -> void:
	var new_size: int = int(value)
	size_value.text = str(new_size)
	board_size_update.emit(new_size)

func _on_ShowNumbers_toggled(button_pressed: bool) -> void:
	show_numbers_update.emit(button_pressed)

func _on_BackButton_pressed() -> void:
	hide_settings.emit()

func _on_FileButton_pressed() -> void:
	file_dialog.popup()

func _on_FileDialog_file_selected(path: String) -> void:
	var image: Image = Image.new()
	var err: Error = image.load(path)
	if err != OK:
		message_popup.setup("Error Occurred", "There was an error importing the image.")
		message_popup.popup()
		return

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	message_popup.setup("Success", "The background image was changed successfully.")
	message_popup.popup()
	background_update.emit(texture)
