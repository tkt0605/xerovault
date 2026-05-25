import { prisma } from '../db'

const BASE_SCORE = 100
const MAX_SCORE = 9999
const CONCRETE_GOAL_PTS = 25   // 期限・担当者あり
const VAGUE_GOAL_PTS = 5       // 期限・担当者なし
const FULL_PARTICIPATION_BONUS = 1.5  // 投票参加率100%
const STREAK_BONUS = 50        // 3連続達成ボーナス

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
  let totalScore = BASE_SCORE

  for (const goal of group.goals) {
    const basePts = goal.deadline && goal.assigneeId ? CONCRETE_GOAL_PTS : VAGUE_GOAL_PTS

    const participantCount = new Set(
      goal.goalVotes.filter((gv) => gv.vote).map((gv) => gv.voterId)
    ).size
    const participationRate = totalMembers > 0 ? participantCount / totalMembers : 0
    const participationBonus = participationRate >= 1.0 ? FULL_PARTICIPATION_BONUS : 1.0

    totalScore += Math.round(basePts * participationBonus)
  }

  if (group.streak >= 3) totalScore += STREAK_BONUS

  await prisma.group.update({
    where: { id: groupId },
    data: { score: Math.min(totalScore, MAX_SCORE) },
  })
}

// ゴール達成時に連続達成カウントを更新
export async function incrementStreak(groupId: string): Promise<void> {
  await prisma.group.update({
    where: { id: groupId },
    data: { streak: { increment: 1 } },
  })
}

// 投票進捗を計算（0〜100の整数）
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
  if (totalMembers === 0) return 0

  const yesCount = goal.goalVotes.filter((gv) => gv.vote?.isYes === true).length
  return Math.round((yesCount / totalMembers) * 100)
}
