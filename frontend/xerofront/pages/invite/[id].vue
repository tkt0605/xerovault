<template>
    <div></div>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthLibrary } from '~/store/library';
import { useAuthFreinds } from '~/store/freind';

const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const friendStore = useAuthFreinds();
const route = useRoute();
const router = useRouter();
const inviting = ref([]);


onMounted(async () => {
    try {
        await authStore.restoreSession();
        console.log('セッション複号完了');
        const routeId = route.params.id;
        inviting.value = await friendStore.fetchFreindId(routeId);
    } catch (error) {
        console.error('情報取得の失敗：', error);
        throw error;
    }
});
</script>

