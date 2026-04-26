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

local function exists(path)
  return hs.fs.attributes(path) ~= nil
end

local function readSpaces()
  local direct, parents = {}, {}
  for _, line in ipairs(readLines(CONFIG .. "/spaces")) do
    local p, n = line:match("^(.+)%s+(%d+)$")
    if p and n then
      if p:sub(1, 1) == "=" then
        direct[p:sub(2)] = tonumber(n)
      else
        parents[#parents + 1] = { path = p, space = tonumber(n) }
      end
    end
  end
  return direct, parents
end

local function lookupSpace(path)
  local direct, parents = readSpaces()
  if direct[path] then return direct[path] end
  for _, entry in ipairs(parents) do
    if path == entry.path or path:sub(1, #entry.path + 1) == entry.path .. "/" then
      return entry.space
    end
  end
end

local function switchToSpace(n)
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  if spaces and spaces[n] then hs.spaces.gotoSpace(spaces[n]) end
end

local function ghosttyWindowOnCurrentSpace()
  local apps = hs.application.applicationsForBundleID("com.mitchellh.ghostty")
  local currentSpace = hs.spaces.focusedSpace()
  for _, app in ipairs(apps) do
    for _, win in ipairs(app:allWindows()) do
      for _, ws in ipairs(hs.spaces.windowSpaces(win) or {}) do
        if ws == currentSpace then return win end
      end
    end
  end
  return nil
end

local function switchToProject(path)
  local recentsFile = CONFIG .. "/recents"
  local seen, result = { [path] = true }, { path }
  for _, p in ipairs(readLines(recentsFile)) do
    if not seen[p] then seen[p] = true; result[#result + 1] = p end
    if #result >= 50 then break end
  end
  writeLines(recentsFile, result)

  local name = path:match("([^/]+)$"):gsub("%.", "_")

  hs.task.new("/bin/zsh", nil, { "-lc", string.format(
    "tmux has-session -t '=%s' 2>/dev/null || tmux new-session -ds '%s' -c '%s'",
    name, name, path
  )}):start()

  local function focus()
    local win = ghosttyWindowOnCurrentSpace()
    if win then
      win:focus()
      hs.execute("/bin/zsh -lc 'tmux switch-client -t " .. name .. "'")
    else
      local wf
      wf = hs.window.filter.new({"Ghostty"}):subscribe(hs.window.filter.windowCreated, function(win)
        wf:unsubscribeAll()
        win:focus()
        hs.eventtap.keyStrokes("tmux attach-session -t " .. name)
        hs.eventtap.keyStroke({}, "return")
      end)
      local apps = hs.application.applicationsForBundleID("com.mitchellh.ghostty")
      if #apps > 0 then
        apps[1]:selectMenuItem({"File", "New Window"})
      else
        hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty")
      end
    end
  end

  local spaceN = lookupSpace(path)
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  local alreadyOnSpace = spaceN and spaces and spaces[spaceN] == hs.spaces.focusedSpace()

  if spaceN and not alreadyOnSpace then
    local watcher
    watcher = hs.spaces.watcher.new(function()
      watcher:stop()
      focus()
    end)
    watcher:start()
    switchToSpace(spaceN)
  else
    focus()
  end
end

local function buildChoices()
  local ignoreFile = CONFIG .. "/ignore"
  if not exists(ignoreFile) then
    hs.execute("mkdir -p " .. CONFIG)
    writeLines(ignoreFile, { "node_modules" })
  end
  local ignore = readLines(ignoreFile)

  local recentsFile = CONFIG .. "/recents"
  local recents = {}
  for _, p in ipairs(readLines(recentsFile)) do
    if exists(p) then recents[#recents + 1] = p end
  end
  writeLines(recentsFile, recents)

  local direct, parent = {}, {}
  for _, line in ipairs(readLines(CONFIG .. "/dirs")) do
    if line:sub(1, 1) == "=" then
      direct[#direct + 1] = line:sub(2)
    else
      parent[#parent + 1] = line
    end
  end

  local found = ""
  if #parent > 0 then
    found = hs.execute(
      "find " .. table.concat(parent, " ") .. " -mindepth 1 -maxdepth 1 -type d -not -name '.*' 2>/dev/null"
    )
  end

  local seen, choices = {}, {}
  local function add(path)
    if path == "" or seen[path] or not exists(path) then return end
    for _, pat in ipairs(ignore) do
      if ("/" .. path .. "/"):find("/" .. pat .. "/", 1, true) then return end
    end
    seen[path] = true
    choices[#choices + 1] = { text = path:match("([^/]+)$"), subText = path, path = path }
  end

  for _, p in ipairs(recents) do add(p) end
  for _, p in ipairs(direct) do add(p) end
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

local function show()
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

hs.hotkey.bind({}, "F18", show)

return {
  show = show
}
