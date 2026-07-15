import { Router, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { requireAuth } from '../middleware/auth'
import { calcVoteProgress } from '../services/scoreService'

const router = Router()
router.use(requireAuth)

async function assertMember(groupId: string, userId: string, res: Response): Promise<boolean> {
  const group = await prisma.group.findUnique({
    where: { id: groupId },
    select: { ownerId: true, members: { select: { id: true } } },
  })
  if (!group) {
    res.status(404).json({ error: 'グループが存在しません' })
    return false
  }
  const ok = group.ownerId === userId || group.members.some((m: { id: string }) => m.id === userId)
  if (!ok) {
    res.status(403).json({ error: 'グループのメンバーではありません' })
    return false
  }
  return true
}

// GET /api/groups/:groupId/goals
router.get('/groups/:groupId/goals', async (req, res, next) => {
  try {
    const userId = req.user!.id
    if (!(await assertMember(req.params.groupId, userId, res))) return

    const goals = await prisma.goal.findMany({
      where: { groupId: req.params.groupId },
      include: {
        assignee: { select: { id: true, email: true, name: true, avatar: true } },
        _count: { select: { messages: true, goalVotes: true } },
      },
      orderBy: { createdAt: 'desc' },
    })

    const goalsWithProgress = await Promise.all(
      goals.map(async (g) => ({ ...g, progress: await calcVoteProgress(g.id) }))
    )
    res.json(goalsWithProgress)
  } catch (err) {
    next(err)
  }
})

// POST /api/groups/:groupId/goals
router.post('/groups/:groupId/goals', async (req, res, next) => {
  try {
    const userId = req.user!.id
    if (!(await assertMember(req.params.groupId, userId, res))) return

    const { header, description, deadline, assigneeId } = z
      .object({
        header: z.string().max(100).optional(),
        description: z.string().min(1),
        deadline: z.string().datetime().optional().nullable(),
        assigneeId: z.string().uuid().optional().nullable(),
      })
      .parse(req.body)

    const isConcrete = !!(deadline || assigneeId)
    const goal = await prisma.goal.create({
      data: {
        header,
        description,
        deadline: deadline ? new Date(deadline) : null,
        assigneeId: assigneeId ?? null,
        isConcrete,
        groupId: req.params.groupId,
      },
      include: { assignee: { select: { id: true, email: true, name: true, avatar: true } } },
    })
    res.status(201).json({ ...goal, progress: 0 })
  } catch (err) {
    next(err)
  }
})

// GET /api/goals/:id
router.get('/goals/:id', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({
      where: { id: req.params.id },
      include: {
        group: {
          include: {
            owner: { select: { id: true, email: true, name: true, avatar: true } },
            members: { select: { id: true, email: true, name: true, avatar: true } },
          },
        },
        assignee: { select: { id: true, email: true, name: true, avatar: true } },
      },
    })
    if (!goal) {
      res.status(404).json({ error: 'ゴールが存在しません' })
      return
    }
    if (!(await assertMember(goal.groupId, userId, res))) return

    const progress = await calcVoteProgress(goal.id)
    res.json({ ...goal, progress })
  } catch (err) {
    next(err)
  }
})

// PATCH /api/goals/:id
router.patch('/goals/:id', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({ where: { id: req.params.id } })
    if (!goal) {
      res.status(404).json({ error: 'ゴールが存在しません' })
      return
    }
    if (!(await assertMember(goal.groupId, userId, res))) return

    const data = z
      .object({
        header: z.string().max(100).optional(),
        description: z.string().min(1).optional(),
        deadline: z.string().datetime().optional().nullable(),
        assigneeId: z.string().uuid().optional().nullable(),
      })
      .parse(req.body)

    const isConcrete = !!(data.deadline || data.assigneeId || goal.deadline || goal.assigneeId)
    const updated = await prisma.goal.update({
      where: { id: goal.id },
      data: {
        ...data,
        deadline:
          data.deadline !== undefined
            ? data.deadline
              ? new Date(data.deadline)
              : null
            : undefined,
        isConcrete,
      },
      include: { assignee: { select: { id: true, email: true, name: true, avatar: true } } },
    })
    res.json({ ...updated, progress: await calcVoteProgress(updated.id) })
  } catch (err) {
    next(err)
  }
})

// DELETE /api/goals/:id
router.delete('/goals/:id', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({ where: { id: req.params.id } })
    if (!goal) {
      res.status(404).json({ error: 'ゴールが存在しません' })
      return
    }
    if (!(await assertMember(goal.groupId, userId, res))) return

    await prisma.goal.delete({ where: { id: goal.id } })
    res.json({ message: 'ゴールを削除しました' })
  } catch (err) {
    next(err)
  }
})

export default router
