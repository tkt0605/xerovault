import type { UserSummary } from './user'

export interface RankingGroup {
  id: string
  name: string
  description: string | null
  tags: string[]
  score: number
  streak: number
  createdAt: string
  owner: Omit<UserSummary, 'email'>
  _count: { members: number; goals: number }
}

export interface TagStat {
  tag: string
  groupCount: number
}

export interface TagSuggestion {
  tag: string
  usageCount: number
}
