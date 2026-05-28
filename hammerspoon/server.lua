local M = {}

local tabById = {}
M.tabStore = {}

local function makeId(browser, tabId, windowId)
  return browser .. ":" .. tostring(tabId) .. ":" .. tostring(windowId)
end

local function rebuildStore()
  local t = {}
  for _, entry in pairs(tabById) do
    t[#t + 1] = entry
  end
  M.tabStore = t
end

local function upsertTab(entry)
  local id = makeId(entry.browser, entry.tabId, entry.windowId)
  entry.id = id
  tabById[id] = entry
  rebuildStore()
end

local function removeTab(browser, tabId, windowId)
  local id = makeId(browser, tabId, windowId)
  tabById[id] = nil
  rebuildStore()
end

local function clearBrowserTabs(browser)
  for id, entry in pairs(tabById) do
    if entry.browser == browser then
      tabById[id] = nil
    end
  end
  rebuildStore()
end

local function handleMessage(raw)
  local ok, msg = pcall(hs.json.decode, raw)
  if not ok or not msg or not msg.browser then return end

  if msg.type == "tabs_all" then
    clearBrowserTabs(msg.browser)
    for _, t in ipairs(msg.tabs or {}) do
      upsertTab({
        browser  = msg.browser,
        tabId    = t.id,
        windowId = t.windowId,
        tabIndex = t.index,
        title    = t.title or "",
        url      = t.url or "",
      })
    end
  elseif msg.type == "tab_upsert" then
    local t = msg.tab
    if t then
      upsertTab({
        browser  = msg.browser,
        tabId    = t.id,
        windowId = t.windowId,
        tabIndex = t.index,
        title    = t.title or "",
        url      = t.url or "",
      })
    end
  elseif msg.type == "tab_removed" then
    removeTab(msg.browser, msg.tabId, msg.windowId)
  end
end

local httpServer = nil

function M.focusTab(entry)
  if httpServer then
    httpServer:send(hs.json.encode({
      type     = "focus",
      browser  = entry.browser,
      tabId    = entry.tabId,
      windowId = entry.windowId,
    }))
  end
  local bundleIds = {
    chrome  = "com.google.Chrome",
    firefox = "org.mozilla.firefox",
  }
  local bid = bundleIds[entry.browser]
  if bid then hs.application.launchOrFocusByBundleID(bid) end
end

function M.stop()
  if httpServer then
    httpServer:stop()
    httpServer = nil
  end
  tabById = {}
  M.tabStore = {}
end

function M.start()
  M.stop()

  httpServer = hs.httpserver.new(false, false)
  httpServer:setPort(27124)
  httpServer:websocket("/", function(message)
    if message == "open" then
      -- connection established
    elseif message == "close" then
      -- tabs refreshed when browser reconnects and sends tabs_all
    else
      handleMessage(message)
    end
    return ""
  end)
  httpServer:start()
end

return M
