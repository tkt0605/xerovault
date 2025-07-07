<template>
    <!-- メインビュー -->
    <main class="flex-1 p-6 overflow-y-auto">
        <div class="p-4 text-center" v-if="!Isyourmember">
            <h2 class="text-xl font-bold">{{ group?.name }}に参加</h2>

            <div v-if="!joinSuccess">
                <p>このスタジオに参加するには、参加トークンが必要です。</p>
                <input v-model="token" type="text" class="border rounded text-black  px-3 py-1 mt-2" placeholder="参加トークンを入力" />
                <button @click="JoinToStudio" class="ml-2 bg-blue-600 text-white px-4 py-1 rounded hover:bg-blue-700"
                    :disabled="isJoining">
                    参加
                </button>

                <p v-if="isJoining" class="mt-4 text-gray-500">スタジオ参加中...</p>
                <p v-if="errorMsg" class="text-red-500 mt-2">{{ errorMsg }}</p>
            </div>

            <div v-else>
                <h1 class="text-xl font-bold text-green-600">スタジオに参加しました！</h1>
                <p class="mt-2">スタジオのトップページにリダイレクトされるか、<br />手動でアクセスしてください。</p>
            </div>
        </div>
        <div v-else>
            <div>あなたは既に、このスタジオのメンバーです。</div>
        </div>
    </main>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useAuthLibrary } from '~/store/library';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
const authStore = useAuthStore();
const groupStore = useAuthGroups();
const libraryStore = useAuthLibrary();
const route = useRoute();
const router = useRouter();
const token = ref(route.query.data);
const studioid = route.params.id;
const group = ref([]);
const isJoining = ref(false);
const joinSuccess = ref(false);
const errorMsg = ref('');
onMounted(async () => {
    if (!token) {
        console.log('トークンがありません。');
        return;
    }
    try {
        console.log('スタジオID：', studioid);
        group.value = await groupStore.fetchGroupId(studioid);
    } catch (error) {
        console.error('参加エラー：', error);
        throw error;
    }
});
const Isyourmember = computed(() => {
    if (!group.value || !Array.isArray(group.value.members) || !authStore.currentUser) return false;
    return group.value.members.some(member => member.email === authStore.currentUser.email);
});
const JoinToStudio = async () => {
    isJoining.value = true;
    const studioid = route.params.id;
    const tokenValue = token.value.trim();
    if (!tokenValue) {
        console.error('トークンが入力されていません。');
        errorMsg.value = 'トークンを入力してください。';
        return;
    }
    try {
        const response = await groupStore.JoinAnonymous(studioid, tokenValue);
        if (response.status === 200) {
            console.log('スタジオ参加成功：', response.data);
            joinSuccess.value = true;
            setTimeout(() => {
                router.push(`/studio/${studioid}`);
            }, 2000);
            isJoining.value = false;
        }
    } catch (error) {
        console.error('スタジオ参加失敗：', error);
        errorMsg.value = 'スタジオ参加に失敗しました。トークンが正しいか確認してください。';
        isJoining.value = false;
    }
};
</script>
