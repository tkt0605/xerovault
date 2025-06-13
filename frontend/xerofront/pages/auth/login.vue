<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100">
    <div class="w-full max-w-md bg-white p-8 rounded-2xl shadow-lg">
      <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">ログイン</h2>
      <form @submit.prevent="handleLogin">
        <div class="mb-4">
          <label class="block mb-1 text-gray-600">メールアドレス</label>
          <input v-model="email" type="email" required class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" />
        </div>
        <div class="mb-6">
          <label class="block mb-1 text-gray-600">パスワード</label>
          <input v-model="password" type="password" required class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" />
        </div>
        <button type="submit" class="w-full bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600 transition duration-200">ログイン</button>
      </form>
      <p class="mt-4 text-center text-sm text-gray-600">
        アカウントをお持ちでない方は
        <NuxtLink to="/auth/signup" class="text-blue-500 hover:underline">こちら</NuxtLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '~/store/auth';
import { useRoute, useRouter } from 'vue-router';

const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const email = ref('')
const password = ref('')

const handleLogin = async () => {
  // TODO: 認証API呼び出し
  try{
    await authStore.login(email.value, password.value);
    console.log('Login with:', email.value, password.value);
    router.push('/');
  }catch(error){
    console.error("ログイン失敗", error);
    throw error;
  }
}
</script>

