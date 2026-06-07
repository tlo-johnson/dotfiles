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

local BT_ICON      = hs.image.imageFromName("NSBluetoothTemplate")
local SPEAKER_ICON = hs.image.imageFromName("NSTouchBarAudioOutputVolumeLowTemplate")
local SEARCH_ICON  = hs.image.imageFromName("NSRevealFreestandingTemplate")

local function styleChooser(chooser)
  chooser:width(30)
  chooser:rows(8)
  chooser:bgDark(true)
  chooser:fgColor({white = 1, alpha = 1})
  chooser:subTextColor({white = 0.5, alpha = 1})
end

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


local function selectAudioDevice()
  local audioDevices = hs.audiodevice.allOutputDevices()
  if not audioDevices or #audioDevices == 0 then notifyError("No audio output devices found") ; return end

  local currentUID = hs.audiodevice.defaultOutputDevice():uid()

  local function extractMac(uid)
    local mac = uid:match("(%x%x%-%x%x%-%x%x%-%x%x%-%x%x%-%x%x)")
    if mac then return mac:gsub("-", ":"):lower() end
  end

  -- Index audio devices by MAC and name for lookup
  local audioByMac  = {}
  local audioByName = {}
  for _, d in ipairs(audioDevices) do
    local mac = extractMac(d:uid())
    if mac then audioByMac[mac] = d end
    audioByName[d:name():lower()] = d
  end

  local function findAudioDevice(dev)
    local addr = dev.address and dev.address:lower():gsub("-", ":")
    if addr and audioByMac[addr] then return audioByMac[addr] end
    return audioByName[(dev.name or dev.address):lower()]
  end

  local function connectAndSwitch(name, address)
    log("Connecting " .. name .. " (" .. address .. ") via blueutil")
    hs.notify.new({title="Bluetooth", informativeText="Connecting " .. name .. "..."}):send()
    hs.task.new("/opt/homebrew/bin/blueutil", function(code, _, stderr)
      log("blueutil connect exit=" .. code .. " stderr=" .. stderr)
      if code ~= 0 then notifyError("Failed to connect " .. name .. ": " .. stderr) ; return end
      waitForAudioDevice(name, 10, function(found)
        if found then switchToDevice(found)
        else notifyError(name .. " connected but never appeared as audio device") end
      end)
    end, {"--connect", address}):start()
  end

  local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    if choice.audioUID then
      local d = hs.audiodevice.findOutputByUID(choice.audioUID)
      if d then switchToDevice(d) end
    else
      connectAndSwitch(choice.devName, choice.address)
    end
  end)

  -- Show CoreAudio devices immediately while blueutil loads
  local function buildFallbackChoices()
    local choices = {}
    for _, d in ipairs(audioDevices) do
      table.insert(choices, {
        text     = d:name() .. (d:uid() == currentUID and " ✓" or ""),
        audioUID = d:uid(),
        image    = SPEAKER_ICON,
      })
    end
    return choices
  end

  styleChooser(chooser)
  chooser:choices(buildFallbackChoices())
  chooser:show()

  -- Rebuild with blueutil as primary source, CoreAudio-only devices appended
  hs.task.new("/opt/homebrew/bin/blueutil", function(code, stdout, _)
    if code ~= 0 then return end
    local btDevices = hs.json.decode(stdout) or {}

    local btMacs = {}
    local choices = {}
    for _, dev in ipairs(btDevices) do
      local name = dev.name or dev.address
      local audioDevice = findAudioDevice(dev)
      local isCurrent = audioDevice and audioDevice:uid() == currentUID
      local addr = dev.address:lower():gsub("-", ":")
      btMacs[addr] = true
      table.insert(choices, {
        text     = name .. (isCurrent and " ✓" or ""),
        subText  = dev.address .. (dev.connected and " · connected" or " · not connected"),
        address  = dev.address,
        devName  = name,
        audioUID = audioDevice and audioDevice:uid(),
        image    = BT_ICON,
      })
    end

    -- Append CoreAudio devices not matched to any BT device
    for _, d in ipairs(audioDevices) do
      local mac = extractMac(d:uid())
      if not (mac and btMacs[mac]) then
        table.insert(choices, {
          text     = d:name() .. (d:uid() == currentUID and " ✓" or ""),
          audioUID = d:uid(),
          image    = SPEAKER_ICON,
        })
      end
    end

    chooser:choices(choices)
  end, {"--paired", "--format", "json"}):start()
end

local function pairNewDevice()
  local found = {}  -- keyed by address to deduplicate across scans

  local function scan(duration)
    log("Inquiry for " .. duration .. "s")

    local chooser = hs.chooser.new(function(choice)
      if not choice then return end
      if choice.scanDuration then
        scan(choice.scanDuration)
        return
      end
      local addr, name = choice.address, choice.devName
      log("Pairing " .. name .. " (" .. addr .. ")")
      hs.notify.new({title="Bluetooth", informativeText="Pairing " .. name .. "..."}):send()
      hs.task.new("/opt/homebrew/bin/blueutil", function(exitCode, _, err)
        log("pair " .. addr .. " exit=" .. exitCode .. " stderr=" .. err)
        if exitCode ~= 0 then notifyError("Failed to pair " .. name .. ": " .. err) ; return end
        hs.notify.new({title="Bluetooth", informativeText="Paired " .. name}):send()
      end, {"--pair", addr}):start()
    end)

    styleChooser(chooser)
    chooser:placeholderText("Scanning for " .. duration .. "s...")
    chooser:choices({})
    chooser:show()

    hs.task.new("/opt/homebrew/bin/blueutil", function(code, stdout, stderr)
      log("inquiry exit=" .. code .. " stderr=" .. stderr)
      if code == 0 then
        for _, dev in ipairs(hs.json.decode(stdout) or {}) do
          found[dev.address] = dev
        end
      end

      local choices = {}
      for _, dev in pairs(found) do
        table.insert(choices, {
          text    = dev.name or dev.address,
          subText = dev.address,
          address = dev.address,
          devName = dev.name or dev.address,
          image   = BT_ICON,
        })
      end
      table.insert(choices, {
        text          = "Scan more (" .. (duration * 2) .. "s)",
        image         = SEARCH_ICON,
        scanDuration  = duration * 2,
      })

      chooser:placeholderText("Select a device")
      chooser:choices(choices)
    end, {"--inquiry", tostring(duration), "--format", "json"}):start()
  end

  scan(2)
end

bluetoothModal:bind({}, "a", function() switchToAirPods() ; bluetoothModal:exit() end)
bluetoothModal:bind({}, "m", function() switchToBuiltIn() ; bluetoothModal:exit() end)
bluetoothModal:bind({}, "s", function() selectAudioDevice() ; bluetoothModal:exit() end)
bluetoothModal:bind({}, "p", function() pairNewDevice() ; bluetoothModal:exit() end)
bluetoothModal:bind({}, "escape", function() bluetoothModal:exit() end)
