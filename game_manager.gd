extends Node

@export var total_notes: int = 10

var collected_notes: int = 0
var is_game_over: bool = false
var is_game_won: bool = false
var is_solving_quiz: bool = false

@onready var hud: CanvasLayer = $"../HUD"
@onready var note_count_label: Label = $"../HUD/NoteCountPanel/MarginContainer/NoteLabel"
@onready var message_label: Label = $"../HUD/MessageLabel"
@onready var game_over_panel: PanelContainer = $"../HUD/GameOverPanel"
@onready var game_over_text: Label = $"../HUD/GameOverPanel/Margin/VBox/TitleLabel"
@onready var static_overlay: ColorRect = $"../HUD/StaticOverlay"

@onready var monster: Node3D = $"../Monster"
@onready var player: Node3D = $"../Player"

var quiz_modal_scene: PackedScene = preload("res://quiz_modal.tscn")
var mobile_controls_scene: PackedScene = preload("res://mobile_controls.tscn")
var quiz_modal: Control = null
var mobile_controls: Control = null
var current_nearby_note: Node3D = null

var msg_timer: float = 0.0
var glitch_burst_timer: float = 0.0
var glitch_burst_alpha: float = 0.0

# 오디오 시스템 (BGM, 긴박한 추격음, 심장박동, 쪽지 소리, 점프스케어)
var bgm_stream: AudioStream = preload("res://audio/bgm_ambient.wav")
var chase_stream: AudioStream = preload("res://audio/sfx_chase_loop.wav")
var heartbeat_stream: AudioStream = preload("res://audio/sfx_heartbeat.wav")
var paper_stream: AudioStream = preload("res://audio/sfx_paper.wav")
var jumpscare_stream: AudioStream = preload("res://audio/sfx_jumpscare.wav")

var bgm_player: AudioStreamPlayer = null
var chase_player: AudioStreamPlayer = null
var heartbeat_player: AudioStreamPlayer = null
var paper_player: AudioStreamPlayer = null
var jumpscare_player: AudioStreamPlayer = null
var heartbeat_timer: float = 0.0

func _ready() -> void:
	collected_notes = 0
	is_game_over = false
	is_game_won = false
	is_solving_quiz = false
	
	if game_over_panel:
		game_over_panel.visible = false
		_setup_game_over_touch_buttons()
	if message_label:
		message_label.text = ""
		message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if static_overlay:
		static_overlay.visible = false
		static_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var note_panel = $"../HUD/NoteCountPanel"
	if note_panel:
		note_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var help_panel = $"../HUD/HelpPanel"
	if help_panel:
		help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var help_lbl = help_panel.get_node_or_null("MarginContainer/Label")
		if help_lbl and help_lbl is Label:
			help_lbl.text = "조이스틱/WASD: 이동 | 화면 드래그: 시점 회전 | 📜버튼/E: 쪽지 풀기 | 출처: 하모쌤"

	# 오디오 플레이어 초기화
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.volume_db = -8.0
	add_child(bgm_player)
	bgm_player.finished.connect(func(): if not is_game_over: bgm_player.play())
	bgm_player.play()

	chase_player = AudioStreamPlayer.new()
	chase_player.stream = chase_stream
	chase_player.volume_db = -80.0
	add_child(chase_player)
	chase_player.finished.connect(func(): if not is_game_over: chase_player.play())

	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.stream = heartbeat_stream
	heartbeat_player.volume_db = -6.0
	add_child(heartbeat_player)

	paper_player = AudioStreamPlayer.new()
	paper_player.stream = paper_stream
	paper_player.volume_db = -3.0
	add_child(paper_player)

	jumpscare_player = AudioStreamPlayer.new()
	jumpscare_player.stream = jumpscare_stream
	jumpscare_player.volume_db = 0.0
	add_child(jumpscare_player)

	# 1. 모바일/태블릿 터치 컨트롤 UI 생성 및 HUD에 연결
	if hud and mobile_controls_scene:
		mobile_controls = mobile_controls_scene.instantiate()
		hud.add_child(mobile_controls)
		if mobile_controls.has_method("setup"):
			mobile_controls.setup(player, self)

	# 2. 퀴즈 모달 인스턴스 생성 및 HUD에 연결 (터치 컨트롤보다 위에 오도록 배치)
	if hud and quiz_modal_scene:
		quiz_modal = quiz_modal_scene.instantiate()
		hud.add_child(quiz_modal)
		quiz_modal.quiz_completed.connect(_on_quiz_completed)
		quiz_modal.quiz_closed.connect(_on_quiz_closed)

	# GameOverPanel이 가장 위에 표시되도록 순서 조정
	if hud and game_over_panel:
		hud.move_child(game_over_panel, hud.get_child_count() - 1)

	# 묘비, 관, 울타리, 나무 등 월드 오브젝트 충돌체 자동 구성
	_setup_world_colliders()

	_update_note_ui()

