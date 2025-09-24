<!-- <template>
    <main class="flex-1 overflow-y-auto md:ml-72 ml-0 text-white">
        <div class="py-2 px-6">
            <div class="max-w-4xl mx-auto space-y-0">
                <div>
                    <header
                        class="sticky top-0 z-10 bg-gradient-to-br from-purple-900 via-zinc-800 to-zinc-900
                 rounded-t-xl shadow-2xl border border-zinc-700 p-2 backdrop-blur supports-[backdrop-filter]:bg-opacity-90">
                        <div class="flex items-center gap-4 p-2 pt-2">
                            <button @click="goBack"
                                class="flex items-center gap-1 text-sm text-zinc-300 hover:text-blue-300 transition">
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"
                                    class="bi bi-arrow-left-circle" viewBox="0 0 16 16" fill="currentColor">
                                    <path fill-rule="evenodd"
                                        d="M1 8a7 7 0 1 0 14 0A7 7 0 0 0 1 8m15 0A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-4.5-.5a.5.5 0 0 1 0 1H5.707l2.147 2.146a.5.5 0 0 1-.708.708l-3-3a.5.5 0 0 1 0-.708l3-3a.5.5 0 1 1 .708.708L5.707 7.5z" />
                                </svg>
                                <span class="text-sm">{{ goal.group?.name || 'スタジオ名不明' }}へ戻る</span>
                            </button>

                            <div class="flex items-center justify-between flex-1">
                                <div class="text-sm font-medium truncate">
                                    {{ goal.header || '無題の目標' }}
                                </div>
                                <div class="text-xs sm:text-sm text-right text-gray-300 shrink-0">
                                    <p class="text-white font-medium">
                                        期限：{{ formatDate(goal.deadline) || '未設定' }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </header>
                    <div class="flex flex-col h-[620px] bg-white dark:bg-zinc-800  overflow-hidden">
                        <div class="flex-1 p-2 h- overflow-y-auto space-y-2">
                            <div v-for="msg in postMessage" :key="msg.id"
                                class="flex items-start gap-3 mb-2 p-2 border-b border-gray-700">
                                <img :src="msg?.auther?.avater" alt="Avatar"
                                    class="w-10 h-10 rounded-full object-cover border border-gray-400 dark:border-zinc-600" />
                                <div class="flex-1">
                                    <div class="flex items-center gap-2 mb-1">
                                        <span class="text-sm font-semibold text-gray-800 dark:text-white">
                                            {{ msg.auther.email }}
                                        </span>
                                        <span class="text-xs text-gray-500 dark:text-gray-400">
                                            {{ formatDate(msg.created_at) }}
                                        </span>
                                    </div>
                                    <div
                                        class="bg-gray-100 dark:bg-zinc-700 mb-2 text-gray-900 dark:text-white px-4 py-2 rounded-xl shadow-sm whitespace-pre-line break-words">
                                        {{ msg.text }}
                                    </div>
                                    <div class="flex items-center gap-3">
                                        <button
                                            class="p-2 rounded-full hover:bg-blue-500/20 transition-all duration-200 text-zinc-400 hover:text-blue-400"
                                            title="リターン">
                                            <svg xmlns="http://www.w3.org/2000/svg" height="22" width="22"
                                                fill="currentColor" viewBox="0 0 24 24">
                                                <path
                                                    d="M10 9V5l-7 7 7 7v-4.1c4.55 0 7.55 1.45 9 4.1-.5-5-3.5-10-9-10Z" />
                                            </svg>
                                        </button>
                                        <button
                                            class="p-2 rounded-full hover:bg-pink-500/20 transition-all duration-200 text-zinc-400 hover:text-pink-400"
                                            title="お祝い">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"
                                                fill="currentColor" class="bi bi-balloon" viewBox="0 0 16 16">
                                                <path fill-rule="evenodd"
                                                    d="M8 9.984C10.403 9.506 12 7.48 12 5a4 4 0 0 0-8 0c0 2.48 1.597 4.506 4 4.984M13 5c0 2.837-1.789 5.227-4.52 5.901l.244.487a.25.25 0 1 1-.448.224l-.008-.017c.008.11.02.202.037.29.054.27.161.488.419 1.003.288.578.235 1.15.076 1.629-.157.469-.422.867-.588 1.115l-.004.007a.25.25 0 1 1-.416-.278c.168-.252.4-.6.533-1.003.133-.396.163-.824-.049-1.246l-.013-.028c-.24-.48-.38-.758-.448-1.102a3 3 0 0 1-.052-.45l-.04.08a.25.25 0 1 1-.447-.224l.244-.487C4.789 10.227 3 7.837 3 5a5 5 0 0 1 10 0m-6.938-.495a2 2 0 0 1 1.443-1.443C7.773 2.994 8 2.776 8 2.5s-.226-.504-.498-.459a3 3 0 0 0-2.46 2.461c-.046.272.182.498.458.498s.494-.227.562-.495" />
                                            </svg>
                                        </button>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div>
                    <div
                        class="block items-end gap-2 p-3 rounded-2xl bg-zinc-900 text-white shadow-inner border border-zinc-700 w-full">
                        <div class="relative w-full">
                            <textarea v-model="newMessage" @keydown.enter.exact.prevent="sendMessage"
                                @keydown.shift.enter.stop rows="1" placeholder="メッセを送る…"
                                class="w-full max-h-48 resize-none overflow-y-auto px-4 py-2 text-white placeholder-zinc-400 bg-transparent focus:outline-none"
                                style="height: auto; min-height: 40px; max-height: 190px;" ref="textareaRef"></textarea>
                        </div>
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-1 pl-1 hover:bg-zinc-600  rounded-xl px-2">
                                <button type="submit" class="dark:text-white text-zinc-400 text-xl flex items-cente">
                                    <span class="text-sm dark:text-white text-zinc-400">＋ツール</span>
                                </button>
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
    </main>
</template> -->
<template>
    <main class="flex-1 overflow-y-auto md:ml-72 ml-0 text-white">
        <div class="py-2 px-6">
            <div class="max-w-4xl mx-auto space-y-0">

                <!-- チャットカード -->
                <section class="bg-white dark:bg-zinc-800">
                    <div class="flex flex-col h-[700px] overflow-hidden min-h-0">
                        <header class="fied z-100 bg-gradient-to-br from-purple-900 via-zinc-800 to-zinc-900
                       rounded-t-xl border-b border-zinc-700 p-2">
                            <div class="flex items-center gap-4 p-2 pt-2">
                                <button @click="goBack"
                                    class="flex items-center gap-1 text-sm text-zinc-300 hover:text-blue-300 transition">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"
                                        class="bi bi-arrow-left-circle" viewBox="0 0 16 16" fill="currentColor">
                                        <path fill-rule="evenodd"
                                            d="M1 8a7 7 0 1 0 14 0A7 7 0 0 0 1 8m15 0A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-4.5-.5a.5.5 0 0 1 0 1H5.707l2.147 2.146a.5.5 0 0 1-.708.708l-3-3a.5.5 0 0 1 0-.708l3-3a.5.5 0 1 1 .708.708L5.707 7.5z" />
                                    </svg>
                                    <span class="text-sm">{{ goal?.group?.name || 'スタジオ名不明' }}へ戻る</span>
                                </button>

                                <div class="flex items-center justify-between flex-1 min-w-0">
                                    <div class="text-sm font-medium truncate">
                                        {{ goal?.header || '無題の目標' }}
                                    </div>
                                    <div class="text-xs sm:text-sm text-right text-gray-300 shrink-0">
                                        <p class="text-white font-medium">
                                            期限：{{ formatDate(goal?.deadline) || '未設定' }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </header>

                        <!-- スクロール領域（ヘッダー＋メッセージ） -->
                        <div ref="scrollArea"
                            class="flex-1 min-h-0 overflow-y-auto overscroll-contain scroll-smooth w-full"
                            style="direction: ltr;">
                            <!-- ヘッダー（スクロール対象） -->
                            <!-- メッセージ一覧 -->
                            <div class="p-3 space-y-3">
                                <div v-for="msg in postMessage" :key="msg.id" class="flex items-start gap-3">
                                    <img :src="msg?.auther?.avater" alt="Avatar"
                                        class="w-9 h-9 rounded-full object-cover border border-zinc-600/60" />
                                    <div class="flex-1 min-w-0">
                                        <div class="flex items-center gap-2 mb-1">
                                            <span class="text-sm font-semibold text-white truncate">{{
                                                msg?.auther?.email || 'Unknown' }}</span>
                                            <span class="text-xs text-zinc-400">{{ formatDate(msg?.created_at) }}</span>
                                        </div>
                                        <div
                                            class="bg-zinc-700/70 text-white px-4 py-2 rounded-2xl shadow-sm whitespace-pre-line break-words">
                                            {{ msg?.text }}
                                        </div>
                                        <div class="flex items-center gap-2 mt-1">
                                            <button
                                                class="p-2 rounded-full hover:bg-blue-500/20 text-zinc-400 hover:text-blue-400"
                                                title="リターン">
                                                <svg xmlns="http://www.w3.org/2000/svg" height="20" width="20"
                                                    viewBox="0 0 24 24" fill="currentColor">
                                                    <path
                                                        d="M10 9V5l-7 7 7 7v-4.1c4.55 0 7.55 1.45 9 4.1-.5-5-3.5-10-9-10Z" />
                                                </svg>
                                            </button>
                                            <button
                                                class="p-2 rounded-full hover:bg-pink-500/20 text-zinc-400 hover:text-pink-400"
                                                title="お祝い">
                                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"
                                                    class="bi bi-balloon" viewBox="0 0 16 16" fill="currentColor">
                                                    <path fill-rule="evenodd"
                                                        d="M8 9.984C10.403 9.506 12 7.48 12 5a4 4 0 0 0-8 0c0 2.48 1.597 4.506 4 4.984M13 5c0 2.837-1.789 5.227-4.52 5.901l.244.487a.25.25 0 1 1-.448.224l-.008-.017c.008.11.02.202.037.29.054.27.161.488.419 1.003.288.578.235 1.15.076 1.629-.157.469-.422.867-.588 1.115l-.004.007a.25.25 0 1 1-.416-.278c.168-.252.4-.6.533-1.003.133-.396.163-.824-.049-1.246l-.013-.028c-.24-.48-.38-.758-.448-1.102a3 3 0 0 1-.052-.45l-.04.08a.25.25 0 1 1-.447-.224l.244-.487C4.789 10.227 3 7.837 3 5a5 5 0 0 1 10 0m-6.938-.495a2 2 0 0 1 1.443-1.443C7.773 2.994 8 2.776 8 2.5s-.226-.504-.498-.459a3 3 0 0 0-2.46 2.461c-.046.272.182.498.458.498s.494-.227.562-.495" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
                <div>
                    <div
                        class="block items-end gap-2 p-3 rounded-2xl bg-zinc-900 text-white shadow-inner border border-zinc-700 w-full">
                        <div class="relative w-full">
                            <textarea v-model="newMessage" @keydown.enter.exact.prevent="sendMessage"
                                @keydown.shift.enter.stop rows="1" placeholder="メッセを送る…"
                                class="w-full max-h-48 resize-none overflow-y-auto px-4 py-2 text-white placeholder-zinc-400 bg-transparent focus:outline-none"
                                style="height: auto; min-height: 40px; max-height: 190px;" ref="textareaRef"></textarea>
                        </div>
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-1 pl-1 hover:bg-zinc-600  rounded-xl px-2">
                                <button type="submit" class="dark:text-white text-zinc-400 text-xl flex items-cente">
                                    <span class="text-sm dark:text-white text-zinc-400">＋ツール</span>
                                </button>
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
    </main>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useGoalStore } from '~/store/goal';
import { useAuthMessage } from '~/store/message';
import { ref, onMounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
const authStore = useAuthStore();
const groupStore = useAuthGroups();
const messageStore = useAuthMessage();
const goalStore = useGoalStore();
const router = useRouter();
const route = useRoute();
const goal = ref([]);
const textareaRef = ref(false);
const newMessage = ref('');
const goalId = route.params.id;
const postMessage = ref([]);
onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複合成功');
        if (!authStore.isAuthenticated) {
            console.log('認証されていません。');
            return router.push('/auth/login');
        }
        goal.value = await goalStore.fetchGoalsId(goalId);
        const target = goal.value.id;
        postMessage.value = await messageStore.fetchMessageByGoalId(target);
        console.log('目標データ：', goal.value);
        adjustHeight();
    } catch (err) {
        console.error('目標データの取得に失敗しました。', err);
    }
});
const messages = computed(() => {
    return postMessage.value.filter((item) => item.goal === route.params.id);
});
const formatDate = (dateStr) => {
    const d = new Date(dateStr)
    return d.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
};
const goBack = () => {
    // router.back();
    return router.push(`/studio/${route.params.routeId}`);
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
    const user = authStore.user?.email;
    if (!user) {
        alert('ログインしてください。');
        return;
    }
    const newtext = newMessage.value.trim();
    const groupId = goal.value.group?.id;
    const goalId = route.params.id;
    // const file = ;
    try {
        const newMessage = await messageStore.CreateMessage(groupId, goalId, newtext);
        console.log('作成結果：', newMessage);
        postMessage.value = await messageStore.fetchMessageByGoalId(goalId);
        console.log('メッセージが追加されました。');
        newMessage.value = ''; // 送信後に入力欄をクリア
        // return router.push({ path: route.fullPath, force: true });
    } catch (err) {
        console.error('messageが作成されませんでした。', err);
        throw new Error;
    }
};
const props = defineProps({
    goal: { type: Object, default: () => ({}) },
    postMessage: { type: Array, default: () => [] }
})

const scrollArea = ref(null)

const autoResize = () => {
    const el = textareaRef.value
    if (!el) return
    el.style.height = 'auto'
    el.style.height = Math.min(el.scrollHeight, 190) + 'px'
}

const scrollToBottom = () => {
    const el = scrollArea.value
    if (!el) return
    el.scrollTop = el.scrollHeight
}


// --- Lifecycle / Watchers ---
onMounted(async () => {
    await nextTick()
    autoResize()
    scrollToBottom()
})

// メッセージ数が変わったら末尾へ
watch(
    () => props.postMessage.length,
    () => nextTick(scrollToBottom)
)
</script>