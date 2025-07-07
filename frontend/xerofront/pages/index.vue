<template>
  <main class="ml-72 flex-1 p-6 bg-gray-50 dark:bg-zinc-800 min-h-screen">
    <!-- トップセクション -->
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-white">
        ようこそ、{{ currentUser?.email || 'ユーザー' }} さん
      </h1>
      <p class="text-sm text-gray-500 dark:text-gray-300">今日も安全な情報管理を。</p>
    </div>

    <!-- ダッシュボードブロック -->
    <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 md:gap-6 place-items-center mb-10">
      <!-- スタジオ -->
      <div
        class="w-5/6 sm:w-32 md:w-36 lg:w-40 bg-white dark:bg-zinc-900 rounded-full aspect-square shadow hover:shadow-md transition flex flex-col items-center justify-center">
        <p class="text-xs sm:text-sm text-gray-500 dark:text-gray-400">スタジオ数</p>
        <p class="text-lg sm:text-xl md:text-2xl font-bold text-blue-600 dark:text-blue-400">3</p>
      </div>

      <!-- ライブラリ -->
      <div
        class="w-5/6 sm:w-32 md:w-36 lg:w-40 bg-white dark:bg-zinc-900 rounded-full aspect-square shadow hover:shadow-md transition flex flex-col items-center justify-center">
        <p class="text-xs sm:text-sm text-gray-500 dark:text-gray-400">ライブラリ数</p>
        <p class="text-lg sm:text-xl md:text-2xl font-bold text-green-600 dark:text-green-400">12</p>
      </div>

      <!-- 未読通知 -->
      <div
        class="w-5/6 sm:w-32 md:w-36 lg:w-40 bg-white dark:bg-zinc-900 rounded-full aspect-square shadow hover:shadow-md transition flex flex-col items-center justify-center cursor-pointer"
        @click="JampToInviting">
        <p class="text-xs sm:text-sm text-gray-500 dark:text-gray-400">未読通知</p>
        <p class="text-lg sm:text-xl md:text-2xl font-bold text-red-600 dark:text-red-400">5</p>
      </div>
    </div>

    <!-- 最近の活動 -->
    <div>
      <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-4">最近のアクティビティ</h2>
      <div class="bg-white dark:bg-zinc-900 rounded-xl shadow p-4 divide-y dark:divide-zinc-700">
        <div class="py-2 text-gray-700 dark:text-gray-200">🔒 トークン「開発用APIキー」が作成されました</div>
        <div class="py-2 text-gray-700 dark:text-gray-200">📁 ライブラリ「研究資料2025」が追加されました</div>
        <div class="py-2 text-gray-700 dark:text-gray-200">✅ グループ「ゼロボルト研究会」に新しいメンバーが参加</div>
      </div>
    </div>
  </main>
</template>

<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';

import { useAuthFreinds } from '~/store/freind';
const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const friendStore = useAuthFreinds();
const currentUser = computed(() => authStore.currentUser);


const JampToInviting = async () => {
  return router.push(`/invite/${authStore.user.id}`);
};
</script>
