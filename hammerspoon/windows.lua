local utils = require("utils")
local log = hs.logger.new("windows", "info")

local windowManager = hs.hotkey.modal.new({}, "F14")

function windowManager:entered()
  utils.showAlert("Window")
end

function windowManager:exited()
  utils.hideAlert()
end

local function moveWindow(unit)
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(unit)
  end
  windowManager:exit()
end

windowManager:bind({}, "left",  function() moveWindow({x=0,   y=0,   w=0.5, h=1  }) end)
windowManager:bind({}, "right", function() moveWindow({x=0.5, y=0,   w=0.5, h=1  }) end)
windowManager:bind({}, "up",    function() moveWindow({x=0,   y=0,   w=1,   h=0.5}) end)
windowManager:bind({}, "down",  function() moveWindow({x=0,   y=0.5, w=1,   h=0.5}) end)
windowManager:bind({}, "h", function() moveWindow({x=0,   y=0,   w=0.5, h=0.5}) end)
windowManager:bind({}, "s", function() moveWindow({x=0.5, y=0,   w=0.5, h=0.5}) end)
windowManager:bind({}, "n", function() moveWindow({x=0,   y=0.5, w=0.5, h=0.5}) end)
windowManager:bind({}, "t", function() moveWindow({x=0.5, y=0.5, w=0.5, h=0.5}) end)

windowManager:bind({}, "c", function() moveWindow({x=0.1, y=0.075, w=0.8, h=0.85}) end)

windowManager:bind({}, "v", function()
  local wins = hs.window.orderedWindows()
  if wins[1] and wins[2] then
    wins[1]:moveToUnit({x=0, y=0, w=0.5, h=1})
    wins[2]:moveToUnit({x=0.5, y=0, w=0.5, h=1})
  end
  windowManager:exit()
end)

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

local function getSpaces()
  return hs.spaces.spacesForScreen(hs.screen.mainScreen())
end

local function gotoSpace(n)
  local spaces = getSpaces()
  if spaces and spaces[n] then
    hs.spaces.gotoSpace(spaces[n])
  else
    log.w("no space at index", n)
  end
  windowManager:exit()
end

local function moveWindowToSpace(n)
  local win = hs.window.focusedWindow()
  if not win then windowManager:exit() return end
  local spaces = getSpaces()
  if spaces and spaces[n] then
    local ok, err = hs.spaces.moveWindowToSpace(win:id(), spaces[n], true)
    if not ok then log.e("move failed:", err) end
  else
    log.w("no space at index", n)
  end
  windowManager:exit()
end

for i = 1, 9 do
  windowManager:bind({}, tostring(i), function() gotoSpace(i) end)
  windowManager:bind({"shift"}, tostring(i), function() moveWindowToSpace(i) end)
end

windowManager:bind({}, "escape", function() windowManager:exit() end)
