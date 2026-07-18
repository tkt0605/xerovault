const STAGNANT_THRESHOLD_MS = 7 * 24 * 60 * 60 * 1000
const DAY_MS = 24 * 60 * 60 * 1000

export function isStagnant(lastActivityAt: string): boolean {
  return Date.now() - new Date(lastActivityAt).getTime() > STAGNANT_THRESHOLD_MS
}

export function formatLastActive(lastActiveAt: string | null): string {
  if (!lastActiveAt) return 'まだ活動なし'
  const days = Math.floor((Date.now() - new Date(lastActiveAt).getTime()) / DAY_MS)
  if (days <= 0) return '今日活動'
  return `${days}日前に活動`
}
