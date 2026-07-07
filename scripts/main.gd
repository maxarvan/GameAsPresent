extends Control

const COLOR_CORRECT := Color(0.20, 0.65, 0.30)
const COLOR_WRONG := Color(0.70, 0.20, 0.20)

@onready var score_label: Label = $ScoreLabel
@onready var name_label: Label = $Content/VBoxContainer/NameLabel
@onready var name_input: LineEdit = $Content/VBoxContainer/NameInput
@onready var start_button: Button = $Content/VBoxContainer/StartButton
@onready var photo_rect: TextureRect = $Content/VBoxContainer/PhotoRect
@onready var question_label: Label = $Content/VBoxContainer/QuestionLabel
@onready var answers_grid: GridContainer = $Content/VBoxContainer/AnswersGrid
@onready var answer_buttons: Array[Button] = [
	$Content/VBoxContainer/AnswersGrid/Answer0,
	$Content/VBoxContainer/AnswersGrid/Answer1,
	$Content/VBoxContainer/AnswersGrid/Answer2,
	$Content/VBoxContainer/AnswersGrid/Answer3,
]
@onready var result_label: Label = $Content/VBoxContainer/ResultLabel
@onready var next_button: Button = $Content/VBoxContainer/NextButton
@onready var quiz_request: HTTPRequest = $QuizRequest
@onready var photo_request: HTTPRequest = $PhotoRequest

var base_url: String = ""
var questions: Array = []
var current_index: int = 0
var score: int = 0
var answered: bool = false
var quiz_finished: bool = false
var player_name: String = ""


func _ready() -> void:
	for i in answer_buttons.size():
		answer_buttons[i].pressed.connect(_on_answer_pressed.bind(i))
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


func _load_quiz_from_bytes(bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		push_error("quiz.json is empty or missing")
		return
	var parsed = JSON.parse_string(bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("questions")) != TYPE_ARRAY:
		push_error("quiz.json is not valid")
		return
	questions = parsed["questions"]
	_show_name_entry()


func _show_name_entry() -> void:
	score_label.visible = false
	photo_rect.visible = false
	question_label.visible = false
	answers_grid.visible = false
	result_label.visible = false
	next_button.visible = false
	name_input.text = player_name
	name_label.visible = true
	name_input.visible = true
	start_button.visible = true
	name_input.grab_focus()


func _on_name_submitted(_new_text: String) -> void:
	_on_start_button_pressed()


func _on_start_button_pressed() -> void:
	player_name = name_input.text.strip_edges()
	name_label.visible = false
	name_input.visible = false
	start_button.visible = false
	score_label.visible = true
	_start_quiz()


func _start_quiz() -> void:
	current_index = 0
	score = 0
	quiz_finished = false
	_update_score_label()
	_show_question(current_index)


func _show_question(index: int) -> void:
	answered = false
	next_button.visible = false
	result_label.visible = false
	question_label.visible = true
	answers_grid.visible = true

	var q: Dictionary = questions[index]
	question_label.text = q.get("question", "")

	var photo_filename: String = q.get("photo", "")
	photo_rect.texture = null
	photo_rect.visible = not photo_filename.is_empty()
	if not photo_filename.is_empty():
		if OS.has_feature("web"):
			photo_request.request(base_url + photo_filename)
		else:
			_load_photo_from_bytes(FileAccess.get_file_as_bytes("res://data/" + photo_filename))

	var options: Array = q.get("answers", []).duplicate()
	options.shuffle()
	for i in answer_buttons.size():
		var button := answer_buttons[i]
		button.disabled = false
		_clear_button_color(button)
		button.text = options[i] if i < options.size() else ""
		button.visible = i < options.size()


func _on_answer_pressed(index: int) -> void:
	if answered:
		return
	answered = true

	var q: Dictionary = questions[current_index]
	var correct_answer: String = q.get("correct_answer", "")
	var pressed_button: Button = answer_buttons[index]
	var is_correct: bool = pressed_button.text == correct_answer

	for button in answer_buttons:
		if not button.visible:
			continue
		button.disabled = true
		if button.text == correct_answer:
			_set_button_color(button, COLOR_CORRECT)
		elif button == pressed_button:
			_set_button_color(button, COLOR_WRONG)

	if is_correct:
		score += 1
		_update_score_label()

	var answer_photo_filename: String = q.get("answer_photo", "")
	if not answer_photo_filename.is_empty():
		photo_rect.texture = null
		photo_rect.visible = true
		if OS.has_feature("web"):
			photo_request.request(base_url + answer_photo_filename)
		else:
			_load_photo_from_bytes(FileAccess.get_file_as_bytes("res://data/" + answer_photo_filename))

	next_button.text = "Next" if current_index < questions.size() - 1 else "Finish"
	next_button.visible = true


func _on_next_button_pressed() -> void:
	if quiz_finished:
		_show_name_entry()
		return
	if current_index < questions.size() - 1:
		current_index += 1
		_show_question(current_index)
	else:
		_show_final_score()


func _show_final_score() -> void:
	quiz_finished = true
	question_label.visible = false
	answers_grid.visible = false
	photo_rect.visible = false
	var name_prefix: String = player_name + ": " if not player_name.is_empty() else ""
	result_label.text = "%sScore: %d / %d" % [name_prefix, score, questions.size()]
	result_label.visible = true
	next_button.text = "Restart"
	next_button.visible = true


func _on_photo_loaded(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_error("Failed to load photo (HTTP %d)" % response_code)
		return
	_load_photo_from_bytes(body)


func _load_photo_from_bytes(bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		push_error("Photo file is empty or missing")
		return
	var image := Image.new()
	if image.load_jpg_from_buffer(bytes) != OK:
		push_error("Could not decode photo")
		return
	photo_rect.texture = ImageTexture.create_from_image(image)


func _update_score_label() -> void:
	score_label.text = "Score: %d" % score


func _set_button_color(button: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style)


func _clear_button_color(button: Button) -> void:
	button.remove_theme_stylebox_override("normal")
	button.remove_theme_stylebox_override("disabled")
