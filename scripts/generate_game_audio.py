"""Generate original, loopable biome music and short game effects."""

from math import pi, sin
from pathlib import Path
import random
import struct
import wave


RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets"


def write(name: str, samples: list[float]) -> None:
    with wave.open(str(OUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 28000)) for v in samples))


def wave_tone(frequency: float, t: float) -> float:
    if frequency <= 0.0:
        return 0.0
    phase = frequency * t
    triangle = 2.0 * abs(2.0 * (phase % 1.0) - 1.0) - 1.0
    return triangle * 0.65 + sin(2.0 * pi * phase) * 0.35


def track(name: str, bass: list[float], notes: list[float], beat_length: float, mood: str) -> None:
    length = len(notes) * beat_length
    samples = []
    for i in range(int(length * RATE)):
        t = i / RATE
        beat = min(len(notes) - 1, int(t / beat_length))
        age = (t / beat_length) % 1.0
        low = wave_tone(bass[beat // 2], t) * (0.14 if mood == "boss" else 0.10)
        lead = wave_tone(notes[beat], t) * (1.0 - age) ** 1.5 * (0.14 if mood == "forest" else 0.11)
        pulse = wave_tone(bass[beat // 2] * 2.0, t) * (1.0 - age) ** 3 * (0.07 if mood == "boss" else 0.035)
        air = sin(2.0 * pi * (notes[beat] * 2.0) * t) * (1.0 - age) ** 2 * 0.012
        seam = min(1.0, t * 18.0, (length - t) * 18.0)
        samples.append((low + lead + pulse + air) * seam)
    write(name, samples)


def effect(name: str, first: float, last: float, seconds: float, grit: float = 0.0) -> None:
    noise = random.Random(sum(ord(c) for c in name))
    samples = []
    for i in range(int(seconds * RATE)):
        t = i / RATE
        p = t / seconds
        frequency = first + (last - first) * p
        envelope = (1.0 - p) ** 2 * min(1.0, t * 100.0)
        samples.append((wave_tone(frequency, t) * 0.54 + noise.uniform(-1.0, 1.0) * grit) * envelope)
    write(name, samples)


track("cave_music.wav", [55.0, 65.41, 49.0, 73.42, 55.0, 65.41, 49.0, 82.41],
      [220.0, 0.0, 261.63, 293.66, 220.0, 196.0, 174.61, 196.0,
       220.0, 261.63, 293.66, 261.63, 196.0, 174.61, 164.81, 220.0], 0.65, "cave")
track("forest_music.wav", [65.41, 73.42, 82.41, 73.42, 65.41, 98.0, 73.42, 82.41],
      [329.63, 392.0, 440.0, 392.0, 349.23, 440.0, 493.88, 392.0,
       329.63, 392.0, 523.25, 493.88, 440.0, 392.0, 349.23, 329.63], 0.52, "forest")
track("warden_music.wav", [55.0, 55.0, 51.91, 49.0, 55.0, 61.74, 65.41, 49.0],
      [220.0, 246.94, 261.63, 220.0, 207.65, 246.94, 293.66, 261.63,
       220.0, 196.0, 207.65, 246.94, 261.63, 293.66, 246.94, 220.0], 0.4, "boss")

effect("attack.wav", 570.0, 210.0, 0.16, 0.12)
effect("heavy_attack.wav", 250.0, 65.0, 0.36, 0.22)
effect("jump.wav", 280.0, 620.0, 0.17)
effect("dodge.wav", 730.0, 190.0, 0.21, 0.08)
effect("heal.wav", 390.0, 740.0, 0.44)
effect("enemy_attack.wav", 180.0, 85.0, 0.20, 0.22)
effect("warden_charge_tell.wav", 210.0, 520.0, 0.55, 0.08)
effect("warden_charge.wav", 170.0, 75.0, 0.44, 0.28)
effect("warden_slam_tell.wav", 500.0, 210.0, 0.62, 0.07)
effect("warden_slam.wav", 110.0, 42.0, 0.47, 0.36)
