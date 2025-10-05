import { useAuthStore } from "./auth";
import { useRoute } from "vue-router";
import { useRouter } from "vue-router";
import { useRuntimeConfig } from "#app";


export const useAuthMessage = defineStore('message', {
    state: () => ({

    }),
    actions: {
        async CreateMessage(group, goal, text) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}message/`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include',
                    body: JSON.stringify({
                        group: group,
                        goal: goal,
                        text: text.trim(),
                        // file:file
                    })
                });
                if (!response.ok){
                    const errorData = await response.json();
                    throw new Error(errorData.detail || 'メッセージの作成失敗');
                }
                const data = await response.json();
                return {
                    id: data.id,
                    group: data.group,
                    goal: data.goal,
                    // auther: data.auther,
                    text: data.text,
                    // file: data.file,
                    parent: data.parent,
                    created_at: data.created_at 
                };
            }catch(error){
                console.error('メッセージ作成失敗:', error);
                throw new Error;
            }
        },
        async fetchMessage(){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}message/`, {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.json();
                    throw new Error(errorData.detail || "メッセージの取得失敗");
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.log('メッセージ取得失敗:', error);
                throw new Error;
            }
        },
        async fetchMessageByGoalId(id){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}message/?goal=${id}`, {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.json();
                    throw new Error(errorData.detail || 'Goalによる特定のメッセージの取得失敗');
                }
                const data = await response.json();
                return data;
            }catch(error){
                console.error('特定メッセージたちの取得失敗:', error);
                throw new Error;
            }
        }
    }
})