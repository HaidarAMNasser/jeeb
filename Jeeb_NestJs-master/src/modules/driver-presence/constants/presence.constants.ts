export const PRESENCE_STALE_THRESHOLD_MS = 45_000;

export function isPresenceStale(lastSeen: number): boolean {
  return Date.now() - lastSeen > PRESENCE_STALE_THRESHOLD_MS;
}
