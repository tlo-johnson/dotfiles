local windowManager = hs.hotkey.modal.new({}, "F14")

function windowManager:entered()
  hs.alert.show("Window")
end

function windowManager:exited()
end

local function moveWindow(unit)
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(unit)
  end
  windowManager:exit()
end

windowManager:bind({}, "h", function() moveWindow({x=0,   y=0,   w=0.5, h=1  }) end) -- left half
windowManager:bind({}, "s", function() moveWindow({x=0.5, y=0,   w=0.5, h=1  }) end) -- right half
windowManager:bind({}, "n", function() moveWindow({x=0,   y=0,   w=1,   h=0.5}) end) -- top half
windowManager:bind({}, "t", function() moveWindow({x=0,   y=0.5, w=1,   h=0.5}) end) -- bottom half
windowManager:bind({}, "g", function() moveWindow({x=0,   y=0,   w=0.5, h=0.5}) end) -- top-left quarter
windowManager:bind({}, "l", function() moveWindow({x=0.5, y=0,   w=0.5, h=0.5}) end) -- top-right quarter
windowManager:bind({}, "m", function() moveWindow({x=0,   y=0.5, w=0.5, h=0.5}) end) -- bottom-left quarter
windowManager:bind({}, "z", function() moveWindow({x=0.5, y=0.5, w=0.5, h=0.5}) end) -- bottom-right quarter

local prevFrames = {}

windowManager:bind({}, "f", function()
  local win = hs.window.focusedWindow()
  if win then
    local id = win:id()
    local screen = win:screen():frame()
    local frame = win:frame()
    local isMaximized = frame.x == screen.x and frame.y == screen.y
      and frame.w == screen.w and frame.h == screen.h
    if isMaximized and prevFrames[id] then
      win:setFrame(prevFrames[id])
      prevFrames[id] = nil
    else
      prevFrames[id] = frame
      win:moveToUnit({x=0, y=0, w=1, h=1})
    end
  end
  windowManager:exit()
end)

windowManager:bind({}, "escape", function()
  windowManager:exit()
end)
