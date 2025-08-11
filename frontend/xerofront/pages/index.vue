<template>
  <main class="ml-72 flex-1 p-6 bg-gray-50 dark:bg-zinc-800">
    <!-- トップメッセージ -->
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-white">
        ようこそ、{{ currentUser?.email || 'ユーザー' }} さん
      </h1>
      <p class="text-sm text-gray-500 dark:text-gray-300">今日も安全な情報管理を。</p>
    </div>


    <!-- 自身のスタジオ -->
    <section class="mb-10">
      <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-4">🎛 自分が作成したスタジオ</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="studio in ownerStudios" :key="studio.id"
          class="bg-white dark:bg-zinc-900 rounded-xl shadow p-4 hover:shadow-lg transition cursor-pointer"
          @click="goToStudio(studio.id)">
          <h3 class="text-lg font-bold text-blue-600 dark:text-blue-400">{{ studio.name }}</h3>
          <p class="text-sm text-gray-500 dark:text-gray-300 mt-1">{{ studio.description || '説明なし' }}</p>
        </div>
      </div>
    </section>

    <!-- 所属スタジオ -->
    <section class="mb-10">
      <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-4">📡 所属しているスタジオ</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="studio in joinedStudios" :key="studio.id"
          class="bg-white dark:bg-zinc-900 rounded-xl shadow p-4 hover:shadow-lg transition cursor-pointer"
          @click="goToStudio(studio.id)">
          <h3 class="text-lg font-bold text-green-600 dark:text-green-400">{{ studio.name }}</h3>
          <p class="text-sm text-gray-500 dark:text-gray-300 mt-1">{{ studio.description || '説明なし' }}</p>
        </div>
      </div>
    </section>

    <!-- 最近のアクティビティ -->
    <section>
      <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-4">📌 最近のアクティビティ</h2>
      <div class="bg-white dark:bg-zinc-900 rounded-xl shadow p-4 divide-y dark:divide-zinc-700">
        <div class="py-2 text-gray-700 dark:text-gray-200">🔒 トークン「開発用APIキー」が作成されました</div>
        <div class="py-2 text-gray-700 dark:text-gray-200">📁 ライブラリ「研究資料2025」が追加されました</div>
        <div class="py-2 text-gray-700 dark:text-gray-200">✅ グループ「ゼロボルト研究会」に新しいメンバーが参加</div>
      </div>
    </section>
  </main>
</template>

<style scoped>
.stat-card {
  @apply w-5/6 sm:w-32 md:w-36 lg:w-40 rounded-full aspect-square shadow flex flex-col items-center justify-center text-white text-lg font-bold transition;
}
</style>

<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const currentUser = computed(() => authStore.currentUser);


const JampToInviting = async () => {
  return router.push(`/invite/${authStore.user.id}`);
};
</script>
