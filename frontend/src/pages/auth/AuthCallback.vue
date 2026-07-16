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

const router = useRouter()
const error = ref('')

onMounted(async () => {
  const { data, error: sessionError } = await supabase.auth.getSession()
  if (sessionError || !data.session) {
    error.value = 'Googleログインに失敗しました'
    return
  }
  router.push('/')
})
</script>
