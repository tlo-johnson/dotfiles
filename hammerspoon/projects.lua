-- ~/.config/tlo/projects/dirs syntax:
--   path            scan directory for immediate subdirs
--   =path           add path directly (not scanned)
--   path N / =path N  assign to macOS space N
--   !pattern        ignore directories matching pattern
-- ~/.config/tlo/projects/recents is auto-managed.

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

local function parseDirs()
  local direct, parents, ignore = {}, {}, {}
  for _, line in ipairs(readLines(CONFIG .. "/dirs")) do
    if line:sub(1, 1) == "!" then
      ignore[#ignore + 1] = line:sub(2)
    else
      local isDirect = line:sub(1, 1) == "="
      local rest = isDirect and line:sub(2) or line
      local path, space = rest:match("^(.-)%s+(%d+)$")
      if not path then path = rest end
      local entry = { path = path, space = space and tonumber(space) }
      if isDirect then direct[#direct + 1] = entry
      else parents[#parents + 1] = entry end
    end
  end
  return direct, parents, ignore
end

local function lookupSpace(path)
  local direct, parents = parseDirs()
  for _, e in ipairs(direct) do
    if e.space and e.path == path then return e.space end
  end
  for _, e in ipairs(parents) do
    if e.space and (path == e.path or path:sub(1, #e.path + 1) == e.path .. "/") then
      return e.space
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

  local sessionReady = false
  local pendingFocus = nil

  hs.task.new("/bin/zsh", function()
    sessionReady = true
    if pendingFocus then pendingFocus() end
  end, { "-lc", string.format(
    "tmux has-session -t '=%s' 2>/dev/null || tmux new-session -ds '%s' -c '%s'",
    name, name, path
  )}):start()

  local function focus()
    local win = ghosttyWindowOnCurrentSpace()
    if win then
      win:focus()
      local function doSwitch()
        local pid = win:application():pid()
        local ttyOut = hs.execute(string.format(
          "ps -eo ppid,tty | awk '$1 == %d && $2 != \"??\" {print $2; exit}'", pid
        ))
        local tty = ttyOut:match("(ttys%d+)")
        local clientArg = tty and ("-c /dev/" .. tty .. " ") or ""
        hs.execute("/bin/zsh -lc 'tmux switch-client " .. clientArg .. "-t " .. name .. "'")
      end
      if sessionReady then doSwitch() else pendingFocus = doSwitch end
    else
      local wf
      wf = hs.window.filter.new({"Ghostty"}):subscribe(hs.window.filter.windowCreated, function(win)
        wf:unsubscribeAll()
        win:focus()
        hs.eventtap.keyStrokes("tmux attach-session -t " .. name)
        hs.eventtap.keyStroke({}, "return")
      end)
      hs.execute("open -na /Applications/Ghostty.app")
    end
  end

  local spaceN = lookupSpace(path)
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  local alreadyOnSpace = spaceN and spaces and spaces[spaceN] == hs.spaces.focusedSpace()

  if spaceN and not alreadyOnSpace then
    local watcher
    watcher = hs.spaces.watcher.new(function()
      watcher:stop()
      hs.timer.doAfter(0.15, focus)
    end)
    watcher:start()
    switchToSpace(spaceN)
  else
    focus()
  end
end

local function buildChoices()
  local recentsFile = CONFIG .. "/recents"
  local recents = {}
  for _, p in ipairs(readLines(recentsFile)) do
    if exists(p) then recents[#recents + 1] = p end
  end
  writeLines(recentsFile, recents)

  local directEntries, parentEntries, ignore = parseDirs()
  local direct, parent = {}, {}
  for _, e in ipairs(directEntries) do direct[#direct + 1] = e.path end
  for _, e in ipairs(parentEntries) do parent[#parent + 1] = e.path end

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
  chooser:query("")
  chooser:show()
end

hs.hotkey.bind({}, "F18", show)

return {
  show = show
}
