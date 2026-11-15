extends Control

@onready var look_pad: Control = $LookPad
@onready var joystick_area: Control = $JoystickMargin/JoystickArea
@onready var joystick_base: Panel = $JoystickMargin/JoystickArea/JoystickBase
@onready var joystick_knob: Panel = $JoystickMargin/JoystickArea/JoystickBase/JoystickKnob

@onready var interact_btn: Button = $ActionMargin/VBox/InteractButton
@onready var sprint_btn: Button = $ActionMargin/VBox/ButtonRow/SprintButton
@onready var flashlight_btn: Button = $ActionMargin/VBox/ButtonRow/FlashlightButton
@onready var jump_btn: Button = $ActionMargin/VBox/ButtonRow/JumpButton
@onready var title_btn: Button = $TopRightMargin/TopBar/TitleButton
@onready var pc_lock_btn: Button = $TopRightMargin/TopBar/PcLockButton

var player: Node3D = null
var game_manager: Node = null

# 멀티터치 조이스틱 상태
var joystick_touch_index: int = -1
var joystick_mouse_dragging: bool = false
var joystick_max_radius: float = 62.0

# 멀티터치 시점 회전 상태 (각 손가락 index별 이전 위치 독립 추적)
# index -> Vector2 (또는 첫 드래그 대기 시 null)
var look_touches: Dictionary = {}
var look_mouse_dragging: bool = false
var look_mouse_has_prev: bool = false
var look_mouse_last_pos: Vector2 = Vector2.ZERO

# 터치 입력 감지 타임스탬프 (태블릿 브라우저의 가짜 마우스 이벤트 점프 완벽 차단용)
var last_touch_msec: int = -10000

# 좌우 회전은 부드럽고 시원하게, 상하 회전은 안정적으로 세팅
var touch_look_sensitivity_x: float = 1.25
var touch_look_sensitivity_y: float = 0.55

var pulse_time: float = 0.0
var has_nearby_note: bool = false

func _ready() -> void:
	# 액션 버튼 연결 (단일 터치 / PC 마우스 클릭용)
	if interact_btn:
		interact_btn.pressed.connect(_on_interact_pressed)
	if sprint_btn:
		sprint_btn.toggled.connect(_on_sprint_toggled)
	if flashlight_btn:
		flashlight_btn.pressed.connect(_on_flashlight_pressed)
	if jump_btn:
		jump_btn.button_down.connect(_on_jump_pressed)
	if title_btn:
		title_btn.pressed.connect(_on_title_pressed)
	if pc_lock_btn:
		pc_lock_btn.pressed.connect(_on_pc_lock_pressed)

	_reset_joystick()
	set_nearby_note_active(false)

func setup(p_player: Node3D, p_gm: Node) -> void:
	player = p_player
	game_manager = p_gm

func _process(delta: float) -> void:
	if has_nearby_note and interact_btn:
		pulse_time += delta * 6.0
		var scale_val: float = 1.0 + sin(pulse_time) * 0.04
		interact_btn.scale = Vector2(scale_val, scale_val)
		interact_btn.pivot_offset = interact_btn.size * 0.5
	elif interact_btn:
		interact_btn.scale = Vector2.ONE

func set_nearby_note_active(active: bool) -> void:
	has_nearby_note = active
	if not interact_btn:
		return
	if active:
		interact_btn.text = "📜 쪽지 문제 풀기! [터치]"
		interact_btn.modulate = Color(1.0, 0.95, 0.55, 1.0)
	else:
		interact_btn.text = "📜 쪽지 풀기 (주변 탐색)"
		interact_btn.modulate = Color(0.85, 0.88, 0.95, 0.78)

# ---------------------------------------------------------
# 전역 멀티터치 & 마우스 입력 처리 (_gui_input 포커스 끊김 완벽 해결)
# ---------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	# 1. 태블릿/모바일 실제 터치 이벤트 처리
	if event is InputEventScreenTouch:
		last_touch_msec = Time.get_ticks_msec()
		look_mouse_dragging = false
		joystick_mouse_dragging = false

		if event.pressed:
			# 버튼 위를 터치한 경우: 시점 회전이나 조이스틱으로 잡지 않음
			if _is_over_any_button(event.position):
				# 두 번째 손가락(index > 0)으로 버튼을 터치했을 때도 즉시 작동하도록 지원
				if event.index > 0:
					_trigger_multitouch_button_at(event.position)
				return

			# 왼쪽 하단 조이스틱 영역을 터치한 경우
			if joystick_touch_index == -1 and _is_in_joystick_zone(event.position):
				joystick_touch_index = event.index
				_update_joystick_global(event.position)
				return

			# 그 외 빈 화면 영역: 시점 회전 손가락으로 등록 (첫 드래그 프레임에서 기준점 설정)
			look_touches[event.index] = null
		else:
			if event.index == joystick_touch_index:
				_reset_joystick()
			if look_touches.has(event.index):
				look_touches.erase(event.index)
		return

	elif event is InputEventScreenDrag:
		last_touch_msec = Time.get_ticks_msec()
		look_mouse_dragging = false
		joystick_mouse_dragging = false

		# 조이스틱 드래그 중인 손가락
		if event.index == joystick_touch_index:
			_update_joystick_global(event.position)
			return

		# 시점 회전 드래그 중인 손가락
		if not look_touches.has(event.index):
			if not _is_in_joystick_zone(event.position) and not _is_over_any_button(event.position):
				look_touches[event.index] = event.position
			return

		if look_touches[event.index] == null:
			# 첫 드래그 이벤트에서는 현재 위치만 기준점으로 저장 (초기 점프 원천 차단!)
			look_touches[event.index] = event.position
			return

		var prev_pos: Vector2 = look_touches[event.index]
		var delta_vec: Vector2 = event.position - prev_pos
		look_touches[event.index] = event.position

		# 모바일 브라우저의 멀티터치 좌표 튐(스파이크) 현상 필터링
		if delta_vec.length() < 0.01 or delta_vec.length() > 80.0:
			return

		_apply_touch_look(delta_vec)
		return

	# 2. PC 마우스 드래그 지원 (최근 1초 내 터치 입력이 전혀 없을 때만 작동)
	if Time.get_ticks_msec() - last_touch_msec < 1000:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_over_any_button(event.position):
					return
				if _is_in_joystick_zone(event.position):
					joystick_mouse_dragging = true
					_update_joystick_global(event.position)
				else:
					look_mouse_dragging = true
					look_mouse_has_prev = false
			else:
				if joystick_mouse_dragging:
					_reset_joystick()
				look_mouse_dragging = false
				look_mouse_has_prev = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			look_mouse_dragging = event.pressed
			look_mouse_has_prev = false

	elif event is InputEventMouseMotion:
		if joystick_mouse_dragging:
			_update_joystick_global(event.position)
		elif look_mouse_dragging and (not player or not player.mouse_captured):
			if not look_mouse_has_prev:
				look_mouse_last_pos = event.position
				look_mouse_has_prev = true
				return
			var delta_vec: Vector2 = event.position - look_mouse_last_pos
			look_mouse_last_pos = event.position
			if delta_vec.length() > 0.01 and delta_vec.length() <= 80.0:
				_apply_touch_look(delta_vec)

