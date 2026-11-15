extends Area3D

@export var note_id: int = 1
@export var note_text: String = "원과 원주율의 비밀"

@onready var prompt_label: Label3D = $PromptLabel
@onready var light: OmniLight3D = $OmniLight3D

var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false
	prompt_label.text = "📜 [쪽지 풀기] 터치  |  [E] 키"

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		open_quiz()

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = true
		prompt_label.visible = true
		var gm = get_tree().root.get_node_or_null("Main/GameManager")
		if gm and gm.has_method("set_nearby_note"):
			gm.set_nearby_note(self)

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = false
		prompt_label.visible = false
		var gm = get_tree().root.get_node_or_null("Main/GameManager")
		if gm and gm.has_method("clear_nearby_note"):
			gm.clear_nearby_note(self)

func _exit_tree() -> void:
	var gm = get_tree().root.get_node_or_null("Main/GameManager")
	if gm and gm.has_method("clear_nearby_note"):
		gm.clear_nearby_note(self)

func open_quiz() -> void:
	var gm = get_tree().root.get_node_or_null("Main/GameManager")
	if gm and gm.has_method("open_note_quiz"):
		gm.open_note_quiz(self, note_id)
