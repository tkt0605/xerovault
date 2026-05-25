import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import cookieParser from 'cookie-parser'
import { errorHandler } from './middleware/errorHandler'
import authRoutes from './routes/auth'
import groupRoutes from './routes/groups'
import goalRoutes from './routes/goals'
import voteRoutes from './routes/votes'
import messageRoutes from './routes/messages'
import rankingRoutes from './routes/rankings'

const app = express()

app.use(helmet())
app.use(cors({
  origin: process.env.CORS_ORIGIN ?? 'http://localhost:5173',
  credentials: true,
}))
app.use(express.json())
app.use(cookieParser())

app.use('/api/auth', authRoutes)
app.use('/api', groupRoutes)
app.use('/api', goalRoutes)
app.use('/api', voteRoutes)
app.use('/api', messageRoutes)
app.use('/api/rankings', rankingRoutes)

app.use(errorHandler)

export default app
