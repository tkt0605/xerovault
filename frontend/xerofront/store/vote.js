import { useAuthStore } from "./auth";
import { useAuthGroups } from "./group";
import { useRuntimeConfig } from "#app";


export const useAuthVote = defineStore('vote', {
    state: () => ({
        votes: [],
    }),
    actions: {
        async CreateVote(groupId, goalId, voteType, is_yes) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}votes/`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        group: groupId,
                        goal: goalId,
                        explain: voteType,
                        is_yes: is_yes
                    })
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error("🔥 サーバーからのエラーレスポンス:", errorData); // 🔥 ここが重要
                    throw new Error("投票作成失敗");
                }
                const data = await response.json();
                return data;
            } catch (error) {
                console.error('投票作成失敗', error);
                throw error;
            }
        },
        async FetchVotes() {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}votes/`, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || "投票取得失敗");
                }
                const data = await response.json();
                return data;
            } catch (error) {
                console.error('投票取得失敗', error);
                throw error;
            }
        },
        async FetchVoteId(id) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            if (!voteId) {
                console.error("voteId が無効です");
                return;
            }
            try {
                const response = await fetch(`${config.public.apiBase}votes/${id}/`, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errData = await response.json();
                    console.error('失敗', errData);
                    throw new Error('投票情報の取得失敗');
                }
                const data = await response.json();
                return data;
            } catch (error) {
                console.error('投票情報取得失敗', error);
                throw error;
            }
        },
        async FetchVotesByGroup(groupId) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}votes/?group=${groupId}`, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errData = await response.json();
                    console.error('失敗', errData);
                    throw new Error('グループの投票情報の取得失敗');
                }
                const data = await response.json();
                return data;
            } catch (error) {
                console.error('グループの投票情報取得失敗', error);
                throw error;
            }
        },
        async PostVoteToGoal(goalId, is_yes){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}goals/${goalId}/vote/`, {
                    method: 'POST',
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        is_yes: is_yes
                    })
                });
                if (!response.ok){
                    const errData = await response.json();
                    console.error('サーバーからのエラー：', errData);
                    throw new Error("目標への投票失敗");
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('目標への投票失敗：', error);
                throw error;
            }
        },
        async DeleteVote(voteId){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}votes/${voteId}/`, {
                    method: 'DELETE',
                    headers: {
                        // "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errData = await response.json();
                    console.error('サーバーからのエラー：', errData);
                    throw new Error("投票削除失敗");
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('投票削除失敗：', error);
                throw error;
            }
        }
    }
})