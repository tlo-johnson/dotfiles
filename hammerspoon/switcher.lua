local M = {}
local projects = require("projects")
local tabs     = require("tabs")

local fzfPath = hs.execute("command -v fzf 2>/dev/null"):gsub("%s+$", "")
if fzfPath == "" then fzfPath = "/opt/homebrew/bin/fzf" end

local inputFile   = os.tmpname()
local allChoices  = {}
local pendingChoices = {}

local chooser = hs.chooser.new(function(choice)
  if not choice then pendingChoices = {}; return end
  local pending = pendingChoices[choice.uuid]
  pendingChoices = {}
  if not pending then return end
  if pending._source == "project" then
    projects.activate(pending)
  else
    tabs.activate(pending)
  end
end)

chooser:placeholderText("Switch to project or tab…")
chooser:queryChangedCallback(function(query)
  if query == "" then chooser:choices(allChoices); return end
  local escaped = query:gsub("'", "'\\''")
  local stdout = hs.execute(
    fzfPath .. " --filter='" .. escaped .. "' --delimiter='\t' --scheme=path < " .. inputFile
  )
  local uuidToChoice = {}
  for _, c in ipairs(allChoices) do uuidToChoice[c.uuid] = c end
  local results = {}
  for line in stdout:gmatch("[^\n]+") do
    local uuid = line:match("\t([^\t\n]+)$")
    if uuid and uuidToChoice[uuid] then
      results[#results + 1] = uuidToChoice[uuid]
    end
  end
  chooser:choices(results)
end)

function M.show()
  pendingChoices = {}
  allChoices    = {}
  local lines   = {}

  for _, c in ipairs(projects.buildChoices()) do
    local uuid = hs.host.uuid()
    pendingChoices[uuid] = { _source = "project", path = c.path, url = c.url }
    allChoices[#allChoices + 1] = { text = c.text, subText = c.subText, uuid = uuid }
    lines[#lines + 1] = c.text .. "\t" .. (c.subText or "") .. "\t" .. uuid
  end

  for _, c in ipairs(tabs.buildChoices()) do
    local uuid = hs.host.uuid()
    pendingChoices[uuid] = { _source = "tab", entry = c.entry }
    allChoices[#allChoices + 1] = { text = c.text, subText = c.subText, uuid = uuid }
    lines[#lines + 1] = c.text .. "\t" .. (c.subText or "") .. "\t" .. uuid
  end

  local f = io.open(inputFile, "w")
  f:write(table.concat(lines, "\n"))
  f:close()

  chooser:choices(allChoices)
  chooser:query("")
  chooser:show()
end

hs.hotkey.bind({}, "F18", M.show)

return M
