import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Session } from '@supabase/supabase-js'
import type { UserSummary } from '@sodalis/shared'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const session = ref<Session | null>(null)
  const user = ref<UserSummary | null>(null)

  const isAuthenticated = computed(() => !!session.value)

  async function fetchProfile(userId: string): Promise<void> {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, email, name, avatar')
      .eq('id', userId)
      .single()
    if (error) throw new Error(error.message)
    user.value = data as UserSummary
  }

  async function login(email: string, password: string): Promise<void> {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw new Error('メールアドレスまたはパスワードが正しくありません')
    session.value = data.session
    await fetchProfile(data.user.id)
  }

  async function signup(email: string, password: string, name?: string): Promise<void> {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: name } },
    })
    if (error) throw new Error(error.message)
    if (!data.session || !data.user) {
      throw new Error('確認メールを送信しました。メール内のリンクから登録を完了してください')
    }
    session.value = data.session
    await fetchProfile(data.user.id)
  }

  async function logout(): Promise<void> {
    await supabase.auth.signOut()
    session.value = null
    user.value = null
  }

  // ページロード時にセッション復元
  async function restoreSession(): Promise<void> {
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    if (data.session) await fetchProfile(data.session.user.id)
  }

  supabase.auth.onAuthStateChange((_event, newSession) => {
    session.value = newSession
    if (newSession) {
      fetchProfile(newSession.user.id).catch(() => {
        user.value = null
      })
    } else {
      user.value = null
    }
  })

  return { session, user, isAuthenticated, login, signup, logout, restoreSession, fetchProfile }
})
