local M = {}

local alertCanvas = nil

function M.showAlert(text)
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
end

function M.hideAlert()
  if alertCanvas then
    alertCanvas:delete()
    alertCanvas = nil
  end
end

return M
