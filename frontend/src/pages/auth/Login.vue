<template>
  <div class="w-full max-w-sm">
    <h1 class="mb-8 text-center font-serif text-2xl font-medium text-ink">ログイン</h1>
    <form class="space-y-4" @submit.prevent="handleLogin">
      <BaseInput
        v-model="email"
        type="email"
        placeholder="メールアドレス"
        required
        autocomplete="email"
      />
      <BaseInput
        v-model="password"
        type="password"
        placeholder="パスワード"
        required
        autocomplete="current-password"
      />
      <p v-if="error" class="text-sm text-bad">{{ error }}</p>
      <BaseButton type="submit" :disabled="loading" class="w-full justify-center py-3">
        {{ loading ? 'ログイン中...' : 'ログイン' }}
      </BaseButton>
    </form>

    <div class="my-5 flex items-center gap-3">
      <div class="h-px flex-1 bg-line" />
      <span class="text-xs text-ink-faint">または</span>
      <div class="h-px flex-1 bg-line" />
    </div>

    <BaseButton
      type="button"
      variant="ghost"
      :disabled="googleLoading"
      class="w-full justify-center gap-2 py-3"
      @click="handleGoogleLogin"
    >
      <GoogleIcon :size="16" />
      {{ googleLoading ? 'リダイレクト中...' : 'Googleでログイン' }}
    </BaseButton>

    <p class="mt-4 text-center text-sm text-ink-soft">
      アカウントをお持ちでない方は
      <RouterLink to="/auth/signup" class="text-accent hover:underline">新規登録</RouterLink>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import BaseInput from '@/components/ui/BaseInput.vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import GoogleIcon from '@/components/ui/GoogleIcon.vue'

const auth = useAuthStore()
const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
const googleLoading = ref(false)
const error = ref('')

async function handleLogin() {
  loading.value = true
  error.value = ''
  try {
    await auth.login(email.value, password.value)
    router.push('/')
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'ログインに失敗しました'
  } finally {
    loading.value = false
  }
}

async function handleGoogleLogin() {
  googleLoading.value = true
  error.value = ''
  const { error: oauthError } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: `${window.location.origin}/auth/callback` },
  })
  if (oauthError) {
    error.value = oauthError.message
    googleLoading.value = false
  }
}
</script>
