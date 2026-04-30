local opPath = hs.execute("command -v op 2>/dev/null"):gsub("%s+$", "")
if opPath == "" then opPath = "/opt/homebrew/bin/op" end

local allChoices = {}
local clearTimer = nil
local CLEAR_AFTER = 15

local function copyValue(value, label)
  hs.pasteboard.setContents(value)
  hs.notify.new({title = "1Password", informativeText = "Copied " .. label .. " (clears in " .. CLEAR_AFTER .. "s)"}):send()
  if clearTimer then clearTimer:stop() end
  clearTimer = hs.timer.doAfter(CLEAR_AFTER, function()
    if hs.pasteboard.getContents() == value then
      hs.pasteboard.setContents("")
      hs.notify.new({title = "1Password", informativeText = "Clipboard cleared"}):send()
    end
  end)
end

local fieldChooser = hs.chooser.new(function(choice)
  if not choice then return end
  copyValue(choice.value, choice.text)
end)
fieldChooser:placeholderText("Select field…")

local chooser = hs.chooser.new(function(choice)
  if not choice then return end
  hs.task.new(opPath, function(code, stdout, stderr)
    if code ~= 0 then
      hs.notify.new({title = "1Password", informativeText = "Error: " .. (stderr or "unknown")}):send()
      return
    end
    local ok, item = pcall(hs.json.decode, stdout)
    if not ok or not item or not item.fields then return end

    local fields = {}
    for _, f in ipairs(item.fields) do
      if f.value and f.value ~= "" then
        local label = f.label or f.id or "unknown"
        local subText = f.type or ""
        if f.purpose == "PASSWORD" then subText = subText .. " (password)" end
        fields[#fields + 1] = { text = label, subText = subText, value = f.value }
      end
    end

    if #fields == 0 then
      hs.notify.new({title = "1Password", informativeText = "No fields found"}):send()
    elseif #fields == 1 then
      copyValue(fields[1].value, fields[1].text)
    else
      fieldChooser:choices(fields)
      fieldChooser:query("")
      fieldChooser:show()
    end
  end, {"item", "get", choice.id, "--format", "json", "--reveal"}):start()
end)

chooser:placeholderText("1Password…")
chooser:queryChangedCallback(function(query)
  if query == "" then chooser:choices(allChoices); return end
  local q = query:lower()
  local results = {}
  for _, c in ipairs(allChoices) do
    if c.text:lower():find(q, 1, true) or (c.subText and c.subText:lower():find(q, 1, true)) then
      results[#results + 1] = c
    end
  end
  chooser:choices(results)
end)

local function show()
  hs.task.new(opPath, function(code, stdout, stderr)
    if code ~= 0 then
      hs.notify.new({title = "1Password", informativeText = "op error: " .. (stderr or "")}):send()
      return
    end
    local ok, items = pcall(hs.json.decode, stdout)
    if not ok or not items then return end
    allChoices = {}
    for _, item in ipairs(items) do
      allChoices[#allChoices + 1] = {
        text = item.title,
        subText = item.vault and item.vault.name or "",
        id = item.id,
      }
    end
    chooser:choices(allChoices)
    chooser:query("")
    chooser:show()
  end, {"item", "list", "--format=json"}):start()
end

hs.hotkey.bind({}, "F19", show)

return { show = show }
