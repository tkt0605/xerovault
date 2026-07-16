import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { UserSummary, AuthResponse } from '@xerovault/shared'

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref<string | null>(null)
  const user = ref<UserSummary | null>(null)

  const isAuthenticated = computed(() => !!accessToken.value)

  async function login(email: string, password: string): Promise<void> {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ email, password }),
    })
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.error ?? 'ログインに失敗しました')
    }
    const data: AuthResponse = await res.json()
    accessToken.value = data.access
    user.value = data.user
  }

  async function signup(email: string, password: string, name?: string): Promise<void> {
    const res = await fetch('/api/auth/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ email, password, name }),
    })
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.error ?? '登録に失敗しました')
    }
    const data: AuthResponse = await res.json()
    accessToken.value = data.access
    user.value = data.user
  }

  // SupabaseのGoogle OAuthセッション(access_token)をバックエンドで検証し、アプリ独自のセッションを発行する
  async function loginWithGoogle(supabaseAccessToken: string): Promise<void> {
    const res = await fetch('/api/auth/google', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ accessToken: supabaseAccessToken }),
    })
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.error ?? 'Googleログインに失敗しました')
    }
    const data: AuthResponse = await res.json()
    accessToken.value = data.access
    user.value = data.user
  }

  async function logout(): Promise<void> {
    await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' })
    accessToken.value = null
    user.value = null
  }

  // リフレッシュトークン（Cookie）でアクセストークンを更新
  async function refresh(): Promise<boolean> {
    try {
      const res = await fetch('/api/auth/refresh', {
        method: 'POST',
        credentials: 'include',
      })
      if (!res.ok) {
        accessToken.value = null
        user.value = null
        return false
      }
      const data: { access: string } = await res.json()
      accessToken.value = data.access
      return true
    } catch {
      return false
    }
  }

  // ページロード時にセッション復元
  async function restoreSession(): Promise<void> {
    const ok = await refresh()
    if (ok) {
      const res = await fetch('/api/auth/me', {
        headers: { Authorization: `Bearer ${accessToken.value}` },
        credentials: 'include',
      })
      if (res.ok) user.value = (await res.json()) as UserSummary
    }
  }

  return {
    accessToken,
    user,
    isAuthenticated,
    login,
    signup,
    loginWithGoogle,
    logout,
    refresh,
    restoreSession,
  }
})
