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
                <!-- Tailwind CSS 使用 -->
                <div
                    class="max-w-md mx-auto bg-white dark:bg-zinc-900 shadow-xl rounded-2xl p-6 space-y-4 border dark:border-zinc-700">
                    <div class="flex justify-between items-center">
                        <h2 class="text-xl font-bold text-zinc-800 dark:text-white">{{ group.name }}</h2>
                        <span
                            class="px-2 py-1 text-sm rounded bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100">サイト</span>
                    </div>

                    <div class="text-sm text-zinc-600 dark:text-zinc-300">
                        <p><strong>オーナー:</strong>{{ group.owner }}</p>
                        <p><strong>スコア:</strong> {{ group.score }}</p>
                        <!-- <p><strong>クレジット:</strong>{{ group. }}</p> -->
                        <p><strong>公開ステータス:</strong> <span class="text-green-600 font-medium">{{ group.is_public }}</span></p>
                    </div>

                    <div class="text-sm text-zinc-600 dark:text-zinc-300">
                        <p><strong>参加メンバー:</strong></p>
                        <ul class="list-disc list-inside">
                            <li>{{ group.members }}</li>
                        </ul>
                    </div>

                    <div class="text-xs text-zinc-500 dark:text-zinc-400">
                        <p>作成日: {{ group.created_at }}</p>
                        <p>更新日: {{ group.updated_at}}</p>
                    </div>

                    <div class="text-xs text-zinc-500 dark:text-zinc-400 break-all">
                        <p><strong>参加トークン:</strong>{{ group.joined_token }}</p>
                    </div>
                </div>

            </main>
        </div>
    </div>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useRoute, useRouter } from 'vue-router';
import { ref, onMounted } from 'vue';
const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const authGroup = useAuthGroups();
const group = ref([]);

onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複合完了');
        const routeId = route.params.id;
        group.value = await authGroup.fetchGroupId(routeId);
    } catch (error) {
        console.error('エラー：', error);
        throw error;
    }
})
</script>
