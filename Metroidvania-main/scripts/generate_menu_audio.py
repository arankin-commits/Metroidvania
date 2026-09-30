"""Generate the small, original menu WAV assets with Python's standard library."""

from math import pi, sin
from pathlib import Path
import struct
import wave


RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets"
OUT.mkdir(exist_ok=True)


def write_wav(name: str, samples: list[float]) -> None:
    with wave.open(str(OUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, sample)) * 26000)) for sample in samples))


def triangle(phase: float) -> float:
    return 2.0 * abs(2.0 * (phase % 1.0) - 1.0) - 1.0


def tone(freq: float, time: float) -> float:
    return triangle(freq * time) * 0.72 + sin(2 * pi * freq * time) * 0.28


def music() -> list[float]:
    # Eight seconds at 120 BPM. The last beat resolves into the opening chord.
    bass = [110.0, 110.0, 130.81, 130.81, 98.0, 98.0, 146.83, 146.83]
    melody = [440.0, 523.25, 659.25, 523.25, 392.0, 493.88, 587.33, 440.0,
              349.23, 440.0, 523.25, 440.0, 392.0, 493.88, 440.0, 329.63]
    samples = []
    for index in range(RATE * 8):
        t = index / RATE
        beat = int(t * 2)
        note_age = (t * 2) % 1.0
        low = tone(bass[beat // 2] / 2.0, t) * 0.16
        pulse = tone(bass[beat // 2], t) * 0.09 * (1.0 - note_age * 0.55)
        lead = tone(melody[beat], t) * 0.12 * (1.0 - note_age) ** 1.5
        shimmer = sin(2 * pi * 880 * t) * 0.013 * (1.0 - note_age) ** 2
        # A short, quiet seam keeps looping from clicking.
        seam = min(1.0, t * 20.0, (8.0 - t) * 20.0)
        samples.append((low + pulse + lead + shimmer) * seam)
    return samples


def effect(start: float, end: float, duration: float, volume: float) -> list[float]:
    result = []
    for index in range(int(RATE * duration)):
        t = index / RATE
        progress = t / duration
        frequency = start + (end - start) * progress
        envelope = (1.0 - progress) ** 2
        result.append(tone(frequency, t) * envelope * volume)
    return result


write_wav("menu_music.wav", music())
write_wav("menu_hover.wav", effect(620, 850, 0.075, 0.35))
write_wav("menu_click.wav", effect(360, 210, 0.17, 0.5))
