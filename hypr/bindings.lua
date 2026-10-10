-- Jarvis Hyprland Keybindings Configuration
-- Works with Omarchy's Hyprland Lua binding system or can be adapted for hyprland.conf.

local jarvis_runtime = (os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000") .. "/jarvis"
local function jarvis_voice_enabled()
  local marker = io.open(jarvis_runtime .. "/voice.enabled", "r")
  if not marker then
    return false
  end
  marker:close()
  return true
end

-- Super + Delete: Toggle Jarvis Voice Mode on / off
hl.unbind("SUPER + DELETE")
hl.bind("SUPER + DELETE", function()
  local action = jarvis_voice_enabled() and "voice-off" or "voice-on"
  hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc " .. action))
  hl.dispatch(hl.dsp.submap("reset"))
end, { submap_universal = true, description = "Jarvis: voice mode on/off" })

-- Delete (Hold / Release): Push-to-Talk
-- Passes Delete through when Jarvis voice mode is off; claims it for PTT when on.
local jarvis_delete_claimed = false
hl.bind("DELETE", function()
  if not jarvis_voice_enabled() then
    return { ok = false }
  end
  jarvis_delete_claimed = true
  hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc ptt-down"))
  return { ok = true }
end, { auto_consuming = true, description = "Jarvis: hold Delete to talk" })

hl.bind("DELETE", function()
  if not jarvis_delete_claimed then
    return { ok = false }
  end
  jarvis_delete_claimed = false
  hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc ptt-up"))
  return { ok = true }
end, { release = true, auto_consuming = true, description = "Jarvis: release Delete to send" })

-- Screen capture while holding Delete (Push-to-Talk active):
-- 1 Click / Tap Print or Right Shift: Takes 1 screenshot during the query.
-- Press & Hold Print or Right Shift: Continuous screen capture (every 3s back-to-back).
-- When Delete is not held, Print performs standard desktop screenshot.
hl.unbind("PRINT")
hl.bind("PRINT", function()
  if jarvis_delete_claimed then
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc screen-down"))
    return { ok = true }
  end
  hl.dispatch(hl.dsp.exec_cmd("omarchy-capture-screenshot"))
  return { ok = true }
end, { auto_consuming = true, description = "Screenshot (or Jarvis screen capture when holding Delete)" })

hl.bind("PRINT", function()
  if jarvis_delete_claimed then
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc screen-up"))
    return { ok = true }
  end
  return { ok = true }
end, { release = true, auto_consuming = true, description = "Jarvis screen capture release" })

hl.bind("Shift_R", function()
  if jarvis_delete_claimed then
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc screen-down"))
    return { ok = true }
  end
  return { ok = false }
end, { auto_consuming = true, description = "Jarvis: screen capture while holding Delete" })

hl.bind("Shift_R", function()
  if jarvis_delete_claimed then
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/vc screen-up"))
    return { ok = true }
  end
  return { ok = false }
end, { release = true, auto_consuming = true, description = "Jarvis: screen capture release" })
