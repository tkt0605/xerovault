<template>
    <header class="bg-white dark:bg-zinc-900 shadow-md px-6 py-4">
        <!-- ヘッダー本体 -->
        <div class="flex items-center justify-between">
            <!-- 左側：メニューアイコンとロゴ -->
            <div class="flex items-center gap-4">
                <button class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-zinc-700 transition">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor"
                        class="bi bi-bar-chart-steps text-gray-700 dark:text-gray-200" viewBox="0 0 16 16">
                        <path
                            d="M.5 0a.5.5 0 0 1 .5.5v15a.5.5 0 0 1-1 0V.5A.5.5 0 0 1 .5 0M2 1.5a.5.5 0 0 1 .5-.5h4a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-4a.5.5 0 0 1-.5-.5zm2 4a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5zm2 4a.5.5 0 0 1 .5-.5h6a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-6a.5.5 0 0 1-.5-.5zm2 4a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5z" />
                    </svg>
                </button>
                <button @click="goHome"
                    class="text-xl font-bold text-gray-800 dark:text-white hover:underline hover:text-blue-600 transition">
                    Studio DEMO
                </button>
            </div>

            <!-- 右側：認証状態で分岐 -->
            <div v-if="isAuthenticated">
                <img @click="openUserInfo(currentUser.email)" :src="currentUser.avater" alt="User Avatar"
                    class="w-10 h-10 rounded-full object-cover cursor-pointer border-2 border-gray-300 hover:border-blue-500 transition" />
            </div>
            <div v-else class="space-x-3">
                <button @click="signin"
                    class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded hover:bg-blue-700 transition">サインイン</button>
                <button @click="signup"
                    class="px-4 py-2 text-sm font-medium text-blue-600 border border-blue-600 rounded hover:bg-blue-50 transition">サインアップ</button>
            </div>
        </div>

        <!-- ユーザー設定モーダル -->
        <div v-show="isopenInfo" id="show-info" class="fixed inset-0 z-50 bg-black bg-opacity-30 flex justify-end"
            @click.self="closeUserInfo">
            <div v-if="isAuthenticated"
                class="mt-20 mr-6 w-80 h-60 p-6 bg-white dark:bg-zinc-800 rounded-2xl shadow-2xl transition transform scale-100">
                <!-- モーダルヘッダー -->
                <div class="flex items-center justify-between border-b border-gray-200 dark:border-zinc-700 pb-3 mb-4">
                    <h2 class="text-lg font-bold text-gray-800 dark:text-white">ユーザー設定</h2>
                    <button @click="closeUserInfo" class="text-gray-400 hover:text-red-500 transition">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor"
                            class="bi bi-x-circle" viewBox="0 0 16 16">
                            <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16" />
                            <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1
                   .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8
                   8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8
                   4.646 5.354a.5.5 0 0 1 0-.708" />
                        </svg>
                    </button>
                </div>

                <!-- ユーザー情報 -->
                <div class="flex items-center gap-3 mb-6">
                    <img class="w-10 h-10 rounded-full bg-gray-200 dark:bg-zinc-600 object-cover"
                        :src="currentUser.avater" alt="avatar" />
                    <p class="text-sm text-gray-700 dark:text-gray-200 break-all">
                        {{ currentUser.email }}
                    </p>
                </div>
                <div class="flex items-center gap3 mb-6">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-hammer" viewBox="0 0 16 16">
                        <path
                            d="M9.972 2.508a.5.5 0 0 0-.16-.556l-.178-.129a5 5 0 0 0-2.076-.783C6.215.862 4.504 1.229 2.84 3.133H1.786a.5.5 0 0 0-.354.147L.146 4.567a.5.5 0 0 0 0 .706l2.571 2.579a.5.5 0 0 0 .708 0l1.286-1.29a.5.5 0 0 0 .146-.353V5.57l8.387 8.873A.5.5 0 0 0 14 14.5l1.5-1.5a.5.5 0 0 0 .017-.689l-9.129-8.63c.747-.456 1.772-.839 3.112-.839a.5.5 0 0 0 .472-.334" />
                    </svg>
                    <p class="text-sm text-gray-700 dark:text-gray-200 break-all" @click="StepToken()">トークン一覧</p>
                </div>
                <!-- ログアウト -->
                <button @click="logout" class="w-full text-left px-4 py-2 text-red-600 hover:text-white hover:bg-red-600
                 rounded-lg font-semibold transition">
                    ログアウト
                </button>
            </div>
        </div>
        <Dialog :visible="isOpenToken" @close="isOpenToken = false">
            <template #header>
                <h2 class="text-xl font-bold text-white">トークン一覧</h2>
            </template>

            <template #default>
                <div v-if="tokens.length" class="space-y-4">
                    <div v-for="token in tokens" :key="token.id"
                        class="border border-gray-700 bg-gray-800 p-4 rounded-md">
                        <p class="text-sm text-gray-300">トークン名: <strong>{{ token.name || '(無題)' }}</strong></p>
                        <p class="text-sm text-gray-400 break-all">UUID: {{ token.token }}</p>

                        <!-- トークンURL -->
                        <div class="mt-2 flex items-center gap-2">
                            <input type="text" :value="generateTokenUrl(token.token)" readonly
                                class="flex-1 text-sm p-1 rounded bg-gray-700 text-white" />
                            <button @click="copyUrl(generateTokenUrl(token.token))"
                                class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 text-sm rounded">
                                コピー
                            </button>
                        </div>

                        <!-- QRコード -->
                        <div class="mt-2">
                            <qrcode-vue :value="generateTokenUrl(token.token)" :size="100" />
                        </div>
                    </div>
                </div>

                <div v-else class="text-gray-400 text-center mt-4">
                    トークンがまだ作成されていません。
                </div>
            </template>

            <template #footer>
                <button @click="isOpenToken = false" class="bg-blue-600 text-white px-4 py-2 rounded">
                    閉じる
                </button>
            </template>
        </Dialog>

    </header>
