extends Control

func _ready():
	$AnimationPlayer.play("menu_in")

func _on_DiscordButton_pressed():
	var _error = OS.shell_open("https://discord.gg/FZY9TqW")


func _on_WebsiteButton_pressed():
	var _error = OS.shell_open("https://delano-lourenco.web.app")


func _on_Button_pressed():
	var _error = get_tree().change_scene("res://src/scenes/game/game_scene.tscn")
