local utils = require("utils")

local bluetoothModal = hs.hotkey.modal.new({}, "F15")

local LOG_PATH = os.getenv("HOME") .. "/Library/Logs/hammerspoon-bluetooth.log"

local function log(msg)
  local f = io.open(LOG_PATH, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
    f:close()
  end
end

local function notifyError(msg)
  log("ERROR: " .. msg)
  hs.notify.new({title="Bluetooth", informativeText=msg .. " (check " .. LOG_PATH .. ")"}):send()
end

function bluetoothModal:entered() utils.showAlert("BT") end
function bluetoothModal:exited() utils.hideAlert() end

local function findOutputDevice(namePart)
  for _, d in ipairs(hs.audiodevice.allOutputDevices()) do
    if d:name():lower():find(namePart:lower(), 1, true) then return d end
  end
end

local function switchToDevice(d)
  log("Switching to " .. d:name())
  d:setDefaultOutputDevice()
  hs.notify.new({title="Bluetooth", informativeText="Audio switched to " .. d:name()}):send()
end

local function waitForAudioDevice(namePart, attempts, callback)
  if attempts <= 0 then callback(nil) ; return end
  local d = findOutputDevice(namePart)
  if d then callback(d) ; return end
  hs.timer.doAfter(1, function() waitForAudioDevice(namePart, attempts - 1, callback) end)
end

local function switchToAirPods()
  local d = findOutputDevice("airpods")
  if d then switchToDevice(d) ; return end

  local AIRPODS_MAC_ADDRESS = "80:95:3A:F1:89:E0"

  log("AirPods not in CoreAudio, connecting via blueutil (" .. AIRPODS_MAC_ADDRESS .. ")")
  hs.notify.new({title="Bluetooth", informativeText="Connecting AirPods..."}):send()
  hs.task.new("/opt/homebrew/bin/blueutil", function(code, stdout, stderr)
    log("blueutil exit=" .. code .. " stdout=" .. stdout .. " stderr=" .. stderr)
    if code ~= 0 then notifyError("Failed to connect AirPods: " .. stderr) ; return end

    waitForAudioDevice("airpods", 10, function(found)
      if found then switchToDevice(found)
      else notifyError("AirPods connected but never appeared as audio device") end
    end)
  end, {"--connect", AIRPODS_MAC_ADDRESS}):start()
end

local function switchToBuiltIn()
  local d = findOutputDevice("macbook") or findOutputDevice("built-in")
  if d then switchToDevice(d)
  else notifyError("Built-in audio device not found") end
end

bluetoothModal:bind({}, "a", function() switchToAirPods() ; bluetoothModal:exit() end)
bluetoothModal:bind({}, "m", function() switchToBuiltIn() ; bluetoothModal:exit() end)
bluetoothModal:bind({}, "escape", function() bluetoothModal:exit() end)
