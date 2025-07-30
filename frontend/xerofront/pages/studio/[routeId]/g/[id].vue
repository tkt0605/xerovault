<template>
    <main class="relative flex-1 overflow-y-auto md:ml-72 ml-0 text-white">
        <div class="py-6 px-6">
            <div class="max-w-4xl mx-auto space-y-0">
                <div
                    class="bg-gradient-to-br from-purple-900 via-zinc-800 to-zinc-900 rounded-t-xl shadow-2xl border border-zinc-700 p-2">
                    <div class="flex items-center gap-3 p-2 px-2 pt-2">
                        <button @click="goBack"
                            class="flex items-center gap-1 text-sm text-zinc-400 hover:text-blue-400 transition">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor"
                                class="bi bi-arrow-left-circle" viewBox="0 0 16 16">
                                <path fill-rule="evenodd"
                                    d="M1 8a7 7 0 1 0 14 0A7 7 0 0 0 1 8m15 0A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-4.5-.5a.5.5 0 0 1 0 1H5.707l2.147 2.146a.5.5 0 0 1-.708.708l-3-3a.5.5 0 0 1 0-.708l3-3a.5.5 0 1 1 .708.708L5.707 7.5z" />
                            </svg>
                            <div class="text-sm">
                                # {{ goal.group?.name || 'スタジオ名不明' }}へ戻る
                            </div>
                            <!-- <span>スタジオへ戻る</span> -->
                        </button>
                    </div>
                </div>
                <div class="bg-zinc-900 border border-zinc-700  p-6 shadow-inner">
                    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6 mb-6">
                        <div class="flex items-center gap-4">
                            <img :src="goal.assignee?.avater" alt="Avatar"
                                class="w-10 h-10 rounded-full border-2 border-white object-cover shadow" />
                            <div>
                                <h1 class="text-2xl sm:text-2xl font-bold tracking-wide">
                                    {{ goal.header || '無題の目標' }}
                                </h1>
                                <p class="text-sm text-purple-300">
                                    {{ goal.assignee?.email || '不明なユーザー' }}
                                </p>
                            </div>
                        </div>
                        <div class="text-sm text-right text-gray-300">
                            <p>📅 締め切り</p>
                            <p class="text-white font-medium">
                                {{ formatDate(goal.deadline) || '未設定' }}
                            </p>
                        </div>
                    </div>
                    <h2 class="text-lg font-semibold border-b border-zinc-600 pb-2 mb-4 text-zinc-300">
                        目標の説明
                    </h2>
                    <p class="text-sm text-gray-300 whitespace-pre-line leading-relaxed">
                        {{ goal.description || '（説明はありません）' }}
                    </p>
                </div>

            </div>
        </div>
    </main>
</template>

<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useGoalStore } from '~/store/goal';
import { ref, onMounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
const authStore = useAuthStore();
const groupStore = useAuthGroups();
const goalStore = useGoalStore();
const router = useRouter();
const route = useRoute();
const goal = ref([]);
const goalId = route.params.id;
onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複合成功');
        if (!authStore.isAuthenticated) {
            console.log('認証されていません。');
            return router.push('/auth/login');
        }
        goal.value = await goalStore.fetchGoalsId(goalId);
        console.log('目標データ：', goal.value);
    } catch (err) {
        console.error('目標データの取得に失敗しました。', err);
    }
});
const formatDate = (dateStr) => {
    const d = new Date(dateStr)
    return d.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
};
const goBack = () => {
    router.back();
}
</script>