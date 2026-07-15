import { Request, Response, NextFunction } from 'express'
import { ZodError } from 'zod'

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  if (err instanceof ZodError) {
    res.status(400).json({ error: '入力値が正しくありません', details: err.flatten() })
    return
  }
  console.error(err)
  res.status(500).json({ error: 'サーバーエラーが発生しました' })
}
