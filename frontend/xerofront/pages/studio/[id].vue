<template>
    <main class="text-black dark:text-white  md:ml-72 ml-0 relative flex-1 overflow-y-auto"
        :class="{ 'bg-white': !$colorMode?.value || $colorMode?.value === 'light', 'bg-black': $colorMode?.value === 'dark' }"
        :style="{
            backgroundImage: $colorMode?.value === 'dark'
                ? `linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.9)), url(${group.background_image || '/default-bg.jpg'})`
                : `linear-gradient(rgba(255,255,255,0.8), rgba(255,255,255,0.9)), url(${group.background_image || '/default-bg.jpg'})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backdropFilter: 'blur(8px)'
        }">
        <div class="dark:bg-zinc-800 backdrop-blur-md  py-4">
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
                <div class="flex items-center justify-between gap-6">
                    <div
                        class="flex flex-col sm:flex-row items-center sm:items-start gap-4 bg-gradient-to-r from-zinc-700 to-zinc-800 p-4 rounded-xl shadow-lg border border-zinc-600">
                        <img :src="group.owner?.avater"
                            class="w-20 h-20 sm:w-14 sm:h-14 rounded-full border-2 border-blue-500 object-cover"
                            alt="オーナーのアバター" />
                        <div class="text-center sm:text-left">
                            <p class="hidden sm:block text-white text-base sm:text-lg font-bold break-all">
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
                        <button v-else @click="QRdialog"
                            class="px-4 py-2 rounded-full border border-blue-500 text-blue-600 hover:bg-blue-500 hover:text-white transition">
                            招待QRコードを表示
                        </button>
                    </div>
                </div>
                <div
                    class="flex flex-col sm:flex-row w-full divide-y sm:divide-y-0 sm:divide-x divide-gray-600 rounded-xl overflow-hidden border border-zinc-600 bg-zinc-800 shadow">
                    <div class="flex-1 min-w-0 p-6 text-center">
                        <p class="text-sm text-blue-400">スコア</p>
                        <p class="text-3xl font-extrabold text-blue-500 mt-2 tracking-wide">
                            {{ group.score }}
                        </p>
                    </div>
                    <button @click="ShowMember"
                        class="flex-1 min-w-0 p-6 text-center hover:bg-zinc-700 transition text-white">
                        <p class="text-sm text-purple-400">メンバー数</p>
                        <p class="text-2xl font-extrabold text-purple-500 mt-2 tracking-wide">
                            {{ group.members?.length || 0 }} 人
                        </p>
                    </button>
                    <button @click="CreateGoal"
                        class="flex-1 min-w-0 p-6 text-center hover:bg-zinc-700 transition text-white">
                        <p class="text-lg text-red-400 font-semibold">＋ゴールの追加</p>
                        <p class="text-sm text-white-400 mt-1">このスタジオでの目標を作成</p>
                    </button>
                </div>


                <div class="text-xs text-zinc-500 flex justify-between pt-6">
                    <span>作成: {{ formatDate(group.created_at) }}</span>
                    <span>更新: {{ formatDate(group.updated_at) }}</span>
                </div>

                <!-- ゴールリスト -->
                <div class="space-y-4">
                    <div v-for="goal in goals" :key="goal.id"
                        class="p-4 rounded-xl border border-zinc-700 shadow hover:shadow-xl transition-all duration-200 flex flex-col gap-2 bg-zinc-800 text-white">
                        <!-- 上段：アバターとタイトル -->
                        <div @click="PushToNextpage(goal.id)">
                            <div class="flex items-center gap-4">
                                <img :src="goal.assignee?.avater"
                                    class="w-12 h-12 rounded-full border-2 border-blue-400 object-cover shadow"
                                    alt="Assignee" />
                                <h3 class="text-lg sm:text-xl font-semibold tracking-wide break-all">
                                    {{ goal.header || '見出し無し' }}
                                </h3>
                            </div>

                            <!-- 締切情報 -->
                            <div class="text-sm text-zinc-400 mt-1">
                                {{ goal.deadline ? '📅 締め切り: ' + formatDate(goal.deadline) : '📅 締め切りなし' }}
                            </div>
                        </div>
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
                    <button @click="submitGoal()"
                        class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition">
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
        <Dialog :visible="isShowMember" @close="isShowMember = false">
            <!-- ヘッダー -->
            <template #header>
                <div class="flex items-center justify-between px-2 py-1 border-b border-zinc-700">
                    <h2 class="text-xl font-bold text-white tracking-wide">メンバー</h2>
                    <button @click="closeShowMember" class="text-gray-400 hover:text-red-500 transition-colors"
                        aria-label="ダイアログを閉じる">
                        <svg xmlns="http://www.w3.org/2000/svg" width="25" height="25" fill="currentColor"
                            class="bi bi-backspace" viewBox="0 0 16 16">
                            <path
                                d="M5.83 5.146a.5.5 0 0 0 0 .708L7.975 8l-2.147 2.146a.5.5 0 0 0 .707.708l2.147-2.147 2.146 2.147a.5.5 0 0 0 .707-.708L9.39 8l2.146-2.146a.5.5 0 0 0-.707-.708L8.683 7.293 6.536 5.146a.5.5 0 0 0-.707 0z" />
                            <path
                                d="M13.683 1a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-7.08a2 2 0 0 1-1.519-.698L.241 8.65a1 1 0 0 1 0-1.302L5.084 1.7A2 2 0 0 1 6.603 1zm-7.08 1a1 1 0 0 0-.76.35L1 8l4.844 5.65a1 1 0 0 0 .759.35h7.08a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1z" />
                        </svg>
                    </button>
                </div>
            </template>

            <!-- メンバーカード一覧 -->
            <template #default>
                <!-- メンバーカード -->
                <div v-for="member in group.members" :key="member.id"
                    class="flex items-center justify-between p-4 rounded-lg bg-black-800 border border-zinc-700 shadow hover:bg-zinc-700 transition space-x-4.">

                    <!-- 左側：アバターと情報 -->
                    <div class="flex items-center space-x-4">
                        <!-- アバター -->
                        <img :src="member.avater"
                            class="w-12 h-12 rounded-full border-2 border-white object-cover shadow" alt="Member" />

                        <!-- 情報 -->
                        <div>
                            <p class="text-white text-sm font-medium break-all">
                                {{ member.username || member.email || '不明なユーザー' }}
                            </p>
                            <p class="inline-block mt-2 text-xs text-white-200 bg-green-700 px-2 py-0.5 rounded-full">
                                メンバー</p>
                        </div>
                    </div>

                    <!-- 右側：削除ボタン -->
                    <button @click="isDeleteAlart(member.id)" class="text-red-500 hover:text-red-400 transition"
                        title="このメンバーを削除">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor"
                            class="bi bi-trash" viewBox="0 0 16 16">
                            <path
                                d="M5.5 5.5A.5.5 0 0 1 6 5h4a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0V6H6v6.5a.5.5 0 0 1-1 0v-7z" />
                            <path fill-rule="evenodd"
                                d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1 0-2H5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1h2.5a1 1 0 0 1 1 1z" />
                        </svg>
                    </button>
                </div>

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
const isShowMember = ref(false);
const isJoined = ref(false);
const routeId = route.params.id;
const toggleSidebar = () => {
    isSidebarOpen.value = !isSidebarOpen.value
};
const currentUser = computed(() => authStore.currentUser);
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
const PushToNextpage = async(id) => {
    try{
        router.push(`/studio/${routeId}/g/${id}`);
    }catch(err){
        console.error("アクセス失敗：", err);
    }
};
const QRdialog = () => {
    openQRdailog.value = true;
}
const closeQRdialog = () => {
    openQRdailog.value = false;
}
const closeShowMember = () => {
    isShowMember.value = false;
}
const ShowMember = () => {
    isShowMember.value = true;
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
const submitGoal = async () => {
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
        const newGoal = await authGoal.CreateGoal(group, goal_header, goal_description, goal_deadline);
        goals.value = await authGoal.fetchGoals();
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
const MemberCounter = computed(() => {
    return group.value.members ? group.value.members.length : 0;
});
const isDeleteAlart = (memberId) => {
    if (currentUser.email === group.owner.email) {
        if (confirm(`本当にメンバー「${memberId}」を削除しますか？`)) {
            removeMember(memberId);
            RemoveQR();
            console.log('メンバーの削除が完了 | 招待トークンも削除されました。');
        } else {
            console.log('メンバーの削除がキャンセルされました。');
        }
    } else {
        alert('あなたはこのスタジオのオーナーではありません。メンバーを削除する権限がありません。');
    }
};
const removeMember = async (memberId) => {
    const groupId = route.params.id;
    console.log("メンバーID：", memberId);
    try {
        const response = await authGroup.DeleteMember(groupId, memberId);
        if (response) {
            console.log('メンバーの削除完了:', response);
            // メンバー削除後の更新処理
            group.value = await authGroup.fetchGroupId(groupId);
            goals.value = await authGoal.fetchGoalsByGroup(groupId);
            return route.push(`/studio/${groupId}`);
        } else {
            console.error('メンバーの削除に失敗しました。');
            throw new Error('メンバーの削除・失敗:');
        }
    } catch (error) {
        console.error('メンバーの削除中にエラー発生:', error);
        throw error;
    }
};
</script>
