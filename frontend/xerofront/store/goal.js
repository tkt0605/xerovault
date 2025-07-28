import { defineStore } from 'pinia';
import { useAuthStore } from './auth';

export const useGoalStore = defineStore('goal',  {
    state: () => ({
        goals: [],
        // goalHead: '',
        // goalDescription: '',
        // goalDeadline: '',
    }),
    actions: {
        async CreateGoal(group, name, description, deadline) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/`, {
                    method: 'POST',
                    headers: {
                        "Content-type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        group: group,
                        name: name,
                        description: description.trim(),
                        deadline: deadline,
                    })
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '目標の作成失敗');
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('目標の作成失敗：', error);
                throw error;
            }
        },
        async fetchGoals(){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/`, {
                    method: 'GET',
                    headers: {
                        "Content-Type": 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '目標情報の取得失敗');
                }
                const data = await response.json();
                this.goals = data;
                return data;
            }catch(error){
                console.error('目標情報・取得失敗：', error);
                throw error;
            }
        },
        async fetchGoalsByGroup(id){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/?group=${id}`, {
                    method: 'GET',
                    headers: {
                        "Content-type": 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '個別の目標情報の取得失敗');
                }
                const data = await response.json();
                this.goals = data;
                return data;
            }catch(error){
                console.error('個別の目標情報・取得失敗：', error);
                throw error;
            }
        },
        async fetchGoalsId(id){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/${id}/`, {
                    method: 'GET',
                    headers: {
                        "Content-type": 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '個別の目標情報の取得失敗');
                }
                const data = await response.json();
                this.goals = data;
                return data;
            }catch(error){
                console.error('個別の目標情報・取得失敗：', error);
                throw error;
            }
        },
    }
})
