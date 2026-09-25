"""Generate the short cave footstep used while walking on stone."""

from math import pi, sin
from pathlib import Path
import random
import struct
import wave


rate = 22050
duration = 0.115
random_source = random.Random(71)
output = Path(__file__).resolve().parent.parent / "assets" / "footstep.wav"

samples = []
previous_noise = 0.0
for index in range(int(rate * duration)):
    t = index / rate
    progress = t / duration
    noise = random_source.uniform(-1.0, 1.0)
    grit = noise - previous_noise * 0.55
    previous_noise = noise
    thud = sin(2 * pi * (90.0 - 45.0 * progress) * t)
    envelope = (1.0 - progress) ** 3
    samples.append((thud * 0.38 + grit * 0.19) * envelope)

with wave.open(str(output), "wb") as audio:
    audio.setnchannels(1)
    audio.setsampwidth(2)
    audio.setframerate(rate)
    audio.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 26000)) for sample in samples))
