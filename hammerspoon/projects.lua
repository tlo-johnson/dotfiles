local HOME   = os.getenv("HOME")
local CONFIG = HOME .. "/.config/tlo/projects"

local function readLines(path)
  local lines, f = {}, io.open(path, "r")
  if not f then return lines end
  for line in f:lines() do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^#") then
      lines[#lines + 1] = line:gsub("%$HOME", HOME)
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

local function switchToProject(path)
  -- prepend to recents, dedupe, cap at 50
  local recentsFile = CONFIG .. "/recents"
  local seen, result = { [path] = true }, { path }
  for _, p in ipairs(readLines(recentsFile)) do
    if not seen[p] then seen[p] = true; result[#result + 1] = p end
    if #result >= 50 then break end
  end
  writeLines(recentsFile, result)

  local name = path:match("([^/]+)$"):gsub("%.", "_")

  local ghosttyRunning = hs.application.get("com.mitchellh.ghostty") ~= nil
  local hasTmuxClient  = hs.execute("/bin/zsh -lc 'tmux list-clients 2>/dev/null'"):gsub("%s+$", "") ~= ""

  hs.task.new("/bin/zsh", nil, { "-lc", string.format(
    "tmux has-session -t '=%s' 2>/dev/null || tmux new-session -ds '%s' -c '%s'%s",
    name, name, path,
    hasTmuxClient and ("; tmux switch-client -t '=" .. name .. "'") or ""
  )}):start()

  hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty")

  if not hasTmuxClient then
    hs.timer.doAfter(ghosttyRunning and 0.3 or 1, function()
      local app = hs.application.get("com.mitchellh.ghostty")
      if app then app:activate() end
      hs.eventtap.keyStrokes("tmux attach-session -t " .. name)
      hs.eventtap.keyStroke({}, "return")
    end)
  end
end

local function buildChoices()
  local ignoreFile = CONFIG .. "/ignore"
  if not io.open(ignoreFile, "r") then
    hs.execute("mkdir -p " .. CONFIG)
    writeLines(ignoreFile, { "node_modules" })
  end
  local ignore  = readLines(ignoreFile)
  local recents = readLines(CONFIG .. "/recents")
  local dirs    = readLines(CONFIG .. "/dirs")
  local found   = hs.execute(
    "find " .. table.concat(dirs, " ") .. " -mindepth 1 -maxdepth 2 -type d 2>/dev/null"
  )

  local seen, choices = {}, {}
  local function add(path)
    path = path:gsub("%s+$", "")
    if path == "" or seen[path] then return end
    for _, pat in ipairs(ignore) do
      for component in path:gmatch("[^/]+") do
        if component == pat then return end
      end
    end
    seen[path] = true
    choices[#choices + 1] = { text = path:match("([^/]+)$"), subText = path, path = path }
  end

  for _, p in ipairs(recents) do add(p) end
  for p in found:gmatch("[^\n]+") do add(p) end
  return choices
end

local fzfPath = hs.execute("command -v fzf 2>/dev/null"):gsub("%s+$", "")
if fzfPath == "" then fzfPath = "/opt/homebrew/bin/fzf" end

local inputFile = os.tmpname()
local allChoices = {}
local pathToChoice = {}

local chooser = hs.chooser.new(function(choice)
  if choice then switchToProject(choice.path) end
end)
chooser:placeholderText("Open project…")
chooser:queryChangedCallback(function(query)
  if query == "" then chooser:choices(allChoices); return end
  local escaped = query:gsub("'", "'\\''")
  local stdout = hs.execute(fzfPath .. " --filter='" .. escaped .. "' --scheme=path < " .. inputFile)
  local results = {}
  for line in stdout:gmatch("[^\n]+") do
    if pathToChoice[line] then results[#results + 1] = pathToChoice[line] end
  end
  chooser:choices(results)
end)

return {
  show = function()
    allChoices = buildChoices()
    pathToChoice = {}
    local lines = {}
    for _, c in ipairs(allChoices) do
      pathToChoice[c.path] = c
      lines[#lines + 1] = c.path
    end
    local f = io.open(inputFile, "w")
    f:write(table.concat(lines, "\n"))
    f:close()
    chooser:choices(allChoices)
    chooser:show()
  end
}
