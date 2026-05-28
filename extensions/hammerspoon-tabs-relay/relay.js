const WebSocket = require('ws');

const PORT = 27124;
const wss = new WebSocket.Server({ port: PORT });

const clients = new Map(); // clientId -> WebSocket

// Tab state: clientId -> Map<tabKey, tabEntry>
const tabStore = new Map();

function tabKey(tabId, windowId) {
  return `${tabId}:${windowId}`;
}

function upsertTab(clientId, browser, tab) {
  if (!tabStore.has(clientId)) tabStore.set(clientId, new Map());
  tabStore.get(clientId).set(tabKey(tab.id, tab.windowId), { clientId, browser, ...tab });
}

function removeTab(clientId, tabId, windowId) {
  tabStore.get(clientId)?.delete(tabKey(tabId, windowId));
}

function clearClientTabs(clientId) {
  tabStore.delete(clientId);
}

function allTabs() {
  const tabs = [];
  for (const clientTabs of tabStore.values()) {
    for (const tab of clientTabs.values()) tabs.push(tab);
  }
  return tabs;
}

function sendToHammerspoon(msg) {
  const hs = clients.get('hammerspoon');
  if (hs?.readyState === WebSocket.OPEN) {
    hs.send(JSON.stringify(msg));
  }
}

wss.on('connection', (ws) => {
  let clientId = null;

  ws.on('message', (rawData) => {
    let msg;
    try { msg = JSON.parse(rawData); } catch { return; }

    if (msg.type === 'register') {
      clientId = msg.id;
      clients.set(clientId, ws);
      console.log(`[+] ${clientId}`);

      if (clientId === 'hammerspoon') {
        ws.send(JSON.stringify({ type: 'state_sync', tabs: allTabs() }));
      }
      return;
    }

    if (!clientId) return;

    if (clientId === 'hammerspoon') {
      const target = clients.get(msg.target);
      if (target?.readyState === WebSocket.OPEN) {
        target.send(rawData.toString());
      }
      return;
    }

    // Browser tab event — update store then forward to Hammerspoon
    if (msg.type === 'tabs_all') {
      clearClientTabs(clientId);
      for (const tab of msg.tabs || []) upsertTab(clientId, msg.browser, tab);
    } else if (msg.type === 'tab_upsert') {
      if (msg.tab) upsertTab(clientId, msg.browser, msg.tab);
    } else if (msg.type === 'tab_removed') {
      removeTab(clientId, msg.tabId, msg.windowId);
    }

    sendToHammerspoon({ ...msg, clientId });
  });

  ws.on('close', () => {
    if (!clientId) return;
    clients.delete(clientId);
    console.log(`[-] ${clientId}`);
    if (clientId !== 'hammerspoon') {
      clearClientTabs(clientId);
      sendToHammerspoon({ type: 'client_disconnected', id: clientId });
    }
  });

  ws.on('error', () => {});
});

console.log(`relay listening on :${PORT}`);
