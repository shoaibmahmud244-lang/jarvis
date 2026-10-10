# Jarvis — Real-Time Voice & Screen Multimodal Assistant

A fast, lightweight, and multimodal voice assistant tailored for Linux (Wayland / Hyprland). Designed for immediate, high-value spoken responses with screen-awareness and persistent memory.

---

## Features

- **Push-to-Talk Voice Flow:** Zero background listening or battery drain. Activate voice mode with `Super + Delete`, hold `Delete` to speak, and release to query.
- **Multimodal Screen Context:**
  - **Single Capture:** Tap `Print` or `Right Shift` while speaking to attach a screenshot of your active monitor.
  - **Continuous Stream:** Hold `Print` or `Right Shift` to capture back-to-back frames (every 3 seconds) for dynamic on-screen workflows.
- **High-Fidelity British Voice:** Uses [Kokoro ONNX](https://github.com/thewh1teagle/kokoro-onnx) (`bm_george` voice) on CPU with AVX2. Synthesizes ~10x–15x faster than real-time with zero resident RAM when idle.
- **Persistent Memory:** Seamless context recall across sessions powered by [Engram](https://github.com) MCP integration.
- **On-Demand Speech Recognition:** Integrated with [Voxtype](https://voxtype.io) running as a shared systemd user daemon (~18MB idle memory, 0% CPU).

---

## Architecture

```
[ Hyprland Keybindings ]
         │
         ▼
[ vc (Controller) ] ──┬──► [ Voxtype ] (Push-to-talk STT)
                      ├──► [ Grim + FFmpeg ] (On-demand Screen Capture)
                      ├──► [ OpenCode ] (Nvidia Nemotron reasoning + Engram MCP)
                      └──► [ Kokoro ONNX ] ──► [ FFplay ] (Spoken Response)
```

---

## Prerequisites

Ensure the following tools are installed on your Linux system:

| Tool | Purpose | Package / Command |
|---|---|---|
| **Voxtype** | Fast local speech-to-text | [voxtype.io](https://voxtype.io) / `cargo install voxtype` |
| **OpenCode** | LLM runner & agent framework | `npm install -g opencode-ai` or native package |
| **uv** | Ultra-fast Python package installer | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **Grim** | Wayland screenshot capture | `pacman -S grim` |
| **FFmpeg** | Image scaling and audio playback | `pacman -S ffmpeg` |
| **Hyprland** | Window manager & compositor | Standard Wayland setup |

*(Optional)* **Engram**: For persistent memory recall across conversations.

---

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shoaibmahmud244-lang/jarvis.git
   cd jarvis
   ```

2. **Run the installer:**
   ```bash
   ./install.sh
   ```
   The installer will:
   - Copy executables (`vc`, `jarvis-speak`, `jarvis-tts-setup`) to `~/.local/bin/`.
   - Copy speech synthesis scripts to `~/.local/share/jarvis/tts/`.
   - Setup and enable the `voxtype.service` systemd user service.
   - Download the Kokoro ONNX model and `bm_george` voice pack via `jarvis-tts-setup`.

3. **Configure Hyprland Keybindings:**
   Merge the bindings from `hypr/bindings.lua` into your Hyprland configuration (e.g. `~/.config/hypr/bindings.lua` or translate them to `hyprland.conf`).

---

## Usage & Keybindings

| Keybinding | Action | Description |
|---|---|---|
| `Super + Delete` | **Toggle Voice Mode** | Toggles Jarvis voice mode on/off. |
| `Delete` (Hold) | **Push to Talk** | Speak your query while holding Delete. |
| `Delete` (Release) | **Send Query** | Stops recording and begins processing. |
| `Print` or `Right Shift` (Tap) | **Attach Screenshot** | Captures 1 screenshot of focused monitor while holding Delete. |
| `Print` or `Right Shift` (Hold) | **Stream Screen** | Continuously captures screen every 3s while talking. |
| `vc reset` | **Clear History** | Clears local conversation context. |

---

## Project Structure

```text
jarvis/
├── bin/
│   ├── vc                  # Main push-to-talk, vision & orchestrator script
│   ├── jarvis-speak        # Wrapper for TTS execution
│   └── jarvis-tts-setup    # Model downloader & virtualenv provisioner
├── tts/
│   └── speak.py            # Sentence chunking & Kokoro ONNX synthesis
├── systemd/
│   └── voxtype.service     # Systemd user unit for Voxtype daemon
├── hypr/
│   └── bindings.lua        # Hyprland Lua bindings
├── docs/
│   └── WORKFLOW_MEMORY.md  # Architectural decisions & benchmarks
├── install.sh              # Automated setup script
├── .gitignore
└── README.md
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.

For details on what data Jarvis sends (notably the cloud LLM step) and what
stays local, see [SECURITY.md](SECURITY.md).
