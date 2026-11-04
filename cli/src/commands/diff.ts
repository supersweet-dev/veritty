import * as path from 'node:path';
import { sendRpcRequest } from '../socket.js';

export async function handleDiff(originalPath: string, modifiedPath: string, title?: string): Promise<void> {
  if (!originalPath || !modifiedPath) {
    throw new Error('Usage: veritty diff <originalPath> <modifiedPath> [title]');
  }

  const resolvedOriginal = path.resolve(process.cwd(), originalPath);
  const resolvedModified = path.resolve(process.cwd(), modifiedPath);

  await sendRpcRequest('editor.diff', {
    originalPath: resolvedOriginal,
    modifiedPath: resolvedModified,
    title: title || `${path.basename(originalPath)} ↔ ${path.basename(modifiedPath)}`,
  });
}
