-- Capture: Hyper+N (Cmd+Ctrl+Alt+Shift+N) runs ~/.hammerspoon/scripts/capture
-- Uses zsh so PATH variable is loaded, since `nvim` is used in the script
hs.hotkey.bind({}, "F14", function()
  local script = os.getenv("HOME") .. "/.hammerspoon/scripts/capture"
  hs.task.new("/bin/zsh", nil, { "-lc", script }):start()
end)

local apps = {
  c = "com.openai.chat",
  f = "com.apple.finder",
  t = "com.mitchellh.ghostty",
  b = "com.google.chrome",
  m = "com.apple.mail",
  w = "net.whatsapp.WhatsApp",
}

local appLauncher = hs.hotkey.modal.new({}, "F13")

function appLauncher:entered()
  hs.alert.show("Apps")
end

function appLauncher:exited()
end

for key, app in pairs(apps) do
  appLauncher:bind({}, key, function()
    hs.application.launchOrFocusByBundleID(app)
    appLauncher:exit()
  end)
end

appLauncher:bind({}, "escape", function()
  appLauncher:exit()
end)
