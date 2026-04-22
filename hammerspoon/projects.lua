local DIRS_FILE    = os.getenv("HOME") .. "/.config/tlo/sessionizer-dirs"
local RECENTS_FILE = os.getenv("HOME") .. "/.config/tlo/sessionizer-recents"

local function readLines(path)
  local lines = {}
  local f = io.open(path, "r")
  if not f then return lines end
  for line in f:lines() do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^#") then
      lines[#lines + 1] = line:gsub("%$HOME", os.getenv("HOME"))
    end
  end
  f:close()
  return lines
end

local function writeLines(path, lines)
  local f = io.open(path, "w")
  if not f then return end
  for _, l in ipairs(lines) do f:write(l .. "\n") end
  f:close()
end

local function updateRecents(selected)
  local existing = readLines(RECENTS_FILE)
  local seen, result = {}, {}
  table.insert(existing, 1, selected)
  for _, p in ipairs(existing) do
    if not seen[p] then
      seen[p] = true
      result[#result + 1] = p
      if #result >= 50 then break end
    end
  end
  writeLines(RECENTS_FILE, result)
end

local function switchToProject(path)
  updateRecents(path)
  local name = path:match("([^/]+)$"):gsub("%.", "_")
  local cmd = string.format(
    "tmux has-session -t '=%s' 2>/dev/null || tmux new-session -ds '%s' -c '%s'; tmux switch-client -t '=%s'",
    name, name, path, name
  )
  hs.task.new("/bin/zsh", nil, { "-lc", cmd }):start()
  hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty")
end

local function buildChoices()
  local recents = readLines(RECENTS_FILE)
  local recentSet = {}
  for _, p in ipairs(recents) do recentSet[p] = true end

  local dirs = readLines(DIRS_FILE)
  local allDirs, _ = hs.execute(
    "find " .. table.concat(dirs, " ") .. " -mindepth 1 -maxdepth 2 -type d 2>/dev/null"
  )

  local seen, choices = {}, {}

  local function addChoice(path)
    path = path:gsub("%s+$", "")
    if path == "" or seen[path] then return end
    seen[path] = true
    choices[#choices + 1] = {
      text    = path:match("([^/]+)$"),
      subText = path,
      path    = path,
    }
  end

  for _, p in ipairs(recents) do addChoice(p) end
  for p in allDirs:gmatch("[^\n]+") do
    if not recentSet[p] then addChoice(p) end
  end

  return choices
end

local chooser = hs.chooser.new(function(choice)
  if choice then switchToProject(choice.path) end
end)
chooser:placeholderText("Open project…")
chooser:searchSubText(true)

return {
  show = function()
    chooser:choices(buildChoices())
    chooser:show()
  end
}
