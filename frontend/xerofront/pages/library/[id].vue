<template>
    <div class="flex flex-col min-h-screen bg-gray-50 dark:bg-zinc-800 text-gray-800 dark:text-white">

        <!-- ヘッダー：上部固定 -->
        <header class="shadow bg-white dark:bg-zinc-900 sticky top-0 z-50">
            <Header />
        </header>

        <!-- メインコンテンツ：サイドバー＋本文 -->
        <div class="flex flex-1 overflow-hidden">
            <!-- サイドバー -->
            <!-- <aside class="w-64 bg-white dark:bg-zinc-900 border-r border-gray-200 dark:border-zinc-700 p-4 overflow-y-auto hidden md:block"> -->
            <aside>
                <Aside />
            </aside>

            <!-- メインビュー -->
            <main class="flex-1 p-6 overflow-y-auto">
                <div
                    class="max-w-3xl w-full mx-auto mt-10 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-2xl shadow-md px-6 py-8 space-y-8">
                    <!-- タイトルとタグ -->
                    <div class="flex flex-wrap justify-between items-start gap-4">
                        <div>
                            <h1 class="text-2xl font-extrabold text-zinc-800 dark:text-white tracking-tight">
                                {{ libraries.name }}
                            </h1>
                            <span
                                class="mt-2 inline-block text-xs font-medium px-2 py-1 rounded bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-100">
                                #{{ libraries.tag || '未分類' }}
                            </span>
                        </div>
                        <div>
                            <span :class="libraries.is_public
                                ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300'
                                : 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'"
                                class="flex items-center gap-1 text-xs font-semibold px-3 py-1 rounded-full">
                                <svg v-if="libraries.is_public" class="w-4 h-4" fill="none" stroke="currentColor"
                                    stroke-width="2" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                                </svg>
                                <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2"
                                    viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                                </svg>
                                {{ libraries.is_public ? '公開中' : '非公開' }}
                            </span>
                        </div>
                    </div>

                    <!-- 詳細情報 -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm text-zinc-700 dark:text-zinc-300">
                        <div>
                            <p class="text-xs text-gray-500 dark:text-gray-400">オーナー</p>
                            <p class="mt-1 font-medium">{{ libraries.owner?.email }}</p>
                        </div>
                        <div>
                            <p class="text-xs text-gray-500 dark:text-gray-400">ライブラリID</p>
                            <p class="mt-1 text-xs text-zinc-500 dark:text-zinc-400 break-all">{{ libraries.id }}</p>
                        </div>
                        <div>
                            <p class="text-xs text-gray-500 dark:text-gray-400">作成日</p>
                            <p class="mt-1">{{ formatDate(libraries.created_at) }}</p>
                        </div>
                        <div>
                            <p class="text-xs text-gray-500 dark:text-gray-400">更新日</p>
                            <p class="mt-1">{{ formatDate(libraries.updated_at) }}</p>
                        </div>
                    </div>
                </div>

            </main>
        </div>
    </div>
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
