import { defineStore } from "#imports";
import { useFetch, useRuntimeConfig } from "#imports";
import { useRouter, useRoute } from "vue-router";
import { useAuthStore } from "./auth";
export const useSearchStore = defineStore('search', {
    state: () => ({
        keyward: '',
        results: [],
        loading: false,
        error: null,
        timer: null,
        useName: null,
    }),
    actions: {
        async GlobalSearchEngine(q){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const query = encodeURIComponent(q);
                const url = `${config.public.apiBase}search/?q=${query}`;
                this.loading = true;
                this.error = null;
                const response = await fetch(url, {
                    method: 'GET',
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    credentials: 'include'
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.log('サーバーからのエラー：', errorData);
                    throw new Error(errorData?.detail || "検索エンジンの失敗");
                }
                const data = await response.json();
                this.results = data;
            } catch (error) {
                this.error = error;
                this.results = [];
            }finally{
                this.loading = false;
            }
        },
        debounceSearch(delay = 300){
            if (this.timer)clearTimeout(this.timer)
            this.timer = setTimeout(()=> this.GlobalSearchEngine(), delay)
        },
        clear(){
            this.keybord = "";
            this.error = null;
            this.results = [];
        }
    }
})