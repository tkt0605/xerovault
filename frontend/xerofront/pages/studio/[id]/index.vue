<template>
    <main class="text-black dark:text-white min-h-screen md:ml-72 ml-0 relative flex-1 overflow-y-auto"
        :class="{ 'bg-white': !$colorMode?.value || $colorMode?.value === 'light', 'bg-black': $colorMode?.value === 'dark' }"
        :style="{
            backgroundImage: $colorMode?.value === 'dark'
                ? `linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.9)), url(${group.background_image || '/default-bg.jpg'})`
                : `linear-gradient(rgba(255,255,255,0.8), rgba(255,255,255,0.9)), url(${group.background_image || '/default-bg.jpg'})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backdropFilter: 'blur(8px)'
        }">
        <div class="dark:bg-zinc-800 backdrop-blur-md min-h-screen py-12">
            <div class="max-w-4xl mx-auto px-6 space-y-12">
                <!-- タイトル -->
                <div class="text-center space-y-2">
                    <button>
                        <h1 class="text-4xl font-extrabold text-transparent bg-clip-text"
                            :class="$colorMode?.value === 'dark' ? 'bg-gradient-to-r from-cyan-400 to-indigo-400' : 'bg-gradient-to-r from-blue-500 to-indigo-600'">
                            {{ group.name }}
                        </h1>
                    </button>
                    <div class="flex justify-center gap-3 text-sm">
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

                <!-- オーナー -->
                <div class="flex items-center justify-between gap-6">
                    <div class="flex items-center gap-4">
                        <img :src="group.owner?.avater"
                            class="w-14 h-14 rounded-full border-2 border-white shadow-lg object-cover" alt="Avatar" />
                    </div>
                    <div>
                        <button v-if="!isJoinToStudioUrl" @click="JoinCreateForm"
                            class="px-4 py-2 rounded-full border border-green-500 text-green-600 hover:bg-green-500 hover:text-white transition">
                            招待リンクを作成する
                        </button>
                        <button v-else @click="QRdialog"
                            class="px-4 py-2 rounded-full border border-blue-500 text-blue-600 hover:bg-blue-500 hover:text-white transition">
                            招待QRコードを表示
                        </button>
                    </div>
                </div>

                <!-- スコア & ゴール -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                    <div class="dark:bg-blackshadow-inner p-6 rounded-xl text-center border border-zinc-200">
                        <p class="text-sm" :class="$colorMode?.value === 'dark' ? 'text-bule-400' : 'text-bule-500'">スコア
                        </p>
                        <p class="text-3xl text-blue-500 font-bold mt-2">{{ group.score }}</p>
                    </div>
                    <button @click="CreateGoal"
                        class="border-2 border-dashed border-zinc-300 hover:border-blue-400 hover:text-blue-500 text-zinc-600 dark:text-zinc-300 p-6 rounded-xl text-center transition">
                        ゴールの追加
                        <div class="text-xs mt-1">このスタジオでの目標を作成</div>
                    </button>
                </div>

                <!-- 参加者 -->
                <div>
                    <h2 class="text-lg font-semibold mb-2">参加者一覧 | メンバー</h2>
                    <div :class="$colorMode?.value === 'dark' ? 'bg-zinc-800/70' : 'bg-zinc-100'"
                        class="dark:bg-zinc-900 flex flex-wrap gap-4 p-4 rounded-xl">
                        <div v-for="member in group.members" :key="member" class="flex items-center justify-between">
                            <img :src="member.avater"
                                class="w-10 h-10 rounded-full border-2 border-white hover:border-blue-400 transition object-cover"
                                alt="Member" />
                            <button @click="isDeleteAlart( member.id)" class="text-red-500 hover:underline">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                                    class="bi bi-feather" viewBox="0 0 16 16">
                                    <path
                                        d="M15.807.531c-.174-.177-.41-.289-.64-.363a3.8 3.8 0 0 0-.833-.15c-.62-.049-1.394 0-2.252.175C10.365.545 8.264 1.415 6.315 3.1S3.147 6.824 2.557 8.523c-.294.847-.44 1.634-.429 2.268.005.316.05.62.154.88q.025.061.056.122A68 68 0 0 0 .08 15.198a.53.53 0 0 0 .157.72.504.504 0 0 0 .705-.16 68 68 0 0 1 2.158-3.26c.285.141.616.195.958.182.513-.02 1.098-.188 1.723-.49 1.25-.605 2.744-1.787 4.303-3.642l1.518-1.55a.53.53 0 0 0 0-.739l-.729-.744 1.311.209a.5.5 0 0 0 .443-.15l.663-.684c.663-.68 1.292-1.325 1.763-1.892.314-.378.585-.752.754-1.107.163-.345.278-.773.112-1.188a.5.5 0 0 0-.112-.172M3.733 11.62C5.385 9.374 7.24 7.215 9.309 5.394l1.21 1.234-1.171 1.196-.027.03c-1.5 1.789-2.891 2.867-3.977 3.393-.544.263-.99.378-1.324.39a1.3 1.3 0 0 1-.287-.018Zm6.769-7.22c1.31-1.028 2.7-1.914 4.172-2.6a7 7 0 0 1-.4.523c-.442.533-1.028 1.134-1.681 1.804l-.51.524zm3.346-3.357C9.594 3.147 6.045 6.8 3.149 10.678c.007-.464.121-1.086.37-1.806.533-1.535 1.65-3.415 3.455-4.976 1.807-1.561 3.746-2.36 5.31-2.68a8 8 0 0 1 1.564-.173" />
                                </svg>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- タイムスタンプ -->
                <div class="text-xs text-zinc-500 flex justify-between pt-6">
                    <span>作成: {{ formatDate(group.created_at) }}</span>
                    <span>更新: {{ formatDate(group.updated_at) }}</span>
                </div>

                <!-- ゴールリスト -->
                <div class="space-y-6">
                    <div v-for="goal in goals" :key="goal.id"
                        :class="$colorMode?.value === 'dark' ? 'bg-zinc-800/80 text-white' : 'bg-white text-gray-900'"
                        class="p-6  shadow-md dark:bg-zinc-800 hover:shadow-lg transition border-b border-zinc-500">
                        <div class="flex items-center justify-between mb-3">
                            <h3 class="text-xl font-bold dark:text-white">{{ goal.header || '見出し無し' }}</h3>
                            <img :src="goal.assignee.avater"
                                class="w-10 h-10 rounded-full border-2 border-white object-cover" alt="Assignee" />
                        </div>
                        <p :class="$colorMode?.value === 'dark' ? 'text-zinc-300' : 'text-white'" class="text-sm">
                            {{ goal.description || '説明がありません。' }}
                        </p>
                        <small class="block mt-2 text-xs"
                            :class="$colorMode?.value === 'dark' ? 'text-zinc-400' : 'text-gray-500'">
                            {{ goal.deadline ? '締め切り: ' + formatDate(goal.deadline) : '締め切りなし' }}
                        </small>
                    </div>
                </div>
            </div>
        </div>
        <Dialog :visible="openGoalDialog" @close="openGoalDialog = false">
            <template #header>
                <h2 class="text-xl font-bold text-white">🎯 ゴールの作成</h2>
            </template>

            <template #default>
                <div class="space-y-6 py-2">
                    <!-- ゴール名 -->
                    <div>
                        <label class="block text-sm font-semibold text-gray-100 mb-1">ゴール名</label>
                        <input v-model="goalHead" type="text" placeholder="例：週に1回プロトタイプを提出"
                            class="w-full bg-gray-800 text-white border border-gray-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                    </div>

                    <!-- ゴールの説明 -->
                    <div>
                        <label class="block text-sm font-semibold text-gray-100 mb-1">詳細な説明</label>
                        <textarea v-model="goalDescription" rows="4" placeholder="このゴールの目的や背景、達成のためのアプローチなどを書いてください。"
                            class="w-full bg-gray-800 text-white border border-gray-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 resize-y"></textarea>
                    </div>

                    <!-- 締め切り日 -->
                    <div>
                        <label class="block text-sm font-semibold text-gray-100 mb-1">締め切り日（任意）</label>
                        <input v-model="goalDeadline" type="date" :min="new Date().toISOString().split('T')[0]"
                            class="w-full bg-gray-800 text-white border border-gray-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="flex justify-end gap-3 mt-4">
                    <button @click="openGoalDialog = false"
                        class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition">
                        キャンセル
                    </button>
                    <button @click="submitGoal"
                        class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">
                        作成する
                    </button>
                </div>
            </template>
        </Dialog>


        <!-- QRコード Dialog -->
        <Dialog :visible="openQRdailog" @close="openQRdailog = false">
            <template #header>
                <h2 class="text-lg font-semibold text-zinc-800 dark:text-white">
                    {{ group.name }} のQRコード
                </h2>
            </template>
            <template #default>
                <div class="space-y-6">
                    <div class="flex justify-center">
                        <div class="bg-white dark:bg-zinc-700 p-4 rounded-lg shadow aspect-square">
                            <QrcodeCanvas :value="invterURL" :size="180" level="M" />
                        </div>
                    </div>
                    <div class="bg-zinc-50 dark:bg-zinc-800 rounded-lg p-4 space-y-3">
                        <div
                            class="flex items-center justify-between gap-2 bg-zinc-100 dark:bg-zinc-700 p-3 rounded-lg shadow-inner">
                            <input type="text" :value="invterURL" readonly
                                class="w-full px-3 py-2 text-sm rounded-md text-gray-800 dark:text-white bg-white dark:bg-zinc-800 border border-gray-300 dark:border-zinc-600 focus:outline-none" />
                            <button @click="copyToClipboard(invterURL)"
                                class="px-3 py-1 text-sm text-white bg-blue-600 hover:bg-blue-700 rounded-md transition">
                                コピー
                            </button>
                        </div>
                        <p class="text-sm text-gray-500 dark:text-gray-400">このコードをコピーして共有してください。</p>
                        <div
                            class="flex items-center justify-between gap-2 bg-zinc-100 dark:bg-zinc-600 p-3 rounded shadow">
                            <div class="text-sm font-mono text-black dark:text-white break-all">{{
                                group.joined_token }}</div>
                            <button @click="copyToClipboard"
                                class="p-2 rounded bg-zinc-600 hover:bg-zinc-700 text-white transition" title="コピー">
                                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="currentColor"
                                    viewBox="0 0 16 16">
                                    <path fill-rule="evenodd"
                                        d="M4 2a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zm2-1a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1zM2 5a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-1h1v1a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h1v1z" />
                                </svg>
                            </button>
                        </div>
                    </div>
                </div>
            </template>
            <template #footer>
                <button @click="closeQRdialog"
                    class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition">
                    キャンセル
                </button>
                <button @click="RemoveQR()" class="">QRを削除する。</button>
            </template>
        </Dialog>
    </main>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useGoalStore } from '~/store/goal';
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
const authGoal = useGoalStore()
const group = ref([]);
const goals = ref([]);
const isJoinToStudioUrl = ref(false);
const invterURL = ref('');
const openQRdailog = ref(false);
const goalHead = ref('');
const goalDescription = ref('');
const goalDeadline = ref('');
const openGoalDialog = ref(false);
const isSidebarOpen = ref(false);
const isJoined = ref(false);
const toggleSidebar = () => {
    isSidebarOpen.value = !isSidebarOpen.value
};
onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複合完了');
        const routeId = route.params.id;
        group.value = await authGroup.fetchGroupId(routeId);
        goals.value = await authGoal.fetchGoalsByGroup(routeId);
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
const QRdialog = () => {
    openQRdailog.value = true;
}
const closeQRdialog = () => {
    openQRdailog.value = false;
}
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
const RemoveQR = async () => {
    const routeId = route.params.id;
    const key = `${group.name}_${routeId}`;
    const inviteTokens = localStorage.getItem(key);
    if (inviteTokens) {
        localStorage.removeItem(key);
        isJoinToStudioUrl.value = false;
        openQRdailog.value = false
        console.log('削除成功');
    } else {
        console.warn('削除失敗');
    }
};
const formatDate = (dateStr) => {
    const d = new Date(dateStr)
    return d.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
};
const copyToClipboard = async () => {
    try {
        await navigator.clipboard.writeText(invterURL.value);
        alert("コピーしました！");
    } catch (err) {
        console.error("コピーに失敗:", err);
        alert("コピーに失敗しました。");
    }
};
const CreateGoal = () => {
    openGoalDialog.value = true;
}
const submitGoal = () => {
    const group = route.params.id;
    if (!group) {
        console.error('グループがしてされていません。');
        return;
    }
    const goal_header = goalHead.value.trim();
    const goal_description = goalDescription.value.trim();
    const goal_deadline = goalDeadline.value;
    try {

        if (!goal_header || !goal_description || !goal_deadline) {
            console.error('ゴールの情報が不完全です。');
            return;
        }
        const newGoal = authGoal.CreateGoal(group, goal_header, goal_description, goal_deadline);
        goals.value = authGoal.fetchGoals();
        if (goals.value) {
            console.log('新しいゴールが作成されました:', newGoal);
            console.log('目標の作成に成功しました。');
            openGoalDialog.value = false;
            goalHead.value = '';
            goalDescription.value = '';
            goalDeadline.value = '';
        } else {
            console.error('目標の作成に失敗しました。')
        }
    } catch (err) {
        console.error('目標の作成中にエラーが発生しました:', err);
        throw err;
    }
};
const isDeleteAlart = (memberId) => {
    if (confirm(`本当にメンバー「${memberId}」を削除しますか？`)) {
        removeMember(memberId);
        RemoveQR();
        console.log('メンバーの削除が完了 | 招待トークンも削除されました。');
    } else {
        console.log('メンバーの削除がキャンセルされました。');
    }
};
const removeMember = async(memberId) => {
    const groupId = route.params.id;
    console.log("メンバーID：", memberId);
    try{
        const response = await authGroup.DeleteMember(groupId, memberId);
        if (response){
            console.log('メンバーの削除完了:', response);
            // メンバー削除後の更新処理
            group.value = await authGroup.fetchGroupId(groupId);
            goals.value = await authGoal.fetchGoalsByGroup(groupId);
            return route.push(`/studio/${groupId}`);
        }else{
            console.error('メンバーの削除に失敗しました。');
            throw new Error('メンバーの削除・失敗:');
        }
    }catch(error){
        console.error('メンバーの削除中にエラー発生:', error);
        throw error;
    }
};
</script>
