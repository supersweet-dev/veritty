import { sendRpcRequest } from '../socket.js';

export type DrawerAction = 'toggle' | 'open' | 'close' | 'peek';

export async function handleDrawer(
  action: string,
  drawerName: string,
  durationMs?: number
): Promise<void> {
  const validActions: DrawerAction[] = ['toggle', 'open', 'close', 'peek'];
  if (!validActions.includes(action as DrawerAction)) {
    throw new Error(`Invalid drawer action: "${action}". Must be one of: ${validActions.join(', ')}`);
  }

  const validDrawers = ['explorer', 'git', 'search', 'diagnostics', 'extensions'];
  if (!drawerName || !validDrawers.includes(drawerName.toLowerCase())) {
    throw new Error(`Invalid or missing drawer name. Must be one of: ${validDrawers.join(', ')}`);
  }

  await sendRpcRequest(`drawer.${action}`, {
    drawer: drawerName.toLowerCase(),
    durationMs: durationMs || 3000,
  });
}
