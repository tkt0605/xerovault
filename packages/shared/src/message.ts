import { z } from 'zod'
import type { UserSummary } from './user'

export const sendMessageSchema = z.object({
  text: z.string().min(1).max(2000),
})
export type SendMessageInput = z.infer<typeof sendMessageSchema>

export interface Message {
  id: string
  text: string
  createdAt: string
  goalId: string
  authorId: string
  author: UserSummary
}
