# Jarvis Speech and Voxtype Resolution (2026-10-09)

## Status: Resolved & Working

- **Speech Engine:** Kokoro ONNX `kokoro-v1.0.int8.onnx` using CPU ONNX Runtime with AVX2.
- **Voice:** `bm_george` with `lang="en-gb"` (authentic British film-JARVIS voice).
- **Latency / Performance:** ~10x-15x faster than real-time synthesis on the 6-core Ryzen 5 4650U. Zero resident CPU or RAM (runs on-demand per spoken turn, ~120MB transient memory during synthesis, then exits).
- **Voxtype Lifecycle:** `voxtype.service` is persistently enabled as a user systemd service with `on_demand_loading = true` (~18MB idle, 0% CPU). Jarvis voice mode (`SUPER + DELETE`) and normal dictation (`RIGHTCTRL` and `F9`) both cleanly share the running daemon without killing or locking each other out.

## Key Changes
1. `~/.local/share/jarvis/tts/speak.py` and `~/.local/bin/jarvis-speak`: Restored to use `kokoro-v1.0.int8.onnx` with `voices-v1.0.bin`. Removed artificial WebGPU-only constraints that caused node assignment errors and deleted the model.
2. `~/.local/bin/jarvis-tts-setup`: Verified download and synthesis smoke test for `kokoro-v1.0.int8.onnx` with `bm_george`.
3. `~/.local/bin/vc`:
   - Removed `stop_owned_voxtype` kill logic from `voice_off()` and `cleanup()`.
   - Removed `voice.enabled` lockout from standalone dictation.
   - `start_voxtype_if_needed()` ensures `voxtype.service` is active without passing `--no-hotkey`.
4. `~/.config/hypr/bindings.lua`: Removed custom F9 and Super+Ctrl+X overrides that were routing dictation through the start/kill loop in `vc`. Omarchy's native bindings handle them directly.
5. Persistent Memory Integration (2026-10-10): Enabled Engram MCP server in `~/.local/bin/vc` with `--project=jarvis` and `permission: {"engram_*": "allow"}` so Jarvis can recall past context and user preferences seamlessly.
