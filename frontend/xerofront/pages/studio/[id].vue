<template>
    <main class="flex-1  overflow-y-auto">
        <div class="max-w-3xl w-full mx-auto bg-white dark:bg-zinc-900  p-6 space-y-6 shadow">

            <!-- タイトルとステータス -->
            <div class="flex justify-between items-start flex-wrap gap-4">
                <div>
                    <div
                        class="text-lg font-bold text-white bg-gradient-to-r from-blue-500 to-indigo-500 px-4 py-2 rounded-full shadow">
                        {{ group.name }}
                    </div>
                </div>
                <div class="flex gap-2">
                    <span
                        class="text-xs font-medium px-3 py-1 bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100 rounded-full">
                        #{{ group.tag || 'タグ未設定' }}
                    </span>
                    <span
                        :class="group.is_public ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300' : 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'"
                        class="text-xs font-semibold px-3 py-1 rounded-full inline-flex items-center gap-1">
                        <svg v-if="group.is_public" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2"
                            viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                        <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2"
                            viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                        {{ group.is_public ? '公開中' : '非公開' }}
                    </span>
                </div>
            </div>

            <!-- オーナー情報 -->
            <div>
                <h3 class="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">オーナー</h3>
                <span
                    class="text-xs bg-zinc-200 dark:bg-zinc-700 text-zinc-800 dark:text-zinc-100 px-3 py-1 rounded-full">
                    {{ group.owner?.email }}
                </span>
            </div>

            <!-- スコア & ゴール -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div
                    class="bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-600 p-4 rounded-xl shadow-sm text-center">
                    <p class="text-xs text-gray-500 dark:text-gray-400">スコア</p>
                    <p class="text-xl font-semibold text-blue-600 dark:text-blue-400 mt-1">{{ group.score }}</p>
                </div>
                <button @click="CreateGoal"
                    class="flex flex-col justify-center items-center border border-dashed border-gray-300 dark:border-zinc-500 p-4 rounded-xl text-gray-500 hover:border-blue-500 hover:text-blue-600 transition">
                    ゴールの追加
                    <span class="text-xs mt-1">このスタジオでの目標を作成</span>
                </button>
            </div>

            <!-- メンバー一覧 -->
            <div>
                <h3 class="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">参加者一覧</h3>
                <div class="bg-zinc-50 dark:bg-zinc-800 rounded p-4 flex flex-wrap items-center justify-between gap-2">
                    <div class="flex flex-wrap gap-2">
                        <span v-for="member in group.members" :key="member"
                            class="text-xs bg-zinc-200 dark:bg-zinc-700 text-zinc-800 dark:text-zinc-100 px-3 py-1 rounded-full">
                            {{ member.email }}
                        </span>
                    </div>
                    <button @click="addMember"
                        class="flex items-center gap-1 px-3 py-1 text-xs text-blue-600 hover:text-white border border-blue-600 hover:bg-blue-600 rounded-full transition">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                        メンバーを追加する
                    </button>
                </div>
            </div>

            <!-- トークン表示 -->
            <div class="text-sm text-gray-600 dark:text-gray-300 break-all flex justify-between rounded p-2">
                <div></div>
                <div v-if="!isJoinToStudioUrl">
                    <button @click="JoinCreateForm()"
                        class="flex items-center gap-1 px-3 py-1 text-xs text-green-600 hover:text-white border border-green-600 hover:bg-green-600 rounded-full transition">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                        招待リンクを作成する
                    </button>
                </div>
                <div v-else>
                    <button @click="QRdialog"
                        class="text-xs text-blue-600 hover:text-white border border-blue-600 hover:bg-blue-600 px-3 py-1 rounded-full transition">
                        招待QRコードを表示
                    </button>
                </div>
            </div>

            <!-- 作成/更新日時 -->
            <div
                class="flex justify-between text-xs text-gray-500 dark:text-gray-400 border-t pt-4 border-gray-200 dark:border-zinc-600">
                <span>作成: {{ formatDate(group.created_at) }}</span>
                <span>更新: {{ formatDate(group.updated_at) }}</span>
            </div>
        </div>

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
                <button @click="RemoveQR()" class="">QRを削除する。</button>
            </template>
        </Dialog>
    </main>
    <!-- </div> -->
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useRoute, useRouter } from 'vue-router';
import { ref, onMounted } from 'vue';
import { v4 as uuidv4 } from 'uuid';
import { errorMessages } from 'vue/compiler-sfc';
import { QrcodeCanvas } from 'qrcode.vue';
import { QrcodeSvg } from 'qrcode.vue';
import { useRuntimeConfig } from "#app";
import Dialog from '~/components/MainDialog.vue';
const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const authGroup = useAuthGroups();
const group = ref([]);
const isJoinToStudioUrl = ref(false);
const invterURL = ref('');
const openQRdailog = ref(false);
const isSidebarOpen = ref(false);
const toggleSidebar = () => {
    isSidebarOpen.value = !isSidebarOpen.value
};
onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複合完了');
        const routeId = route.params.id;
        group.value = await authGroup.fetchGroupId(routeId);
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
    invterURL.value = `${baseUrl}/studio/${routeId}/join?data=${encodeURIComponent(encryptedData)}`;
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
</script>
