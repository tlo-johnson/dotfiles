local utils = require("utils")

local keypad = hs.hotkey.modal.new({}, "F17")

function keypad:entered()
  utils.showAlert("Keypad")
end

function keypad:exited()
  utils.hideAlert()
end

local function tap(key)
  return function()
    hs.eventtap.keyStroke({}, key, 0)
  end
end

-- Number layout (numpad-style, Dvorak physical positions):
--   g=7  c=8  r=9
--   h=4  t=5  n=6
--   m=1  w=2  v=3
--        space=0
keypad:bind({}, "m",     tap("1"))
keypad:bind({}, "w",     tap("2"))
keypad:bind({}, "v",     tap("3"))
keypad:bind({}, "h",     tap("4"))
keypad:bind({}, "t",     tap("5"))
keypad:bind({}, "n",     tap("6"))
keypad:bind({}, "g",     tap("7"))
keypad:bind({}, "c",     tap("8"))
keypad:bind({}, "r",     tap("9"))
keypad:bind({}, "space", tap("0"))

keypad:bind({}, "escape", function() keypad:exit() end)
