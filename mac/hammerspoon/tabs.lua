local M = {}
local store = require("browser-tab-store")

function M.buildChoices()
  local choices = {}
  for _, entry in ipairs(store.tabStore) do
    choices[#choices + 1] = {
      text    = (entry.title ~= "" and entry.title) or entry.url,
      subText = "[" .. entry.browser .. "] " .. entry.url,
      entry   = entry,
    }
  end
  return choices
end

function M.activate(choice)
  store.focusTab(choice.entry)
end

function M.showTabChooser()
  local choices = M.buildChoices()
  if #choices == 0 then
    hs.notify.new({
      title           = "Browser Tabs",
      informativeText = "No browser tabs — are the extensions connected?",
    }):send()
    return
  end

  local pending = {}
  local chooserChoices = {}
  for _, c in ipairs(choices) do
    local uuid = hs.host.uuid()
    pending[uuid] = c
    chooserChoices[#chooserChoices + 1] = { text = c.text, subText = c.subText, uuid = uuid }
  end

  local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    M.activate(pending[choice.uuid])
  end)
  chooser:choices(chooserChoices)
  chooser:placeholderText("Search browser tabs…")
  chooser:show()
end

return M
