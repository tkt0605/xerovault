import { Router } from 'express'
import bcrypt from 'bcryptjs'
import { signupSchema, loginSchema, googleAuthSchema } from '@xerovault/shared'
import { prisma } from '../db'
import { signAccess, signRefresh, verifyToken } from '../utils/jwt'
import { requireAuth } from '../middleware/auth'

const router = Router()

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax' as const,
  maxAge: 7 * 24 * 60 * 60 * 1000,
}

function avatarUrl(email: string): string {
  const seed = email.split('@')[0]
  return `https://api.dicebear.com/9.x/identicon/svg?seed=${seed}`
}

// POST /api/auth/signup
router.post('/signup', async (req, res, next) => {
  try {
    const { email, password, name } = signupSchema.parse(req.body)

    const exists = await prisma.user.findUnique({ where: { email } })
    if (exists) {
      res.status(400).json({ error: 'このメールアドレスは既に使用されています' })
      return
    }

    const hashed = await bcrypt.hash(password, 12)
    const user = await prisma.user.create({
      data: { email, password: hashed, name, avatar: avatarUrl(email) },
    })

    const [access, refresh] = await Promise.all([signAccess(user.id), signRefresh(user.id)])
    res.cookie('refresh_token', refresh, COOKIE_OPTS)
    res.status(201).json({
      access,
      user: { id: user.id, email: user.email, name: user.name, avatar: user.avatar },
    })
  } catch (err) {
    next(err)
  }
})

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = loginSchema.parse(req.body)

    const user = await prisma.user.findUnique({ where: { email } })
    if (!user || !user.password || !(await bcrypt.compare(password, user.password))) {
      res.status(401).json({ error: 'メールアドレスまたはパスワードが正しくありません' })
      return
    }

    const [access, refresh] = await Promise.all([signAccess(user.id), signRefresh(user.id)])
    res.cookie('refresh_token', refresh, COOKIE_OPTS)
    res.json({
      access,
      user: { id: user.id, email: user.email, name: user.name, avatar: user.avatar },
    })
  } catch (err) {
    next(err)
  }
})

// POST /api/auth/google — Supabase経由のGoogle OAuthセッションを検証し、アプリ独自のセッションを発行する
router.post('/google', async (req, res, next) => {
  try {
    const { accessToken } = googleAuthSchema.parse(req.body)

    const supabaseUrl = process.env.SUPABASE_URL
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY
    if (!supabaseUrl || !supabaseAnonKey) {
      res.status(500).json({ error: 'Supabaseの設定が不足しています' })
      return
    }

    const supabaseRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${accessToken}`, apikey: supabaseAnonKey },
    })
    if (!supabaseRes.ok) {
      res.status(401).json({ error: 'Google認証の検証に失敗しました' })
      return
    }

    const supabaseUser = (await supabaseRes.json()) as {
      email?: string
      user_metadata?: Record<string, unknown>
    }
    const email = supabaseUser.email
    if (!email) {
      res.status(400).json({ error: 'メールアドレスを取得できませんでした' })
      return
    }

    const metadata = supabaseUser.user_metadata ?? {}
    const name = (metadata.full_name ?? metadata.name ?? null) as string | null
    const avatar = (metadata.avatar_url ?? metadata.picture ?? avatarUrl(email)) as string

    let user = await prisma.user.findUnique({ where: { email } })
    if (!user) {
      // 既存の同一メールアカウントがなければ、Googleプロフィールから新規作成する（passwordなし）
      user = await prisma.user.create({ data: { email, password: null, name, avatar } })
    }
    if (!user.isActive) {
      res.status(403).json({ error: 'このアカウントは無効化されています' })
      return
    }

    const [access, refresh] = await Promise.all([signAccess(user.id), signRefresh(user.id)])
    res.cookie('refresh_token', refresh, COOKIE_OPTS)
    res.json({
      access,
      user: { id: user.id, email: user.email, name: user.name, avatar: user.avatar },
    })
  } catch (err) {
    next(err)
  }
})

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const token = req.cookies?.refresh_token as string | undefined
    if (!token) {
      res.status(401).json({ error: 'リフレッシュトークンがありません' })
      return
    }
    const payload = await verifyToken(token)
    if (payload.type !== 'refresh') throw new Error('invalid type')

    const user = await prisma.user.findUnique({ where: { id: payload.sub } })
    if (!user || !user.isActive) {
      res.status(401).json({ error: 'ユーザーが存在しません' })
      return
    }

    const [access, newRefresh] = await Promise.all([signAccess(user.id), signRefresh(user.id)])
    res.cookie('refresh_token', newRefresh, COOKIE_OPTS)
    res.json({ access })
  } catch {
    res.clearCookie('refresh_token')
    res.status(401).json({ error: 'トークンが無効です' })
  }
})

// POST /api/auth/logout
router.post('/logout', (req, res) => {
  res.clearCookie('refresh_token')
  res.json({ message: 'ログアウトしました' })
})

// GET /api/auth/me
router.get('/me', requireAuth, (req, res) => {
  const u = req.user!
  res.json({ id: u.id, email: u.email, name: u.name, avatar: u.avatar })
})

export default router
