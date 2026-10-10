# Security Policy

This document describes what Jarvis touches, what data leaves your machine,
where, and how to report a vulnerability. It is written for users deciding
whether to trust this tool and for reviewers auditing the code.

---

## Supported Versions

Jarvis is a personal-use project maintained on a best-effort basis. Only the
latest commit on the default branch receives fixes.

| Version | Supported |
|---|---|
| latest (`main`) | :white_check_mark: |
| older commits | :x: |

---

## Data flow at a glance

```
[ Hyprland keybindings ]
         │
         ▼
    [ vc orchestrator ] ──► Voxtype (local STT) ─────────────► transcript
         │
         ├──► grim + ffmpeg (local screenshot) ─────────────► frame(s)
         │
         └──► OpenCode ──► OpenRouter API (cloud LLM) ◄──────┘
                              │
                              ▼
                       spoken reply
                              │
                       Kokoro ONNX (local TTS) ──► ffplay (local audio)
```

The only outbound network path is the **OpenCode → OpenRouter** hop. Everything
else runs locally.

---

## What leaves your machine

When you release push-to-talk (`vc ask`), the following are sent to
**OpenRouter** (a third-party cloud API) via the `opencode run` call in
`bin/vc`:

1. **Your transcribed question** — the plain text Voxtype produced from your speech.
2. **Recent conversation history** — up to the last ~2000 bytes of
   `~/.local/share/jarvis/conversation.txt` (`tail -c 2000`).
3. **Screenshot frames** — any screenshots you attached (tap/hold `Print` or
   `Right Shift` during a query), sent as `--file` attachments.
4. **The system prompt** — a fixed, non-personal instruction string.

The configured model is `openrouter/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free`.

> **Important:** speech transcripts and screen contents are sensitive. Because
> they are sent to a cloud provider, Jarvis is **not** fully private/offline.
> The local components are STT (Voxtype), TTS (Kokoro), and all storage — but
> the reasoning step is remote. Treat anything you say on-mic or show on-screen
> while attached as data shared with OpenRouter (and, transitively, the
> underlying model provider).

### Machine access during reasoning

The OpenCode `build` agent runs with a working directory of the temporary
Jarvis runtime directory (`$XDG_RUNTIME_DIR/jarvis`). Reviewers should be aware
that the agent framework can invoke tools; Jarvis passes only the prompt and
attachments, but the cloud model influences what runs inside that runtime
directory. The runtime directory is removed on cleanup.

---

## What stays local

| Component | Location | Notes |
|---|---|---|
| **Speech-to-text** | Voxtype daemon (systemd user service) | Runs on-device; no audio leaves the machine. |
| **Text-to-speech** | Kokoro ONNX int8 (`bm_george`) | Runs on-device on CPU; no text leaves for synthesis. |
| **Conversation history** | `~/.local/share/jarvis/conversation.txt` | Plaintext. Truncated to the last 10,000 bytes. |
| **Screenshots** | `$XDG_RUNTIME_DIR/jarvis/frames.*` | Temporary; deleted after each query by the `ask` cleanup trap. |
| **Persistent memory** | Engram MCP server (`~/.engram`) | Local MCP server started by OpenCode; stored under your home directory. |

### File permissions

Jarvis hardens its own files:

- The orchestrator sets `umask 077`.
- Runtime (`$XDG_RUNTIME_DIR/jarvis`) and data (`~/.local/share/jarvis`)
  directories are created with mode `700`.
- `conversation.txt` is created with mode `600`.
- Screenshot frames are written to a `700` directory and are short-lived.

Because history and memory are stored in plaintext, anyone with access to your
logged-in session can read them. Use full-disk encryption if that matters.

---

## Network endpoints contacted

| Endpoint | When | Purpose |
|---|---|---|
| OpenRouter API (`openrouter.ai`) | Every spoken query | LLM reasoning (cloud). |
| `github.com/thewh1teagle/kokoro-onnx` releases | Only during `jarvis-tts-setup` | Download Kokoro ONNX model + voice weights. |

> Note: the `opencode` and `voxtype` binaries are third-party tools. Jarvis
> does not control any additional network requests they may make (e.g. update
> checks). Enforce network restrictions at the OS level if you need a hard
> boundary.

### Reducing network exposure

To keep reasoning local, point OpenCode at a local model endpoint (e.g. Ollama
or llama.cpp) by changing the `MODEL` value in `bin/vc` before installing.
Jarvis makes no other assumptions about the provider.

---

## Reporting a Vulnerability

This is a personal project, but responsible disclosure is welcome.

- **Do not** open a public issue for security-sensitive bugs.
- Please report privately via GitHub Security Advisories
  (`Security → Report a vulnerability`) on the repository, or contact the
  maintainer directly.

Include: a description, affected file(s)/commit, reproduction steps, and impact.
You can expect an acknowledgement; fix timing depends on maintainer
availability.

---

## License

Jarvis is MIT-licensed. This `SECURITY.md` describes behavior of the code as
written and does not grant warranties of any kind. See [LICENSE](LICENSE).
