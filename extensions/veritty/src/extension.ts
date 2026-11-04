import * as vscode from 'vscode';
import * as net from 'node:net';
import * as fs from 'node:fs';
import * as path from 'node:path';

interface JsonRpcRequest {
  jsonrpc: '2.0';
  id: string | number;
  method: string;
  params?: Record<string, unknown>;
}

interface JsonRpcResponse {
  jsonrpc: '2.0';
  id: string | number;
  result?: unknown;
  error?: {
    code: number;
    message: string;
    data?: unknown;
  };
}

let server: net.Server | undefined;
let activeSocketPath: string | undefined;

function getSocketPath(): string {
  if (process.platform === 'win32') {
    const user = process.env.USERNAME || 'default';
    return `\\\\.\\pipe\\veritty-${user}`;
  }

  const uid = typeof process.getuid === 'function' ? process.getuid() : 1000;
  const runtimeDir = process.env.XDG_RUNTIME_DIR;

  if (runtimeDir) {
    const dir = path.join(runtimeDir, 'veritty');
    if (!fs.existsSync(dir)) {
      try {
        fs.mkdirSync(dir, { recursive: true });
      } catch {
        // Fallback to /tmp if creation fails
        return `/tmp/veritty-${uid}.sock`;
      }
    }
    return path.join(dir, `veritty-${uid}.sock`);
  }

  return `/tmp/veritty-${uid}.sock`;
}

async function handleRequest(request: JsonRpcRequest): Promise<unknown> {
  const { method, params = {} } = request;

  switch (method) {
    case 'editor.open': {
      const filePath = params.path as string;
      if (!filePath) {
        throw new Error('Missing parameter: path');
      }

      const uri = vscode.Uri.file(filePath);
      const document = await vscode.workspace.openTextDocument(uri);

      const line = typeof params.line === 'number' ? Math.max(0, params.line - 1) : undefined;
      const column = typeof params.column === 'number' ? Math.max(0, params.column - 1) : 0;

      const selection = line !== undefined ? new vscode.Range(line, column, line, column) : undefined;

      await vscode.window.showTextDocument(document, {
        selection,
        preview: Boolean(params.preview),
      });

      return { status: 'opened', path: filePath };
    }

    case 'editor.diff': {
      const originalPath = params.originalPath as string;
      const modifiedPath = params.modifiedPath as string;
      const title = (params.title as string) || `${path.basename(originalPath)} ↔ ${path.basename(modifiedPath)}`;

      if (!originalPath || !modifiedPath) {
        throw new Error('Missing parameters: originalPath and modifiedPath');
      }

      await vscode.commands.executeCommand(
        'vscode.diff',
        vscode.Uri.file(originalPath),
        vscode.Uri.file(modifiedPath),
        title
      );

      return { status: 'opened' };
    }

    case 'editor.scratch': {
      const content = (params.content as string) || '';
      const language = (params.language as string) || 'plaintext';

      const document = await vscode.workspace.openTextDocument({
        content,
        language,
      });

      await vscode.window.showTextDocument(document);

      return { status: 'opened' };
    }

    case 'drawer.open':
    case 'drawer.toggle':
    case 'drawer.close':
    case 'drawer.peek': {
      const drawer = (params.drawer as string)?.toLowerCase();
      const durationMs = typeof params.durationMs === 'number' ? params.durationMs : 3000;

      const drawerCommandMap: Record<string, string> = {
        explorer: 'workbench.view.explorer',
        git: 'workbench.view.scm',
        search: 'workbench.view.search',
        diagnostics: 'workbench.actions.view.problems',
      };

      if (method === 'drawer.close') {
        await vscode.commands.executeCommand('workbench.action.closeSidebar');
        return { status: 'closed' };
      }

      const targetCommand = drawerCommandMap[drawer] || 'workbench.view.explorer';
      await vscode.commands.executeCommand(targetCommand);

      if (method === 'drawer.peek') {
        setTimeout(async () => {
          try {
            await vscode.commands.executeCommand('workbench.action.closeSidebar');
          } catch {
            // Ignore if already closed
          }
        }, durationMs);
      }

      return { status: 'ok', drawer };
    }

    default:
      throw new Error(`Unknown method: "${method}"`);
  }
}

export function activate(context: vscode.ExtensionContext): void {
  const socketPath = getSocketPath();
  activeSocketPath = socketPath;

  // Clean up stale socket file on POSIX systems
  if (process.platform !== 'win32' && fs.existsSync(socketPath)) {
    try {
      fs.unlinkSync(socketPath);
    } catch {
      // Ignore cleanup error
    }
  }

  server = net.createServer((socket) => {
    let buffer = '';

    socket.on('data', async (data) => {
      buffer += data.toString('utf-8');
      const lines = buffer.split('\n');

      for (let i = 0; i < lines.length - 1; i++) {
        const line = lines[i].trim();
        if (!line) {
          continue;
        }

        try {
          const request: JsonRpcRequest = JSON.parse(line);
          try {
            const result = await handleRequest(request);
            const response: JsonRpcResponse = {
              jsonrpc: '2.0',
              id: request.id,
              result,
            };
            socket.write(JSON.stringify(response) + '\n');
          } catch (err: unknown) {
            const response: JsonRpcResponse = {
              jsonrpc: '2.0',
              id: request.id,
              error: {
                code: -32603,
                message: err instanceof Error ? err.message : String(err),
              },
            };
            socket.write(JSON.stringify(response) + '\n');
          }
        } catch {
          const response: JsonRpcResponse = {
            jsonrpc: '2.0',
            id: 0,
            error: {
              code: -32700,
              message: 'Parse error: invalid JSON',
            },
          };
          socket.write(JSON.stringify(response) + '\n');
        }
      }

      buffer = lines[lines.length - 1];
    });

    socket.on('error', () => {
      // Ignore socket read/write errors on client disconnect
    });
  });

  server.listen(socketPath, () => {
    console.log(`[VeriTTY] IPC server active on ${socketPath}`);
  });

  server.on('error', (err) => {
    console.error(`[VeriTTY] IPC server error: ${err.message}`);
  });

  context.subscriptions.push({
    dispose: () => {
      deactivate();
    },
  });
}

export function deactivate(): void {
  if (server) {
    server.close();
    server = undefined;
  }

  if (activeSocketPath && process.platform !== 'win32' && fs.existsSync(activeSocketPath)) {
    try {
      fs.unlinkSync(activeSocketPath);
    } catch {
      // Ignore cleanup error
    }
    activeSocketPath = undefined;
  }
}
