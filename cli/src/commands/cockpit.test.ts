import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import { handleCockpit } from './cockpit.js';

describe('Cockpit Command', () => {
  it('throws helpful error message when binary is missing', async () => {
    // Set invalid binary path
    process.env.VERITTY_COCKPIT_BIN = '/tmp/nonexistent-veritty-bin';

    await assert.rejects(
      async () => {
        await handleCockpit();
      },
      (err: Error) => {
        assert.match(err.message, /VeriTTY Cockpit binary not found/);
        return true;
      }
    );

    delete process.env.VERITTY_COCKPIT_BIN;
  });
});
