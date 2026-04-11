local utils = require("utils")

local bluetoothModal = hs.hotkey.modal.new({}, "F15")

function bluetoothModal:entered()
  utils.showAlert("BT")
end

function bluetoothModal:exited()
  utils.hideAlert()
end

local function findOutput(uidPart)
  for _, d in ipairs(hs.audiodevice.allOutputDevices()) do
    if d:uid():find(uidPart, 1, true) then return d end
  end
end

local function switchTo(output)
  if output then
    output:setDefaultOutputDevice()
    hs.notify.new({title="Bluetooth", informativeText="Audio switched to " .. output:name()}):send()
  end
  bluetoothModal:exit()
end

bluetoothModal:bind({}, "a", function() switchTo(findOutput("80-95-3A-F1-89-E0")) end)
bluetoothModal:bind({}, "m", function() switchTo(findOutput("BuiltIn")) end)
bluetoothModal:bind({}, "escape", function() bluetoothModal:exit() end)
