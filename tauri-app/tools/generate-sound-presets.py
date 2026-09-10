#!/usr/bin/env python3
"""Generates the bundled notification sound presets in public/presets/sounds.

The presets are synthesized here rather than shipped as opaque binaries so
they stay small, regenerable and free of third-party licensing. Run with:

    python3 tools/generate-sound-presets.py
"""

import math
import pathlib
import struct
import wave

SAMPLE_RATE = 22050
OUT_DIR = pathlib.Path(__file__).resolve().parent.parent / "public" / "presets" / "sounds"

# name -> list of (frequency in Hz, start in s, duration in s, peak amplitude 0..1)
PRESETS = {
    # A soft two-note bell, the general-purpose default.
    "chime": [(880.0, 0.00, 0.45, 0.45), (1174.7, 0.16, 0.55, 0.40)],
    # One short, bright note for low-key notifications.
    "ping": [(1318.5, 0.00, 0.28, 0.40)],
    # Three quick beeps to actually get someone's attention.
    "alert": [(988.0, 0.00, 0.12, 0.45), (988.0, 0.18, 0.12, 0.45), (988.0, 0.36, 0.16, 0.45)],
    # Rising major triad, for "the thing you waited for finished".
    "success": [(523.3, 0.00, 0.20, 0.40), (659.3, 0.13, 0.20, 0.40), (784.0, 0.26, 0.40, 0.40)],
    # Falling minor second, for failures.
    "error": [(415.3, 0.00, 0.22, 0.42), (311.1, 0.20, 0.45, 0.42)],
}


def envelope(position: float) -> float:
    """Percussive envelope: a few ms of attack, then exponential decay."""
    attack = 0.02
    if position < attack:
        return position / attack
    return math.exp(-4.0 * (position - attack) / (1.0 - attack))


def render(tones) -> bytes:
    length = max(start + duration for _, start, duration, _ in tones)
    samples = [0.0] * int(length * SAMPLE_RATE)

    for frequency, start, duration, amplitude in tones:
        first = int(start * SAMPLE_RATE)
        count = int(duration * SAMPLE_RATE)
        for i in range(count):
            value = math.sin(2.0 * math.pi * frequency * i / SAMPLE_RATE)
            # A quiet second harmonic keeps the sine from sounding hollow.
            value += 0.2 * math.sin(4.0 * math.pi * frequency * i / SAMPLE_RATE)
            samples[first + i] += amplitude * envelope(i / count) * value / 1.2

    return b"".join(
        struct.pack("<h", max(-32768, min(32767, int(sample * 32767)))) for sample in samples
    )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, tones in PRESETS.items():
        path = OUT_DIR / f"{name}.wav"
        with wave.open(str(path), "wb") as out:
            out.setnchannels(1)
            out.setsampwidth(2)
            out.setframerate(SAMPLE_RATE)
            out.writeframes(render(tones))
        print(f"{path.name}: {path.stat().st_size / 1024:.1f} KiB")


if __name__ == "__main__":
    main()
