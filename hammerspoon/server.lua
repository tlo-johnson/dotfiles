local M = {}

local tabById = {}
M.tabStore = {}

local ws = nil
local reconnectTimer = nil

local function makeId(clientId, tabId, windowId)
  return clientId .. ":" .. tostring(tabId) .. ":" .. tostring(windowId)
end

local function rebuildStore()
  local t = {}
  for _, entry in pairs(tabById) do
    t[#t + 1] = entry
  end
  M.tabStore = t
end

local function upsertTab(entry)
  local id = makeId(entry.clientId, entry.tabId, entry.windowId)
  entry.id = id
  tabById[id] = entry
  rebuildStore()
end

local function removeTab(clientId, tabId, windowId)
  local id = makeId(clientId, tabId, windowId)
  tabById[id] = nil
  rebuildStore()
end

local function clearClientTabs(clientId)
  for id, entry in pairs(tabById) do
    if entry.clientId == clientId then
      tabById[id] = nil
    end
  end
  rebuildStore()
end

local function makeEntry(clientId, browser, t)
  return {
    clientId = clientId,
    browser  = browser,
    tabId    = t.id,
    windowId = t.windowId,
    tabIndex = t.index,
    title    = t.title or "",
    url      = t.url or "",
  }
end

local function handleMessage(raw)
  local ok, msg = pcall(hs.json.decode, raw)
  if not ok or not msg then return end

  if msg.type == "state_sync" then
    tabById = {}
    for _, t in ipairs(msg.tabs or {}) do
      local entry = makeEntry(t.clientId, t.browser, t)
      local id = makeId(t.clientId, t.id, t.windowId)
      entry.id = id
      tabById[id] = entry
    end
    rebuildStore()
  elseif msg.type == "tabs_all" then
    for id, entry in pairs(tabById) do
      if entry.clientId == msg.clientId then tabById[id] = nil end
    end
    for _, t in ipairs(msg.tabs or {}) do
      local entry = makeEntry(msg.clientId, msg.browser, t)
      local id = makeId(msg.clientId, t.id, t.windowId)
      entry.id = id
      tabById[id] = entry
    end
    rebuildStore()
  elseif msg.type == "tab_upsert" then
    local t = msg.tab
    if t then upsertTab(makeEntry(msg.clientId, msg.browser, t)) end
  elseif msg.type == "tab_removed" then
    removeTab(msg.clientId, msg.tabId, msg.windowId)
  elseif msg.type == "client_disconnected" then
    clearClientTabs(msg.id)
  end
end

local function scheduleReconnect()
  if reconnectTimer then reconnectTimer:stop() end
  reconnectTimer = hs.timer.doAfter(2, M.start)
end

function M.focusTab(entry)
  if ws and ws:status() == "open" then
    ws:send(hs.json.encode({
      type     = "focus",
      target   = entry.clientId,
      tabId    = entry.tabId,
      windowId = entry.windowId,
    }))
  end
  if entry.browser == "firefox" then
    hs.application.launchOrFocusByBundleID("org.mozilla.firefox")
  end
end

function M.stop()
  if reconnectTimer then
    reconnectTimer:stop()
    reconnectTimer = nil
  end
  if ws then
    ws:close()
    ws = nil
  end
  tabById = {}
  M.tabStore = {}
end

function M.start()
  M.stop()

  ws = hs.websocket.new("ws://localhost:27124", function(event, message)
    if event == "open" then
      ws:send(hs.json.encode({ type = "register", id = "hammerspoon" }))
    elseif event == "received" then
      handleMessage(message)
    elseif event == "closed" or event == "fail" then
      ws = nil
      scheduleReconnect()
    end
  end)
end

return M
