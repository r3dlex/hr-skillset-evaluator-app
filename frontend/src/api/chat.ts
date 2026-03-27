import { apiGet, apiPost, apiDelete } from './client'
import type { Conversation, ChatMessage } from '@/types'
import type { ScreenContext } from '@/composables/useScreenContext'

export interface SearchResult extends Conversation {
  match_snippet: string
  match_type: string
}

export const chatApi = {
  async createConversation(locale?: string): Promise<Conversation> {
    const resp = await apiPost<{ data: Conversation }>('/chat/conversations', { locale })
    return resp.data
  },

  async listConversations(): Promise<Conversation[]> {
    const resp = await apiGet<{ data: Conversation[] }>('/chat/conversations')
    return resp.data
  },

  async searchConversations(query: string): Promise<SearchResult[]> {
    const resp = await apiGet<{ data: SearchResult[] }>(
      `/chat/conversations?q=${encodeURIComponent(query)}`,
    )
    return resp.data
  },

  async getConversation(id: number): Promise<{ conversation: Conversation; messages: ChatMessage[] }> {
    const resp = await apiGet<{ data: Conversation & { messages: ChatMessage[] } }>(`/chat/conversations/${id}`)
    return { conversation: resp.data, messages: resp.data.messages || [] }
  },

  async deleteConversation(id: number): Promise<void> {
    await apiDelete(`/chat/conversations/${id}`)
  },

  sendMessage(conversationId: number, content: string, screenContext?: ScreenContext): { stream: Promise<ReadableStream<Uint8Array>>; abort: () => void } {
    const controller = new AbortController()

    const stream = fetch(`/api/chat/conversations/${conversationId}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content, screen_context: screenContext }),
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
