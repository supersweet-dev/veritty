import * as net from 'node:net';
import * as os from 'node:os';
import * as path from 'node:path';

export interface JsonRpcRequest {
  jsonrpc: '2.0';
  id: string | number;
  method: string;
  params?: Record<string, unknown>;
}

export interface JsonRpcResponse<T = unknown> {
  jsonrpc: '2.0';
  id: string | number;
  result?: T;
  error?: {
    code: number;
    message: string;
    data?: unknown;
  };
}

/**
 * Resolves the active VeriTTY IPC transport path.
 */
export function getSocketPath(): string {
  if (process.platform === 'win32') {
    const user = process.env.USERNAME || 'default';
    return `\\\\.\\pipe\\veritty-${user}`;
  }

  const uid = typeof process.getuid === 'function' ? process.getuid() : 1000;
  const runtimeDir = process.env.XDG_RUNTIME_DIR;

  if (runtimeDir) {
    return path.join(runtimeDir, `veritty-${uid}.sock`);
  }

  return `/tmp/veritty-${uid}.sock`;
}

/**
 * Sends a single JSON-RPC request to the running VeriTTY instance over IPC.
 */
export async function sendRpcRequest<T = unknown>(
  method: string,
  params: Record<string, unknown> = {}
): Promise<T> {
  const socketPath = getSocketPath();

  return new Promise((resolve, reject) => {
    const client = net.createConnection({ path: socketPath }, () => {
      const payload: JsonRpcRequest = {
        jsonrpc: '2.0',
        id: Date.now().toString(),
        method,
        params,
      };
      client.write(JSON.stringify(payload) + '\n');
    });

    let buffer = '';

    client.on('data', (data) => {
      buffer += data.toString('utf-8');
      const lines = buffer.split('\n');
      for (let i = 0; i < lines.length - 1; i++) {
        const line = lines[i].trim();
        if (line) {
          try {
            const response: JsonRpcResponse<T> = JSON.parse(line);
            client.end();
            if (response.error) {
              reject(new Error(response.error.message));
            } else {
              resolve(response.result as T);
            }
            return;
          } catch (err) {
            reject(new Error(`Invalid JSON-RPC response: ${String(err)}`));
          }
        }
      }
      buffer = lines[lines.length - 1];
    });

    client.on('error', (err: NodeJS.ErrnoException) => {
      if (err.code === 'ENOENT' || err.code === 'ECONNREFUSED') {
        reject(
          new Error(
            `Unable to connect to VeriTTY at ${socketPath}.\n` +
            `Ensure VeriTTY is running, or check $XDG_RUNTIME_DIR.`
          )
        );
      } else {
        reject(err);
      }
    });

    client.setTimeout(5000, () => {
      client.destroy();
      reject(new Error('Timed out waiting for VeriTTY response.'));
    });
  });
}