func _setup_game_over_touch_buttons() -> void:
	var vbox = game_over_panel.get_node_or_null("Margin/VBox")
	if not vbox:
		return
	var sub_label = vbox.get_node_or_null("SubLabel")
	if sub_label and sub_label is Label:
		sub_label.text = "아래 버튼을 터치하거나 단축키(R / M)를 누르세요"

	var btn_row = HBoxContainer.new()
	btn_row.name = "TouchButtonRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)

	var retry_btn = Button.new()
	retry_btn.custom_minimum_size = Vector2(180, 48)
	retry_btn.text = "🔄 다시 도전하기 (R)"
	retry_btn.add_theme_font_size_override("font_size", 16)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	btn_row.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.custom_minimum_size = Vector2(180, 48)
	menu_btn.text = "🏠 타이틀 화면으로 (M)"
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://title_screen.tscn"))
	btn_row.add_child(menu_btn)

	vbox.add_child(btn_row)

func set_nearby_note(note_node: Node3D) -> void:
	current_nearby_note = note_node
	if mobile_controls and mobile_controls.has_method("set_nearby_note_active"):
		mobile_controls.set_nearby_note_active(true)

func clear_nearby_note(note_node: Node3D) -> void:
	if current_nearby_note == note_node:
		current_nearby_note = null
		if mobile_controls and mobile_controls.has_method("set_nearby_note_active"):
			mobile_controls.set_nearby_note_active(false)

func trigger_touch_interact() -> void:
	if is_game_over or is_game_won or is_solving_quiz:
		return

	if is_instance_valid(current_nearby_note) and current_nearby_note.has_method("open_quiz"):
		current_nearby_note.open_quiz()
		return

	# 플레이어 반경 3.8m 이내에 쪽지가 있으면 즉시 열기 (태블릿 터치 편의성 보정)
	var notes_root = get_node_or_null("../Notes")
	if notes_root and player:
		var closest_note: Node3D = null
		var min_dist: float = 3.8
		for child in notes_root.get_children():
			if is_instance_valid(child) and child is Node3D:
				var d: float = child.global_position.distance_to(player.global_position)
				if d < min_dist:
					min_dist = d
					closest_note = child
		if closest_note and closest_note.has_method("open_quiz"):
			closest_note.open_quiz()
			return

	if message_label:
		message_label.text = "주변에 쪽지가 없습니다. 노란 빛이 나는 쪽지 가까이 다가가세요!"
		msg_timer = 2.5

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or is_game_won:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_R:
				get_tree().reload_current_scene()
			elif event.keycode == KEY_M:
				get_tree().change_scene_to_file("res://title_screen.tscn")
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			get_tree().change_scene_to_file("res://title_screen.tscn")

