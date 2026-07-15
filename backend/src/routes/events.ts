import { Router } from 'express'
import { prisma } from '../db'
import { requireAuth } from '../middleware/auth'
import { subscribeGoalEvents } from '../services/eventBus'

const router = Router()
router.use(requireAuth)

const HEARTBEAT_INTERVAL_MS = 25000

// GET /api/goals/:id/events — 投票・チャットのリアルタイム更新(SSE)
router.get('/goals/:id/events', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const goal = await prisma.goal.findUnique({
      where: { id: req.params.id },
      include: { group: { include: { members: { select: { id: true } } } } },
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

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.flushHeaders()

    const send = (event: string, data: unknown): void => {
      res.write(`event: ${event}\n`)
      res.write(`data: ${JSON.stringify(data)}\n\n`)
    }

    send('connected', { goalId: goal.id })

    const unsubscribe = subscribeGoalEvents(goal.id, (eventName, payload) => {
      send(eventName, payload)
    })

    const heartbeat = setInterval(() => {
      res.write(': heartbeat\n\n')
    }, HEARTBEAT_INTERVAL_MS)

    req.on('close', () => {
      clearInterval(heartbeat)
      unsubscribe()
      res.end()
    })
  } catch (err) {
    next(err)
  }
})

export default router
