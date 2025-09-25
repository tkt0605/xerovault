<template>
  <main class="text-black dark:text-white  md:ml-70 ml-0 relative flex-1 overflow-y-auto">
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
      <section class="flex items-center justify-between w-full">
        <div class="rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4">
          <p class="text-xs uppercase font-medium text-gray-500 dark:text-gray-400">作成日</p>
          <p class="mt-2 text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {{ formatDate(libraries.created_at) }}
          </p>
        </div>
        <div v-if="my_files.length">
          <input type="file" ref="fileInput" multiple class="hidden" @change="handlePick">
          <button type="submit" @click="openPicker" class="inline-flex items-center gap-2 px-4 py-2 rounded-xl
                         bg-indigo-600 text-white font-medium hover:bg-indigo-700 transition">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M5 20h14v-2H5v2zm7-18L5.33 9h3.84v6h6.66V9h3.84L12 2z" />
            </svg>
            アップロード
          </button>
        </div>
      </section>

      <!-- ファイル一覧（既存データをそのまま使用） -->
      <section class="space-y-4" v-if="my_files.length">
        <ul
          class="divide-y divide-zinc-200 dark:divide-zinc-800  rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <li v-for="file in filterFiles" :key="file.id"
            class="flex items-center justify-between gap-4 px-4 py-3 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition">
            <div class="flex items-center gap-3 min-w-0">
              <div class="h-9 w-9 rounded-lg bg-zinc-900 transition flex items-center justify-center shrink-0">
                <!-- 汎用ファイルアイコン -->
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zinc-600 dark:text-zinc-300"
                  viewBox="0 0 24 24" fill="currentColor">
                  <path d="M6 2h7l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4c0-1.1.9-2 2-2z" />
                </svg>
              </div>
              <div class="min-w-0">
                <p class="truncate font-medium text-zinc-900 dark:text-zinc-100">
                  {{ formatFile(file.file) }}
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
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">ここからアップロードできます</p>
        <div class="pt-2">
          <input ref="fileInput" type="file" multiple class="hidden" @change="handlePick" />
          <button type="button" @click="openPicker"
            class="px-4 py-2 rounded-xl bg-indigo-600 text-white hover:bg-indigo-500">
            アップロード
          </button>
        </div>
      </section>
      <div v-if="uploading" class="mt-2">
        <div class="h-2 w-full rounded-full bg-zinc-200 dark:bg-zinc-700 overflow-hidden">
          <div class="h-2 bg-indigo-600 transition-all" :style="{ width: uploadProgress + '%' }"></div>
        </div>
        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">{{ uploadProgress }}%</p>
      </div>

    </section>
  </main>
</template>

<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthLibrary } from '~/store/library';
import { eventBus } from '#imports';
import { useRuntimeConfig } from '#imports';
const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const route = useRoute();
const router = useRouter();
const libraries = ref([]);
const form = ref({ filename: '' });
const isSidebarOpen = ref(false);
const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value
};
const fileInput = ref(null);
const files = ref([]);
const config = useRuntimeConfig();
const my_files = ref([]);
onMounted(async () => {
  try {
    await authStore.restoreSession();
    console.log('セッション複号完了');
    const routeId = route.params.id;
    libraries.value = await libraryStore.FetchLibraryId(routeId);
    my_files.value = await libraryStore.FetchLibraryFiles();
  } catch (error) {
    console.error('情報取得の失敗：', error);
    throw error;
  }
});
const filterFiles = computed(() => {
  const routeId = route.params.id;
  return my_files.value.filter((f) => f.target.id === routeId);
})
const formatDate = (dateStr) => {
  const d = new Date(dateStr)
  return d.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
};
const API_BASE = config.public.apiBase;
const uploading = ref(false);
const uploadProgress = ref(0);
const uploadFile = async (file) => {
  const fd = new FormData();
  const routeId = route.params.id;
  fd.append('file', file);
  fd.append('target', String(routeId));
  const res = await fetch(`${API_BASE}library_files/`, {
    method: 'POST',
    headers: {
      "Authorization": `${authStore.accessToken}`
    },
    body: fd,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`Upload failed (${res.status}): ${text || 'no bady'}`);
  }
  return res.json();
};
const uploadFiles = async (fileList) => {
  uploading.value = true;
  uploadProgress.value = 0;
  const total = fileList.length;
  const uploaded = [];
  try {
    for (let i = 0; i < total; i++) {
      const data = await uploadFile(fileList[i]);
      uploaded.push(data);
      uploadProgress.value = Math.round(((i + 1) / total) * 100);
    }
    files.value.push(...uploaded);
  } finally {
    uploading.value = false;
  }
};
const handlePick = async (e) => {
  const target = e.target;
  const picked = Array.from(target.files || []);
  if (!picked.length) return;
  try {
    await uploadFiles(picked);
  } catch (error) {
    console.error('ファイルアップロード失敗：', error);
  } finally {
    if (fileInput.value) fileInput.value.value = '';
  }
};
const openPicker = () => {
  if (fileInput.value) fileInput.value.click();
};
function formatFile(input) {
  if (input && typeof input === 'string' && input.name) return input.name;
  const s = String(input || '');
  if (!s) return '不明なファイル';
  let last = s;
  try {
    const url = new URL(s, window.location.origin);
    last = url.pathname.split('/').pop() || s;
  } catch (error) {
    last = s.split('/').pop() || '';
  }
  last = last.split('?')[0].split('#')[0];
  let decode = last;
  try {
    decode = decodeURIComponent(last);
  } catch (error) {
    decode = last.replace(/%[0-9A-Fa-f]{2}/g, m => {
      try { return decodeURIComponent(m) } catch (e) { return m; }
    });
  }
  return decode.normalize('NFC');
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