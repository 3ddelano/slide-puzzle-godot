extends WindowDialog

func setup(title, text):
	$V/Message.text = text
	set_title(title)


func _on_ClosePopupButton_pressed():
	visible = false
