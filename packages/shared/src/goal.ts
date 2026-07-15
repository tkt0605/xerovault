import { z } from 'zod'
import type { UserSummary } from './user'

export const createGoalSchema = z.object({
  header: z.string().max(100).optional(),
  description: z.string().min(1),
  deadline: z.string().datetime().optional().nullable(),
  assigneeId: z.string().uuid().optional().nullable(),
})
export type CreateGoalInput = z.infer<typeof createGoalSchema>

export const updateGoalSchema = z.object({
  header: z.string().max(100).optional(),
  description: z.string().min(1).optional(),
  deadline: z.string().datetime().optional().nullable(),
  assigneeId: z.string().uuid().optional().nullable(),
})
export type UpdateGoalInput = z.infer<typeof updateGoalSchema>

export interface Goal {
  id: string
  header: string | null
  description: string
  deadline: string | null
  isConcrete: boolean
  isCompleted: boolean
  createdAt: string
  updatedAt: string
  groupId: string
  assigneeId: string | null
  assignee: UserSummary | null
  progress: number
  // GET /goals/:id のみ含む
  group?: {
    id: string
    name: string
    members: UserSummary[]
  }
}