func _apply_touch_look(delta_vec: Vector2) -> void:
	if not player or not player.has_method("rotate_view"):
		return
	var dx: float = delta_vec.x * touch_look_sensitivity_x
	var dy: float = delta_vec.y * touch_look_sensitivity_y

	# 엄지손가락으로 좌우로 화면을 넘길 때 손가락 궤적 때문에 위(천장)/아래로 휘는 현상 보정
	if abs(delta_vec.x) > abs(delta_vec.y) * 1.5:
		dy *= 0.22

	player.rotate_view(Vector2(dx, dy))

func _is_in_joystick_zone(global_pos: Vector2) -> bool:
	if not joystick_area:
		return false
	return joystick_area.get_global_rect().grow(32.0).has_point(global_pos)

func _is_over_any_button(global_pos: Vector2) -> bool:
	var btns: Array[Button] = [interact_btn, sprint_btn, flashlight_btn, jump_btn, title_btn, pc_lock_btn]
	for b in btns:
		if b and b.is_visible_in_tree() and b.get_global_rect().grow(8.0).has_point(global_pos):
			return true
	return false

func _trigger_multitouch_button_at(global_pos: Vector2) -> void:
	if interact_btn and interact_btn.get_global_rect().grow(8.0).has_point(global_pos):
		_on_interact_pressed()
	elif sprint_btn and sprint_btn.get_global_rect().grow(8.0).has_point(global_pos):
		sprint_btn.button_pressed = not sprint_btn.button_pressed
	elif flashlight_btn and flashlight_btn.get_global_rect().grow(8.0).has_point(global_pos):
		_on_flashlight_pressed()
	elif jump_btn and jump_btn.get_global_rect().grow(8.0).has_point(global_pos):
		_on_jump_pressed()
	elif title_btn and title_btn.get_global_rect().grow(8.0).has_point(global_pos):
		_on_title_pressed()
	elif pc_lock_btn and pc_lock_btn.get_global_rect().grow(8.0).has_point(global_pos):
		_on_pc_lock_pressed()

func _update_joystick_global(global_pos: Vector2) -> void:
	if not joystick_base or not joystick_knob:
		return
	var base_rect: Rect2 = joystick_base.get_global_rect()
	var base_center: Vector2 = base_rect.position + base_rect.size * 0.5
	var delta_vec: Vector2 = global_pos - base_center
	var dist: float = delta_vec.length()
	if dist > joystick_max_radius:
		delta_vec = delta_vec.normalized() * joystick_max_radius
	
	joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5) + delta_vec
	
	var norm_vec: Vector2 = delta_vec / joystick_max_radius
	if norm_vec.length() < 0.12:
		norm_vec = Vector2.ZERO
	
	if player and "touch_move_dir" in player:
		player.touch_move_dir = norm_vec

func _reset_joystick() -> void:
	joystick_touch_index = -1
	joystick_mouse_dragging = false
	if joystick_base and joystick_knob:
		joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5)
	if player and "touch_move_dir" in player:
		player.touch_move_dir = Vector2.ZERO

func reset_all_touches() -> void:
	_reset_joystick()
	look_touches.clear()
	look_mouse_dragging = false
	look_mouse_has_prev = false
# ---------------------------------------------------------
# 우측 하단 & 상단 액션 버튼 핸들러
# ---------------------------------------------------------
func _on_interact_pressed() -> void:
	if game_manager and game_manager.has_method("trigger_touch_interact"):
		game_manager.trigger_touch_interact()

func _on_sprint_toggled(toggled_on: bool) -> void:
	if player and "touch_sprint" in player:
		player.touch_sprint = toggled_on
	if sprint_btn:
		if toggled_on:
			sprint_btn.text = "🏃 달리기: ON"
			sprint_btn.modulate = Color(1.0, 0.85, 0.4, 1.0)
		else:
			sprint_btn.text = "🏃 달리기"
			sprint_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_flashlight_pressed() -> void:
	if player and player.has_method("_toggle_flashlight"):
		player._toggle_flashlight()

func _on_jump_pressed() -> void:
	if player and "touch_jump_requested" in player:
		player.touch_jump_requested = true

func _on_title_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _on_pc_lock_pressed() -> void:
	if not player:
		return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.mouse_captured = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.mouse_captured = true
