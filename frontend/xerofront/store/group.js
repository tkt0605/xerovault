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
        async CreateGroup(name, is_public, tag) {
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
                        tag: tag.trim()
                    })
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error('サーバーからのエラー情報詳細：', errorData);
                    throw Error(errorData.detail || 'グループ作成失敗');
                }
                const data = await response.json();
                return {
                    id: data.id,
                    name: data.name,
                    owner: data.owner,
                    members: data.members,
                    goals: data.goals,
                    tag: data.tag,
                    joined_token: data.joined_token,
                    is_public: data.is_public,
                    created_at: data.created_at,
                    updated_at: data.updated_at,
                    score: data.score,
                };
            } catch (error) {
                console.error('グループ作成の失敗:', error);
                throw error;
            }
        },
        async fetchGroup() {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}groups/my_groups/`, {
                    method: "GET",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
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
                        goals: data.goals,
                        tag: data.tag,
                        joined_token: data.joined_token,
                        is_public: data.is_public,
                        created_at: data.created_at,
                        updated_at: data.updated_at,
                        score: data.score,
                    }
                }
                return data.map((item) => ({
                    id: item.id,
                    name: item.name,
                    owner: item.owner,
                    members: item.members,
                    goals: item.goals,
                    tag: item.tag,
                    joined_token: item.joined_token,
                    is_public: item.is_public,
                    created_at: item.created_at,
                    updated_at: item.updated_at,
                    score: item.score
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
                    },
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
                        goals: data.goals,
                        tag: data.tag,
                        joined_token: data.joined_token,
                        is_public: data.is_public,
                        created_at: data.created_at,
                        updated_at: data.updated_at,
                        score: data.score,
                    }
                }
                return data.map((item) => ({
                    id: item.id,
                    name: item.name,
                    owner: item.owner,
                    members: item.members,
                    goals: item.goals,
                    tag: item.tag,
                    joined_token: item.joined_token,
                    is_public: item.is_public,
                    created_at: item.created_at,
                    updated_at: item.updated_at,
                    score: item.score
                }));
            } catch (error) {
                console.error('個別グループ情報取得・エラー：', error);
                throw error;
            }
        },
        async AdditionalMembers(id, email) {
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try {
                const response = await fetch(`${config.public.apiBase}groups/${id}/add_members/`, {
                    method: 'POST',
                    headers: {
                        "Content-Type": 'application/json',
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        email,
                    })
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('エラー：', errorData);
                    throw new Error(errorData.detail || "メンバー追加エラー");
                }
                const data = await response.json();
                console.log('追加完了：', data);
                return data;
            } catch (error) {
                console.error('追加失敗：', error);
                throw error;
            }
        },
        async JoinAnonymous(id, token){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}groups/${id}/join/?data=${token}`, {
                    method: 'POST',
                    headers: {
                        "Content-Type": 'application/json',
                        'Authorization': `Bearer ${authStore.accessToken}`
                    },
                });
                if (!response.ok){
                    const errorData = await response.json();
                    console.error('スタジオの紹介失敗：', errorData);
                    throw new Error(errorData.detail || "参加失敗");
                }
                const data = await response.json();
                console.log('参加完了：', data);
                return data;
            }catch(error){
                console.error('参加失敗：', error);
                throw error;
            }
        },
        async DeleteMember(id, memberId) {
            const config = useRuntimeConfig();
            const authStore =useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}groups/${id}/remove-member/${memberId}/`, {
                    method: 'DELETE',
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    // body: JSON.stringify({
                    //     email: EmailUrlEncode,
                    // })
                });
                if (!response.ok){
                    const errorText = await response.text();
                    console.error('メンバー削除エラー:', errorText);
                    throw new Error("メンバー削除失敗");                    
                }
                console.log('メンバー削除完了');
                const data = await response.json();
                return data;
            }catch(error){
                console.error('メンバー削除失敗:', error);
                throw error;
            }
        }
    }
})
