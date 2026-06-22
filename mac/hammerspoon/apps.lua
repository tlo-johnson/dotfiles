local apps = {
  c = "com.openai.chat",
  f = "com.apple.finder",
  w = "net.whatsapp.WhatsApp",
}

local utils = require("utils")
local projects = require("projects")

local appLauncher = utils.createModal("F13", "Apps")

for key, app in pairs(apps) do
  appLauncher:bind({}, key, function()
    hs.application.launchOrFocusByBundleID(app)
    appLauncher:exit()
  end)
end

appLauncher:bind({}, "b", function()
  print(hs.application.frontmostApplication():bundleID())
  local browserIds = { "com.google.Chrome", "org.mozilla.firefox" }
  local currentSpace = hs.spaces.focusedSpace()
  for _, bundleId in ipairs(browserIds) do
    for _, app in ipairs(hs.application.applicationsForBundleID(bundleId)) do
      for _, win in ipairs(app:allWindows()) do
        for _, ws in ipairs(hs.spaces.windowSpaces(win) or {}) do
          if ws == currentSpace then
            win:focus()
            appLauncher:exit()
            return
          end
        end
      end
    end
  end
  appLauncher:exit()
end)

appLauncher:bind({}, "t", function()
  local win = projects.ghosttyWindowOnCurrentSpace()
  if win then
    win:focus()
  else
    hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty")
  end
  appLauncher:exit()
end)

appLauncher:bind({}, "p", function()
  hs.application.launchOrFocusByBundleID("app.tuple.app")
  appLauncher:exit()
end)


appLauncher:bind({}, "n", function()
  local script = os.getenv("HOME") .. "/.hammerspoon/scripts/capture"
  hs.task.new("/bin/zsh", nil, { "-lc", script }):start()

  appLauncher:exit()
end)

