<template>
    <main class="text-black dark:text-white  md:ml-72 ml-0 relative flex-1 overflow-y-auto"
        :class="{ 'bg-white': !$colorMode?.value || $colorMode?.value === 'light', 'bg-black': $colorMode?.value === 'dark' }"
        :style="{
            backgroundImage: $colorMode?.value === 'dark'
                ? `linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.9)), url(${group.background_image || null} )`
                : `linear-gradient(rgba(255,255,255,0.8), rgba(255,255,255,0.9)), url(${group.background_image || null} )`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backdropFilter: 'blur(8px)'
        }">
        <div class="dark:bg-zinc-800 backdrop-blur-md py-4 pt-4">
            <div class="max-w-6xl mx-auto px-6 space-y-4">
                <div class="text-center ">
                    <button>
                        <h1 class="text-4xl dark:text-white">
                            {{ group.name }}
                        </h1>
                    </button>
                    <div class="flex justify-center gap-3 text-sm mt-2">
                        <span class="px-3 py-1 rounded-full">
                            #{{ group.tag || 'タグ未設定' }}
                        </span>
                        <span :class="group.is_public
                            ? ($colorMode?.value === 'dark' ? 'bg-green-600/80 text-white' : 'bg-green-200 text-green-800')
                            : ($colorMode?.value === 'dark' ? 'bg-red-600/80 text-white' : 'bg-red-200 text-red-800')"
                            class="px-3 py-1 rounded-full">
                            {{ group.is_public ? '公開中' : '非公開' }}
                        </span>
                    </div>
                </div>
                <div class="flex items-center justify-between gap-6">
                    <div
                        class="flex flex-col sm:flex-row items-center sm:items-start gap-2 bg-white dark:bg-gradient-to-r from-zinc-700 to-zinc-800 p-2 rounded-xl shadow-lg border  dark:border-zinc-600">
                        <img :src="group.owner?.avater"
                            class="size-14   sm:size-12 rounded-full border-2 border-blue-500 object-cover"
                            alt="オーナーのアバター" />
                        <div class="text-center sm:text-left">
                            <p class="hidden sm:block dark:text-white text-base sm:text-lg font-bold break-all">
                                {{ group.owner?.email || 'オーナー名未設定' }}
                            </p>
                            <span class="inline-block mt-2 text-xs text-purple-200 bg-purple-700/60 px-2 rounded-full">
                                👑 グループオーナー
                            </span>
                        </div>
                    </div>

                    <div>
                        <button v-if="!isJoinToStudioUrl" @click="JoinCreateForm"
                            class="px-4 py-2 rounded-full border border-green-500 text-green-600 hover:bg-green-500 hover:text-white transition">
                            招待リンクを作成する
                        </button>
                        <button v-else @click="$emit('QR-dialog')"
                            class="px-4 py-2 rounded-full border border-blue-500 text-blue-600 hover:bg-blue-500 hover:text-white transition">
                            招待QRコードを表示
                        </button>
                    </div>
                </div>
                <div class="flex flex-row w-full sm:divide-x divide-y sm:divide-y-0 divide-gray-200 dark:divide-gray-600 
                    rounded-xl border border-gray-100 dark:border-zinc-600 dark:bg-zinc-800 shadow
                    sm:overflow-visible overflow-x-auto no-scrollbar divide-x sm:divide-x divide-gray-200 dark:divide-gray-600">
                    <!-- スコア -->
                    <div class="flex-1 min-w-[175px] flex-shrink-0 p-4 text-center flex-shrink-0">
                        <p class="text-2xl font-extrabold text-blue-500 tracking-wide">
                            {{ group.score }}
                        </p>
                        <p class="text-sm dark:text-white-400 mt-1">スコア</p>
                    </div>

                    <!-- メンバー -->
                    <button @click="$emit('Member-dialog')"
                        class="flex-1 min-w-[175px] flex-shrink-0 p-4 text-center flex-shrink-0 hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-2xl font-extrabold text-purple-500 tracking-wide">
                            {{ group.members?.length || 0 }} 人
                        </p>
                        <p class="text-sm dark:text-white-400 mt-1">メンバー数</p>
                    </button>

                    <!-- ドッキング -->
                    <button @click="$emit('DockingtoStudio-dialog')"
                        class="flex-1 min-w-[175px] flex-shrink-0 p-4 text-center flex-shrink-0 hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-green-400 font-semibold">ドッキング</p>
                        <p class="text-sm dark:text-white-400 mt-1">結びつける</p>
                    </button>

                    <!-- ゴール追加 -->
                    <button @click="$emit('Goal-dialog')"
                        class="flex-1 min-w-[175px] flex-shrink-0 p-4 text-center flex-shrink-0 hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-red-400 font-semibold">＋ゴールの追加</p>
                        <p class="text-sm dark:text-white-400 mt-1">ゴールの作成</p>
                    </button>

                    <!-- 投票箱 -->
                    <button @click="$emit('Goalvote-dialog')"
                        class="flex-1 min-w-[175px] flex-shrink-0 p-4 text-center flex-shrink-0 hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-yellow-400 font-semibold">投票箱を作成</p>
                        <p class="text-sm dark:text-white-400 mt-1">投票の作成</p>
                    </button>
                </div>

                <div class="flex space-x-4  mb-4">
                    <button v-for="tab in tabs" :key="tab" @click="activeTab = tab" :class="[
                        'px-4 py-2',
                        activeTab === tab
                            ? 'border-b-2 border-blue-500 text-blue-600'
                            : 'text-gray-500 hover:text-gray-700'
                    ]">
                        {{ tab }}
                    </button>
                </div>
                <div v-if="activeTab === 'ゴール'">
                    <!-- 空状態 -->
                    <div v-if="!goals?.length"
                        class="rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8 text-center">
                        <p class="text-sm text-zinc-500 dark:text-zinc-400">まだゴールがありません。</p>
                        <p class="text-xs text-zinc-400 mt-1">右上の「＋」から作成しましょう。</p>
                    </div>
                    <div v-else>
                        <ul
                            class="divide-y divide-zinc-200 dark:divide-zinc-800 hover:bg-zinc-700 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
                            <li v-for="goal in goals" :key="goal.id"
                                class="group bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 border-b border-zinc-200 dark:border-zinc-700 transition-colors cursor-pointer shadow-sm">
                                <button type="button" class="w-full text-left p-4 sm:p-5 flex flex-col gap-3 transition-colors
                   hover:bg-zinc-50 dark:hover:bg-zinc-800/60 focus:outline-none focus-visible:ring-2
                   focus-visible:ring-blue-500" @click="PushToNextpage(goal.id)"
                                    @keydown.enter.prevent="PushToNextpage(goal.id)"
                                    @keydown.space.prevent="PushToNextpage(goal.id)"
                                    :aria-label="`ゴール詳細を開く: ${goal.header || '見出し無し'}`">
                                    <!-- ヘッダー行 -->
                                    <div class="flex items-start gap-3 sm:gap-4">
                                        <img :src="goal?.assignee?.avater || defaultAvatar" @error="onAvatarError"
                                            class="size-10 sm:size-12 rounded-full object-cover ring-2 ring-white dark:ring-zinc-700 shadow"
                                            alt="" loading="lazy" />
                                        <div class="min-w-0 flex-1">
                                            <div class="flex items-center gap-2">
                                                <h3 class="text-base sm:text-lg font-semibold tracking-wide text-zinc-800 dark:text-zinc-50
                           line-clamp-1 break-all">
                                                    {{ goal.header || '見出し無し' }}
                                                </h3>
                                                <!-- 完了バッジ -->
                                                <span v-if="goal.progress >= 100" class="inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-medium
                           bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300">
                                                    完了
                                                </span>
                                            </div>

                                            <!-- 進捗バー -->
                                            <div class="mt-2">
                                                <div
                                                    class="h-2.5 w-full rounded-full bg-zinc-200 dark:bg-zinc-700 overflow-hidden">
                                                    <div class="h-full rounded-full transition-all duration-300"
                                                        :class="progressBarClass(goal.progress)"
                                                        :style="{ width: Math.min(Math.max(goal.progress ?? 0, 0), 100) + '%' }"
                                                        role="progressbar" :aria-valuenow="clamp(goal.progress)"
                                                        aria-valuemin="0" aria-valuemax="100" />
                                                </div>
                                                <div
                                                    class="mt-1 flex items-center justify-between text-xs text-zinc-500 dark:text-zinc-400">
                                                    <span>{{ clamp(goal.progress) }}%</span>
                                                    <span class="inline-flex items-center gap-1">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="size-3.5"
                                                            viewBox="0 0 24 24" fill="currentColor">
                                                            <path d="M7 11h10v2H7z" />
                                                        </svg>
                                                        <span class="sr-only">進捗バー</span>
                                                    </span>
                                                </div>
                                            </div>

                                            <!-- メタ情報 -->
                                            <div
                                                class="mt-2 text-xs sm:text-[13px] text-zinc-500 dark:text-zinc-400 flex flex-wrap items-center gap-3">
                                                <span class="inline-flex items-center gap-1">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="size-4"
                                                        viewBox="0 0 24 24" fill="currentColor">
                                                        <path
                                                            d="M7 2h10a2 2 0 0 1 2 2v2H5V4a2 2 0 0 1 2-2zm12 6v12a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V8h14z" />
                                                    </svg>
                                                    {{ goal.deadline ? ('締め切り: ' + formatDate(goal.deadline)) :
                                                    '📅締め切りなし' }}
                                                </span>

                                                <span v-if="goal?.assignee?.name"
                                                    class="inline-flex items-center gap-1">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="size-4"
                                                        viewBox="0 0 24 24" fill="currentColor">
                                                        <path
                                                            d="M12 12a5 5 0 1 0-5-5 5 5 0 0 0 5 5zm0 2c-4.33 0-8 2.17-8 5v1h16v-1c0-2.83-3.67-5-8-5z" />
                                                    </svg>
                                                    {{ goal.assignee.name }}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </button>
                            </li>
                        </ul>
                    </div>
                </div>
                <div v-else-if="activeTab === 'ライブラリ'" class="space-y-4">
                    <div v-if="!alllibrary?.length"
                        class="rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8 text-center">
                        <p class="text-sm text-zinc-500 dark:text-zinc-400">まだドッキングされたライブラリがありません。</p>
                        <p class="text-xs text-zinc-400 mt-1">右上の「＋」から追加しましょう。</p>
                    </div>
                    <div v-else
                        class="divide-y divide-zinc-200 dark:divide-zinc-800 hover:bg-zinc-700 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
                        <div v-for="lib in alllibrary" :key="lib.id" @click="emitLibrary(lib.target.id)" class="bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 p-4
                        shadow-sm transition cursor-pointer border-b border-zinc-200 dark:border-zinc-700">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor"
                                        class="text-amber-500 dark:text-yellow-300" viewBox="0 0 16 16">
                                        <path
                                            d="M.54 3.87.5 3a2 2 0 0 1 2-2h3.672a2 2 0 0 1 1.414.586l.828.828A2 2 0 0 0 9.828 3h3.982a2 2 0 0 1 1.992 2.181l-.637 7A2 2 0 0 1 13.174 14H2.826a2 2 0 0 1-1.991-1.819l-.637-7a2 2 0 0 1 .342-1.31z" />
                                    </svg>
                                    <h3 class="text-base font-medium text-zinc-800 dark:text-white break-words">
                                        {{ lib.target.name }}
                                    </h3>
                                </div>
                                <div>
                                    {{ formatDate(lib.created_at) }}
                                </div>
                            </div>
                            <!-- タグ -->
                            <div v-if="lib.target.tag" class="ml-7 mt-1">
                                <p class="text-sm text-zinc-500 dark:text-zinc-400">#{{ lib.target.tag }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div v-else-if="activeTab === '投票'" class="space-y-6">
                    <div v-if="!allvotes?.length"
                        class="rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8 text-center">
                        <p class="text-sm text-zinc-500 dark:text-zinc-400">まだ投票箱がありません。</p>
                        <p class="text-xs text-zinc-400 mt-1">右上の「＋」から作成しましょう。</p>
                    </div>
                    <div v-else
                        class="divide-y divide-zinc-200 dark:divide-zinc-800 hover:bg-zinc-700 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
                        <div v-for="vote in allvotes" :key="vote.id" @click="emitVote(vote.id)"
                            class="group bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 border-b border-zinc-200 dark:border-zinc-700 p-4 transition-colors cursor-pointer shadow-sm">
                            <!-- 上段：説明とユーザー -->
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
                                <!-- 投票内容 -->
                                <div class="flex items-center justify-between flex-1">
                                    <div class="flex items-center items-start gap-3">
                                        <div class="pt-1">
                                            <div
                                                class="flex items-center gap-3 text-sm text-zinc-500 dark:text-zinc-400">
                                                <img :src="vote.voter.avater" alt="avatar"
                                                    class="w-10 h-10 rounded-full border border-white dark:border-zinc-600 object-cover shadow" />
                                            </div>
                                        </div>
                                        <h3
                                            class="sm:text-xl font-semibold text-zinc-800 dark:text-white break-words leading-snug">
                                            {{ vote.explain }}
                                        </h3>
                                    </div>
                                    <span v-if="vote.goal.progress >= 100"
                                        class="px-2 py-1 rounded bg-green-600 text-white text-xs">
                                        達成済み
                                    </span>
                                    <span v-if="isVoting" class="px-2 py-1 rounded bg-yellow-600 text-white text-xs">
                                        投票済み
                                    </span>
                                </div>
                            </div>
                            <div v-if="vote.goal?.header"
                                class="pl-12 mt-[-4px] sm:text-xl text-zinc-500 dark:text-zinc-400">
                                <span
                                    class="inline-block bg-zinc-100 dark:bg-zinc-700 px-2 py-0.5 rounded text-sm font-medium tracking-wide">
                                    #{{ vote.goal.header }}の投票
                                </span>
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
import { useAuthVote } from '~/store/vote';
import { useAuthLibrary } from '~/store/library';
import { useRoute, useRouter } from 'vue-router';
import { ref, onMounted, createCommentVNode } from 'vue';
import { v4 as uuidv4 } from 'uuid';
import { errorMessages } from 'vue/compiler-sfc';
import { QrcodeCanvas } from 'qrcode.vue';
import { QrcodeSvg } from 'qrcode.vue';
import { useRuntimeConfig } from "#app";
import { eventBus } from '~/utils/eventBus';
import Dialog from '~/components/MainDialog.vue';
import {
    hasVote,
    getVote,
    setVote,
    loadVote
} from '~/composables/useVoteHistory.js';
const colorMode = useColorMode();
const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const authGroup = useAuthGroups();
const authGoal = useGoalStore();
const authVote = useAuthVote();
const group = ref([]);
const goals = ref([]);
const allgoals = ref([]);
const allvotes = ref([]);
const alllibrary = ref([]);
const isJoinToStudioUrl = ref(false);
const invterURL = ref('');
const openQRdailog = ref(false);
const openGoalDialog = ref(false);
const isSidebarOpen = ref(false);
const isShowMember = ref(false);
const isJoined = ref(false);
const routeId = route.params.id;
const toggleSidebar = () => {
    isSidebarOpen.value = !isSidebarOpen.value
};
const authLibrary = useAuthLibrary();
const tabs = ['ゴール', 'ライブラリ', '投票'];
const activeTab = ref('ゴール');
const currentUser = computed(() => authStore.currentUser);
const isVoteing = ref(false);
onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複合完了');
        const routeId = route.params.id;
        group.value = await authGroup.fetchGroupId(routeId);
        goals.value = await authGoal.fetchGoalsByGroup(routeId);
        allgoals.value = await authGoal.fetchGoals();
        allvotes.value = await authVote.FetchVotesByGroup(routeId);
        alllibrary.value = await authLibrary.FetchDockingLibrary(routeId);
        const key = `${group.name}_${route.params.id}`;
        const storedUrl = localStorage.getItem(key);
        if (storedUrl) {
            invterURL.value = storedUrl;
            isJoinToStudioUrl.value = true;
        }
    } catch (error) {
        console.error('エラー：', error);
        throw error;
    }
});
function emitVote(voteId) {
    console.log('投票ID:', voteId);
    eventBus.emit('Vote-dialog', voteId);
};
function emitLibrary(libraryId) {
    console.log('ライブラリID:', libraryId);
    eventBus.emit('Folder-dialog', libraryId);
};
const mygoals = computed(() => {
    return allgoals.value.filter((item) => item.assignee?.email === authStore.user?.email)
});
const PushToNextpage = async (id) => {
    try {
        router.push(`/studio/${routeId}/g/${id}`);
    } catch (err) {
        console.error("アクセス失敗：", err);
    }
};
const props = defineProps({
    activeTab: { type: String, required: true },
    goals: { type: Array, default: () => [] }, // [{ id, header, progress, deadline, assignee: { avater, name } }]
    vote: { type: Object, required: true },
});
const isVoting = computed(() => {
    const userId = authStore.user?.id;
    const voteId = props.vote?.id;
    if (!userId || !voteId) return false;
    return hasVote(userId, voteId);
})
const JoinCreateForm = async () => {
    const config = useRuntimeConfig();
    const routeId = route.params.id;
    const authStore = useAuthStore();
    const baseUrl = window.location.origin;
    const response = await fetch(`${config.public.apiBase}invite/create/`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${authStore.accessToken}`
        },
        body: JSON.stringify({
            group_id: routeId,
            expire_in: 3600
        })
    });
    if (!response.ok) {
        throw new Error(`サーバーエラー: ${response.status}`);
    }
    const res = await response.json();
    const encryptedData = res.encrypted_data;
    console.log('暗号化されたデータ:', encryptedData);
    invterURL.value = `${baseUrl}/studio/${routeId}/join?data=${encodeURIComponent(encryptedData)}`;
    console.log('複合化された招待URL:', decodeURIComponent(encryptedData));
    localStorage.setItem(`${group.name}_${routeId}`, invterURL.value);
    const inviteTokens = localStorage.getItem(`${group.name}_${routeId}`);
    if (inviteTokens) {
        isJoinToStudioUrl.value = true;
        console.log('招待リンク生成成功:', invterURL.value);
    } else {
        console.error('招待URL・トークンの作成失敗');
    }
};
const formatDate = (dateStr) => {
    const d = new Date(dateStr)
    return d.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
};
const DeleteVote = async (voteId) => {
    try {
        const response = await authVote.DeleteVote(voteId);
        if (response.status === 204) {
            console.log('投票削除成功', response);
            return router.go(0);
        } else {
            console.error('投票削除失敗', response.status);
            throw new Error('投票削除に失敗しました');
        }
    } catch (err) {
        console.error('投票削除エラー:', err);
        throw err;
    }
};

// 0〜100 に丸める
const clamp = (n) => {
    const v = typeof n === 'number' ? n : 0
    return Math.min(100, Math.max(0, Math.round(v)))
}

// 進捗バーの色クラス
const progressBarClass = (p) => {
    const v = clamp(p)
    if (v < 40) return 'bg-red-500'
    if (v < 80) return 'bg-yellow-500'
    return 'bg-green-500'
}

// アバターのデフォルト（SVG）
const defaultAvatar = 'data:image/svg+xml;utf8,' + encodeURIComponent(`
  <svg xmlns='http://www.w3.org/2000/svg' width='96' height='96' viewBox='0 0 24 24' fill='none'>
    <rect width='24' height='24' rx='12' fill='#71717A'/>
    <path d='M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4zm0 2c-4 0-7 2-7 4v1h14v-1c0-2-3-4-7-4z' fill='white'/>
  </svg>
`)

// 画像エラー時フォールバック
const onAvatarError = (e) => {
    const img = e.target
    if (img && img.tagName === 'IMG') {
        img.src = defaultAvatar
    }
}
</script>
