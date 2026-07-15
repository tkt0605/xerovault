import type { GoalStatus } from '@xerovault/shared'
import { prisma } from '../db'

export const BASE_SCORE = 100
export const MAX_SCORE = 9999
export const MIN_SCORE = 0
export const CONCRETE_GOAL_PTS = 25 // 期限・担当者あり
export const VAGUE_GOAL_PTS = 5 // 期限・担当者なし
export const FULL_PARTICIPATION_BONUS = 1.5 // 投票参加率100%
export const MISSED_GOAL_PENALTY = 25 // concrete goalを1件missするごとの減点(達成報酬と対称)
export const STREAK_BONUS = 50 // 連続達成ボーナス
export const STREAK_THRESHOLD = 3 // ボーナスに必要な連続達成数

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
  missedConcreteGoalCount: number,
  totalMembers: number,
  streak: number
): number {
  let totalScore = BASE_SCORE
  for (const goal of completedGoals) {
    totalScore += calcGoalPoints(goal, totalMembers)
  }
  totalScore -= missedConcreteGoalCount * MISSED_GOAL_PENALTY
  if (streak >= STREAK_THRESHOLD) totalScore += STREAK_BONUS
  return Math.max(MIN_SCORE, Math.min(totalScore, MAX_SCORE))
}

export interface ResolvedConcreteGoal {
  deadline: Date
  isCompleted: boolean
}

// concrete goal(deadline昇順に無関係な順序で渡してよい)から現在のストリークを導出する（純粋関数）
export function calcStreak(resolvedConcreteGoals: ResolvedConcreteGoal[]): number {
  const sorted = [...resolvedConcreteGoals].sort(
    (a, b) => a.deadline.getTime() - b.deadline.getTime()
  )
  let streak = 0
  for (let i = sorted.length - 1; i >= 0; i--) {
    if (!sorted[i].isCompleted) break
    streak++
  }
  return streak
}

// 投票進捗を計算（0〜100の整数、純粋関数）
export function calcProgress(yesCount: number, totalMembers: number): number {
  if (totalMembers === 0) return 0
  return Math.round((yesCount / totalMembers) * 100)
}

// ゴールの状態を導出する（純粋関数）。concrete goal = deadline と assigneeId の両方がある
export function calcGoalStatus(
  goal: { isCompleted: boolean; deadline: Date | null; assigneeId: string | null },
  now: Date = new Date()
): GoalStatus {
  if (goal.isCompleted) return 'completed'
  const isConcrete = !!(goal.deadline && goal.assigneeId)
  if (isConcrete && goal.deadline!.getTime() < now.getTime()) return 'missed'
  return 'pending'
}

export async function updateGroupScore(groupId: string): Promise<void> {
  const now = new Date()
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

  // concrete goal(deadline・assigneeId両方あり)のうち「解決済み」(達成 or 期限切れ未達成)なもの
  const resolvedConcreteGoals = await prisma.goal.findMany({
    where: {
      groupId,
      deadline: { not: null },
      assigneeId: { not: null },
      OR: [{ isCompleted: true }, { deadline: { lt: now } }],
    },
    select: { deadline: true, isCompleted: true },
  })
  const resolved: ResolvedConcreteGoal[] = resolvedConcreteGoals.map((g) => ({
    deadline: g.deadline!,
    isCompleted: g.isCompleted,
  }))
  const missedConcreteGoalCount = resolved.filter((g) => !g.isCompleted).length
  const streak = calcStreak(resolved)

  const score = calcGroupScore(completedGoals, missedConcreteGoalCount, totalMembers, streak)

  await prisma.group.update({
    where: { id: groupId },
    data: { score, streak },
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
