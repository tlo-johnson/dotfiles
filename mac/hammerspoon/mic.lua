local muted = false
local currentDevice = hs.audiodevice.defaultInputDevice()
local liveCanvas = nil
local livePulseTimer = nil

local function updateLiveAlert(isMuted)
  if livePulseTimer then
    livePulseTimer:stop()
    livePulseTimer = nil
  end
  if liveCanvas then
    liveCanvas:delete()
    liveCanvas = nil
  end
  if not isMuted then
    liveCanvas = hs.canvas.new({ x = 12, y = 12, w = 120, h = 40 })
    liveCanvas:appendElements(
      {
        type = "rectangle",
        action = "fill",
        fillColor = { alpha = 1, red = 0.08, green = 0.08, blue = 0.08 },
        roundedRectRadii = { xRadius = 8, yRadius = 8 },
      },
      {
        type = "rectangle",
        action = "fill",
        fillColor = { alpha = 1, red = 0.9, green = 0.15, blue = 0.15 },
        roundedRectRadii = { xRadius = 2, yRadius = 2 },
        frame = { x = 8, y = 8, w = 4, h = 24 },
      },
      {
        type = "text",
        text = "MIC IS ON",
        textColor = { white = 1, alpha = 1 },
        textSize = 15,
        textFont = "Helvetica-Bold",
        textAlignment = "left",
        frame = { x = 20, y = 12, w = 80, h = 20 },
      }
    )
    liveCanvas:show()

    local visible = true
    livePulseTimer = hs.timer.doEvery(0.8, function()
      if not liveCanvas then return end
      visible = not visible
      if visible then liveCanvas:show() else liveCanvas:hide() end
    end)
  end
end

local function toggleMic()
  local device = hs.audiodevice.defaultInputDevice()
  if not device then return end
  muted = not muted
  device:setInputMuted(muted)
  updateLiveAlert(muted)
end

-- Initialize from actual device state
if currentDevice then
  muted = currentDevice:inputMuted() or false
  updateLiveAlert(muted)
end

hs.audiodevice.watcher.setCallback(function(event)
  if event == "dIn " then
    local oldDevice = currentDevice
    currentDevice = hs.audiodevice.defaultInputDevice()
    if currentDevice then currentDevice:setInputMuted(muted) end
    updateLiveAlert(muted)

    if oldDevice then oldDevice:setInputMuted(false) end
  end
end)
hs.audiodevice.watcher.start()

hs.hotkey.bind({ "cmd", "shift" }, "m", toggleMic)