func _process(delta: float) -> void:
	if is_game_over or is_game_won:
		return

	# 쪽지 메시지 표시 타이머
	if msg_timer > 0.0:
		msg_timer -= delta
		if msg_timer <= 0.0 and message_label:
			message_label.text = ""

	# 문제를 푸는 동안에는 화면 노이즈/비네트 효과 끄기 (집중 방해 방지)
	if is_solving_quiz:
		if static_overlay:
			static_overlay.visible = false
		return

	# 괴물 출현/돌진 시 순간 글리치 효과
	if glitch_burst_timer > 0.0:
		glitch_burst_timer -= delta
		if static_overlay:
			static_overlay.visible = true
			static_overlay.modulate.a = glitch_burst_alpha + randf_range(-0.08, 0.08)
		return

	# 괴물 근접 시 화면 노이즈 / 비네트 효과 및 긴박한 추격 사운드
	if monster and player and static_overlay:
		var is_chasing: bool = false
		var is_active: bool = true
		if "current_state" in monster and "State" in monster:
			is_chasing = (monster.current_state == monster.State.CHASE)
			is_active = (monster.current_state == monster.State.LURK or is_chasing)

		# 1. 쫓기는 동안 긴박감 넘치는 추격음 제어 (140BPM 긴박한 펄스 + 스트링스)
		if is_chasing and not is_solving_quiz:
			if chase_player and not chase_player.playing:
				chase_player.play()
			if chase_player:
				chase_player.volume_db = lerp(chase_player.volume_db, -2.5, 6.0 * delta)
			if bgm_player:
				bgm_player.volume_db = lerp(bgm_player.volume_db, -18.0, 5.0 * delta)
		else:
			if chase_player and chase_player.playing:
				chase_player.volume_db = lerp(chase_player.volume_db, -80.0, 4.0 * delta)
				if chase_player.volume_db <= -65.0:
					chase_player.stop()
			if bgm_player:
				bgm_player.volume_db = lerp(bgm_player.volume_db, -8.0, 3.0 * delta)

		# 2. 화면 노이즈 효과
		if is_active:
			var dist: float = monster.global_position.distance_to(player.global_position)
			if dist < 16.0:
				static_overlay.visible = true
				var intensity: float = clamp(1.0 - (dist / 16.0), 0.0, 1.0)
				static_overlay.modulate.a = (intensity * 0.45) + randf_range(-0.04, 0.04)
			else:
				static_overlay.visible = false
		else:
			static_overlay.visible = false

func trigger_glitch_burst(intensity: float = 0.5) -> void:
	glitch_burst_timer = 0.35
	glitch_burst_alpha = clamp(intensity * 0.65, 0.2, 0.7)

# 묘비, 관, 울타리, 나무 등 월드 에셋에 물리 충돌체 부여
func _setup_world_colliders() -> void:
	# 1. 묘지 구역 (묘비, 관, 울타리)
	var graveyard: Node3D = get_node_or_null("../Graveyard")
	if graveyard:
		for item in graveyard.get_children():
			if not item is Node3D:
				continue
			var item_name: String = item.name
			if item_name.begins_with("GraveItem_"):
				var sb = StaticBody3D.new()
				sb.collision_layer = 1
				sb.collision_mask = 0
				var col = CollisionShape3D.new()
				var box = BoxShape3D.new()
				var path: String = item.scene_file_path.to_lower()
				if "coffin" in path:
					box.size = Vector3(1.1, 0.75, 2.2)
					col.position.y = 0.38
				elif "dest" in path:
					box.size = Vector3(1.0, 0.7, 0.6)
					col.position.y = 0.35
				else:
					box.size = Vector3(0.9, 1.4, 0.45)
					col.position.y = 0.7
				col.shape = box
				sb.add_child(col)
				item.add_child(sb)
			elif item_name.begins_with("GraveFence_"):
				var sb = StaticBody3D.new()
				sb.collision_layer = 1
				sb.collision_mask = 0
				var col = CollisionShape3D.new()
				var box = BoxShape3D.new()
				box.size = Vector3(2.4, 1.5, 0.35)
				col.position.y = 0.75
				col.shape = box
				sb.add_child(col)
				item.add_child(sb)

	# 2. 숲 구역 (나무 기둥 154그루 충돌체)
	var forest: Node3D = get_node_or_null("../Forest")
	if forest:
		for tree in forest.get_children():
			if not tree is Node3D or not tree.name.begins_with("Tree_"):
				continue
			var sb = StaticBody3D.new()
			sb.collision_layer = 1
			sb.collision_mask = 0
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.45
			cyl.height = 4.0
			col.shape = cyl
			col.position.y = 2.0
			sb.add_child(col)
			tree.add_child(sb)

	# 3. 골목/건물 프랍 (벤치, 제단, 등불 기둥)
	var buildings: Node3D = get_node_or_null("../Buildings")
	if buildings:
		for prop in buildings.get_children():
			if not prop is Node3D or not prop.name.begins_with("AlleyProp_"):
				continue
			var path: String = prop.scene_file_path.to_lower()
			var sb = StaticBody3D.new()
			sb.collision_layer = 1
			sb.collision_mask = 0
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			if "bench" in path:
				box.size = Vector3(1.6, 0.8, 0.7)
				col.position.y = 0.4
			elif "shrine" in path:
				box.size = Vector3(1.2, 1.6, 1.0)
				col.position.y = 0.8
			elif "post_lantern" in path:
				box.size = Vector3(0.35, 2.5, 0.35)
				col.position.y = 1.25
			else:
				box.size = Vector3(0.6, 0.6, 0.6)
				col.position.y = 0.3
			col.shape = box
			sb.add_child(col)
			prop.add_child(sb)

