local utils = require("utils")

local micBar = hs.menubar.new()
local muted = false
local currentDevice = hs.audiodevice.defaultInputDevice()

local function setMicBar(state)
  micBar:setTitle(state and "🔇" or "🎙")
end

local function toggleMic()
  local device = hs.audiodevice.defaultInputDevice()
  if not device then return end
  muted = not muted
  device:setInputMuted(muted)
  setMicBar(muted)
  utils.showAlert(muted and "Mic Off" or "Mic On", 1.5)
end

-- Initialize from actual device state
if currentDevice then
  muted = currentDevice:inputMuted() or false
  setMicBar(muted)
end

hs.audiodevice.watcher.setCallback(function(event)
  if event == "dIn " then
    local oldDevice = currentDevice
    currentDevice = hs.audiodevice.defaultInputDevice()
    if currentDevice then currentDevice:setInputMuted(muted) end
    setMicBar(muted)

    if oldDevice then oldDevice:setInputMuted(false) end
  end
end)
hs.audiodevice.watcher.start()

micBar:setClickCallback(toggleMic)
hs.hotkey.bind({ "cmd", "shift" }, "m", toggleMic)
