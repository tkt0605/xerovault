import { Router } from 'express'
import { castVoteSchema } from '@xerovault/shared'
import { prisma } from '../db'
import { requireAuth } from '../middleware/auth'
import { calcVoteProgress, updateGroupScore, incrementStreak } from '../services/scoreService'

const router = Router()
router.use(requireAuth)

const COMPLETION_THRESHOLD = 90

// GET /api/goals/:id/votes — 投票状況
router.get('/goals/:id/votes', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({
      where: { id: req.params.id },
      include: {
        group: { include: { members: { select: { id: true } } } },
        goalVotes: {
          include: {
            voter: { select: { id: true, email: true, name: true, avatar: true } },
            vote: true,
          },
        },
      },
    })
    if (!goal) {
      res.status(404).json({ error: 'ゴールが存在しません' })
      return
    }

    const isMember =
      goal.group.ownerId === userId || goal.group.members.some((m) => m.id === userId)
    if (!isMember) {
      res.status(403).json({ error: 'アクセス権がありません' })
      return
    }

    const progress = await calcVoteProgress(goal.id)
    const myVote = goal.goalVotes.find((gv) => gv.voterId === userId)

    res.json({
      goalId: goal.id,
      isCompleted: goal.isCompleted,
      progress,
      totalMembers: goal.group.members.length,
      votes: goal.goalVotes.map((gv) => ({
        voter: gv.voter,
        isYes: gv.vote?.isYes ?? null,
      })),
      myVote: myVote?.vote?.isYes ?? null,
    })
  } catch (err) {
    next(err)
  }
})

// POST /api/goals/:id/votes — 投票する
router.post('/goals/:id/votes', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const { isYes } = castVoteSchema.parse(req.body)

    const goal = await prisma.goal.findUnique({
      where: { id: req.params.id },
      include: { group: { include: { members: { select: { id: true } } } } },
    })
    if (!goal) {
      res.status(404).json({ error: 'ゴールが存在しません' })
      return
    }
    if (goal.isCompleted) {
      res.status(400).json({ error: 'このゴールはすでに達成済みです' })
      return
    }

    const isMember =
      goal.group.ownerId === userId || goal.group.members.some((m) => m.id === userId)
    if (!isMember) {
      res.status(403).json({ error: 'グループのメンバーではありません' })
      return
    }

    // GoalVote（投票箱）を取得 or 作成
    const goalVote = await prisma.goalVote.upsert({
      where: { goalId_voterId: { goalId: goal.id, voterId: userId } },
      create: { goalId: goal.id, voterId: userId },
      update: {},
    })

    // Vote（実際の投票）を更新 or 作成
    await prisma.vote.upsert({
      where: { goalVoteId: goalVote.id },
      create: { goalVoteId: goalVote.id, voterId: userId, isYes },
      update: { isYes },
    })

    const progress = await calcVoteProgress(goal.id)
    let justCompleted = false

    // 達成チェック
    if (!goal.isCompleted && progress >= COMPLETION_THRESHOLD) {
      await prisma.goal.update({ where: { id: goal.id }, data: { isCompleted: true } })
      await incrementStreak(goal.groupId)
      await updateGroupScore(goal.groupId)
      justCompleted = true
    }

    res.json({ ok: true, isYes, progress, justCompleted })
  } catch (err) {
    next(err)
  }
})

// DELETE /api/goals/:id/votes — 投票取り消し
router.delete('/goals/:id/votes', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({ where: { id: req.params.id } })
    if (!goal) {
      res.status(404).json({ error: 'ゴールが存在しません' })
      return
    }

    const goalVote = await prisma.goalVote.findUnique({
      where: { goalId_voterId: { goalId: goal.id, voterId: userId } },
    })
    if (!goalVote) {
      res.status(404).json({ error: '投票が存在しません' })
      return
    }

    await prisma.vote.deleteMany({ where: { goalVoteId: goalVote.id } })
    const progress = await calcVoteProgress(goal.id)
    res.json({ ok: true, progress })
  } catch (err) {
    next(err)
  }
})

export default router
