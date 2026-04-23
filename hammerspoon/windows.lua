local utils = require("utils")
local log = hs.logger.new("windows", "info")

local function logSpaces()
  local allSpaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  if not allSpaces then log.w("no spaces found") return end
  for i, id in ipairs(allSpaces) do
    log.i("space", i, "id=" .. id)
  end
end

logSpaces()

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

windowManager:bind({}, "left",  function() moveWindow({x=0,   y=0,   w=0.5, h=1  }) end) -- left half
windowManager:bind({}, "right", function() moveWindow({x=0.5, y=0,   w=0.5, h=1  }) end) -- right half
windowManager:bind({}, "up",    function() moveWindow({x=0,   y=0,   w=1,   h=0.5}) end) -- top half
windowManager:bind({}, "down",  function() moveWindow({x=0,   y=0.5, w=1,   h=0.5}) end) -- bottom half
windowManager:bind({}, "h", function() moveWindow({x=0,   y=0,   w=0.5, h=0.5}) end) -- top-left quarter
windowManager:bind({}, "s", function() moveWindow({x=0.5, y=0,   w=0.5, h=0.5}) end) -- top-right quarter
windowManager:bind({}, "n", function() moveWindow({x=0,   y=0.5, w=0.5, h=0.5}) end) -- bottom-left quarter
windowManager:bind({}, "t", function() moveWindow({x=0.5, y=0.5, w=0.5, h=0.5}) end) -- bottom-right quarter

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

local function gotoSpace(n)
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  if spaces and spaces[n] then
    log.i("going to space", n, "(id=" .. spaces[n] .. ")")
    hs.spaces.gotoSpace(spaces[n])
  else
    log.w("no space at index", n)
  end
  windowManager:exit()
end

local function moveWindowToSpace(n)
  local win = hs.window.focusedWindow()
  if not win then
    log.w("moveWindowToSpace: no focused window")
    windowManager:exit()
    return
  end
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  if spaces and spaces[n] then
    log.i("moving", win:title(), "to space", n, "(id=" .. spaces[n] .. ")")
    local ok, err = hs.spaces.moveWindowToSpace(win:id(), spaces[n], true)
    if ok then
      log.i("move succeeded")
    else
      log.e("move failed:", err)
    end
    -- hs.spaces.gotoSpace(spaces[n])
  else
    log.w("no space at index", n)
  end
  windowManager:exit()
end

for i = 1, 9 do
  windowManager:bind({}, tostring(i), function() gotoSpace(i) end)
  windowManager:bind({"shift"}, tostring(i), function() moveWindowToSpace(i) end)
end

windowManager:bind({}, "escape", function()
  windowManager:exit()
end)
