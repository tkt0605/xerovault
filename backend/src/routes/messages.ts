import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { requireAuth } from '../middleware/auth'

const router = Router()
router.use(requireAuth)

// GET /api/goals/:id/messages
router.get('/goals/:id/messages', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({
      where: { id: req.params.id },
      include: { group: { include: { members: { select: { id: true } } } } },
    })
    if (!goal) { res.status(404).json({ error: 'ゴールが存在しません' }); return }

    const isMember =
      goal.group.ownerId === userId || goal.group.members.some((m) => m.id === userId)
    if (!isMember) { res.status(403).json({ error: 'アクセス権がありません' }); return }

    const messages = await prisma.message.findMany({
      where: { goalId: req.params.id },
      include: { author: { select: { id: true, email: true, avatar: true } } },
      orderBy: { createdAt: 'asc' },
    })
    res.json(messages)
  } catch (err) {
    next(err)
  }
})

// POST /api/goals/:id/messages
router.post('/goals/:id/messages', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const { text } = z.object({ text: z.string().min(1).max(2000) }).parse(req.body)

    const goal = await prisma.goal.findUnique({
      where: { id: req.params.id },
      include: { group: { include: { members: { select: { id: true } } } } },
    })
    if (!goal) { res.status(404).json({ error: 'ゴールが存在しません' }); return }

    const isMember =
      goal.group.ownerId === userId || goal.group.members.some((m) => m.id === userId)
    if (!isMember) { res.status(403).json({ error: 'グループのメンバーではありません' }); return }

    const message = await prisma.message.create({
      data: { text, goalId: goal.id, authorId: userId },
      include: { author: { select: { id: true, email: true, avatar: true } } },
    })
    res.status(201).json(message)
  } catch (err) {
    next(err)
  }
})

export default router
