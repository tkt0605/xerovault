<template>
    <header class="bg-white dark:bg-black  px-1 py-4 s-50 ">
        <!-- ヘッダー本体 -->
        <div class="flex items-center justify-between">
            <!-- 左側：メニューアイコンとロゴ -->
            <div class="flex items-center gap-4">
                <button @click="clickAsideOpen" id="menu-toggle-button"
                    class="hover:bg-gray-100 dark:hover:bg-zinc-700 p-2 rounded-md transition">
                    <!-- ハンバーガーアイコン -->
                    <svg class="w-6 h-6 text-gray-700 dark:text-white" fill="none" stroke="currentColor"
                        stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"></path>
                    </svg>
                </button>
                <button @click="goHome" class="group">
                    <div class="text-2xl font-extrabold tracking-wide bg-clip-text text-transparent 
                        bg-gradient-to-r from-purple-400 to-indigo-500 dark:from-purple-300 dark:to-blue-400
                        group-hover:from-indigo-400 group-hover:to-blue-600 transition-all duration-300 py-2">
                        iStudio
                    </div>
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
                class="mt-20 mr-6 w-80 h-48 p-6 bg-white dark:bg-zinc-800 rounded-2xl shadow-2xl transition transform scale-100">
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
                <!-- ログアウト -->
                <button @click="logout" class="w-full text-left px-4 py-2 text-red-600 hover:text-white hover:bg-red-600
                 rounded-lg font-semibold transition">
                    ログアウト
                </button>
            </div>
        </div>

    </header>
</template>
<script setup>
import "~/assets/css/header.css";
import { useAuthStore } from "~/store/auth";
import { useAuthGroups } from "~/store/group";
import { useAuthLibrary } from "~/store/library";
import { ref, onMounted, inject } from "vue";
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
const isSidebarOpen = ref(false);
const props = defineProps({
    isAsideOpen: {
        type: Boolean,
        default: false
    },
    isSabAsideOpen: {
        type: Boolean,
        default: false
    }
});
const emit = defineEmits(['update:isAsideOpen', 'update:isSabAsideOpen']);
const clickAsideOpen = () => {
    document.getElementById('menu-toggle-button')?.blur();
    const target_sm = props.isAsideOpen;
    const target_pc = props.isSabAsideOpen;
    console.log("SM", target_sm);
    console.log("PC", target_pc);
    // const isMobile = window.matchMedia('(max-width: 768px)').matches;
    const isMobile = window.innerWidth;
    if(isMobile < 766 ) {
        emit('update:isSabAsideOpen', !props.isSabAsideOpen)
        return emit('update:isAsideOpen', !props.isAsideOpen);
    }else {
        return emit('update:isSabAsideOpen', !props.isSabAsideOpen);
    }
};

onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log("セッション復元成功");
        if (authStore.isAuthenticated) {
            try {
                user.value = await authStore.getUserInfo();
                console.log('ユーザー情報取得：', user.value);
            } catch (error) {
                console.error('ユーザー情報の取得失敗:', error);
                throw error;
            }
        }
        nextTick(() => {
            document.getElementById('menu-toggle-button').focus();
        });
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
    nextTick(() => {
        document.getElementById('menu-toggle-button')?.focus();
    });
};
const signin = () => {
    router.push('/auth/login');
};
const signup = () => {
    router.push('/auth/aignup');
};
const logout = async () => {
    console.log('refreshToken:', authStore.refreshToken);
    try {
        await authStore.logout();
        console.log('ログアウト成功');
        router.push('/auth/login');
    } catch (error) {
        console.error('ログアウト失敗:', error);
        alert('ログアウトに失敗しました。時間をおいて再度お願いします。');
    }
};
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
const toggleSidebar = () => {
    isAsideOpen.value = !isAsideOpen.value;
};
</script>
