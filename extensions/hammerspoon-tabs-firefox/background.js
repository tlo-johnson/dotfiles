const IS_FIREFOX = navigator.userAgent.includes('Firefox');
const api = IS_FIREFOX ? browser : chrome;
const WS_URL = 'ws://localhost:27124';
const BROWSER = IS_FIREFOX ? 'firefox' : 'chrome';

let ws = null;
let wsReady = false;

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

async function getClientId() {
  const result = await api.storage.local.get('clientId');
  if (result.clientId) return result.clientId;
  const id = BROWSER + ':' + crypto.randomUUID();
  await api.storage.local.set({ clientId: id });
  return id;
}

function wsSend(data) {
  if (ws && wsReady) {
    ws.send(JSON.stringify(data));
  }
}

function connect() {
  if (ws && (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN)) return;

  ws = new WebSocket(WS_URL);

  ws.onopen = async () => {
    wsReady = true;
    const clientId = await getClientId();
    wsSend({ type: 'register', id: clientId });
    const tabs = await getAllTabs();
    wsSend({ type: 'tabs_all', browser: BROWSER, tabs });
  };

  ws.onclose = () => {
    wsReady = false;
    ws = null;
  };

  ws.onerror = () => {};

  ws.onmessage = ({ data }) => {
    let msg;
    try { msg = JSON.parse(data); } catch { return; }
    if (msg.type === 'focus') {
      api.tabs.update(msg.tabId, { active: true });
      api.windows.update(msg.windowId, { focused: true });
    }
  };
}

if (!IS_FIREFOX) {
  chrome.alarms.create('keepalive', { periodInMinutes: 25 / 60 });
  chrome.alarms.onAlarm.addListener(alarm => {
    if (alarm.name === 'keepalive') connect();
  });
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
