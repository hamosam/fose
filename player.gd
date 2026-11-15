extends CharacterBody3D

@export_group("Movement")
@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.8
@export var jump_velocity: float = 4.8
@export var acceleration: float = 18.0
@export var friction: float = 20.0

@export_group("Mouse & Touch Look")
@export var mouse_sensitivity: float = 0.0025

@export_group("Flashlight")
@export var flashlight_enabled: bool = true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight_holder: Node3D = $Head/Camera3D/FlashlightHolder
@onready var flashlight_light: SpotLight3D = $Head/Camera3D/FlashlightHolder/FlashlightLight

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var mouse_captured: bool = false
var bob_time: float = 0.0
var holder_default_pos: Vector3 = Vector3(0.24, -0.18, -0.36)
var holder_target_offset: Vector3 = Vector3.ZERO

# 모바일/태블릿 터치 연동 변수
var touch_move_dir: Vector2 = Vector2.ZERO
var touch_sprint: bool = false
var touch_jump_requested: bool = false

# 오디오 효과음
var grass_steps: Array[AudioStream] = [
	preload("res://audio/sfx_footstep.wav"),
	preload("res://audio/sfx_grass_step1.wav"),
	preload("res://audio/sfx_grass_step2.wav")
]
var flashlight_stream: AudioStream = preload("res://audio/sfx_flashlight.wav")
var sfx_player: AudioStreamPlayer = null
var footstep_player: AudioStreamPlayer = null
var step_distance: float = 0.0

func _ready() -> void:
	# 태블릿/모바일 터치 UI 조작이 즉시 가능하도록 기본 커서는 표시 상태 유지
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	
	if flashlight_light:
		flashlight_light.visible = flashlight_enabled
	if flashlight_holder:
		holder_default_pos = flashlight_holder.position

	# 효과음 플레이어 초기화
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	footstep_player = AudioStreamPlayer.new()
	footstep_player.volume_db = -8.0
	add_child(footstep_player)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		elif event.is_action_pressed("toggle_flashlight"):
			_toggle_flashlight()

	# PC 마우스 고정 모드일 때의 시점 회전
	if event is InputEventMouseMotion and mouse_captured:
		rotate_view(event.relative)

func rotate_view(relative: Vector2) -> void:
	# 멀티터치 전환 시 비정상적인 단일 프레임 튐(스파이크) 원천 차단
	if relative.length() > 85.0:
		return
	rotate_y(-relative.x * mouse_sensitivity)
	if head:
		head.rotate_x(-relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-50.0), deg_to_rad(50.0))
	
	# 시점 이동에 따른 손전등 관성 스웨이 오프셋
	holder_target_offset.x = clamp(-relative.x * 0.0008, -0.04, 0.04)
	holder_target_offset.y = clamp(relative.y * 0.0008, -0.04, 0.04)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if (Input.is_action_just_pressed("jump") or touch_jump_requested) and is_on_floor():
		velocity.y = jump_velocity
	touch_jump_requested = false

	var kb_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var combined_dir: Vector2 = kb_dir + touch_move_dir
	if combined_dir.length() > 1.0:
		combined_dir = combined_dir.normalized()

	var is_sprinting: bool = Input.is_action_pressed("sprint") or touch_sprint
	var target_speed: float = sprint_speed if is_sprinting else walk_speed

	var direction: Vector3 = (transform.basis * Vector3(combined_dir.x, 0, combined_dir.y))
	if direction.length() > 1.0:
		direction = direction.normalized()

	if direction.length() > 0.05:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()

	# 외벽 밖으로 나가지 못하도록 절대 경계 제한 (-40.5m ~ +40.5m)
	global_position.x = clamp(global_position.x, -40.5, 40.5)
	global_position.z = clamp(global_position.z, -40.5, 40.5)

	# 발소리 재생
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.4:
		var step_interval: float = 1.35 if is_sprinting else 1.85
		step_distance += horizontal_speed * delta
		if step_distance >= step_interval:
			step_distance = 0.0
			if footstep_player and grass_steps.size() > 0:
				footstep_player.stream = grass_steps.pick_random()
				footstep_player.pitch_scale = randf_range(0.92, 1.08)
				footstep_player.volume_db = -5.0 if is_sprinting else -8.5
				footstep_player.play()
	else:
		step_distance = 0.0

	_process_head_bob_and_sway(delta, is_sprinting)

func _process_head_bob_and_sway(delta: float, is_sprinting: bool) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	
	if is_on_floor() and horizontal_speed > 0.4:
		var frequency: float = 14.0 if is_sprinting else 10.0
		var amp_y: float = 0.04 if is_sprinting else 0.02
		var amp_x: float = 0.02 if is_sprinting else 0.01
		
		bob_time += delta * frequency
		camera.position.y = sin(bob_time) * amp_y
		camera.position.x = cos(bob_time * 0.5) * amp_x
	else:
		bob_time = 0.0
		camera.position = camera.position.lerp(Vector3.ZERO, 10.0 * delta)

	if flashlight_holder:
		holder_target_offset = holder_target_offset.lerp(Vector3.ZERO, 12.0 * delta)
		var sway_pos: Vector3 = holder_default_pos + holder_target_offset
		if horizontal_speed > 0.4:
			sway_pos.y += sin(bob_time) * 0.015
			sway_pos.x += cos(bob_time * 0.5) * 0.01
		flashlight_holder.position = flashlight_holder.position.lerp(sway_pos, 16.0 * delta)

func _toggle_flashlight() -> void:
	flashlight_enabled = not flashlight_enabled
	if flashlight_light:
		flashlight_light.visible = flashlight_enabled
	if sfx_player and flashlight_stream:
		sfx_player.stream = flashlight_stream
		sfx_player.volume_db = -4.0
		sfx_player.pitch_scale = randf_range(0.96, 1.04)
		sfx_player.play()
