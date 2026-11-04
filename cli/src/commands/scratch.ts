import { sendRpcRequest } from '../socket.js';

export async function handleScratch(language?: string): Promise<void> {
  // Read all of stdin
  const chunks: Buffer[] = [];
  process.stdin.resume();

  for await (const chunk of process.stdin) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  const content = Buffer.concat(chunks).toString('utf-8');
  if (!content.trim()) {
    throw new Error('No input provided on stdin for scratch buffer.');
  }

  await sendRpcRequest('editor.scratch', {
    content,
    language: language || 'plaintext',
  });
}
