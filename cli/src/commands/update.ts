import * as os from 'node:os';
import * as path from 'node:path';
import * as fs from 'node:fs';
import { spawnSync } from 'node:child_process';

const REPO = 'supersweet-dev/veritty';
const CURRENT_VERSION = '1.0.2';

export interface UpdateOptions {
  check?: boolean;
  targetVersion?: string;
}

export async function handleUpdate(options: UpdateOptions = {}): Promise<void> {
  const configDir = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config', 'veritty');
  const localInstaller = path.join(configDir, 'install.sh');

  if (options.check) {
    try {
      const res = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
        headers: { 'User-Agent': 'veritty-cli' },
      });

      if (!res.ok) {
        throw new Error(`GitHub API returned status ${res.status}`);
      }

      const data = (await res.json()) as { tag_name?: string };
      const latestTag = data.tag_name || 'unknown';
      const cleanLatest = latestTag.replace(/^v/, '');
      const cleanCurrent = CURRENT_VERSION.replace(/^v/, '');

      if (cleanLatest === cleanCurrent) {
        console.log(`VeriTTY is up to date (current: v${CURRENT_VERSION}, latest: ${latestTag}).`);
      } else {
        console.log(`Update available: v${CURRENT_VERSION} -> ${latestTag}`);
        console.log(`Run 'veritty update' to install.`);
      }
    } catch (err: unknown) {
      console.error(`Failed to check for updates: ${err instanceof Error ? err.message : String(err)}`);
    }
    return;
  }

  // If local installer script exists, invoke it directly
  const installerArgs: string[] = [];
  if (options.targetVersion) {
    installerArgs.push('--version', options.targetVersion);
  }

  if (fs.existsSync(localInstaller)) {
    console.log(`==> Running local installer at ${localInstaller}...`);
    const proc = spawnSync(localInstaller, installerArgs, { stdio: 'inherit' });
    if (proc.status !== 0) {
      process.exit(proc.status ?? 1);
    }
    return;
  }

  // Fallback to fetching remote installer
  console.log(`==> Fetching and running latest installer from GitHub...`);
  const remoteCmd = `curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash -s -- ${installerArgs.join(' ')}`;
  const proc = spawnSync('bash', ['-c', remoteCmd], { stdio: 'inherit' });
  if (proc.status !== 0) {
    process.exit(proc.status ?? 1);
  }
}
