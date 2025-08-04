import { useAuthStore } from "./auth";
import { useAuthGroups } from "./group";
import { useRuntimeConfig } from "#app";


export const useAuthVote = defineStore('vote', {
    state: () => ({
        votes: [],
    }),
    actions: {
        async CreateVote(goalId, voteType) {
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
                        goal_id: goalId,
                        vote_type: voteType
                    })
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || '投票作成失敗');
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
        }
    }
})