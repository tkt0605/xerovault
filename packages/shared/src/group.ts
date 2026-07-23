import { z } from 'zod'
import type { UserSummary, GroupMember } from './user'

export const createGroupSchema = z.object({
  name: z.string().min(1).max(50),
  tags: z.array(z.string().trim().min(1).max(30)).max(10).default([]),
  isPublic: z.boolean().default(false),
  description: z.string().trim().max(200).optional(),
})
export type CreateGroupInput = z.infer<typeof createGroupSchema>

export const updateGroupSchema = z.object({
  name: z.string().min(1).max(50).optional(),
  tags: z.array(z.string().trim().min(1).max(30)).max(10).optional(),
  description: z.string().trim().max(200).optional(),
})
export type UpdateGroupInput = z.infer<typeof updateGroupSchema>

export const createInviteSchema = z.object({
  expireIn: z.number().min(300).max(86400).default(3600),
})
export type CreateInviteInput = z.infer<typeof createInviteSchema>

export const joinGroupSchema = z.object({
  data: z.string(),
})
export type JoinGroupInput = z.infer<typeof joinGroupSchema>

export interface ScoreBreakdown {
  base: number
  completedPoints: number
  missedCount: number
  missedPenalty: number
  streak: number
  streakBonus: number
  total: number
}

export interface JoinRequestTarget {
  id: string
  name: string
  description: string | null
  tags: string[]
  myRequestStatus: 'pending' | 'approved' | 'rejected' | null
}

export interface GroupJoinRequest {
  id: string
  user: UserSummary
  message: string | null
  createdAt: string
}

export interface GroupInvite {
  id: string
  token: string
  expiresAt: string
  createdAt: string
}

export interface GroupActivityStats {
  weeklyPostCounts: { weekStart: string; count: number }[]
  repeatRate: number
}

export interface Group {
  id: string
  name: string
  description: string | null
  tags: string[]
  isPublic: boolean
  score: number
  streak: number
  createdAt: string
  updatedAt: string
  lastActivityAt: string
  owner: UserSummary
  members: GroupMember[]
  // グループ一覧・詳細取得時のみ含まれる（作成直後のレスポンスには含まれない）
  _count?: { goals: number }
}
