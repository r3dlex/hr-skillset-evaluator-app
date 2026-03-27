import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { chatApi } from '@/api/chat'
import type { Conversation, ChatMessage } from '@/types'

export const useChatStore = defineStore('chat', () => {
  const conversations = ref<Conversation[]>([])
  const activeConversationId = ref<number | null>(null)
  const messages = ref<ChatMessage[]>([])
  const isStreaming = ref(false)
  const streamingContent = ref('')
  const error = ref<string | null>(null)
  const isPanelOpen = ref(false)

  const activeConversation = computed(() =>
    conversations.value.find(c => c.id === activeConversationId.value) || null,
  )

  async function loadConversations() {
    try {
      conversations.value = await chatApi.listConversations()
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to load conversations'
    }
  }

  async function createConversation(locale?: string) {
    try {
      const conv = await chatApi.createConversation(locale)
      conversations.value.unshift(conv)
      activeConversationId.value = conv.id
      messages.value = []
      return conv
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to create conversation'
      return null
    }
  }

  async function loadMessages(conversationId: number) {
    try {
      activeConversationId.value = conversationId
      const data = await chatApi.getConversation(conversationId)
      messages.value = data.messages
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to load messages'
    }
  }

  async function sendMessage(content: string) {
    if (!activeConversationId.value || isStreaming.value) return

    // Add user message locally
    const userMsg: ChatMessage = {
      id: Date.now(),
      role: 'user',
      content,
      token_usage: { input: 0, output: 0 },
      provider: '',
      model: '',
      inserted_at: new Date().toISOString(),
    }
    messages.value.push(userMsg)

    // Start streaming
    isStreaming.value = true
    streamingContent.value = ''
    error.value = null

    try {
      const { stream } = chatApi.sendMessage(activeConversationId.value, content)
      const body = await stream

      if (!body) throw new Error('No response body')

      const reader = body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''
      let finalMessageId: number | null = null
      let finalTokenUsage = { input: 0, output: 0 }

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() || ''

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6)
            try {
              const parsed = JSON.parse(data)

              if (parsed.content !== undefined) {
                streamingContent.value += parsed.content
              }
              if (parsed.message_id) {
                finalMessageId = parsed.message_id
                finalTokenUsage = parsed.token_usage || finalTokenUsage
              }
              if (parsed.code) {
                error.value = parsed.message
              }
            } catch {
              // ignore non-JSON SSE data
            }
          }
        }
      }

      // Finalize: add assistant message
      if (streamingContent.value) {
        const assistantMsg: ChatMessage = {
          id: finalMessageId || Date.now(),
          role: 'assistant',
          content: streamingContent.value,
          token_usage: finalTokenUsage,
          provider: 'anthropic',
          model: '',
          inserted_at: new Date().toISOString(),
        }
        messages.value.push(assistantMsg)
      }
    } catch (e: unknown) {
      if (e instanceof Error && e.name !== 'AbortError') {
        error.value = e.message || 'Failed to send message'
      }
    } finally {
      isStreaming.value = false
      streamingContent.value = ''
    }
  }

  async function deleteConversation(id: number) {
    try {
      await chatApi.deleteConversation(id)
      conversations.value = conversations.value.filter(c => c.id !== id)
      if (activeConversationId.value === id) {
        activeConversationId.value = null
        messages.value = []
      }
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to delete conversation'
    }
  }

  function togglePanel() {
    isPanelOpen.value = !isPanelOpen.value
  }

  function openPanel() {
    isPanelOpen.value = true
  }

  function closePanel() {
    isPanelOpen.value = false
  }

  return {
    conversations,
    activeConversationId,
    messages,
    isStreaming,
    streamingContent,
    error,
    isPanelOpen,
    activeConversation,
    loadConversations,
    createConversation,
    loadMessages,
    sendMessage,
    deleteConversation,
    togglePanel,
    openPanel,
    closePanel,
  }
})
