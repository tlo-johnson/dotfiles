-- ~/.config/tlo/projects/dirs sections:
--
-- [directories]
--   path              scan directory for immediate subdirs
--   =path             add path directly (not scanned)
--   path -> N         assign to macOS space N
--   path -> P         link to Chrome profile directory P
--   path -> N -> P    space N and Chrome profile P
--   !pattern          ignore directories matching pattern
--
-- [urls]
--   https://... -> ProfileDir   open this URL when switching to that Chrome profile
--
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

local function parseSections()
  local sections, current = {}, nil
  for _, line in ipairs(readLines(CONFIG .. "/dirs")) do
    local section = line:match("^%[(.-)%]$")
    if section then
      current = section
      sections[current] = sections[current] or {}
    elseif current then
      sections[current][#sections[current] + 1] = line
    end
  end
  return sections
end

local function parseDirs()
  local sections = parseSections()
  local direct, parents, ignore = {}, {}, {}
  for _, line in ipairs(sections["directories"] or {}) do
    if line:sub(1, 1) == "!" then
      ignore[#ignore + 1] = line:sub(2)
    else
      local isDirect = line:sub(1, 1) == "="
      local rest = isDirect and line:sub(2) or line
      local segments = {}
      for seg in (rest .. "->"):gmatch("(.-)%s*->%s*") do
        seg = seg:gsub("^%s+", ""):gsub("%s+$", "")
        if seg ~= "" then segments[#segments + 1] = seg end
      end
      local path = segments[1] or rest
      local space, chrome
      for i = 2, #segments do
        if segments[i]:match("^%d+$") then space = tonumber(segments[i])
        else chrome = segments[i] end
      end
      local entry = { path = path, space = space, chrome = chrome }
      if isDirect then direct[#direct + 1] = entry
      else parents[#parents + 1] = entry end
    end
  end
  return direct, parents, ignore
end

local function lookupProject(path)
  local direct, parents = parseDirs()
  local space, chrome
  for _, e in ipairs(direct) do
    if e.path == path then
      space = space or e.space
      chrome = chrome or e.chrome
    end
  end
  for _, e in ipairs(parents) do
    if path == e.path or path:sub(1, #e.path + 1) == e.path .. "/" then
      space = space or e.space
      chrome = chrome or e.chrome
    end
  end
  return space, chrome
end

local function chromeWindowFrameForProfile(profile)
  local direct, parents = parseDirs()
  local spaceN
  for _, e in ipairs(direct) do
    if e.chrome and resolveProfile(e.chrome) == resolveProfile(profile) and e.space then
      spaceN = e.space; break
    end
  end
  if not spaceN then
    for _, e in ipairs(parents) do
      if e.chrome and resolveProfile(e.chrome) == resolveProfile(profile) and e.space then
        spaceN = e.space; break
      end
    end
  end
  if not spaceN then return nil end
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  local targetSpaceID = spaces and spaces[spaceN]
  if not targetSpaceID then return nil end
  local chromeApps = hs.application.applicationsForBundleID("com.google.Chrome")
  for _, app in ipairs(chromeApps) do
    for _, win in ipairs(app:allWindows()) do
      for _, ws in ipairs(hs.spaces.windowSpaces(win) or {}) do
        if ws == targetSpaceID then return win:frame() end
      end
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

local chromeProfileMap = nil
local function resolveProfile(name)
  if not chromeProfileMap then
    chromeProfileMap = {}
    local localState = HOME .. "/Library/Application Support/Google/Chrome/Local State"
    local out = hs.execute(string.format(
      "python3 -c \"import json; s=json.load(open('%s')); cache=s['profile']['info_cache']; [print(k+'\\\\t'+v['name']) for k,v in cache.items()]\"",
      localState
    ))
    for dir, profileName in out:gmatch("([^\t\n]+)\t([^\n]+)") do
      chromeProfileMap[profileName:lower()] = dir
      chromeProfileMap[dir:lower()] = dir
    end
  end
  return chromeProfileMap[name:lower()] or name
end

local CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

local function openUrl(url, profile)
  local dir = profile and resolveProfile(profile) or nil
  if dir then
    local frame = chromeWindowFrameForProfile(profile)
    if frame then
      local left   = math.floor(frame.x)
      local top    = math.floor(frame.y)
      local script = string.format([[
        tell application "Google Chrome"
          repeat with w in windows
            set wb to bounds of w
            if item 1 of wb = %d and item 2 of wb = %d then
              repeat with t in tabs of w
                if URL of t starts with "%s" then
                  set active tab index of w to index of t
                  activate
                  return "found"
                end if
              end repeat
              exit repeat
            end if
          end repeat
          return "not found"
        end tell
      ]], left, top, url)
      local _, result = hs.osascript.applescript(script)
      if result == "found" then return end
    end
    hs.execute(string.format('"%s" --profile-directory="%s" "%s" &', CHROME, dir, url))
    return
  end
  local script = string.format([[
    tell application "Google Chrome"
      repeat with w in windows
        repeat with t in tabs of w
          if URL of t starts with "%s" then
            set active tab index of w to index of t
            return "found"
          end if
        end repeat
      end repeat
      return "not found"
    end tell
  ]], url)
  local _, result = hs.osascript.applescript(script)
  if result ~= "found" then
    hs.execute(string.format("open -g 'Google Chrome' '%s'", url))
  end
end

local function switchToChrome(profile)
  local sections = parseSections()
  local urls = {}
  for _, line in ipairs(sections["urls"] or {}) do
    local url, p = line:match("^(https?://%S+)%s*->%s*(.+)$")
    if p == profile then urls[#urls + 1] = url end
  end
  if #urls == 0 then
    hs.execute(string.format('"%s" --profile-directory="%s" &', CHROME, resolveProfile(profile)))
    return
  end
  for _, url in ipairs(urls) do openUrl(url, profile) end
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

  local spaceN, chromeProfile = lookupProject(path)
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  local alreadyOnSpace = spaceN and spaces and spaces[spaceN] == hs.spaces.focusedSpace()

  if spaceN and not alreadyOnSpace then
    local watcher
    watcher = hs.spaces.watcher.new(function()
      watcher:stop()
      hs.timer.doAfter(0.15, function()
        focus()
        if chromeProfile then switchToChrome(chromeProfile) end
      end)
    end)
    watcher:start()
    switchToSpace(spaceN)
  else
    focus()
    if chromeProfile then switchToChrome(chromeProfile) end
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

  local sections = parseSections()
  for _, line in ipairs(sections["urls"] or {}) do
    local url, profile = line:match("^(https?://%S+)%s*->%s*(.+)$")
    if url then
      choices[#choices + 1] = {
        text = url:gsub("^https?://", ""),
        subText = profile,
        url = url,
        profile = profile,
      }
    end
  end

  return choices
end

local fzfPath = hs.execute("command -v fzf 2>/dev/null"):gsub("%s+$", "")
if fzfPath == "" then fzfPath = "/opt/homebrew/bin/fzf" end

local inputFile = os.tmpname()
local allChoices = {}
local pathToChoice = {}

local chooser = hs.chooser.new(function(choice)
  if not choice then return end
  if choice.url then openUrl(choice.url, choice.profile)
  else switchToProject(choice.path) end
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
    local key = c.url or c.path
    pathToChoice[key] = c
    lines[#lines + 1] = key
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
  show = show,
  ghosttyWindowOnCurrentSpace = ghosttyWindowOnCurrentSpace,
}