# 쪽지 상호작용 시 퀴즈 창 열기
func open_note_quiz(note_node: Node3D, note_id: int) -> void:
	if is_game_over or is_game_won or is_solving_quiz:
		return
	
	is_solving_quiz = true

	if mobile_controls:
		mobile_controls.visible = false
		if mobile_controls.has_method("reset_all_touches"):
			mobile_controls.reset_all_touches()
		elif mobile_controls.has_method("_reset_joystick"):
			mobile_controls._reset_joystick()

	# 쪽지 바스락 소리 재생
	if paper_player:
		paper_player.pitch_scale = randf_range(0.95, 1.05)
		paper_player.play()

	# 1. 괴물 일시정지 (문제를 푸는 동안 플레이어를 쫓거나 잡지 못함)
	if monster:
		monster.is_paused = true

	# 2. 플레이어 조작 일시정지 및 마우스/터치 커서 표시
	if player:
		player.set_physics_process(false)
		player.touch_move_dir = Vector2.ZERO
		if "mouse_captured" in player:
			player.mouse_captured = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# 3. 퀴즈 모달 팝업 열기
	if quiz_modal:
		quiz_modal.open_quiz(note_node, note_id)

# 퀴즈 정답 맞춤 완료
func _on_quiz_completed(note_node: Node3D, note_id: int) -> void:
	clear_nearby_note(note_node)
	if is_instance_valid(note_node):
		note_node.queue_free()

	collected_notes += 1
	_update_note_ui()

	var quiz = MathQuizData.QUIZZES.get(note_id, null)
	var title = quiz.get("title", "수학 쪽지") if quiz else "쪽지"
	if message_label:
		message_label.text = "[봉인 해제!] %s (%d/%d)" % [title, collected_notes, total_notes]
		msg_timer = 4.0

	if monster and monster.has_method("on_note_collected"):
		monster.on_note_collected(collected_notes, total_notes)

	_resume_gameplay()

	if collected_notes >= total_notes:
		_win_game()

func _on_quiz_closed() -> void:
	_resume_gameplay()

func _resume_gameplay() -> void:
	is_solving_quiz = false

	if is_game_over or is_game_won:
		return

	if mobile_controls:
		mobile_controls.visible = true

	if monster:
		monster.is_paused = false

	if player:
		player.set_physics_process(true)
		if "mouse_captured" in player:
			player.mouse_captured = false
	# 태블릿/모바일 터치 조작을 위해 마우스 모드는 항상 VISIBLE 유지
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_note_ui() -> void:
	if note_count_label:
		note_count_label.text = "수학 쪽지: %d / %d" % [collected_notes, total_notes]

func game_over() -> void:
	if is_game_won:
		return
	is_game_over = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if mobile_controls:
		mobile_controls.visible = false

	# BGM 및 추격음 중단, 점프스케어 사운드 작렬!
	if bgm_player:
		bgm_player.stop()
	if chase_player:
		chase_player.stop()
	if heartbeat_player:
		heartbeat_player.stop()
	if jumpscare_player:
		jumpscare_player.play()

	if game_over_panel:
		game_over_panel.visible = true
		game_over_text.text = "잡혔습니다...\n귀여운 괴물이 당신을 붙잡았습니다!\n\n출처 : 하모쌤"

func _win_game() -> void:
	is_game_won = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if mobile_controls:
		mobile_controls.visible = false
	if game_over_panel:
		game_over_panel.visible = true
		game_over_text.text = "탈출 성공!\n초등 6학년 원의 둘레와 넓이의 비밀을 모두 풀어\n어둠의 숲을 탈출했습니다!\n\n출처 : 하모쌤"
