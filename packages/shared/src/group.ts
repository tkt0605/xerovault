import { z } from 'zod'
import type { UserSummary } from './user'

export const createGroupSchema = z.object({
  name: z.string().min(1).max(50),
  tag: z.string().max(30).optional(),
  isPublic: z.boolean().default(false),
})
export type CreateGroupInput = z.infer<typeof createGroupSchema>

export const createInviteSchema = z.object({
  expireIn: z.number().min(300).max(86400).default(3600),
})
export type CreateInviteInput = z.infer<typeof createInviteSchema>

export const joinGroupSchema = z.object({
  data: z.string(),
})
export type JoinGroupInput = z.infer<typeof joinGroupSchema>

export interface Group {
  id: string
  name: string
  tag: string | null
  isPublic: boolean
  score: number
  streak: number
  credits: number
  joinToken: string | null
  createdAt: string
  updatedAt: string
  owner: UserSummary
  members: UserSummary[]
  // グループ一覧・詳細取得時のみ含まれる（作成直後のレスポンスには含まれない）
  _count?: { goals: number }
}
