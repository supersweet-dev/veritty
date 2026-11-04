import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import { handleLaunch } from './launch.js';

describe('Launch Command', () => {
  it('throws helpful error message when binary is missing', async () => {
    process.env.VERITTY_APP_BIN = '/tmp/nonexistent-veritty-bin';

    await assert.rejects(
      async () => {
        await handleLaunch();
      },
      (err: Error) => {
        assert.match(err.message, /VeriTTY application binary not found/);
        return true;
      }
    );

    delete process.env.VERITTY_APP_BIN;
  });
});
