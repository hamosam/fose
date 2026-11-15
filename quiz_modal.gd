extends Control

signal quiz_completed(note_node: Node3D, note_id: int)
signal quiz_closed()

@onready var header_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeaderLabel
@onready var question_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuestionLabel
@onready var hint_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HintLabel
@onready var feedback_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FeedbackLabel
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

@onready var option_buttons: Array[Button] = [
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/OptionButton0,
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/OptionButton1,
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/OptionButton2,
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsContainer/OptionButton3,
]

var current_note_node: Node3D = null
var current_note_id: int = 1
var current_correct_index: int = 0
var is_answering: bool = false

# 효과음
var sfx_correct: AudioStream = preload("res://audio/sfx_correct.wav")
var sfx_wrong: AudioStream = preload("res://audio/sfx_wrong.wav")
var audio_player: AudioStreamPlayer = null

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func open_quiz(note_node: Node3D, note_id: int) -> void:
	current_note_node = note_node
	current_note_id = note_id
	is_answering = true
	feedback_label.text = "※ 문제를 푸는 동안 괴물은 멈춰있습니다. 안심하고 풀어보세요!"
	feedback_label.modulate = Color(0.7, 0.88, 1.0)
	
	var quiz = MathQuizData.QUIZZES.get(note_id, null)
	if not quiz:
		quiz = {
			"title": "📜 쪽지 #%d : 원주율의 비밀" % note_id,
			"question": "원의 지름이 10cm일 때, 원주는 몇 cm일까요? (원주율: 3.14)",
			"hint": "💡 공식: (지름) × (원주율)",
			"options": ["① 15.7 cm", "② 31.4 cm", "③ 62.8 cm", "④ 314 cm"],
			"correct": 1,
			"explanation": "정답! 10 × 3.14 = 31.4cm 입니다."
		}

	header_label.text = quiz.get("title", "📜 쪽지 문제")
	question_label.text = quiz.get("question", "")
	hint_label.text = quiz.get("hint", "")
	current_correct_index = quiz.get("correct", 0)

	var options = quiz.get("options", [])
	for i in range(option_buttons.size()):
		if i < options.size():
			option_buttons[i].visible = true
			option_buttons[i].text = options[i]
			option_buttons[i].disabled = false
		else:
			option_buttons[i].visible = false

	visible = true

func _on_option_pressed(index: int) -> void:
	if not is_answering:
		return

	if index == current_correct_index:
		# 정답!
		is_answering = false
		feedback_label.text = "🎉 정답입니다! 쪽지의 봉인이 풀렸습니다."
		feedback_label.modulate = Color(0.3, 1.0, 0.4)
		for btn in option_buttons:
			btn.disabled = true
		
		if audio_player and sfx_correct:
			audio_player.stream = sfx_correct
			audio_player.volume_db = -2.0
			audio_player.play()
		
		# 0.7초 후 완료 시그널 전송
		await get_tree().create_timer(0.7).timeout
		visible = false
		quiz_completed.emit(current_note_node, current_note_id)
	else:
		# 오답!
		feedback_label.text = "❌ 틀렸습니다! 다시 계산해 보세요. (괴물은 멈춰있습니다)"
		feedback_label.modulate = Color(1.0, 0.35, 0.3)
		
		if audio_player and sfx_wrong:
			audio_player.stream = sfx_wrong
			audio_player.volume_db = -3.0
			audio_player.play()

func _on_close_pressed() -> void:
	visible = false
	quiz_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
