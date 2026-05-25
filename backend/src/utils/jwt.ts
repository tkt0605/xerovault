import { SignJWT, jwtVerify } from 'jose'

const secret = new TextEncoder().encode(process.env.JWT_SECRET ?? 'change-me')

export async function signAccess(userId: string): Promise<string> {
  return new SignJWT({ sub: userId, type: 'access' })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('60m')
    .setIssuedAt()
    .sign(secret)
}

export async function signRefresh(userId: string): Promise<string> {
  return new SignJWT({ sub: userId, type: 'refresh' })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('7d')
    .setIssuedAt()
    .sign(secret)
}

export async function verifyToken(token: string): Promise<{ sub: string; type: string }> {
  const { payload } = await jwtVerify(token, secret)
  return payload as { sub: string; type: string }
}
