<template>
    <div>

    </div>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useGoalStore } from '~/store/goal';
import { ref, onMounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
const authStore = useAuthStore();
const groupStore = useAuthGroups();
const goalStore = useGoalStore();
const router = useRouter();
const route = useRoute();
const goal = ref([]);
onMounted(async () => {
    const goalId = route.params.id;
    try{
        await authStore.restoreSession();
        console.log('セッション複合成功');
        if(!authStore.isAuthenticated){
            console.log('認証されていません。');
            return router.push('/auth/login');
        }
        goal.value = await goalStore.fetchGoalsId(goalId);
        console.log('目標データ：', goal.value);
    }catch(err){
        console.error('目標データの取得に失敗しました。', err);
    }
});

</script>