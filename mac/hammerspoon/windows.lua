local utils = require("utils")
local log = hs.logger.new("windows", "info")

local windowManager = utils.createModal("F14", "Window")

local function moveWindow(unit)
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(unit)
  end
  windowManager:exit()
end

windowManager:bind({"shift"}, "left",  function() moveWindow({x=0,   y=0,   w=0.5, h=1  }) end)
windowManager:bind({"shift"}, "right", function() moveWindow({x=0.5, y=0,   w=0.5, h=1  }) end)
windowManager:bind({"shift"}, "up",    function() moveWindow({x=0,   y=0,   w=1,   h=0.5}) end)
windowManager:bind({"shift"}, "down",  function() moveWindow({x=0,   y=0.5, w=1,   h=0.5}) end)

local NUDGE = 10

local function nudgeWindow(dx, dy)
  local win = hs.window.focusedWindow()
  if win then
    local f = win:frame()
    f.x = f.x + dx
    f.y = f.y + dy
    win:setFrame(f)
  end
end

local function bindNudge(key, dx, dy)
  local fn = function() nudgeWindow(dx, dy) end
  windowManager:bind({}, key, fn, nil, fn)
end

bindNudge("left",  -NUDGE, 0)
bindNudge("right",  NUDGE, 0)
bindNudge("up",    0, -NUDGE)
bindNudge("down",  0,  NUDGE)
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

windowManager:bind({"shift"}, "f", function()
  local win = hs.window.focusedWindow()
  if win then
    win:setFullScreen(not win:isFullScreen())
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

windowManager:bind({}, "]", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToScreen(win:screen():next()) end
  windowManager:exit()
end)

windowManager:bind({}, "[", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToScreen(win:screen():previous()) end
  windowManager:exit()
end)

