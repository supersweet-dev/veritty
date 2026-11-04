import { describe, it } from 'node:test';
import * as assert from 'node:assert';
import * as path from 'node:path';
import { parseTarget } from './open.js';

describe('parseTarget', () => {
  it('parses simple file path', () => {
    const result = parseTarget('src/main.ts');
    assert.strictEqual(result.filePath, path.resolve(process.cwd(), 'src/main.ts'));
    assert.strictEqual(result.line, undefined);
    assert.strictEqual(result.column, undefined);
  });

  it('parses file path with line number', () => {
    const result = parseTarget('src/main.ts:42');
    assert.strictEqual(result.filePath, path.resolve(process.cwd(), 'src/main.ts'));
    assert.strictEqual(result.line, 42);
    assert.strictEqual(result.column, undefined);
  });

  it('parses file path with line and column numbers', () => {
    const result = parseTarget('src/main.ts:42:15');
    assert.strictEqual(result.filePath, path.resolve(process.cwd(), 'src/main.ts'));
    assert.strictEqual(result.line, 42);
    assert.strictEqual(result.column, 15);
  });
});
