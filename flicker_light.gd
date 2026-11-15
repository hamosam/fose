extends OmniLight3D

@export var min_energy: float = 0.2
@export var max_energy: float = 2.5
@export var flicker_interval: float = 0.1

var time_accum: float = 0.0
var next_flicker: float = 0.1

func _process(delta: float) -> void:
	time_accum += delta
	if time_accum >= next_flicker:
		time_accum = 0.0
		# 불규칙하게 깜빡거리거나 갑자기 꺼졌다 켜짐
		if randf() < 0.25:
			light_energy = 0.0
			next_flicker = randf_range(0.05, 0.3)
		elif randf() < 0.5:
			light_energy = min_energy
			next_flicker = randf_range(0.05, 0.15)
		else:
			light_energy = randf_range(min_energy, max_energy)
			next_flicker = randf_range(0.05, 0.4)
