const IS_FIREFOX = typeof browser !== 'undefined';
const api = IS_FIREFOX ? browser : chrome;
const WS_URL = 'ws://localhost:27124';
const BROWSER = IS_FIREFOX ? 'firefox' : 'chrome';

let ws = null;
let wsReady = false;
let reconnectDelay = 1000;
const MAX_DELAY = 30000;

function serializeTab(tab) {
  return {
    id:       tab.id,
    windowId: tab.windowId,
    index:    tab.index,
    title:    tab.title || '',
    url:      tab.url || '',
    active:   tab.active,
  };
}

async function getAllTabs() {
  const wins = await api.windows.getAll({ populate: true });
  return wins.flatMap(w => (w.tabs || []).map(serializeTab));
}

function wsSend(data) {
  if (ws && wsReady) {
    ws.send(JSON.stringify(data));
  }
}

function connect() {
  ws = new WebSocket(WS_URL);

  ws.onopen = async () => {
    wsReady = true;
    reconnectDelay = 1000;
    const tabs = await getAllTabs();
    wsSend({ type: 'tabs_all', browser: BROWSER, tabs });
  };

  ws.onclose = () => {
    wsReady = false;
    ws = null;
    setTimeout(connect, reconnectDelay);
    reconnectDelay = Math.min(reconnectDelay * 2, MAX_DELAY);
  };

  ws.onerror = () => {};

  ws.onmessage = ({ data }) => {
    let msg;
    try { msg = JSON.parse(data); } catch { return; }
    if (msg.type === 'focus' && msg.browser === BROWSER) {
      api.tabs.update(msg.tabId, { active: true });
      api.windows.update(msg.windowId, { focused: true });
    }
  };
}

api.tabs.onCreated.addListener(tab => {
  wsSend({ type: 'tab_upsert', browser: BROWSER, tab: serializeTab(tab) });
});

api.tabs.onUpdated.addListener((_id, change, tab) => {
  if (change.title !== undefined || change.url !== undefined || change.status === 'complete') {
    wsSend({ type: 'tab_upsert', browser: BROWSER, tab: serializeTab(tab) });
  }
});

api.tabs.onRemoved.addListener((tabId, info) => {
  wsSend({ type: 'tab_removed', browser: BROWSER, tabId, windowId: info.windowId });
});

connect();
