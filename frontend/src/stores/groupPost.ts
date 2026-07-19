import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { GroupPost } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'

export const useGroupPostStore = defineStore('groupPost', () => {
  const posts = ref<GroupPost[]>([])

  async function fetchPosts(groupId: string): Promise<GroupPost[]> {
    posts.value = await rpc<GroupPost[]>('get_group_posts', { p_group_id: groupId })
    return posts.value
  }

  async function createPost(
    groupId: string,
    text: string,
    parentPostId?: string
  ): Promise<GroupPost> {
    const post = await rpc<GroupPost>('create_group_post', {
      p_group_id: groupId,
      p_text: text,
      p_parent_post_id: parentPostId ?? null,
    })
    if (parentPostId) {
      const parent = posts.value.find((p) => p.id === parentPostId)
      if (parent) parent.replies = [...parent.replies, post]
    } else {
      posts.value.unshift(post)
    }
    return post
  }

  return { posts, fetchPosts, createPost }
})
