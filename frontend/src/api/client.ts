import { useAuthStore } from '@/stores/auth'

type Method = 'GET' | 'POST' | 'PATCH' | 'DELETE'

async function request<T>(method: Method, path: string, body?: unknown): Promise<T> {
  const auth = useAuthStore()
  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  if (auth.accessToken) headers['Authorization'] = `Bearer ${auth.accessToken}`

  const res = await fetch(`/api${path}`, {
    method,
    headers,
    credentials: 'include',
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  // アクセストークン期限切れ → リフレッシュして再試行
  if (res.status === 401 && auth.accessToken) {
    const ok = await auth.refresh()
    if (ok) {
      headers['Authorization'] = `Bearer ${auth.accessToken}`
      const retry = await fetch(`/api${path}`, {
        method,
        headers,
        credentials: 'include',
        body: body !== undefined ? JSON.stringify(body) : undefined,
      })
      if (!retry.ok) throw await retry.json()
      return retry.json() as Promise<T>
    }
  }

  if (!res.ok) throw await res.json()
  if (res.status === 204) return undefined as T
  return res.json() as Promise<T>
}

export const api = {
  get: <T>(path: string) => request<T>('GET', path),
  post: <T>(path: string, body?: unknown) => request<T>('POST', path, body),
  patch: <T>(path: string, body?: unknown) => request<T>('PATCH', path, body),
  delete: <T>(path: string) => request<T>('DELETE', path),
}
