extends CharacterBody3D

enum State {
	HIDDEN,    # 사라짐 (8~14초간 어둠 속에 숨어 플레이어에게 탐색/휴식 시간 부여)
	LURK,      # 출현 & 응시 (원거리에서 으스스하게 서서 플레이어를 바라봄)
	CHASE,     # 플레이어를 향해 몇 초간 추격!
	FADING,    # 몇 초 후 스윽 사라지는 중 (빛과 크기가 서서히 줄어들며 사라짐)
}

@export_group("Speeds")
@export var base_chase_speed: float = 3.2
@export var max_chase_speed: float = 4.1
@export var lurk_speed: float = 1.2
@export var current_chase_speed: float = 3.2

@onready var visuals: Node3D = $Visuals
@onready var aura_light: OmniLight3D = $AuraLight

var player: Node3D = null
var current_state: State = State.LURK
var state_timer: float = 0.0
var float_time: float = 0.0
var caught_player: bool = false
var is_paused: bool = false
var collected_progress: float = 0.0

var default_light_energy: float = 2.4

# 3D 입체 음향 효과음
var sfx_lurk: AudioStream = preload("res://audio/sfx_monster_lurk.wav")
var sfx_vanish: AudioStream = preload("res://audio/sfx_monster_vanish.wav")
var monster_audio: AudioStreamPlayer3D = null

func _ready() -> void:
	player = get_tree().root.get_node_or_null("Main/Player")
	current_chase_speed = base_chase_speed

	# 3D 공간 음향 플레이어 설정 (괴물 위치에서 소리가 들려옴)
	monster_audio = AudioStreamPlayer3D.new()
	monster_audio.max_distance = 45.0
	monster_audio.unit_size = 10.0
	monster_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(monster_audio)

	_enter_state(State.LURK)

func _physics_process(delta: float) -> void:
	if caught_player:
		return

	if is_paused:
		velocity = Vector3.ZERO
		return

	if not player:
		player = get_tree().root.get_node_or_null("Main/Player")
		if not player:
			return

	float_time += delta * 3.8
	state_timer -= delta

	# 귀여운 둥둥 떠다니기 애니메이션
	visuals.position.y = 0.8 + sin(float_time) * 0.18
	visuals.rotation.z = sin(float_time * 0.8) * 0.08

	var dist: float = global_position.distance_to(player.global_position)

	# 잡힘 판정: 오직 돌진 추격(CHASE) 상태에서 1.35m 이내 근접 시에만 잡힘
	if current_state == State.CHASE and dist < 1.35:
		_catch_player()
		return

	match current_state:
		State.HIDDEN:
			velocity = Vector3.ZERO
			if state_timer <= 0.0:
				_appear_near_player()

		State.LURK:
			_look_at_player(delta)
			aura_light.light_color = Color(0.85, 0.35, 0.95)
			aura_light.light_energy = default_light_energy

			var dir: Vector3 = (player.global_position - global_position).normalized()
			dir.y = 0
			velocity = dir * lurk_speed

			if dist < 7.5 or state_timer <= 0.0:
				var rush_chance: float = 0.65 + (collected_progress * 0.25)
				if randf() < rush_chance:
					_enter_state(State.CHASE)
				else:
					_enter_state(State.FADING)

		State.CHASE:
			_look_at_player(delta * 1.5)
			aura_light.light_color = Color(1.0, 0.15, 0.1)
			aura_light.light_energy = default_light_energy * 1.5

			var dir: Vector3 = (player.global_position - global_position).normalized()
			dir.y = 0
			velocity = dir * current_chase_speed

			# 몇 초 후 스윽 사라짐
			if state_timer <= 0.0 or dist > 26.0:
				_enter_state(State.FADING)

		State.FADING:
			velocity = velocity.lerp(Vector3.ZERO, 3.5 * delta)
			visuals.scale = visuals.scale.lerp(Vector3(0.02, 0.02, 0.02), 3.5 * delta)
			aura_light.light_energy = lerp(aura_light.light_energy, 0.0, 4.0 * delta)

			if state_timer <= 0.0:
				_enter_state(State.HIDDEN)

	global_position += velocity * delta

func _look_at_player(delta: float) -> void:
	if not player:
		return
	var diff: Vector3 = player.global_position - global_position
	diff.y = 0
	if diff.length_squared() > 0.01:
		var target_angle: float = atan2(diff.x, diff.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 10.0 * delta)

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.HIDDEN:
			visuals.visible = false
			aura_light.visible = false
			visuals.scale = Vector3.ONE
			state_timer = randf_range(8.0, 14.0)

		State.LURK:
			visuals.visible = true
			aura_light.visible = true
			visuals.scale = Vector3.ONE
			aura_light.light_energy = default_light_energy
			state_timer = randf_range(4.0, 6.0)
			_notify_glitch(0.3)
			if monster_audio and sfx_lurk:
				monster_audio.stream = sfx_lurk
				monster_audio.volume_db = 2.0
				monster_audio.play()

		State.CHASE:
			visuals.visible = true
			aura_light.visible = true
			visuals.scale = Vector3.ONE
			state_timer = randf_range(3.8, 5.0)
			_notify_glitch(0.55)

		State.FADING:
			state_timer = 1.2
			if monster_audio and sfx_vanish:
				monster_audio.stream = sfx_vanish
				monster_audio.volume_db = 3.0
				monster_audio.play()

func _appear_near_player() -> void:
	if not player:
		return

	var spawn_dist: float = randf_range(16.0, 24.0)
	var spawn_pos: Vector3

	if randf() < 0.5:
		var forward: Vector3 = -player.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var side_offset: Vector3 = player.global_transform.basis.x * randf_range(-0.5, 0.5)
		spawn_pos = player.global_position + (forward + side_offset).normalized() * spawn_dist
	else:
		var angle: float = randf_range(0, TAU)
		var offset: Vector3 = Vector3(cos(angle), 0, sin(angle)) * spawn_dist
		spawn_pos = player.global_position + offset

	spawn_pos.x = clamp(spawn_pos.x, -37.0, 37.0)
	spawn_pos.z = clamp(spawn_pos.z, -37.0, 37.0)
	spawn_pos.y = 0.0

	global_position = spawn_pos
	_enter_state(State.LURK)

func on_note_collected(notes_count: int, total_notes: int) -> void:
	collected_progress = float(notes_count) / float(total_notes)
	current_chase_speed = lerp(base_chase_speed, max_chase_speed, collected_progress)
	
	if current_state == State.HIDDEN:
		_appear_near_player()
	_enter_state(State.LURK)

func _notify_glitch(intensity: float) -> void:
	var gm = get_tree().root.get_node_or_null("Main/GameManager")
	if gm and gm.has_method("trigger_glitch_burst"):
		gm.trigger_glitch_burst(intensity)

func _catch_player() -> void:
	var gm = get_tree().root.get_node_or_null("Main/GameManager")
	if gm and gm.has_method("on_player_hit"):
		var hit_applied: bool = gm.on_player_hit()
		if not hit_applied:
			return
		if gm.is_game_over:
			caught_player = true
			velocity = Vector3.ZERO
			if player:
				visuals.look_at(player.global_position, Vector3.UP)
		else:
			# 목숨이 남았으면 즉시 안개 속으로 사라지며 도망갈 시간 부여
			_enter_state(State.FADING)
	elif gm and gm.has_method("game_over"):
		caught_player = true
		velocity = Vector3.ZERO
		if player:
			visuals.look_at(player.global_position, Vector3.UP)
		gm.game_over()
