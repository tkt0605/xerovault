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
                <div class="p-4 text-center">
                    <h2 class="text-xl font-bold">{{ group?.name }}に参加</h2>

                    <div v-if="!joinSuccess">
                        <p>このスタジオに参加するには、参加トークンが必要です。</p>
                        <input v-model="token" type="text" class="border rounded px-3 py-1 mt-2"
                            placeholder="参加トークンを入力" />
                        <button @click="JoinToStudio"
                            class="ml-2 bg-blue-600 text-white px-4 py-1 rounded hover:bg-blue-700"
                            :disabled="isJoining">
                            参加
                        </button>

                        <p v-if="isJoining" class="mt-4 text-gray-500">スタジオ参加中...</p>
                        <p v-if="errorMsg" class="text-red-500 mt-2">{{ errorMsg }}</p>
                    </div>

                    <div v-else>
                        <h1 class="text-xl font-bold text-green-600">スタジオに参加しました！</h1>
                        <p class="mt-2">スタジオのトップページにリダイレクトされるか、<br />手動でアクセスしてください。</p>
                    </div>
                </div>
            </main>
        </div>
    </div>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useAuthLibrary } from '~/store/library';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
const authStore = useAuthStore();
const groupStore = useAuthGroups();
const libraryStore = useAuthLibrary();
const route = useRoute();
const router = useRouter();
const token = route.query.token;
const studioId = route.params.id;
const group = ref([]);

onMounted(async () => {
    if (!token) {
        console.log('トークンがありません。');
        return;
    }
    try {
        group.value = await groupStore.fetchGroupId(studioId);
        // const result = await groupStore.JoinAnonymous(studioId, token);
        console.log('参加成功：', result);
        router.push(`/studio/${studioId}`);
    } catch (error) {
        console.error('参加エラー：', error);
        throw error;
    }
});
const JoinToStudio = async () => {
};
</script>
