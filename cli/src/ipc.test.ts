import { describe, it, before, after } from 'node:test';
import * as assert from 'node:assert';
import * as net from 'node:net';
import * as fs from 'node:fs';
import { getSocketPath, sendRpcRequest } from './socket.js';

describe('VeriTTY IPC Integration', () => {
  let mockServer: net.Server;
  const socketPath = getSocketPath();
  const receivedRequests: Array<{ method: string; params: unknown }> = [];

  before(async () => {
    // Clean up if old socket exists
    if (process.platform !== 'win32' && fs.existsSync(socketPath)) {
      try {
        fs.unlinkSync(socketPath);
      } catch {
        // ignore
      }
    }

    mockServer = net.createServer((socket) => {
      let buffer = '';
      socket.on('data', (chunk) => {
        buffer += chunk.toString('utf-8');
        const lines = buffer.split('\n');
        for (let i = 0; i < lines.length - 1; i++) {
          const line = lines[i].trim();
          if (line) {
            const req = JSON.parse(line);
            receivedRequests.push({ method: req.method, params: req.params });
            socket.write(
              JSON.stringify({
                jsonrpc: '2.0',
                id: req.id,
                result: { ok: true, method: req.method },
              }) + '\n'
            );
          }
        }
        buffer = lines[lines.length - 1];
      });
    });

    await new Promise<void>((resolve) => {
      mockServer.listen(socketPath, () => resolve());
    });
  });

  after(async () => {
    await new Promise<void>((resolve) => {
      mockServer.close(() => resolve());
    });
    if (process.platform !== 'win32' && fs.existsSync(socketPath)) {
      try {
        fs.unlinkSync(socketPath);
      } catch {
        // ignore
      }
    }
  });

  it('sends editor.open request and receives response', async () => {
    const res = await sendRpcRequest<{ ok: boolean; method: string }>('editor.open', {
      path: '/path/to/test.ts',
      line: 42,
      column: 5,
    });

    assert.strictEqual(res.ok, true);
    assert.strictEqual(res.method, 'editor.open');

    const lastReq = receivedRequests[receivedRequests.length - 1];
    assert.strictEqual(lastReq.method, 'editor.open');
    assert.deepStrictEqual(lastReq.params, {
      path: '/path/to/test.ts',
      line: 42,
      column: 5,
    });
  });

  it('sends drawer.toggle request and receives response', async () => {
    const res = await sendRpcRequest<{ ok: boolean; method: string }>('drawer.toggle', {
      drawer: 'explorer',
    });

    assert.strictEqual(res.ok, true);
    assert.strictEqual(res.method, 'drawer.toggle');

    const lastReq = receivedRequests[receivedRequests.length - 1];
    assert.strictEqual(lastReq.method, 'drawer.toggle');
    assert.deepStrictEqual(lastReq.params, {
      drawer: 'explorer',
    });
  });

  it('sends editor.diff request and receives response', async () => {
    const res = await sendRpcRequest<{ ok: boolean; method: string }>('editor.diff', {
      originalPath: '/a.ts',
      modifiedPath: '/b.ts',
    });

    assert.strictEqual(res.ok, true);
    assert.strictEqual(res.method, 'editor.diff');
  });
});
