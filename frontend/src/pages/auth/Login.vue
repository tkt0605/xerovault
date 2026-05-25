<template>
  <div class="w-full max-w-sm">
    <h1 class="text-2xl font-bold text-center mb-8">ログイン</h1>
    <form @submit.prevent="handleLogin" class="space-y-4">
      <input v-model="email" type="email" placeholder="メールアドレス" required autocomplete="email"
        class="w-full px-4 py-3 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500" />
      <input v-model="password" type="password" placeholder="パスワード" required autocomplete="current-password"
        class="w-full px-4 py-3 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500" />
      <p v-if="error" class="text-sm text-red-500">{{ error }}</p>
      <button type="submit" :disabled="loading"
        class="w-full py-3 rounded-xl bg-brand-500 text-white font-medium hover:bg-brand-600 disabled:opacity-50 transition">
        {{ loading ? 'ログイン中...' : 'ログイン' }}
      </button>
    </form>
    <p class="text-center mt-4 text-sm text-zinc-500">
      アカウントをお持ちでない方は
      <RouterLink to="/auth/signup" class="text-brand-500 hover:underline">新規登録</RouterLink>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
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
</script>
