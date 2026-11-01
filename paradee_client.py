#!/usr/bin/env python
"""Drop-in for RHVoice-client: text on stdin, streaming WAV on stdout.

    echo "Hello there." | paradee_client.py | aplay -q

Environment: PARADEE_VOICE (default af_heart), PARADEE_SPEED (default 1.0, higher is faster).
"""
import os
import re
import struct
import sys

# Libraries print to stdout (spaCy's model download does), which would corrupt the
# audio stream. Keep the real stdout for audio and send fd 1 to stderr.
audio_out = os.fdopen(os.dup(1), "wb", buffering=0)
os.dup2(2, 1)

from paradee import Paradee, SAMPLE_RATE  # noqa: E402
import numpy as np  # noqa: E402

VOICE = os.environ.get("PARADEE_VOICE", "af_heart")
SPEED = float(os.environ.get("PARADEE_SPEED", "1.0"))
STREAM_SIZE = 0x7FFFFFFF  # total length is unknown up front; players read until EOF


def wav_header(rate):
    return (b"RIFF" + struct.pack("<I", STREAM_SIZE) + b"WAVEfmt "
            + struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16)
            + b"data" + struct.pack("<I", STREAM_SIZE))


def main():
    text = sys.stdin.read().strip()
    # Written before the model loads, so the reader starts on any input, even empty.
    audio_out.write(wav_header(SAMPLE_RATE))
    if not text:
        return
    tts = Paradee()
    for sentence in re.split(r"(?<=[.!?…])\s+|\n+", text):
        if sentence.strip():
            pcm = np.clip(tts(sentence, speed=SPEED, voice=VOICE), -1, 1) * 32767
            audio_out.write(pcm.astype("<i2").tobytes())


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:  # the player went away
        pass
