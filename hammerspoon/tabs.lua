local M = {}
local server = require("server")

-- hs.chooser only round-trips text/subText/image/uuid/valid — store entries by uuid
local pendingEntries = {}

function M.showTabChooser()
  pendingEntries = {}
  local choices = {}

  for _, entry in ipairs(server.tabStore) do
    local uuid = hs.host.uuid()
    pendingEntries[uuid] = entry
    table.insert(choices, {
      text    = (entry.title ~= "" and entry.title) or entry.url,
      subText = "[" .. entry.browser .. "] " .. entry.url,
      uuid    = uuid,
    })
  end

  if #choices == 0 then
    hs.notify.new({
      title           = "Tabs",
      informativeText = "No browser tabs — are the extensions connected?",
    }):send()
    return
  end

  local chooser = hs.chooser.new(function(choice)
    if not choice then
      pendingEntries = {}
      return
    end
    local entry = pendingEntries[choice.uuid]
    if entry then server.focusTab(entry) end
    pendingEntries = {}
  end)

  chooser:choices(choices)
  chooser:placeholderText("Search browser tabs…")
  chooser:show()
end

return M
