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
import BaseInput from '@/components/ui/BaseInput.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

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
