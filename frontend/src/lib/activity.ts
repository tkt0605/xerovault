const STAGNANT_THRESHOLD_MS = 7 * 24 * 60 * 60 * 1000

export function isStagnant(lastActivityAt: string): boolean {
  return Date.now() - new Date(lastActivityAt).getTime() > STAGNANT_THRESHOLD_MS
}
