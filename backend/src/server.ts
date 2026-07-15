import 'dotenv/config'
import app from './app'
import { prisma } from './db'
import { runScoreSweep } from './services/scoreService'

const PORT = Number(process.env.PORT ?? 8000)
const SCORE_SWEEP_INTERVAL_MS = Number(process.env.SCORE_SWEEP_INTERVAL_MS ?? 300_000)

async function main() {
  await prisma.$connect()
  console.log('Database connected')
  app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`))

  runScoreSweep().catch((err) => console.error('Initial score sweep failed', err))
  setInterval(() => {
    runScoreSweep().catch((err) => console.error('Score sweep failed', err))
  }, SCORE_SWEEP_INTERVAL_MS)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
