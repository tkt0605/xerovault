import type { UserSummary } from './user'

export interface RankingGroup {
  id: string
  name: string
  tags: string[]
  score: number
  streak: number
  createdAt: string
  owner: UserSummary
  _count: { members: number; goals: number }
}

export interface TagStat {
  tag: string
  groupCount: number
}
