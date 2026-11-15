import os
import math
import wave
import struct
import random

os.makedirs('audio', exist_ok=True)
SAMPLE_RATE = 44100

def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    # Normalize
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val > 0.001:
        norm = [s / max_val * 0.95 for s in samples]
    else:
        norm = samples
    
    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        raw = bytearray()
        for s in norm:
            clamped = max(-1.0, min(1.0, s))
            raw.extend(struct.pack('<h', int(clamped * 32767)))
        wf.writeframes(raw)
    print(f"Generated {path} ({len(samples)} samples, {len(samples)/sample_rate:.2f}s)")

# 1. BGM: Dark Ambient Horror Drone (Seamlessly loopable)
def gen_bgm():
    duration = 16.0
    total_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * total_samples
    
    # Detuned bass drone
    freqs = [45.0, 52.0, 68.0, 103.0]
    for f in freqs:
        phase = random.uniform(0, math.tau)
        for i in range(total_samples):
            t = i / SAMPLE_RATE
            # Slow LFO modulation
            lfo = 1.0 + 0.25 * math.sin(2 * math.pi * 0.125 * t)
            samples[i] += 0.22 * math.sin(2 * math.pi * f * t + phase) * lfo
            
    # Wind noise with moving filter
    noise_val = 0.0
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        noise_val = 0.96 * noise_val + 0.04 * (random.random() * 2.0 - 1.0)
        wind_mod = 0.5 + 0.5 * math.sin(2 * math.pi * 0.1875 * t)
        samples[i] += noise_val * wind_mod * 0.28
        
    # Eerie high harmonics
    harmonics = [440.0, 554.37, 659.25]
    for h in harmonics:
        phase = random.uniform(0, math.tau)
        for i in range(total_samples):
            t = i / SAMPLE_RATE
            shimmer = 0.5 + 0.5 * math.sin(2 * math.pi * 0.25 * t + phase)
            samples[i] += 0.06 * math.sin(2 * math.pi * h * t) * shimmer

    # Seamless loop crossfade (1.5s)
    fade_len = int(1.5 * SAMPLE_RATE)
    for i in range(fade_len):
        frac = i / fade_len
        end_idx = total_samples - fade_len + i
        blended = samples[end_idx] * (1.0 - frac) + samples[i] * frac
        samples[i] = blended
        samples[end_idx] = blended
        
    write_wav('audio/bgm_ambient.wav', samples)

# 2. Footstep SFX
def gen_footstep():
    duration = 0.14
    n = int(duration * SAMPLE_RATE)
    samples = []
    noise = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 32.0)
        # Thump
        thump = math.sin(2 * math.pi * 75.0 * (1.0 - t * 4.0) * t) * 0.6
        # Dirt/Grass crunch
        noise = 0.82 * noise + 0.18 * (random.random() * 2.0 - 1.0)
        samples.append((thump + noise * 0.45) * env)
    write_wav('audio/sfx_footstep.wav', samples)

# 3. Flashlight click SFX
def gen_flashlight():
    duration = 0.07
    n = int(duration * SAMPLE_RATE)
    samples = [0.0] * n
    # Click 1
    for i in range(int(0.03 * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 180.0)
        samples[i] += math.sin(2 * math.pi * 2400.0 * t) * env * 0.8
    # Click 2 (spring release)
    offset = int(0.018 * SAMPLE_RATE)
    for i in range(offset, n):
        t = (i - offset) / SAMPLE_RATE
        env = math.exp(-t * 140.0)
        samples[i] += math.sin(2 * math.pi * 3200.0 * t) * env * 0.6
    write_wav('audio/sfx_flashlight.wav', samples)

# 4. Note paper rustle SFX
def gen_paper():
    duration = 0.32
    n = int(duration * SAMPLE_RATE)
    samples = []
    noise = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # double rustle envelope
        env = (math.sin(math.pi * t / duration) ** 2) * (0.6 + 0.4 * math.sin(t * 40.0))
        noise = 0.85 * noise + 0.15 * (random.random() * 2.0 - 1.0)
        samples.append(noise * env * 0.9)
    write_wav('audio/sfx_paper.wav', samples)

# 5. Quiz correct chime SFX
def gen_correct():
    duration = 0.75
    n = int(duration * SAMPLE_RATE)
    samples = [0.0] * n
    notes = [
        (0.0, 523.25),   # C5
        (0.08, 659.25),  # E5
        (0.16, 783.99),  # G5
        (0.24, 1046.50), # C6
    ]
    for start_t, f in notes:
        start_i = int(start_t * SAMPLE_RATE)
        for i in range(start_i, n):
            t = (i - start_i) / SAMPLE_RATE
            env = math.exp(-t * 5.5)
            # Bell with harmonic
            sine = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2 * t)
            samples[i] += sine * env * 0.3
    write_wav('audio/sfx_correct.wav', samples)

