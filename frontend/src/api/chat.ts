import { apiGet, apiPost, apiDelete } from './client'
import type { Conversation, ChatMessage } from '@/types'

export const chatApi = {
  async createConversation(locale?: string): Promise<Conversation> {
    return apiPost<Conversation>('/chat/conversations', { locale })
  },

  async listConversations(): Promise<Conversation[]> {
    const resp = await apiGet<{ data: Conversation[] }>('/chat/conversations')
    return resp.data
  },

  async getConversation(id: number): Promise<{ conversation: Conversation; messages: ChatMessage[] }> {
    return apiGet<{ conversation: Conversation; messages: ChatMessage[] }>(`/chat/conversations/${id}`)
  },

  async deleteConversation(id: number): Promise<void> {
    await apiDelete(`/chat/conversations/${id}`)
  },

  sendMessage(conversationId: number, content: string): { stream: Promise<ReadableStream<Uint8Array>>; abort: () => void } {
    const controller = new AbortController()

    const stream = fetch(`/api/chat/conversations/${conversationId}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content }),
      signal: controller.signal,
      credentials: 'same-origin',
    }).then(response => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      return response.body!
    })

    return {
      stream,
      abort: () => controller.abort(),
    }
  },
}
