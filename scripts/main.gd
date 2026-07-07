extends Control

@onready var question_label: Label = $CenterContainer/VBoxContainer/QuestionLabel
@onready var answers_box: HBoxContainer = $CenterContainer/VBoxContainer/HBoxContainer
@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton


func _on_button_4_pressed() -> void:
	_show_result("You won")


func _on_button_5_pressed() -> void:
	_show_result("You lost")


func _on_restart_button_pressed() -> void:
	question_label.visible = true
	answers_box.visible = true
	result_label.visible = false
	restart_button.visible = false


func _show_result(text: String) -> void:
	question_label.visible = false
	answers_box.visible = false
	result_label.text = text
	result_label.visible = true
	restart_button.visible = true
