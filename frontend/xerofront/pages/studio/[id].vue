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
                <div
                    class="max-w-3xl w-full mx-auto bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-xl p-6 space-y-6 shadow-sm">

                    <!-- タイトルとタグ -->
                    <div class="flex justify-between items-start">
                        <!-- Name 吹き出し -->
                        <div class="relative">
                            <div
                                class="text-lg font-bold bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 px-4 py-2 rounded-full">
                                {{ group.name }}
                            </div>
                        </div>
                        <!-- タグ -->
                        <!-- <span class="text-sm text-gray-500 dark:text-gray-400 mt-1">#{{ group.tag || 'タグ未設定' }}</span> -->
                        <span
                            class="mt-1 inline-block text-xs font-medium px-2 py-1 bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-100 rounded">
                            #{{ group.tag || 'タグ未設定' }}</span>
                    </div>
                    <div>
                        <h3 class="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">オーナー</h3>
                        <span
                            class="text-xs bg-zinc-200 dark:bg-zinc-700 text-zinc-800 dark:text-zinc-100 px-3 py-1 rounded-full">
                            {{ group.owner?.email }}
                        </span>
                        <!-- <div class="bg-zinc-50 dark:bg-zinc-800 rounded p-4 flex flex-wrap gap-2">
                        </div> -->
                    </div>
                    <!-- スコア・ゴール -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="bg-zinc-50 dark:bg-zinc-800 p-4 rounded shadow text-center">
                            <p class="text-xs text-gray-500 dark:text-gray-400">スコア</p>
                            <p class="text-xl font-semibold text-blue-600 dark:text-blue-400 mt-1">{{ group.score }}
                            </p>
                        </div>
                        <button @click="CreateGoal"
                            class="bg-zinc-50 dark:bg-zinc-800 p-4 rounded shadow text-center hover:bg-gray-600 round-full transtion">
                            ゴールの追加
                            <p class="text-xs text-gray-500 dark:text-gray-400">このスタジオでの目標を作成。</p>
                        </button>
                    </div>

                    <!-- メンバー一覧 -->
                    <div>
                        <h3 class="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">参加者 一覧</h3>
                        <div class="bg-zinc-50 dark:bg-zinc-800 rounded p-4 flex flex-wrap gap-2 justify-between">
                            <span v-for="member in group.members" :key="member"
                                class="text-xs bg-zinc-200 dark:bg-zinc-700 text-zinc-800 dark:text-zinc-100 px-3 py-1 rounded-full">
                                {{ member.email }}
                            </span>
                            <div class="">
                                <button @click="addMember"
                                    class="flex items-center gap-1 px-3 py-1 text-xs text-blue-600 hover:text-white border border-blue-600 hover:bg-blue-600 rounded-full transition ">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2"
                                        viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                                    </svg>
                                    メンバーを追加する。
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- トークン -->
                    <div class="text-sm text-gray-600 dark:text-gray-300 break-all flex justify-between rounded p-2">
                        <span class="font-semibold text-gray-500 dark:text-gray-400"></span>
                        <div v-if="!isJoinToStudioUrl === true">
                            <button @click="JoinCreateForm()"
                                class="flex items-center gap-1 px-3 py-1 text-xs text-green-600 hover:text-white border border-green-600 hover:bg-green-600 rounded-full transition">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2"
                                    viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                                </svg>
                                招待リンクを作成する
                            </button>
                        </div>
                        <div v-else>
                            <button @click="QRdialog"
                                class="text-xs text-blue-600 hover:text-white border border-blue-600 hover:bg-blue-600 px-3 py-1 rounded-full transition ">
                                招待QRコードを表示
                            </button>
                        </div>
                    </div>

                    <!-- 作成・更新日時 -->
                    <div
                        class="flex justify-between text-xs text-gray-500 dark:text-gray-400 border-t pt-4 border-gray-200 dark:border-zinc-600">
                        <span>作成: {{ formatDate(group.created_at) }}</span>
                        <span>更新: {{ formatDate(group.updated_at) }}</span>
                    </div>
                </div>
                <Dialog :visible="openQRdailog" @close="openQRdailog = false">
                    <!-- ヘッダー -->
                    <template #header>
                        <h2 class="text-lg font-semibold text-zinc-800 dark:text-white">
                            {{ group.name }} のQRコード
                        </h2>
                    </template>

                    <!-- コンテンツ -->
                    <template #default>
                        <div class="space-y-6">
                            <!-- QRコード -->
                            <div class="flex justify-center">
                                <div class="bg-white dark:bg-zinc-700 p-4 rounded-lg shadow aspect-square">
                                    <QrcodeCanvas :value="invterURL" :size="180" level="M" />
                                </div>
                            </div>

                            <!-- トークンとコピー -->
                            <div class="bg-zinc-50 dark:bg-zinc-800 rounded-lg p-4 space-y-3">
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    このコードをコピーして共有してください。
                                </p>

                                <div class="flex items-center justify-between gap-2 bg-zinc-50 dark:bg-zinc-600 p-4 rounded shadow text-center  round-full transtion">
                                    <div class="text-sm text-black-700 dark:text-black-200 break-all font-mono">
                                        {{ group.joined_token }}
                                    </div>
                                    <button @click="copyToClipboard"
                                        class="p-2 rounded bg-zinc-600 hover:bg-zinc-700 text-white transition"
                                        title="コピー">
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
                </Dialog>


            </main>
        </div>
    </div>
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
import Dialog from '~/components/MainDialog.vue';
const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const authGroup = useAuthGroups();
const group = ref([]);
const isJoinToStudioUrl = ref(false);
const invterURL = ref('');
const openQRdailog = ref(false);
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
    const routeId = route.params.id;
    const token = uuidv4();
    const baseUrl = window.location.origin;
    invterURL.value = `${baseUrl}/studio/${routeId}/join?token=${token}`;
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
