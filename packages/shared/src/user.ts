export interface UserSummary {
  id: string
  email: string
  name: string | null
  avatar: string | null
}

export interface GroupMember extends UserSummary {
  bio: string | null
  interestTags: string[]
  completedGoalsCount: number
  lastActiveAt: string | null
}
