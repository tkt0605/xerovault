<template>
  <main class="text-black dark:text-white  md:ml-72 ml-0 relative flex-1 overflow-y-auto">
    <section
      class="max-w-5xl mx-auto backdrop-blur-md border border-zinc-200 dark:border-zinc-800 rounded-3xl shadow-2xl p-8 md:p-10 space-y-10">

      <!-- ヘッダー -->
      <header class="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div class="space-y-2">
          <h1 class="text-3xl md:text-4xl font-extrabold tracking-tight text-zinc-900 dark:text-white">
            {{ libraries.name }}
          </h1>
          <div class="flex items-center gap-2">
            <span
              class="text-xs font-medium inline-flex items-center gap-1 px-2 py-1 rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-200">
              #{{ libraries.tag || '未分類' }}
            </span>
            <span :class="libraries.is_public
              ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-800 dark:text-emerald-200'
              : 'bg-rose-100 text-rose-700 dark:bg-rose-800 dark:text-rose-200'"
              class="inline-flex items-center gap-2 text-xs font-semibold px-3 py-1.5 rounded-full">
              {{ libraries.is_public ? '公開中' : '非公開' }}
            </span>
          </div>
        </div>

        <!-- 右上メタ -->
        <div class="grid grid-cols-2 gap-4 text-xs">
          <div class="rounded-2xl border border-zinc-200 dark:border-zinc-700 p-3">
            <p class="uppercase text-zinc-500 dark:text-zinc-400">オーナー</p>
            <p class="mt-1 text-sm font-semibold text-zinc-900 dark:text-zinc-100 truncate">
              {{ libraries.owner?.email }}
            </p>
          </div>
          <div class="rounded-2xl border border-zinc-200 dark:border-zinc-700 p-3">
            <p class="uppercase text-zinc-500 dark:text-zinc-400">ライブラリID</p>
            <p class="mt-1 text-[11px] leading-5 break-all text-zinc-600 dark:text-zinc-300">
              {{ libraries.id }}
            </p>
          </div>
        </div>
      </header>

      <!-- 概要 -->
      <section class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4">
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">作成日</p>
          <p class="mt-2 text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {{ formatDate(libraries.created_at) }}
          </p>
        </div>
        <div class="rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4">
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">更新日</p>
          <p class="mt-2 text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {{ formatDate(libraries.updated_at) }}
          </p>
        </div>
      </section>

      <!-- アップロードカード -->
      <form @submit.prevent="uploadFile" enctype="multipart/form-data"
        class="rounded-2xl border border-zinc-200 dark:border-zinc-800 bg-white/70 dark:bg-zinc-900/50 p-6 space-y-5">
        <h2 class="text-lg font-semibold text-zinc-900 dark:text-white">ファイルのアップロード</h2>

        <!-- ファイル選択 -->
        <div class="grid gap-2">
          <label for="file" class="block text-sm font-medium text-zinc-700 dark:text-zinc-200">ファイルを選択</label>
          <input id="file" ref="fileInput" type="file" @change="handleFileChange" class="block w-full text-sm text-zinc-900 dark:text-zinc-100 bg-white dark:bg-zinc-800
                   border border-zinc-300 dark:border-zinc-700 rounded-xl cursor-pointer
                   focus:outline-none focus:ring-2 focus:ring-indigo-500 px-3 py-2" />
          <p class="text-xs text-zinc-500 dark:text-zinc-400">最大 100MB / JPG・PNG・PDF・ZIP</p>
        </div>

        <!-- 任意のファイル名 -->
        <div class="grid gap-2">
          <label for="filename" class="block text-sm font-medium text-zinc-700 dark:text-zinc-200">表示名（任意）</label>
          <input id="filename" v-model="form.filename" type="text" placeholder="例: 仕様書.pdf" class="block w-full rounded-xl border border-zinc-300 dark:border-zinc-700
                   bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white text-sm
                   focus:ring-indigo-500 focus:border-indigo-500 px-3 py-2" />
        </div>

        <!-- 送信 -->
        <div class="pt-2">
          <button type="submit" @click="uploadfile" class="inline-flex items-center gap-2 px-4 py-2 rounded-xl
                         bg-indigo-600 text-white font-medium hover:bg-indigo-700 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M5 20h14v-2H5v2zm7-18L5.33 9h3.84v6h6.66V9h3.84L12 2z" />
            </svg>
            アップロード
          </button>
        </div>
      </form>

      <!-- ファイル一覧（既存データをそのまま使用） -->
      <section class="space-y-4" v-if="libraries.files?.length">
        <h2 class="text-xl font-semibold text-zinc-800 dark:text-white">ファイル一覧</h2>

        <ul
          class="divide-y divide-zinc-200 dark:divide-zinc-800 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <li v-for="file in libraries.files" :key="file.id"
            class="flex items-center justify-between gap-4 px-4 py-3 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition">
            <div class="flex items-center gap-3 min-w-0">
              <div class="h-9 w-9 rounded-lg bg-zinc-100 dark:bg-zinc-700 flex items-center justify-center shrink-0">
                <!-- 汎用ファイルアイコン -->
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zinc-600 dark:text-zinc-300"
                  viewBox="0 0 24 24" fill="currentColor">
                  <path d="M6 2h7l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4c0-1.1.9-2 2-2z" />
                </svg>
              </div>
              <div class="min-w-0">
                <p class="truncate font-medium text-zinc-900 dark:text-zinc-100">
                  {{ file.filename || file.name || '無題ファイル' }}
                </p>
                <p class="text-xs text-zinc-500 dark:text-zinc-400">
                  {{ formatDate(file.updated_at || file.created_at) }}
                </p>
              </div>
            </div>

            <a :href="file.file_url" target="_blank" class="shrink-0 inline-flex items-center gap-2 text-xs font-medium
                     px-3 py-1.5 rounded-lg border border-zinc-200 dark:border-zinc-700
                     hover:bg-zinc-100 dark:hover:bg-zinc-700 text-zinc-700 dark:text-zinc-200">
              ダウンロード
            </a>
          </li>
        </ul>
      </section>

      <!-- 空状態 -->
      <section v-else class="rounded-2xl border border-dashed border-zinc-300 dark:border-zinc-700 p-10 text-center">
        <p class="text-zinc-700 dark:text-zinc-200 font-medium">ファイルはまだありません</p>
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">上のフォームからアップロードできます</p>
      </section>

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

const uploadfile = async()=>{
  const file = fileInput.value.files[0];
  if (!file) {
    alert('ファイルを選択してください');
    return;
  }

  const formData = new FormData();
  formData.append('file', file);
  // formData.append('name', form.value.filename || file.name);
  const name = form.value.filename || file.name;

  try {
    await libraryStore.UploadfileToLibrary(libraries.value.id ,name , formData);
    alert('ファイルがアップロードされました');
    fileInput.value.value = ''; // Reset file input
    libraries.value = await libraryStore.FetchLibraryId(libraries.value.id); // Refresh library data
  } catch (error) {
    console.error('ファイルアップロード失敗：', error);
    alert('ファイルのアップロードに失敗しました');
  }
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