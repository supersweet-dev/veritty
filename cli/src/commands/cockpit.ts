import { spawn } from 'node:child_process';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';

function findCockpitBinary(): string | undefined {
  if (process.env.VERITTY_COCKPIT_BIN && fs.existsSync(process.env.VERITTY_COCKPIT_BIN)) {
    return process.env.VERITTY_COCKPIT_BIN;
  }

  // Check sibling paths in packaged bundle layout
  const candidatePaths = [
    // Next to app bundle root
    path.resolve(__dirname, '..', '..', 'veritty'),
    path.resolve(__dirname, '..', '..', 'bin', 'veritty-cockpit'),
    path.resolve(__dirname, '..', '..', '..', 'veritty'),
    // User local share path
    path.join(os.homedir(), '.local', 'share', 'veritty', 'veritty'),
    path.join(os.homedir(), '.local', 'share', 'veritty', 'bin', 'veritty-cockpit'),
    // System path
    '/usr/share/veritty/veritty',
    '/usr/local/bin/veritty-cockpit',
    '/usr/bin/veritty-cockpit',
  ];

  for (const candidate of candidatePaths) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return undefined;
}

export async function handleCockpit(args: string[] = []): Promise<void> {
  const binary = findCockpitBinary();

  if (!binary) {
    throw new Error(
      'VeriTTY Cockpit binary not found.\n' +
      'Install the desktop bundle with:\n' +
      '  curl -fsSL https://raw.githubusercontent.com/supersweet-dev/veritty/main/install.sh | bash'
    );
  }

  const launchArgs = [...args];

  // Root environments need no-sandbox flag for Electron
  if (typeof process.getuid === 'function' && process.getuid() === 0) {
    if (!launchArgs.includes('--no-sandbox')) {
      launchArgs.push('--no-sandbox');
    }
  }

  const child = spawn(binary, launchArgs, {
    detached: true,
    stdio: 'ignore',
    env: process.env,
  });

  child.unref();
  console.log(`VeriTTY Cockpit started: ${binary}`);
}
