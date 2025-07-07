<template>
    <div class="min-h-screen flex items-center justify-center bg-gray-100">
        <div class="w-full max-w-md bg-white p-8 rounded-2xl shadow-lg">
            <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">新規登録</h2>
            <form @submit.prevent="handleSignup">
                <div class="mb-4">
                    <label class="block mb-1 text-gray-600">メールアドレス</label>
                    <input v-model="email" type="email" required
                        class="text-black w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" />
                </div>
                <div class="mb-4">
                    <label class="block mb-1 text-gray-600">パスワード</label>
                    <input v-model="password" type="password" required
                        class="text-black w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" />
                </div>
                <div class="mb-6">
                    <label class="block mb-1 text-gray-600">パスワード（確認）</label>
                    <input v-model="confirmPassword" type="password" required
                        class="text-black w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400" />
                </div>
                <button type="submit"
                    class="text-black w-full bg-green-500 text-white py-2 rounded-lg hover:bg-green-600 transition duration-200">登録する</button>
            </form>
            <p class="mt-4 text-center text-sm text-gray-600">
                すでにアカウントをお持ちの方は
                <NuxtLink to="/auth/login" class="text-blue-500 hover:underline">ログイン</NuxtLink>
            </p>
        </div>
    </div>
</template>

<script setup>
import { useAuthStore } from '~/store/auth';
import { useRoute, useRouter } from 'vue-router';
const email = ref('');
const password = ref('');
const confirmPassword = ref('');
const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
definePageMeta({
  layout: 'auth',
});
const handleSignup = async () => {
    if (password.value !== confirmPassword.value) {
        alert('パスワードが一致しません')
        return
    }
    try {
        // TODO: 登録API呼び出し
        await authStore.signup(email.value, password.value);
        console.log('Signup with:',email.value, password.value);
        router.push('/');
    } catch (error) {
        console.error('サインアップエラー:', error);
        throw error;
    }
}
</script>
