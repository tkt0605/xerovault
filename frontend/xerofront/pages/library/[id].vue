<template>
  <main
    class="flex-1 px-6 py-12 overflow-y-auto bg-gradient-to-tr from-zinc-100 to-white dark:from-zinc-950 dark:to-zinc-900">
    <section
      class="max-w-5xl mx-auto  backdrop-blur-md border border-zinc-200 dark:border-zinc-800 rounded-3xl shadow-2xl p-10 space-y-10">

      <!-- タイトル -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
        <div>
          <h1 class="text-4xl font-extrabold tracking-tight text-zinc-900 dark:text-white">
            {{ libraries.name }}
          </h1>
          <div class="mt-3">
            <span
              class="text-sm font-medium inline-flex items-center px-2 py-1 rounded bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-200">
              {{ libraries.tag || '未分類' }}
            </span>
          </div>
        </div>
        <span :class="libraries.is_public
          ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-800 dark:text-emerald-200'
          : 'bg-rose-100 text-rose-700 dark:bg-rose-800 dark:text-rose-200'"
          class="inline-flex items-center gap-2 text-sm font-semibold px-4 py-2 rounded-full shadow-sm">
          {{ libraries.is_public ? '公開中' : '非公開' }}
        </span>
      </div>

      <!-- 詳細情報 -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-8 text-sm">
        <div>
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">オーナー</p>
          <p class="mt-2 text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {{ libraries.owner?.email }}
          </p>
        </div>
        <div>
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">ライブラリID</p>
          <p class="mt-2 text-xs break-all text-zinc-500 dark:text-zinc-400">
            {{ libraries.id }}
          </p>
        </div>
        <div>
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">作成日</p>
          <p class="mt-2 text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {{ formatDate(libraries.created_at) }}
          </p>
        </div>
        <div>
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">更新日</p>
          <p class="mt-2 text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {{ formatDate(libraries.updated_at) }}
          </p>
        </div>
      </div>
      <form @submit.prevent="uploadFile" enctype="multipart/form-data"
        class="space-y-4 bg-zinc-50 dark:bg-zinc-800 p-6 rounded-xl border border-zinc-200 dark:border-zinc-700">
        <!-- ファイル選択 -->
        <div>
          <label for="file" class="block text-sm font-medium text-zinc-700 dark:text-zinc-200">ファイルを選択</label>
          <input type="file" id="file" ref="fileInput" @change="handleFileChange"
            class="mt-1 block w-full text-sm text-gray-900 dark:text-gray-100 bg-white dark:bg-zinc-700 border border-gray-300 dark:border-zinc-600 rounded-md cursor-pointer focus:outline-none focus:ring-2 focus:ring-indigo-500" />
        </div>

        <!-- ファイル名入力（オプション） -->
        <div>
          <label for="filename" class="block text-sm font-medium text-zinc-700 dark:text-zinc-200">ファイル名（任意）</label>
          <input type="text" id="filename" v-model="form.filename" placeholder="例: 仕様書.pdf"
            class="mt-1 block w-full rounded-md border border-gray-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 text-zinc-900 dark:text-white text-sm shadow-sm focus:ring-indigo-500 focus:border-indigo-500" />
        </div>

        <!-- 送信ボタン -->
        <div class="pt-4">
          <button type="submit"
            class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-md transition">
            アップロード
          </button>
        </div>
      </form>
      <!-- ファイル一覧 -->
      <!-- <div v-if="libraries.files?.length" class="pt-6 border-t border-zinc-200 dark:border-zinc-800">
        <h2 class="text-xl font-semibold text-zinc-800 dark:text-white mb-4">ファイル一覧</h2>
        <ul class="space-y-3">
          <li v-for="file in libraries.files" :key="file.id"
            class="flex items-center justify-between bg-zinc-100 dark:bg-zinc-800 px-4 py-2 rounded-md">
            <span class="text-sm text-zinc-800 dark:text-zinc-200"></span>
            <a :href="file.file_url" target="_blank"
              class="text-blue-600 dark:text-blue-400 text-xs hover:underline">ダウンロード</a>
          </li>
        </ul>
      </div> -->
    </section>
  </main>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthLibrary } from '~/store/library';

const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const route = useRoute();
const router = useRouter();
const libraries = ref([]);
const fileInput = ref(null);
const form = ref({ filename: '' });
const isSidebarOpen = ref(false);
const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value
};
onMounted(async () => {
  try {
    await authStore.restoreSession();
    console.log('セッション複号完了');
    const routeId = route.params.id;
    libraries.value = await libraryStore.FetchLibraryId(routeId);
  } catch (error) {
    console.error('情報取得の失敗：', error);
    throw error;
  }
});

const formatDate = (dateStr) => {
  const d = new Date(dateStr)
  return d.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
};


</script>
<style scoped>
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fadeIn {
  animation: fadeIn 0.6s ease-out both;
}
</style>