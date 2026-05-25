import { createCipheriv, createDecipheriv, randomBytes } from 'crypto'

const ALGORITHM = 'aes-256-cbc'

function getKey(): Buffer {
  const raw = process.env.AES_SECRET_KEY ?? ''
  if (!raw) throw new Error('AES_SECRET_KEY is not set')
  return Buffer.from(raw, 'base64').subarray(0, 32)
}

export function encryptInvite(data: object): string {
  const iv = randomBytes(16)
  const cipher = createCipheriv(ALGORITHM, getKey(), iv)
  const json = JSON.stringify(data)
  const encrypted = Buffer.concat([cipher.update(json, 'utf8'), cipher.final()])
  return iv.toString('hex') + ':' + encrypted.toString('hex')
}

export function decryptInvite(encrypted: string): object | null {
  try {
    const [ivHex, dataHex] = encrypted.split(':')
    const iv = Buffer.from(ivHex, 'hex')
    const decipher = createDecipheriv(ALGORITHM, getKey(), iv)
    const decrypted = Buffer.concat([
      decipher.update(Buffer.from(dataHex, 'hex')),
      decipher.final(),
    ])
    return JSON.parse(decrypted.toString('utf8'))
  } catch {
    return null
  }
}
