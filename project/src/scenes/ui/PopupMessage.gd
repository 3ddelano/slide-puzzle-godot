class_name PopupMessage
extends Window

func _ready() -> void:
	if not close_requested.is_connected(hide):
		close_requested.connect(hide)

func setup(message_title: String, text: String) -> void:
	var message: Label = $V/Message
	message.text = text
	title = message_title

func _on_ClosePopupButton_pressed() -> void:
	hide()
