import { Router } from 'express'
import { prisma } from '../db'

const router = Router()

// GET /api/rankings — 公開グループのスコアランキング（認証不要）
router.get('/', async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 20, 100)
    const groups = await prisma.group.findMany({
      where: { isPublic: true },
      select: {
        id: true,
        name: true,
        tag: true,
        score: true,
        streak: true,
        createdAt: true,
        owner: { select: { id: true, email: true, avatar: true } },
        _count: { select: { members: true, goals: true } },
      },
      orderBy: { score: 'desc' },
      take: limit,
    })
    res.json(groups)
  } catch (err) {
    next(err)
  }
})

export default router
