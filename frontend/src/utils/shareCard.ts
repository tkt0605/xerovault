const CARD_WIDTH = 1200
const CARD_HEIGHT = 630

const SERIF_FONT_STACK =
  'ui-serif, "Iowan Old Style", "Palatino Linotype", "Hiragino Mincho ProN", "Noto Serif JP", serif'
const SANS_FONT_STACK =
  '-apple-system, BlinkMacSystemFont, "Segoe UI", "Hiragino Kaku Gothic ProN", "Yu Gothic", "Noto Sans JP", sans-serif'

function cssVar(name: string): string {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}

export function generateShareCardDataUrl(groupName: string): string {
  const canvas = document.createElement('canvas')
  canvas.width = CARD_WIDTH
  canvas.height = CARD_HEIGHT
  const ctx = canvas.getContext('2d')
  if (!ctx) return ''

  ctx.fillStyle = cssVar('--paper-raised')
  ctx.fillRect(0, 0, CARD_WIDTH, CARD_HEIGHT)

  ctx.fillStyle = cssVar('--accent-soft')
  ctx.fillRect(0, 0, CARD_WIDTH, 12)

  ctx.fillStyle = cssVar('--accent')
  ctx.font = `600 28px ${SANS_FONT_STACK}`
  ctx.fillText('Xerovault クローズドβに招待されました', 80, 140)

  ctx.fillStyle = cssVar('--ink')
  ctx.font = `500 56px ${SERIF_FONT_STACK}`
  ctx.fillText(groupName, 80, 260)

  ctx.fillStyle = cssVar('--ink-soft')
  ctx.font = `400 30px ${SANS_FONT_STACK}`
  ctx.fillText('曖昧な目標を許さない。自己申告を許さない。', 80, 360)
  ctx.fillText('メンバーの投票だけが、達成を決める。', 80, 405)

  ctx.strokeStyle = cssVar('--line')
  ctx.lineWidth = 1
  ctx.beginPath()
  ctx.moveTo(80, 470)
  ctx.lineTo(CARD_WIDTH - 80, 470)
  ctx.stroke()

  ctx.fillStyle = cssVar('--ink-faint')
  ctx.font = `400 22px ${SANS_FONT_STACK}`
  ctx.fillText('xerovault', 80, 540)

  return canvas.toDataURL('image/png')
}
