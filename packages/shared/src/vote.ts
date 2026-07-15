import { z } from 'zod'
import type { UserSummary } from './user'

export const castVoteSchema = z.object({
  isYes: z.boolean(),
})
export type CastVoteInput = z.infer<typeof castVoteSchema>

export interface VoteStatus {
  goalId: string
  isCompleted: boolean
  progress: number
  totalMembers: number
  myVote: boolean | null
  votes: { voter: UserSummary; isYes: boolean | null }[]
}

export interface CastVoteResponse {
  ok: true
  isYes: boolean
  progress: number
  justCompleted: boolean
}

export interface CancelVoteResponse {
  ok: true
  progress: number
}
