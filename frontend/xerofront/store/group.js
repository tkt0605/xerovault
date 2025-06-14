import { useAuthStore } from "./auth";
import { useRoute } from "vue-router";
import { useRouter } from "vue-router";
import { useRuntimeConfig } from "#app";


export const useAuthGroups = defineStore('group', {
    state: () => ({
        groups: [],
        groupDetails: null,
        loading: false,
        error: null,
        members: [],
        text: '',
    }),
    getters: {
        PublicGroups: (state) => state.groups.filter(g => g.is_public),
        PrivateGroups: (state) => state.groups.filter(g => !g.is_public)
    },
    actions: {
        async CreateGroup(name, is_public, members, text) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}groups/`, {
                    method: "POST",
                    headers: {
                        "Content-Type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        name: name.trim(),
                        is_public: is_public,
                        members: members,
                        description: text.trim()
                    })
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || 'グループ作成失敗');
                }
                const data = await response.json();
                return {
                    id: data.id,
                    name: data.name,
                    owner: data.owner,
                    members: data.members,
                    related_name: data.related_name,
                    description: data.description,
                    joined_token: data.joined_token,
                    is_public: data.is_public,
                    requires_secret_key: data.requires_secret_key,
                    crated_at: data.crated_at,
                    token_expiry: data.token_expiry,
                }
            } catch (error) {
                console.error('グループ作成の失敗:', error);
                throw error;
            }
        },
        async fetchGroup() {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}groups/`, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.detail || "グループ情報取得失敗");
                }
                const data = await response.json();
                if (!Array.isArray(data)) {
                    return {
                        id: data.id,
                        name: data.name,
                        owner: data.owner,
                        members: data.members,
                        related_name: data.related_name,
                        description: data.description,
                        joined_token: data.joined_token,
                        is_public: data.is_public,
                        requires_secret_key: data.requires_secret_key,
                        crated_at: data.crated_at,
                        token_expiry: data.token_expiry,
                    }
                }
                return data.map((item) => ({
                    id: item.id,
                    name: item.name,
                    owner: item.owner,
                    members: item.members,
                    related_name: item.related_name,
                    description: item.description,
                    joined_token: item.joined_token,
                    is_public: item.is_public,
                    requires_secret_key: item.requires_secret_key,
                    crated_at: item.crated_at,
                    token_expiry: item.token_expiry,
                }));
            } catch (error) {
                console.error("グループ情報取得の失敗：", error);
                throw error;
            }
        },
        async fetchGroupId(id) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}groups/${id}/`, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.detail || "個別グループ情報取得・エラー");
                }
                const data = await response.json();
                if (!Array.isArray(data)) {
                    return {
                        id: data.id,
                        name: data.name,
                        owner: data.owner,
                        members: data.members,
                        related_name: data.related_name,
                        description: data.description,
                        joined_token: data.joined_token,
                        is_public: data.is_public,
                        requires_secret_key: data.requires_secret_key,
                        crated_at: data.crated_at,
                        token_expiry: data.token_expiry,
                    }
                }
                return data.map((item) => ({
                    id: item.id,
                    name: item.name,
                    owner: item.owner,
                    members: item.members,
                    related_name: item.related_name,
                    description: item.description,
                    joined_token: item.joined_token,
                    is_public: item.is_public,
                    requires_secret_key: item.requires_secret_key,
                    crated_at: item.crated_at,
                    token_expiry: item.token_expiry,
                }));
            } catch (error) {
                console.error('個別グループ情報取得・エラー：', error);
                throw error;
            }
        }
    }
})
