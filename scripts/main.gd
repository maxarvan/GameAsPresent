extends Control

@onready var photo_rect: TextureRect = $CenterContainer/VBoxContainer/PhotoRect
@onready var question_label: Label = $CenterContainer/VBoxContainer/QuestionLabel
@onready var answers_box: HBoxContainer = $CenterContainer/VBoxContainer/HBoxContainer
@onready var right_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/RightButton
@onready var wrong_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/WrongButton
@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var quiz_request: HTTPRequest = $QuizRequest
@onready var photo_request: HTTPRequest = $PhotoRequest

var quiz_data: Dictionary = {}
var base_url: String = ""


func _ready() -> void:
	quiz_request.request_completed.connect(_on_quiz_loaded)
	photo_request.request_completed.connect(_on_photo_loaded)

	if OS.has_feature("web"):
		base_url = JavaScriptBridge.eval("window.location.href.replace(/[^/]*$/, '')", true)
		quiz_request.request(base_url + "quiz.json")
	else:
		_load_quiz_from_bytes(FileAccess.get_file_as_bytes("res://data/quiz.json"))


func _on_quiz_loaded(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_error("Failed to load quiz.json (HTTP %d)" % response_code)
		return
	_load_quiz_from_bytes(body)


func _on_photo_loaded(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_error("Failed to load photo (HTTP %d)" % response_code)
		return
	_load_photo_from_bytes(body)


func _load_quiz_from_bytes(bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		push_error("quiz.json is empty or missing")
		return
	var parsed = JSON.parse_string(bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("quiz.json is not valid JSON")
		return
	quiz_data = parsed
	question_label.text = quiz_data.get("question", "")
	right_button.text = quiz_data.get("right_answer", "")
	wrong_button.text = quiz_data.get("wrong_answer", "")

	var photo_filename: String = quiz_data.get("photo", "")
	if photo_filename.is_empty():
		return
	if OS.has_feature("web"):
		photo_request.request(base_url + photo_filename)
	else:
		_load_photo_from_bytes(FileAccess.get_file_as_bytes("res://data/" + photo_filename))


func _load_photo_from_bytes(bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		push_error("Photo file is empty or missing")
		return
	var image := Image.new()
	if image.load_jpg_from_buffer(bytes) != OK:
		push_error("Could not decode photo")
		return
	photo_rect.texture = ImageTexture.create_from_image(image)


func _on_right_button_pressed() -> void:
	_show_result(quiz_data.get("right_message", ""))


func _on_wrong_button_pressed() -> void:
	_show_result(quiz_data.get("wrong_message", ""))


func _on_restart_button_pressed() -> void:
	photo_rect.visible = true
	question_label.visible = true
	answers_box.visible = true
	result_label.visible = false
	restart_button.visible = false


func _show_result(text: String) -> void:
	photo_rect.visible = false
	question_label.visible = false
	answers_box.visible = false
	result_label.text = text
	result_label.visible = true
	restart_button.visible = true
