extends Control

@onready var start_button: Button = $UI/MarginContainer/VBoxContainer/MenuButtons/StartButton
@onready var howto_button: Button = $UI/MarginContainer/VBoxContainer/MenuButtons/HowToButton
@onready var quit_button: Button = $UI/MarginContainer/VBoxContainer/MenuButtons/QuitButton
@onready var howto_modal: Control = $HowToModal
@onready var close_howto_button: Button = $HowToModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseHowToButton
@onready var camera_pivot: Node3D = $Diorama/CameraPivot
@onready var monster_node: Node3D = $Diorama/MonsterPeeking
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var cam_time: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	start_button.pressed.connect(_on_start_pressed)
	howto_button.pressed.connect(_on_howto_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_howto_button.pressed.connect(_on_close_howto_pressed)
	
	start_button.mouse_entered.connect(_play_hover_sfx)
	howto_button.mouse_entered.connect(_play_hover_sfx)
	quit_button.mouse_entered.connect(_play_hover_sfx)
	close_howto_button.mouse_entered.connect(_play_hover_sfx)
	
	howto_modal.visible = false

func _process(delta: float) -> void:
	cam_time += delta * 0.5
	if camera_pivot:
		camera_pivot.rotation.y = sin(cam_time) * 0.06
		camera_pivot.rotation.x = sin(cam_time * 0.7) * 0.02
	
	if monster_node:
		monster_node.position.y = 0.85 + sin(cam_time * 3.5) * 0.12

func _play_hover_sfx() -> void:
	if click_sfx:
		click_sfx.pitch_scale = randf_range(1.15, 1.25)
		click_sfx.volume_db = -12.0
		click_sfx.play()

func _on_start_pressed() -> void:
	if click_sfx:
		click_sfx.pitch_scale = 0.95
		click_sfx.volume_db = -3.0
		click_sfx.play()
	
	# 부드러운 전환을 위한 대기
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://main.tscn")

func _on_howto_pressed() -> void:
	if click_sfx:
		click_sfx.pitch_scale = 1.05
		click_sfx.volume_db = -5.0
		click_sfx.play()
	howto_modal.visible = true

func _on_close_howto_pressed() -> void:
	if click_sfx:
		click_sfx.pitch_scale = 0.95
		click_sfx.volume_db = -5.0
		click_sfx.play()
	howto_modal.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
