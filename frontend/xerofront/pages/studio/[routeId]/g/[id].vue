<template>
    <main class="flex-1 overflow-y-auto md:ml-72 ml-0 text-white">
        <div class="py-2 px-6">
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
                    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
                        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
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
                            <p class="text-white font-medium">
                                期限：{{ formatDate(goal.deadline) || '未設定' }}
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
                <div class="flex flex-col h-[580px] bg-white dark:bg-zinc-800  overflow-hidden">
                    <!-- チャット表示エリア -->
                    <div class="flex-1 p-2 h- overflow-y-auto space-y-2">
                        <div v-for="(msg, i) in messages" :key="i" :class="msg.sender === 'user'
                            ? 'self-end bg-blue-500 text-white'
                            : 'self-start bg-gray-300 text-black dark:bg-zinc-700 dark:text-white'"
                            class="max-w-xs px-4 py-2 rounded-lg shadow">
                            {{ msg.text }}
                        </div>
                    </div>
                    <div>
                        <div
                            class="block items-end gap-2 p-3 rounded-2xl bg-zinc-900 text-white shadow-inner border border-zinc-700 w-full">
                            <div class="relative w-full">
                                <textarea v-model="newMessage" @keydown.enter.exact.prevent="sendMessage"
                                    @keydown.shift.enter.stop rows="1" placeholder="メッセを送る…"
                                    class="w-full max-h-48 resize-none overflow-y-auto px-4 py-2 text-white placeholder-zinc-400 bg-transparent focus:outline-none"
                                    style="height: auto; min-height: 40px; max-height: 190px;"
                                    ref="textareaRef"></textarea>
                            </div>
                            <div class="flex items-center justify-between">
                                <!-- 左側アイコン -->
                                <div class="flex items-center gap-1 pl-1 hover:bg-zinc-600  rounded-xl px-2">
                                    <button class="dark:text-white text-zinc-400 text-xl">＋</button>
                                    <span class="text-sm dark:text-white text-zinc-400">ツール</span>
                                </div>
                                <div class="flex items-center gap-2 pr-1">
                                    <button class=" dark:text-white hover:bg-zinc-600   rounded-xl p-2" title="マイク">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="currentColor"
                                            viewBox="0 0 16 16">
                                            <path d="M8 12a3 3 0 0 0 3-3V5a3 3 0 0 0-6 0v4a3 3 0 0 0 3 3z" />
                                            <path
                                                d="M5 10.5a.5.5 0 0 0-1 0A4 4 0 0 0 8 14a4 4 0 0 0 4-3.5.5.5 0 0 0-1 0 3 3 0 0 1-6 0z" />
                                        </svg>
                                    </button>
                                    <button @click="sendMessage()"
                                        class="bg-zinc-700 hover:bg-zinc-600 text-white p-2 rounded-full">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="currentColor"
                                            viewBox="0 0 16 16">
                                            <path
                                                d="M15.854.146a.5.5 0 0 0-.683-.183L.146 7.236a.5.5 0 0 0 .043.895l4.856 1.714 1.714 4.856a.5.5 0 0 0 .895.043l7.273-15.025a.5.5 0 0 0-.183-.683zM6.06 12.708l-1.25-3.536 6.153-6.153L6.06 12.708z" />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
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
const textareaRef = ref(false);
const newMessage = ref('');
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
        adjustHeight();
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
};
const adjustHeight = () => {
    const el = textareaRef.value;
    if (!el) return
    el.style.height = 'auto' // 一度リセット
    el.style.height = Math.min(el.scrollHeight, 192) + 'px' // 最大192pxに制限
};
// 変更のたびに高さ調整
watch(newMessage, adjustHeight)

const sendMessage = async () => {

};


</script>