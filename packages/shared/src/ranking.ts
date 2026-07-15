import type { UserSummary } from './user'

export interface RankingGroup {
  id: string
  name: string
  tag: string | null
  score: number
  streak: number
  createdAt: string
  owner: UserSummary
  _count: { members: number; goals: number }
}
