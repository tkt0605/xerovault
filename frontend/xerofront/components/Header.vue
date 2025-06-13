<template>
    <header>
        <div class="dashbord">
        </div>
        <div class="headline">
            <div class="logo-bord">
                <div class="dashmenu">
                    <button class="dash_button">
                        <yt-icon>
                            <span>
                                <div>
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor"
                                        class="bi bi-bar-chart-steps" viewBox="0 0 16 16">
                                        <path
                                            d="M.5 0a.5.5 0 0 1 .5.5v15a.5.5 0 0 1-1 0V.5A.5.5 0 0 1 .5 0M2 1.5a.5.5 0 0 1 .5-.5h4a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-4a.5.5 0 0 1-.5-.5zm2 4a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5zm2 4a.5.5 0 0 1 .5-.5h6a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-6a.5.5 0 0 1-.5-.5zm2 4a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5z" />
                                    </svg>
                                </div>
                            </span>
                        </yt-icon>
                    </button>
                </div>
                <div>
                    <button class="logo">
                        <div class="logo-font">
                            <b>XeroVault</b>
                        </div>
                    </button>
                </div>
            </div>
            <div class="account_menu" v-if="isAuthenticated">
                <div>
                    <img @click="openUserInfo(currentUser.email)" v-if="currentUser" :src="currentUser.avater"
                        class="icon_img" alt="User Avatar" />
                </div>
            </div>
            <div class="auth" v-else>
                <form action="">
                    <button class="signin" @click="signin()">サインイン</button>
                    <button class="signup" @click="signup()">サインアップ</button>
                </form>
            </div>
        </div>
        <!-- <div class="modal-overlay-user" v-show="isopenInfo" id="show-info">
            <div class="modal-contant-user" v-if="isAuthenticated">
                <div class="head">
                    <div class="info-head">
                        <b>ユーザー設定</b>
                        <button @click="closeUserInfo()" class="cancel">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x-circle" viewBox="0 0 16 16">
                                <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16" />
                                <path
                                    d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708" />
                            </svg>
                        </button>
                    </div>
                    <div class="info-icon">{{ currentUser.avater }}</div>
                    <div class="info-email">{{ currentUser.email }}</div>
                    <form action="">
                        <button @click="logout()" class="logout">ログアウト</button>
                    </form>
                </div>
            </div>
        </div> -->
        <!-- 背景オーバーレイ（透明） -->
        <div v-show="isopenInfo" id="show-info" class="fixed inset-0 z-50 bg-transparent">
            <!-- 右上に配置されるモーダル本体 -->
            <div v-if="isAuthenticated" class="fixed top-20 right-20 w-80 p-6 rounded-2xl shadow-2xl bg-white dark:bg-zinc-800">
                <!-- ヘッダー -->
                <div class="flex items-center justify-between border-b pb-3 mb-4">
                    <h2 class="text-lg font-bold text-gray-800 dark:text-white">ユーザー設定</h2>
                    <button @click="closeUserInfo" class="text-gray-400 hover:text-red-500 transition">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor"
                            class="bi bi-x-circle" viewBox="0 0 16 16">
                            <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16" />
                            <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1.708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L88.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 84.646 5.354a.5.5 0 0 1 0-.708" />
                        </svg>
                    </button>
                </div>

                <!-- ユーザー情報 -->
                <div class="flex items-center gap-2 mb-4">
                    <img class="w-10 h-10 rounded-full bg-gray-200 dark:bg-zinc-600 flex items-center justify-center text-xl font-semibold text-gray-600 dark:text-white" :src="currentUser.avater" />
                    <p class="text-16px text-gray-500 dark:text-gray-300">
                        {{ currentUser.email }}
                    </p>
                </div>

                <!-- ログアウトボタン -->
                <!-- <button @click="logout"class="w-full bg-black-500 hover:bg-gray-600 text-left text-white py-2 ml-4 mx-4 rounded-lg font-semibold transition"> -->
                <button @click="logout" class="ml-4 px-4 py-2 w-full text-left text-red-600 hover:text-white hover:bg-gray-600
         rounded-lg font-semibold transition ">
                    ログアウト
                </button>
            </div>
        </div>

    </header>
</template>
<script setup>
import "~/assets/css/header.css";
import { useAuthStore } from "~/store/auth";
import { ref, onMounted } from "vue";
import { useRouter, useRoute } from "vue-router";
import Signup from "~/pages/auth/signup.vue";
const authStore = useAuthStore();
const isopenInfo = ref(false);
const setUserId = ref(null);
const user = ref(null);
const route = useRoute();
const router = useRouter();
const isDSialogUserOpen = ref(false);
const currentUser = computed(() => authStore.currentUser);
const isAuthenticated = computed(() => authStore.isAuthenticated);

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
</script>
