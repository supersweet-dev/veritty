#!/usr/bin/env node
import { handleOpen } from './commands/open.js';
import { handleDiff } from './commands/diff.js';
import { handleDrawer } from './commands/drawer.js';
import { handleScratch } from './commands/scratch.js';
import { handleUpdate } from './commands/update.js';
import { handleCockpit } from './commands/cockpit.js';

function printHelp(): void {
  console.log(`
VeriTTY CLI - Terminal-first IDE IPC client

USAGE:
  veritty [command] [options] [arguments]
  veritty <file>[:line[:col]]...

COMMANDS:
  cockpit [path]                 Launch the graphical VeriTTY Cockpit application
  open <file>[:line[:col]]...    Open file(s) in detached native OS auxiliary window(s)
                                   --reuse     Reuse an existing auxiliary window
                                   --preview   Open in preview mode
  diff <fileA> <fileB> [title]   Open a detached diff view comparing two files
  drawer <action> <drawer>       Control dynamic drawers in VeriTTY Cockpit
                                   Actions: toggle | open | close | peek
                                   Drawers: explorer | git | search | diagnostics
  scratch [--lang=<lang>]        Read stdin and open in a detached scratchpad editor
  update [--check] [--version=V] Check for or install VeriTTY updates
  help, --help, -h               Show this help message
  version, --version, -v         Show version info

EXAMPLES:
  veritty
  veritty cockpit .
  veritty src/main.rs:12:4
  veritty open --reuse README.md
  veritty diff package.json package.json.bak "Package Diff"
  veritty drawer toggle explorer
  veritty drawer peek diagnostics
  git diff | veritty scratch --lang=diff
`);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.includes('-h') || args.includes('--help') || args[0] === 'help') {
    printHelp();
    return;
  }

  if (args.length === 0) {
    try {
      await handleCockpit(['.']);
      return;
    } catch {
      printHelp();
      return;
    }
  }

  if (args.includes('-v') || args.includes('--version') || args[0] === 'version') {
    console.log('veritty-cli 1.0.2');
    return;
  }

  const firstArg = args[0];

  try {
    switch (firstArg) {
      case 'open': {
        const fileArgs = args.slice(1).filter((a) => !a.startsWith('--'));
        const reuse = args.includes('--reuse');
        const preview = args.includes('--preview');
        await handleOpen(fileArgs, { reuseWindow: reuse, preview });
        break;
      }

      case 'diff': {
        const fileA = args[1];
        const fileB = args[2];
        const title = args[3];
        await handleDiff(fileA, fileB, title);
        break;
      }

      case 'drawer': {
        const action = args[1];
        const drawerName = args[2];
        const durationArg = args.find((a) => a.startsWith('--duration='));
        const duration = durationArg ? parseInt(durationArg.split('=')[1], 10) : undefined;
        await handleDrawer(action, drawerName, duration);
        break;
      }

      case 'scratch': {
        const langArg = args.find((a) => a.startsWith('--lang='));
        const language = langArg ? langArg.split('=')[1] : undefined;
        await handleScratch(language);
        break;
      }

      case 'update':
      case 'upgrade': {
        const check = args.includes('--check');
        const versionArg = args.find((a) => a.startsWith('--version='));
        const targetVersion = versionArg
          ? versionArg.split('=')[1]
          : args[1] && !args[1].startsWith('--')
          ? args[1]
          : undefined;
        await handleUpdate({ check, targetVersion });
        break;
      }

      default: {
        // If first argument is not a known command, treat arguments as paths to open
        const fileArgs = args.filter((a) => !a.startsWith('--'));
        const reuse = args.includes('--reuse');
        const preview = args.includes('--preview');
        await handleOpen(fileArgs, { reuseWindow: reuse, preview });
        break;
      }
    }
  } catch (err: unknown) {
    if (err instanceof Error) {
      console.error(`\x1b[31merror:\x1b[0m ${err.message}`);
    } else {
      console.error(`\x1b[31merror:\x1b[0m ${String(err)}`);
    }
    process.exit(1);
  }
}

main();
