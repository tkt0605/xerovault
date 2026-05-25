import { Request, Response, NextFunction } from 'express'
import { verifyToken } from '../utils/jwt'
import { prisma } from '../db'
import { User } from '@prisma/client'

declare global {
  namespace Express {
    interface Request {
      user?: User
    }
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: '認証が必要です' })
    return
  }
  try {
    const token = header.slice(7)
    const payload = await verifyToken(token)
    if (payload.type !== 'access') throw new Error('invalid type')
    const user = await prisma.user.findUnique({ where: { id: payload.sub } })
    if (!user || !user.isActive) throw new Error('user not found')
    req.user = user
    next()
  } catch {
    res.status(401).json({ error: 'トークンが無効です' })
  }
}