# 6. Quiz wrong buzzer SFX
def gen_wrong():
    duration = 0.45
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 6.0)
        f = 175.0 - t * 65.0
        # Mild distortion
        val = math.sin(2 * math.pi * f * t)
        val = math.copysign(abs(val) ** 0.8, val)
        samples.append(val * env * 0.6)
    write_wav('audio/sfx_wrong.wav', samples)

# 7. Monster lurk eerie whistle SFX
def gen_monster_lurk():
    duration = 1.6
    n = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * t / duration) ** 1.5
        vib = math.sin(2 * math.pi * 12.0 * t) * 25.0
        f = 320.0 + math.sin(t * 3.0) * 110.0 + vib
        sine = math.sin(2 * math.pi * f * t) + 0.35 * math.sin(2 * math.pi * (f * 1.5) * t)
        samples.append(sine * env * 0.5)
    write_wav('audio/sfx_monster_lurk.wav', samples)

# 8. Monster vanish "스윽" fade swoosh SFX
def gen_monster_vanish():
    duration = 1.3
    n = int(duration * SAMPLE_RATE)
    samples = []
    noise = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # S-curve fade
        env = math.exp(-t * 2.8) * math.sin(math.pi * t / duration)
        noise = 0.9 * noise + 0.1 * (random.random() * 2.0 - 1.0)
        sine = math.sin(2 * math.pi * (340.0 - t * 160.0) * t)
        samples.append((noise * 0.6 + sine * 0.4) * env * 0.7)
    write_wav('audio/sfx_monster_vanish.wav', samples)

# 9. Heartbeat tension SFX
def gen_heartbeat():
    duration = 0.8
    n = int(duration * SAMPLE_RATE)
    samples = [0.0] * n
    # Lub
    for i in range(int(0.18 * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 22.0)
        samples[i] += math.sin(2 * math.pi * 58.0 * t) * env * 0.85
    # Dub
    offset = int(0.24 * SAMPLE_RATE)
    for i in range(offset, min(n, offset + int(0.20 * SAMPLE_RATE))):
        t = (i - offset) / SAMPLE_RATE
        env = math.exp(-t * 20.0)
        samples[i] += math.sin(2 * math.pi * 52.0 * t) * env * 0.7
    write_wav('audio/sfx_heartbeat.wav', samples)

# 10. Jumpscare caught shock SFX
def gen_jumpscare():
    duration = 1.5
    n = int(duration * SAMPLE_RATE)
    samples = []
    noise = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 3.0)
        # Low thud
        thud = math.sin(2 * math.pi * 48.0 * t) * 0.6
        # Dissonant screech
        screech = math.sin(2 * math.pi * 780.0 * t) + math.sin(2 * math.pi * 835.0 * t)
        # Harsh static
        noise = 0.7 * noise + 0.3 * (random.random() * 2.0 - 1.0)
        samples.append((thud + screech * 0.3 + noise * 0.5) * env)
    write_wav('audio/sfx_jumpscare.wav', samples)

if __name__ == '__main__':
    gen_bgm()
    gen_footstep()
    gen_flashlight()
    gen_paper()
    gen_correct()
    gen_wrong()
    gen_monster_lurk()
    gen_monster_vanish()
    gen_heartbeat()
    gen_jumpscare()
    print("All audio files generated successfully!")
