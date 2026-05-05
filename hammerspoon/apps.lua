local apps = {
  c = "com.openai.chat",
  f = "com.apple.finder",
  b = "com.google.chrome",
  m = "com.apple.mail",
  w = "net.whatsapp.WhatsApp",
}

local utils = require("utils")
local projects = require("projects")

local appLauncher = hs.hotkey.modal.new({}, "F13")

function appLauncher:entered()
  utils.showAlert("Apps")
end

function appLauncher:exited()
  utils.hideAlert()
end

for key, app in pairs(apps) do
  appLauncher:bind({}, key, function()
    hs.application.launchOrFocusByBundleID(app)
    appLauncher:exit()
  end)
end

appLauncher:bind({}, "t", function()
  local win = projects.ghosttyWindowOnCurrentSpace()
  if win then
    win:focus()
  else
    hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty")
  end
  appLauncher:exit()
end)

appLauncher:bind({}, "escape", function()
  appLauncher:exit()
end)

appLauncher:bind({}, "n", function()
  local script = os.getenv("HOME") .. "/.hammerspoon/scripts/capture"
  hs.task.new("/bin/zsh", nil, { "-lc", script }):start()

  appLauncher:exit()
end)