</template>
<script setup>
import "~/assets/css/header.css";
import { useAuthStore } from "~/store/auth";
import { useAuthGroups } from "~/store/group";
import { useAuthLibrary } from "~/store/library";
import { ref, onMounted } from "vue";
import { useRouter, useRoute } from "vue-router";
import Signup from "~/pages/auth/signup.vue";
import Dialog from "~/components/MainDialog.vue";
import QrcodeVue from 'qrcode.vue';

const authStore = useAuthStore();
const groupStore = useAuthGroups();
const libraryStore = useAuthLibrary();
const isopenInfo = ref(false);
const setUserId = ref(null);
const user = ref(null);
const route = useRoute();
const router = useRouter();
const isDSialogUserOpen = ref(false);
const currentUser = computed(() => authStore.currentUser);
const isAuthenticated = computed(() => authStore.isAuthenticated);
const isOpenToken = ref(false);
// const isOpenToken = ref(false)

onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log("セッション復元成功");
        if (authStore.isAuthenticated) {
            try {
                user.value = await authStore.getUserInfo();
                console.log('ユーザー情報取得：', user.value);
                // await groupStore.fetchGroup();
                // await libraryStore.FetchLibrary();
            } catch (error) {
                console.error('ユーザー情報の取得失敗:', error);
                throw error;
            }
        }
    } catch (error) {
        console.error('初期データのロードに失敗しました。', error);
    }
});

const openUserInfo = (userEmail) => {
    setUserId.value = userEmail;
    isopenInfo.value = true;
};
const closeUserInfo = () => {
    isopenInfo.value = false;
};
const signin = () => {
    router.push('/auth/login');
};
const signup = () => {
    router.push('/auth/aignup');
};
const logout = async () => {
    try {
        await authStore.logout();
        console.log('   ログアウト成功');
        router.push('/auth/login');
    } catch (error) {
        console.error('ログアウト失敗:', error);
        alert('ログアウトに失敗しました。時間をおいて再度お願いします。');
    }
}
const StepToken = () => {
    isOpenToken.value = true
    isopenInfo.value = false
};

const tokens = ref([
    {
        id: 1,
        name: 'グループ参加用',
        token: 'fc98a9d2-7cda-4a5b-835c-xxxxxxx',
    },
    {
        id: 2,
        name: '',
        token: '43eabfc1-fd6e-442d-b49a-yyyyyyy',
    }
])

const baseUrl = 'https://xerovault.com/join/'

function generateTokenUrl(token) {
    return `${baseUrl}${token}`
}

function copyUrl(url) {
    navigator.clipboard.writeText(url).then(() => {
        alert('コピーしました')
    })
}
const goHome = () => {
    router.push('/');
};
</script>
