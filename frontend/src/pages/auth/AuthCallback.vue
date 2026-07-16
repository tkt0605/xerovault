<template>
  <div class="w-full max-w-sm text-center">
    <p v-if="error" class="text-sm text-bad">{{ error }}</p>
    <p v-else class="text-sm text-ink-soft">ログイン処理中...</p>
    <RouterLink
      v-if="error"
      to="/auth/login"
      class="mt-4 inline-block text-sm text-accent hover:underline"
    >
      ログイン画面へ戻る
    </RouterLink>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()
const error = ref('')

onMounted(async () => {
  const { data, error: sessionError } = await supabase.auth.getSession()
  const token = data.session?.access_token
  if (sessionError || !token) {
    error.value = 'Googleログインに失敗しました'
    return
  }
  try {
    await auth.loginWithGoogle(token)
    router.push('/')
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Googleログインに失敗しました'
  }
})
</script>
