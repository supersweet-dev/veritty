import * as path from 'node:path';
import { sendRpcRequest } from '../socket.js';

export interface OpenOptions {
  reuseWindow?: boolean;
  preview?: boolean;
}

export function parseTarget(target: string): { filePath: string; line?: number; column?: number } {
  // Matches file.ext:10:5 or file.ext:10
  const match = target.match(/^(.*?):(\d+)(?::(\d+))?$/);
  if (match) {
    return {
      filePath: path.resolve(process.cwd(), match[1]),
      line: parseInt(match[2], 10),
      column: match[3] ? parseInt(match[3], 10) : undefined,
    };
  }

  return {
    filePath: path.resolve(process.cwd(), target),
  };
}

export async function handleOpen(targets: string[], options: OpenOptions = {}): Promise<void> {
  if (targets.length === 0) {
    throw new Error('No target path specified. Usage: veritty open <file>[:line[:col]]');
  }

  for (const target of targets) {
    const { filePath, line, column } = parseTarget(target);
    await sendRpcRequest('editor.open', {
      path: filePath,
      line,
      column,
      reUseWindow: options.reuseWindow ?? false,
      preview: options.preview ?? false,
    });
  }
}
