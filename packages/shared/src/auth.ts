import { z } from 'zod'
import type { UserSummary } from './user'

export const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1).max(50).optional(),
})
export type SignupInput = z.infer<typeof signupSchema>

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})
export type LoginInput = z.infer<typeof loginSchema>

export const googleAuthSchema = z.object({
  accessToken: z.string().min(1),
})
export type GoogleAuthInput = z.infer<typeof googleAuthSchema>

export interface AuthResponse {
  access: string
  user: UserSummary
}
