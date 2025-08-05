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
            <div class="max-w-4xl mx-auto px-6 space-y-6">
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
                    <div v-for="goal in goals" :key="goal.id"
                        class="p-4 transition-all duration-200 border-b border-zinc-700 flex flex-col gap-2 dark:bg-zinc-800  dark:hover:bg-zinc-700 text-white">
                        <div @click="PushToNextpage(goal.id)">
                            <div class="flex items-center gap-2">
                                <img :src="goal?.assignee?.avater"
                                    class="w-10 h-10 rounded-full border-2 border-white object-cover shadow" />
                                <h3 class="text-lg sm:text-xl font-semibold tracking-wide break-all dark:text-white">
                                    {{ goal.header || '見出し無し' }}
                                </h3>
                            </div>
                            <div class="text-sm ml-12 text-zinc-400 mt-1">
                                {{ goal.deadline ? '締め切り: ' + formatDate(goal.deadline) : '📅 締め切りなし' }}
                            </div>
                        </div>
                    </div>
                </div>
                <div v-else-if="activeTab === 'ライブラリ'">
                    <div v-for="lib in alllibrary" :key="lib.id"
                        class="p-4 transition-all duration-200 border-b border-zinc-700 flex flex-col gap-2 dark:bg-zinc-800  dark:hover:bg-zinc-700 text-white">
                        <div>
                            <div class="flex items-center gap-2">
                                <h3 class="text-lg sm:text-xl font-semibold tracking-wide break-all dark:text-white">
                                    {{ lib.target.name }}
                                </h3>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-else-if="activeTab === '投票'" class="p-4">
                    <div v-for="vote in allvotes" :key="vote.id"
                        class="p-4 transition-all duration-200 border-b border-zinc-700 flex flex-col gap-2 dark:bg-zinc-800  dark:hover:bg-zinc-700 text-white">
                        <div @click="$emit('Vote-dialog', vote.id)">
                            <div class="flex items-center gap-2">
                                <h3 class="text-lg sm:text-xl font-semibold tracking-wide break-all dark:text-white">
                                    {{ vote.explain }}
                                </h3>
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
import { ref, onMounted } from 'vue';
import { v4 as uuidv4 } from 'uuid';
import { errorMessages } from 'vue/compiler-sfc';
import { QrcodeCanvas } from 'qrcode.vue';
import { QrcodeSvg } from 'qrcode.vue';
import { useRuntimeConfig } from "#app";
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
</script>
