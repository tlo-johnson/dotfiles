local utils = require("utils")

local wm = hs.hotkey.modal.new({}, "F14")

function wm:entered() utils.showAlert("Window") end
function wm:exited()  utils.hideAlert() end

local function act(name)
    return function()
        spoon.PaperWM.actions.actions()[name]()
        wm:exit()
    end
end

-- Focus
wm:bind({},          "left",  act("focus_left"))
wm:bind({},          "right", act("focus_right"))
wm:bind({},          "up",    act("focus_up"))
wm:bind({},          "down",  act("focus_down"))

-- Swap
wm:bind({"shift"},   "left",  act("swap_left"))
wm:bind({"shift"},   "right", act("swap_right"))

-- Resize
wm:bind({},          "h",     act("decrease_width"))
wm:bind({},          "s",     act("increase_width"))

-- Resize
wm:bind({},          "r",     act("cycle_width"))
wm:bind({},          "f",     act("full_width"))

-- Columns
wm:bind({},          "i",     act("slurp_in"))
wm:bind({},          "o",     act("barf_out"))

-- Spaces
for i = 1, 9 do
    wm:bind({},        tostring(i), act("switch_space_" .. i))
    wm:bind({"shift"}, tostring(i), act("move_window_"   .. i))
end

wm:bind({}, "escape", function() wm:exit() end)
