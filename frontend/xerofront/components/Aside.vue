<template>
  <aside class="w-72 min-h-screen bg-white dark:bg-zinc-900 border-r dark:border-zinc-700 p-4 flex flex-col gap-6">
    <!-- 操作ボタン -->
    <div class="flex flex-col gap-3">
      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-blue-600 hover:bg-blue-700 rounded transition"
        @click="createNewGroup">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2"
             viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path>
        </svg>
        新しいグループ
      </button>

      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-green-600 hover:bg-green-700 rounded transition">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2"
             viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round"
                d="M12 4v16m8-8H4m3-6h10a2 2 0 012 2v10a2 2 0 01-2 2H7a2 2 0 01-2-2V8a2 2 0 012-2z" />
        </svg>
        ライブラリ新規作成
      </button>

      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-purple-600 hover:bg-purple-700 rounded transition">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2"
             viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        トークン新規作成
      </button>

      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-gray-800 bg-gray-200 hover:bg-gray-300 dark:bg-zinc-700 dark:text-white dark:hover:bg-zinc-600 rounded transition">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2"
             viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        探す
      </button>
    </div>

    <!-- グループ一覧 -->
    <div>
      <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">グループ一覧</h2>
      <div class="flex flex-col gap-2">
        <div v-for="group in groups" :key="group.id"
             class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
          {{ group.name }}
        </div>
      </div>
    </div>

    <!-- マイ・ライブラリ -->
    <div>
      <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">マイ・ライブラリ</h2>
      <div class="flex flex-col gap-2">
        <div v-for="mylib in libraries" :key="mylib.id"
             class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
          {{ mylib.name }}
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';

const authStore = useAuthStore();
const currentUser = computed(()=>authStore.currentUser);


const groups = [
  { id: 1, name: 'ゼロボルト研究会' },
  { id: 2, name: '開発チームA' }
];

const libraries = [
  { id: 1, name: '研究資料2025' },
  { id: 2, name: 'セキュリティポリシー' }
];

function createNewGroup() {
  console.log("新しいグループ作成");
}
</script>
