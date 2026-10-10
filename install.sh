#!/usr/bin/env bash
# Jarvis automated installer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
DATA_TTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/jarvis/tts"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

echo "=== Installing Jarvis ==="

# 1. Ensure target directories exist
mkdir -p "$BIN_DIR" "$DATA_TTS_DIR" "$SYSTEMD_USER_DIR"

# 2. Install binaries
echo "-> Installing command line tools to $BIN_DIR..."
install -m 755 "$SCRIPT_DIR/bin/vc" "$BIN_DIR/vc"
install -m 755 "$SCRIPT_DIR/bin/jarvis-speak" "$BIN_DIR/jarvis-speak"
install -m 755 "$SCRIPT_DIR/bin/jarvis-tts-setup" "$BIN_DIR/jarvis-tts-setup"

# 3. Install TTS script
echo "-> Installing TTS engine to $DATA_TTS_DIR..."
install -m 755 "$SCRIPT_DIR/tts/speak.py" "$DATA_TTS_DIR/speak.py"

# 4. Install Voxtype systemd service
echo "-> Setting up voxtype systemd user service..."
cp "$SCRIPT_DIR/systemd/voxtype.service" "$SYSTEMD_USER_DIR/voxtype.service"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  systemctl --user enable voxtype.service || true
fi

# 5. Check dependencies
echo "-> Checking dependencies..."
for cmd in uv voxtype grim ffmpeg ffplay opencode hyprctl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "   [WARNING] '$cmd' is not found in PATH. Please install it."
  else
    echo "   [OK] $cmd"
  fi
done

# 6. Run TTS setup
echo "-> Setting up Kokoro TTS model (download & virtualenv)..."
if command -v "$BIN_DIR/jarvis-tts-setup" >/dev/null 2>&1; then
  "$BIN_DIR/jarvis-tts-setup"
fi

echo ""
echo "=== Jarvis Installation Complete! ==="
echo "Add the keybindings from 'hypr/bindings.lua' to your Hyprland configuration."
echo "Use 'vc voice-on' or Super+Delete to toggle voice mode."
