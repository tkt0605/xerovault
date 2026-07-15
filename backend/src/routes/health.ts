import { Router } from 'express'
import { prisma } from '../db'

const router = Router()

// GET /api/health — 死活監視用（認証不要）
router.get('/', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`
    res.json({ status: 'ok', db: 'ok', uptime: process.uptime() })
  } catch (err) {
    console.error(err)
    res.status(503).json({ status: 'error', db: 'unreachable' })
  }
})

export default router
