<template>
  <div class="w-full max-w-sm">
    <h1 class="mb-8 text-center font-serif text-2xl font-medium text-ink">アカウント作成</h1>
    <form class="space-y-4" @submit.prevent="handleSignup">
      <BaseInput v-model="name" type="text" placeholder="名前" maxlength="50" autocomplete="name" />
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
        placeholder="パスワード（8文字以上）"
        required
        minlength="8"
      />
      <p v-if="error" class="text-sm text-bad">{{ error }}</p>
      <BaseButton type="submit" :disabled="loading" class="w-full justify-center py-3">
        {{ loading ? '登録中...' : '登録する' }}
      </BaseButton>
    </form>
    <p class="mt-4 text-center text-sm text-ink-soft">
      既にアカウントをお持ちの方は
      <RouterLink to="/auth/login" class="text-accent hover:underline">ログイン</RouterLink>
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
const name = ref('')
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleSignup() {
  loading.value = true
  error.value = ''
  try {
    await auth.signup(email.value, password.value, name.value || undefined)
    router.push('/')
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : '登録に失敗しました'
  } finally {
    loading.value = false
  }
}
</script>
