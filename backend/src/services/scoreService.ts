import { prisma } from '../db'

export const BASE_SCORE = 100
export const MAX_SCORE = 9999
export const CONCRETE_GOAL_PTS = 25 // 期限・担当者あり
export const VAGUE_GOAL_PTS = 5 // 期限・担当者なし
export const FULL_PARTICIPATION_BONUS = 1.5 // 投票参加率100%
export const STREAK_BONUS = 50 // 3連続達成ボーナス

export interface CompletedGoalInput {
  hasDeadline: boolean
  hasAssignee: boolean
  participantCount: number
}

// 達成ゴール1件ぶんの獲得点数（純粋関数）
export function calcGoalPoints(goal: CompletedGoalInput, totalMembers: number): number {
  const basePts = goal.hasDeadline && goal.hasAssignee ? CONCRETE_GOAL_PTS : VAGUE_GOAL_PTS
  const participationRate = totalMembers > 0 ? goal.participantCount / totalMembers : 0
  const participationBonus = participationRate >= 1.0 ? FULL_PARTICIPATION_BONUS : 1.0
  return Math.round(basePts * participationBonus)
}

// グループの合計スコア（純粋関数）
export function calcGroupScore(
  completedGoals: CompletedGoalInput[],
  totalMembers: number,
  streak: number
): number {
  let totalScore = BASE_SCORE
  for (const goal of completedGoals) {
    totalScore += calcGoalPoints(goal, totalMembers)
  }
  if (streak >= 3) totalScore += STREAK_BONUS
  return Math.min(totalScore, MAX_SCORE)
}

// 投票進捗を計算（0〜100の整数、純粋関数）
export function calcProgress(yesCount: number, totalMembers: number): number {
  if (totalMembers === 0) return 0
  return Math.round((yesCount / totalMembers) * 100)
}

export async function updateGroupScore(groupId: string): Promise<void> {
  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: true,
      goals: {
        where: { isCompleted: true },
        include: {
          goalVotes: { include: { vote: true } },
        },
      },
    },
  })
  if (!group) return

  const totalMembers = group.members.length
  const completedGoals: CompletedGoalInput[] = group.goals.map((goal) => ({
    hasDeadline: !!goal.deadline,
    hasAssignee: !!goal.assigneeId,
    participantCount: new Set(goal.goalVotes.filter((gv) => gv.vote).map((gv) => gv.voterId)).size,
  }))

  const score = calcGroupScore(completedGoals, totalMembers, group.streak)

  await prisma.group.update({
    where: { id: groupId },
    data: { score },
  })
}

// ゴール達成時に連続達成カウントを更新
export async function incrementStreak(groupId: string): Promise<void> {
  await prisma.group.update({
    where: { id: groupId },
    data: { streak: { increment: 1 } },
  })
}

export async function calcVoteProgress(goalId: string): Promise<number> {
  const goal = await prisma.goal.findUnique({
    where: { id: goalId },
    include: {
      group: { include: { members: true } },
      goalVotes: { include: { vote: true } },
    },
  })
  if (!goal) return 0

  const totalMembers = goal.group.members.length
  const yesCount = goal.goalVotes.filter((gv) => gv.vote?.isYes === true).length
  return calcProgress(yesCount, totalMembers)
}
