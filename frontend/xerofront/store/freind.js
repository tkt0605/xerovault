import { useAuthStore } from "./auth";
import { useRoute } from "vue-router";
import { useRouter } from "vue-router";
import { useRuntimeConfig } from "#app";
export const useAuthFreinds = defineStore('freind', {
    state: () => ({
        freinds: [],
        isInvite: false,
    }),
    actions: {
        async fetchFreind() {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}invite/`, {
                    method: 'GET',
                    headers: {
                        "Content-Type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || "友達情報の取得失敗");

                }
                const data = await response.json();
                this.freinds = data;
            }catch(error){
                console.error('友達情報・取得失敗：', error);
                throw error;
            }
        },
        async fetchFreindId(id) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}invite/${id}/`, {
                    method: 'GET',
                    headers: {
                        "Content-Type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || "友達情報の取得失敗");

                }
                const data = await response.json();
                this.freinds = data;
            }catch(error){
                console.error('友達情報・取得失敗：', error);
                throw error;
            }
        },
        async sendFriendRequest(email){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}invite/`, {
                    method: "POST",
                    headers: {
                        "Content-type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        email: email.trim()
                    })
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバーからのエラー：', errorData);
                    throw new Error(errorData.detail || "友達リクエスト送信");
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('送信エラー：', error);
                throw error;
            }
        },
        async approveFriendInvite(inviteId){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}invite/${inviteId}/approver/`, {
                    method: "POST",
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('サーバからのエラー：', errorData);
                    throw new Error(errorData.detail || "友達承認失敗");
                }
                const data = await response.json();
                this.isInvite = data.is_approved;
                return data;
            } catch (error) {
                console.error('承認エラー：', error);
                throw error;
            }
        }
    }
})
