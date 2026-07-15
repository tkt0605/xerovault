import { Router } from 'express'
import { z } from 'zod'
import { randomUUID } from 'crypto'
import { prisma } from '../db'
import { requireAuth } from '../middleware/auth'
import { encryptInvite, decryptInvite } from '../utils/crypto'

const router = Router()
router.use(requireAuth)

// GET /api/groups — 参加中のグループ一覧
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const groups = await prisma.group.findMany({
      where: { OR: [{ ownerId: userId }, { members: { some: { id: userId } } }] },
      include: {
        owner: { select: { id: true, email: true, name: true, avatar: true } },
        members: { select: { id: true, email: true, name: true, avatar: true } },
        _count: { select: { goals: true } },
      },
      orderBy: { updatedAt: 'desc' },
    })
    res.json(groups)
  } catch (err) {
    next(err)
  }
})

// POST /api/groups — グループ作成
router.post('/', async (req, res, next) => {
  try {
    const { name, tag, isPublic } = z
      .object({
        name: z.string().min(1).max(50),
        tag: z.string().max(30).optional(),
        isPublic: z.boolean().default(false),
      })
      .parse(req.body)

    const userId = req.user!.id
    const group = await prisma.group.create({
      data: {
        name,
        tag,
        isPublic,
        owner: { connect: { id: userId } },
        members: { connect: { id: userId } },
      },
      include: {
        owner: { select: { id: true, email: true, name: true, avatar: true } },
        members: { select: { id: true, email: true, name: true, avatar: true } },
      },
    })
    res.status(201).json(group)
  } catch (err) {
    next(err)
  }
})

// GET /api/groups/:id — グループ詳細
router.get('/:id', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const group = await prisma.group.findUnique({
      where: { id: req.params.id },
      include: {
        owner: { select: { id: true, email: true, name: true, avatar: true } },
        members: { select: { id: true, email: true, name: true, avatar: true } },
        _count: { select: { goals: true } },
      },
    })
    if (!group) {
      res.status(404).json({ error: 'グループが存在しません' })
      return
    }

    const isMember = group.members.some((m) => m.id === userId) || group.ownerId === userId
    if (!isMember && !group.isPublic) {
      res.status(403).json({ error: 'アクセス権がありません' })
      return
    }
    res.json(group)
  } catch (err) {
    next(err)
  }
})

// POST /api/groups/:id/invite — 招待リンク生成（オーナーのみ）
router.post('/:id/invite', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const { expireIn = 3600 } = z
      .object({ expireIn: z.number().min(300).max(86400).default(3600) })
      .parse(req.body)

    const group = await prisma.group.findUnique({ where: { id: req.params.id } })
    if (!group) {
      res.status(404).json({ error: 'グループが存在しません' })
      return
    }
    if (group.ownerId !== userId) {
      res.status(403).json({ error: '招待権限がありません' })
      return
    }

    const token = randomUUID()
    const exp = Math.floor(Date.now() / 1000) + expireIn
    await prisma.group.update({ where: { id: group.id }, data: { joinToken: token } })

    const encrypted = encryptInvite({ token, exp, groupId: group.id })
    res.json({ encryptedData: encrypted })
  } catch (err) {
    next(err)
  }
})

// POST /api/groups/:id/join — 招待リンクで参加
router.post('/:id/join', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const { data } = z.object({ data: z.string() }).parse(req.body)

    const payload = decryptInvite(data) as { token: string; exp: number; groupId: string } | null
    if (!payload) {
      res.status(400).json({ error: '無効な招待リンクです' })
      return
    }
    if (Date.now() / 1000 > payload.exp) {
      res.status(400).json({ error: '招待リンクの有効期限が切れています' })
      return
    }

    const group = await prisma.group.findUnique({
      where: { id: req.params.id },
      include: { members: { select: { id: true } } },
    })
    if (!group || group.joinToken !== payload.token) {
      res.status(400).json({ error: '無効なトークンです' })
      return
    }
    if (group.members.some((m) => m.id === userId)) {
      res.status(400).json({ error: 'すでに参加しています' })
      return
    }

    const updated = await prisma.group.update({
      where: { id: group.id },
      data: { members: { connect: { id: userId } } },
      include: {
        owner: { select: { id: true, email: true, name: true, avatar: true } },
        members: { select: { id: true, email: true, name: true, avatar: true } },
      },
    })
    res.json({ message: `${group.name}に参加しました`, group: updated })
  } catch (err) {
    next(err)
  }
})

// DELETE /api/groups/:id/members/:userId — メンバー除名（オーナーのみ）
router.delete('/:id/members/:memberId', async (req, res, next) => {
  try {
    const userId = req.user!.id
    const group = await prisma.group.findUnique({ where: { id: req.params.id } })
    if (!group) {
      res.status(404).json({ error: 'グループが存在しません' })
      return
    }
    if (group.ownerId !== userId) {
      res.status(403).json({ error: '除名権限がありません' })
      return
    }
    if (group.ownerId === req.params.memberId) {
      res.status(400).json({ error: 'オーナーを除名できません' })
      return
    }

    await prisma.group.update({
      where: { id: group.id },
      data: { members: { disconnect: { id: req.params.memberId } } },
    })
    res.json({ message: 'メンバーを除名しました' })
  } catch (err) {
    next(err)
  }
})

export default router
