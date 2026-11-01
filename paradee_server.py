#!/usr/bin/env python
"""Paradee speech service, started by systemd when a client connects to its socket.

Request:  "<speed> <voice>\\n" followed by UTF-8 text, then the client shuts down its
          write side.
Response: a 24 kHz mono 16-bit WAV stream, one sentence at a time. An invalid request
          closes the connection with no data.

Handles one client at a time. Exits after PARADEE_IDLE_SECS without a client, which
frees the memory; systemd keeps the socket and starts the service again when needed.
"""
import os
import re
import socket
import struct
import sys
import time
import traceback

import numpy as np
from paradee import Paradee, SAMPLE_RATE

SYSTEMD_FIRST_FD = 3
IDLE_SECS = float(os.environ.get("PARADEE_IDLE_SECS", "1800"))
CLIENT_TIMEOUT_SECS = 30  # so a stuck client can't hold up the ones behind it
STREAM_SIZE = 0x7FFFFFFF  # total length is unknown up front; players read until EOF
WAV_HEADER = (b"RIFF" + struct.pack("<I", STREAM_SIZE) + b"WAVEfmt "
              + struct.pack("<IHHIIHH", 16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16)
              + b"data" + struct.pack("<I", STREAM_SIZE))


def systemd_socket():
    if os.environ.get("LISTEN_PID") != str(os.getpid()) or os.environ.get("LISTEN_FDS") != "1":
        sys.exit("paradee_server: start me through paradee-tts.socket")
    return socket.socket(fileno=SYSTEMD_FIRST_FD)


def read_request(conn):
    data = bytearray()
    while chunk := conn.recv(65536):
        data += chunk
    header, _, text = bytes(data).partition(b"\n")
    speed, voice = header.decode().split()
    speed = float(speed)
    if not 0 < speed <= 10:
        raise ValueError(f"speed {speed} out of range")
    return speed, voice, text.decode()


def serve(tts, conn):
    speed, voice, text = read_request(conn)
    tts.check_voice(voice)
    conn.sendall(WAV_HEADER)
    for sentence in re.split(r"(?<=[.!?…])\s+|\n+", text.strip()):
        if sentence.strip():
            pcm = np.clip(tts(sentence, speed=speed, voice=voice), -1, 1) * 32767
            conn.sendall(pcm.astype("<i2").tobytes())


def main():
    listener = systemd_socket()
    started = time.monotonic()
    tts = Paradee()
    tts("Ready.")  # loads the G2P data too, so the first request is as fast as the rest
    print(f"loaded in {time.monotonic() - started:.1f} s", flush=True)

    listener.settimeout(IDLE_SECS)
    while True:
        try:
            conn, _ = listener.accept()
        except TimeoutError:
            print(f"idle for {IDLE_SECS:.0f} s, exiting", flush=True)
            return
        with conn:
            conn.settimeout(CLIENT_TIMEOUT_SECS)
            try:
                serve(tts, conn)
            except (BrokenPipeError, ConnectionResetError):
                pass  # interrupted by a new selection
            except Exception:
                traceback.print_exc()


if __name__ == "__main__":
    main()
