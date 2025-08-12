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
        <div class="dark:bg-zinc-800 backdrop-blur-md py-4 pt-16">
            <div class="max-w-6xl mx-auto px-6 space-y-4">
                <div class="text-center ">
                    <button>
                        <h1 class="text-4xl dark:text-white">
                            {{ group.name }}
                        </h1>
                    </button>
                    <div class="flex justify-center gap-3 text-sm mt-2">
                        <span
                            :class="$colorMode?.value === 'dark' ? 'bg-zinc-800/80 text-white' : 'bg-zinc-100 text-gray-800'"
                            class="px-3 py-1 rounded-full">
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
                        class="flex flex-col sm:flex-row items-center sm:items-start gap-4 bg-white dark:bg-gradient-to-r from-zinc-700 to-zinc-800 p-4 rounded-xl shadow-lg border  dark:border-zinc-600">
                        <img :src="group.owner?.avater"
                            class="w-20 h-20 sm:w-14 sm:h-14 rounded-full border-2 border-blue-500 object-cover"
                            alt="オーナーのアバター" />
                        <div class="text-center sm:text-left">
                            <p class="hidden sm:block dark:text-white text-base sm:text-lg font-bold break-all">
                                {{ group.owner?.email || 'オーナー名未設定' }}
                            </p>
                            <span
                                class="inline-block mt-2 text-xs text-purple-200 bg-purple-700/60 px-2 py-0.5 rounded-full">
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
                <div
                    class="flex flex-col sm:flex-row w-full divide-y sm:divide-y-0 sm:divide-x divide-gray-200 dark:divide-gray-600 rounded-xl overflow-hidden border border-gray-100 dark:border-zinc-600 dark:bg-zinc-800 shadow ">
                    <div class="flex-1 min-w-0 p-6 text-center">
                        <p class="text-sm text-blue-400">スコア</p>
                        <p class="text-3xl font-extrabold text-blue-500 mt-2 tracking-wide">
                            {{ group.score }}
                        </p>
                    </div>
                    <button @click="$emit('Member-dialog')"
                        class="flex-1 min-w-0 p-6 text-center hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-sm text-purple-400">メンバー数</p>
                        <p class="text-2xl font-extrabold text-purple-500 mt-2 tracking-wide">
                            {{ group.members?.length || 0 }} 人
                        </p>
                    </button>
                    <button @click="$emit('DockingtoStudio-dialog')"
                        class="flex-1 min-w-0 p-6 text-center hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-green-400 font-semibold">ドッキング</p>
                        <p class="text-sm dark:text-white-400 mt-1">ライブラリを結びつける</p>
                    </button>
                    <button @click="$emit('Goal-dialog')"
                        class="flex-1 min-w-0 p-6 text-center hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-red-400 font-semibold">＋ゴールの追加</p>
                        <p class="text-sm dark:text-white-400 mt-1">新規ゴールを作成</p>
                    </button>
                    <button @click="$emit('Goalvote-dialog')"
                        class="flex-1 min-w-0 p-6 text-center hover:bg-gray-100 dark:hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-yellow-400 font-semibold">ゴールの投票</p>
                        <p class="text-sm dark:text-white-400 mt-1">ゴールの結果投票</p>
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
                    <div
                        class="divide-y divide-zinc-200 dark:divide-zinc-800 hover:bg-zinc-700 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
                        <div v-for="goal in goals" :key="goal.id"
                            class="p-4 transition-all duration-200 border-b border-zinc-700 flex flex-col gap-2 dark:bg-zinc-800  dark:hover:bg-zinc-700 text-white">
                            <div @click="PushToNextpage(goal.id)">
                                <div class="flex items-center gap-2">
                                    <img :src="goal?.assignee?.avater"
                                        class="w-10 h-10 rounded-full border-2 border-white object-cover shadow" />
                                    <h3
                                        class="text-lg sm:text-xl font-semibold tracking-wide break-all dark:text-white">
                                        {{ goal.header || '見出し無し' }}
                                    </h3>
                                </div>
                                <div class="text-sm ml-12 text-zinc-400 mt-1">
                                    {{ goal.deadline ? '締め切り: ' + formatDate(goal.deadline) : '📅 締め切りなし' }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-else-if="activeTab === 'ライブラリ'" class="space-y-4">
                    <div
                        class="divide-y divide-zinc-200 dark:divide-zinc-800 hover:bg-zinc-700 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
                        <div v-for="lib in alllibrary" :key="lib.id" @click="emitLibrary(lib.target.id)" class="bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 p-4
                        shadow-sm transition cursor-pointer border-b border-zinc-200 dark:border-zinc-700">
                            <div class="flex items-center justify-between">
                                <!-- 上段：フォルダアイコン + ライブラリ名 -->
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
                    <div
                        class="divide-y divide-zinc-200 dark:divide-zinc-800 hover:bg-zinc-700 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
                        <div v-for="vote in allvotes" :key="vote.id" @click="emitVote(vote.id)"
                            class="group bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 border-b border-zinc-200 dark:border-zinc-700 rounded-xl px-6 py-4 transition-colors cursor-pointer shadow-sm">
                            <!-- 上段：説明とユーザー -->
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                                <!-- 投票内容 -->
                                <div class="flex items-start gap-3">
                                    <div class="pt-1">
                                        <!-- SVGアイコン -->
                                        <button class="hover:bg-zinc-100 rounded-full" @click="DeleteVote(vote.id)">
                                            <svg xmlns="http://www.w3.org/2000/svg"
                                                class="w-5 h-5 text-indigo-500 dark:text-indigo-300" fill="currentColor"
                                                viewBox="0 0 16 16">
                                                <path
                                                    d="M6 6.207v9.043a.75.75 0 0 0 1.5 0V10.5a.5.5 0 0 1 1 0v4.75a.75.75 0 0 0 1.5 0v-8.5a.25.25 0 1 1 .5 0v2.5a.75.75 0 0 0 1.5 0V6.5a3 3 0 0 0-3-3H6.236a1 1 0 0 1-.447-.106l-.33-.165A.83.83 0 0 1 5 2.488V.75a.75.75 0 0 0-1.5 0v2.083c0 .715.404 1.37 1.044 1.689L5.5 5c.32.32.5.754.5 1.207" />
                                                <path d="M8 3a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3" />
                                            </svg>
                                        </button>
                                    </div>
                                    <h3
                                        class="text-lg font-semibold text-zinc-800 dark:text-white break-words leading-snug">
                                        {{ vote.explain }}
                                    </h3>
                                </div>

                                <!-- 投稿者情報 -->
                                <div class="flex items-center gap-3 text-sm text-zinc-500 dark:text-zinc-400">
                                    <img :src="vote.voter.avater" alt="avatar"
                                        class="w-8 h-8 rounded-full border border-white dark:border-zinc-600 object-cover shadow" />
                                    <div class="flex flex-col">
                                        <span>{{ vote.voter.email }}</span>
                                        <time class="text-xs text-zinc-400">{{ formatDate(vote.created_at) }}</time>
                                    </div>
                                </div>
                            </div>

                            <!-- 関連ゴール -->
                            <div v-if="vote.goal?.header" class="mt-3 pl-8 text-sm text-zinc-500 dark:text-zinc-400">
                                <span
                                    class="inline-block bg-zinc-100 dark:bg-zinc-700 px-2 py-0.5 rounded text-xs font-medium tracking-wide">
                                    #{{ vote.goal.header }}
                                </span>
                                に関連する投票です
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
const colorMode = useColorMode()
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
}
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
</script>
