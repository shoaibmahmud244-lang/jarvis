#!/usr/bin/env python3
"""Speak Jarvis replies with the local Kokoro bm_george voice."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from kokoro_onnx import Kokoro


def plain_text(source: str) -> str:
    source = re.sub(r"```.*?```", " ", source, flags=re.S)
    source = re.sub(r"`([^`]*)`", r"\1", source)
    source = re.sub(r"!\[([^]]*)\]\([^)]*\)", r"\1", source)
    source = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", source)
    source = re.sub(r"^\s{0,3}#{1,6}\s*", "", source, flags=re.M)
    source = re.sub(r"^\s*>\s?", "", source, flags=re.M)
    source = re.sub(r"^\s*[-*+]\s+", "", source, flags=re.M)
    source = re.sub(r"^\s*\d+[.)]\s+", "", source, flags=re.M)
    source = re.sub(r"[*_~]", "", source)
    return re.sub(r"\s+", " ", source).strip()


def chunks(text: str, limit: int = 280) -> list[str]:
    pieces = re.split(r"(?<=[.!?])\s+", text)
    result: list[str] = []
    current = ""
    for piece in pieces:
        while len(piece) > limit:
            split = piece.rfind(" ", 0, limit)
            split = split if split > 0 else limit
            part, piece = piece[:split].strip(), piece[split:].strip()
            if current:
                result.append(current)
                current = ""
            result.append(part)
        if current and len(current) + len(piece) + 1 > limit:
            result.append(current)
            current = piece
        else:
            current = f"{current} {piece}".strip()
    if current:
        result.append(current)
    return result


def main() -> int:
    text = plain_text(sys.stdin.read())
    if not text:
        return 0

    data_dir = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "jarvis/tts"
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "jarvis"
    runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
    model = Kokoro(str(data_dir / "kokoro-v1.0.int8.onnx"), str(data_dir / "voices-v1.0.bin"))
    pcm: list[np.ndarray] = []
    sample_rate = 0
    for part in chunks(text):
        samples, sample_rate = model.create(part, voice="bm_george", speed=1.0, lang="en-gb")
        pcm.append(np.asarray(samples, dtype=np.float32))
        pcm.append(np.zeros(int(sample_rate * 0.18), dtype=np.float32))
    audio = np.concatenate(pcm)
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(prefix="reply.", suffix=".wav", dir=runtime, delete=False) as tmp:
            tmp_path = Path(tmp.name)
        with wave.open(str(tmp_path), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(sample_rate)
            pcm16 = np.clip(audio, -1.0, 1.0)
            output.writeframes((pcm16 * 32767).astype("<i2").tobytes())
        subprocess.run(
            ["ffplay", "-nodisp", "-autoexit", "-loglevel", "error", "-af", "volume=10.0", str(tmp_path)],
            check=True,
        )
    finally:
        if tmp_path is not None:
            tmp_path.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"Jarvis speech failed: {error}", file=sys.stderr)
        raise SystemExit(1)
