local M = {}

local alertCanvas = nil
local hideTimer = nil

function M.showAlert(text, duration)
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if alertCanvas then alertCanvas:delete(); alertCanvas = nil end

  local screen = hs.screen.mainScreen()
  local frame = screen:frame()
  local w, h, pad = 80, 28, 12
  alertCanvas = hs.canvas.new({ x = frame.x + frame.w - w - pad, y = frame.y + pad, w = w, h = h })
  alertCanvas[1] = {
    type = "rectangle", action = "fill",
    fillColor = { alpha = 0.75, white = 0 },
    roundedRectRadii = { xRadius = 6, yRadius = 6 },
  }
  alertCanvas[2] = {
    type = "text", text = text,
    textColor = { white = 1, alpha = 1 },
    textAlignment = "center",
    textSize = 13,
    frame = { x = 0, y = 6, w = w, h = h },
  }
  alertCanvas:show()
  if duration then hideTimer = hs.timer.doAfter(duration, M.hideAlert) end
end

function M.hideAlert()
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if alertCanvas then alertCanvas:delete(); alertCanvas = nil end
end

function M.createModal(key, label)
  local modal = hs.hotkey.modal.new({}, key)
  function modal:entered() M.showAlert(label) end
  function modal:exited()  M.hideAlert() end
  modal:bind({}, "escape", function() modal:exit() end)
  return modal
end

return M
