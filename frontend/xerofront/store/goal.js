import { defineStore } from 'pinia';
import { useAuthStore } from './auth';
import Join from '~/pages/studio/[routeId]/join.vue';

export const useGoalStore = defineStore('goal',  {
    state: () => ({
        goals: [],
        // goalHead: '',
        // goalDescription: '',
        // goalDeadline: '',
    }),
    actions: {
        async CreateGoal(group, header, description, deadline) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/`, {
                    method: 'POST',
                    headers: {
                        "Content-type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include',
                    body: JSON.stringify({
                        group: group,
                        header: header,
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
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '目標情報の取得失敗');
                }
                const data = await response.json();
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
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '個別の目標情報の取得失敗');
                }
                const data = await response.json();
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
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.text();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error('個別の目標情報の取得失敗');
                }
                const data = await response.json();
                // this.goals = data;
                return data;
            }catch(error){
                console.error('個別の目標情報・取得失敗：', error);
                throw error;
            }
        },
        async MyGoals(){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/my_goals/`, {
                    method: 'GET',
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorText = await response.text();
                    console.error('サーバーからのエラー：', errorText);
                    throw new Error('自身の目標情報の取得失敗');
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('自身の目標情報・取得失敗：', error);
                throw error;
            }
        },
        async GoalVoteRate(){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/vote_rate/`, {
                    method: 'GET',
                    header: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '目標の投票率情報の取得失敗');
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('目標の投票率情報・取得失敗：', error);
                throw error;
            }
        },
        async GoalVote(id, is_yes){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/${id}/vote/`, {
                    method: 'POST',
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include',
                    body: JSON.stringify({
                        is_yes: is_yes
                    })
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || '目標の投票失敗');
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('目標の投票失敗：', error);
                throw error;
            }
        },
    }
})
