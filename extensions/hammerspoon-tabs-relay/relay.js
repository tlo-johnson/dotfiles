const WebSocket = require('ws');

const PORT = 27124;
const wss = new WebSocket.Server({ port: PORT });

// clientId -> WebSocket
const clients = new Map();

wss.on('connection', (ws) => {
  let clientId = null;

  ws.on('message', (rawData) => {
    let msg;
    try { msg = JSON.parse(rawData); } catch { return; }

    if (msg.type === 'register') {
      clientId = msg.id;
      clients.set(clientId, ws);
      console.log(`[+] ${clientId}`);
      return;
    }

    if (!clientId) return;

    if (clientId === 'hammerspoon') {
      // Focus command: route to the target browser profile
      const target = clients.get(msg.target);
      if (target?.readyState === WebSocket.OPEN) {
        target.send(rawData.toString());
      }
    } else {
      // Tab event: forward to Hammerspoon, injecting clientId
      const hs = clients.get('hammerspoon');
      if (hs?.readyState === WebSocket.OPEN) {
        hs.send(JSON.stringify({ ...msg, clientId }));
      }
    }
  });

  ws.on('close', () => {
    if (!clientId) return;
    clients.delete(clientId);
    console.log(`[-] ${clientId}`);
    const hs = clients.get('hammerspoon');
    if (hs?.readyState === WebSocket.OPEN) {
      hs.send(JSON.stringify({ type: 'client_disconnected', id: clientId }));
    }
  });

  ws.on('error', () => {});
});

console.log(`relay listening on :${PORT}`);
