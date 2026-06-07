local M = {}
local projects = require("projects")
local tabs     = require("tabs")

local HOME        = os.getenv("HOME")
local RECENTS     = HOME .. "/.config/tlo/projects/switcher-recents"

local fzfPath = hs.execute("command -v fzf 2>/dev/null"):gsub("%s+$", "")
if fzfPath == "" then fzfPath = "/opt/homebrew/bin/fzf" end

local inputFile      = os.tmpname()
local allChoices     = {}
local pendingChoices = {}

local function readRecents()
  local timestamps = {}
  local f = io.open(RECENTS, "r")
  if not f then return timestamps end
  for line in f:lines() do
    local ts, key = line:match("^(%d+)\t(.+)$")
    if ts and key then timestamps[key] = tonumber(ts) end
  end
  f:close()
  return timestamps
end

local function writeRecents(timestamps)
  local entries = {}
  for key, ts in pairs(timestamps) do
    entries[#entries + 1] = { key = key, ts = ts }
  end
  table.sort(entries, function(a, b) return a.ts > b.ts end)
  local f = io.open(RECENTS, "w")
  if not f then return end
  for i = 1, math.min(#entries, 50) do
    f:write(entries[i].ts .. "\t" .. entries[i].key .. "\n")
  end
  f:close()
end

local function recordRecent(key)
  local timestamps = readRecents()
  timestamps[key] = os.time()
  writeRecents(timestamps)
end

local chooser = hs.chooser.new(function(choice)
  if not choice then pendingChoices = {}; return end
  local pending = pendingChoices[choice.uuid]
  pendingChoices = {}
  if not pending then return end
  if pending._source == "project" then
    recordRecent(pending.path)
    projects.activate(pending)
  else
    recordRecent(pending.entry.url)
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

  local timestamps = readRecents()

  local raw = {}

  for _, c in ipairs(projects.buildChoices()) do
    raw[#raw + 1] = { text = c.text, subText = c.subText, key = c.path,
                      pending = { _source = "project", path = c.path } }
  end

  for _, c in ipairs(tabs.buildChoices()) do
    raw[#raw + 1] = { text = c.text, subText = c.subText, key = c.entry.url,
                      pending = { _source = "tab", entry = c.entry } }
  end

  for i, item in ipairs(raw) do item.index = i end

  table.sort(raw, function(a, b)
    local ta, tb = timestamps[a.key] or 0, timestamps[b.key] or 0
    if ta ~= tb then return ta > tb end
    return a.index < b.index
  end)

  for _, item in ipairs(raw) do
    local uuid = hs.host.uuid()
    pendingChoices[uuid] = item.pending
    allChoices[#allChoices + 1] = { text = item.text, subText = item.subText, uuid = uuid }
    lines[#lines + 1] = item.text .. "\t" .. (item.subText or "") .. "\t" .. uuid
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
