import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { chatApi } from '@/api/chat'
import type { Conversation, ChatMessage, ChatError } from '@/types'
import type { SearchResult } from '@/api/chat'

export const useChatStore = defineStore('chat', () => {
  const conversations = ref<Conversation[]>([])
  const activeConversationId = ref<number | null>(null)
  const messages = ref<ChatMessage[]>([])
  const isStreaming = ref(false)
  const streamingContent = ref('')
  const error = ref<ChatError | null>(null)
  const isPanelOpen = ref(false)
  const searchQuery = ref('')
  const searchResults = ref<SearchResult[]>([])
  const isSearching = ref(false)
  let searchTimeout: ReturnType<typeof setTimeout> | null = null
  let lastMessageContent = ''

  const activeConversation = computed(() =>
    conversations.value.find(c => c.id === activeConversationId.value) || null,
  )

  async function loadConversations() {
    try {
      conversations.value = await chatApi.listConversations()
    } catch (e: unknown) {
      error.value = { code: 'load_error', message: e instanceof Error ? e.message : 'Failed to load conversations', retryable: true }
    }
  }

  function setSearchQuery(query: string) {
    searchQuery.value = query
    if (searchTimeout) clearTimeout(searchTimeout)
    if (!query.trim()) {
      searchResults.value = []
      isSearching.value = false
      return
    }
    isSearching.value = true
    searchTimeout = setTimeout(async () => {
      try {
        searchResults.value = await chatApi.searchConversations(query.trim())
      } catch {
        searchResults.value = []
      } finally {
        isSearching.value = false
      }
    }, 300)
  }

  function clearSearch() {
    searchQuery.value = ''
    searchResults.value = []
    isSearching.value = false
    if (searchTimeout) clearTimeout(searchTimeout)
  }

  async function createConversation(locale?: string) {
    try {
      const conv = await chatApi.createConversation(locale)
      conversations.value.unshift(conv)
      activeConversationId.value = conv.id
      messages.value = []
      return conv
    } catch (e: unknown) {
      error.value = { code: 'create_error', message: e instanceof Error ? e.message : 'Failed to create conversation', retryable: true }
      return null
    }
  }

  async function loadMessages(conversationId: number) {
    try {
      activeConversationId.value = conversationId
      const data = await chatApi.getConversation(conversationId)
      messages.value = data.messages
    } catch (e: unknown) {
      error.value = { code: 'load_error', message: e instanceof Error ? e.message : 'Failed to load messages', retryable: true }
    }
  }

  async function sendMessage(content: string) {
    if (isStreaming.value) return

    // Auto-create conversation if none active
    if (!activeConversationId.value) {
      const conv = await createConversation()
      if (!conv) return
    }

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
      const { stream } = chatApi.sendMessage(activeConversationId.value!, content)
      const body = await stream

      if (!body) throw new Error('No response body')

      const reader = body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''
      let currentEvent = ''
      let finalMessageId: number | null = null
      let finalTokenUsage = { input: 0, output: 0 }

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() || ''

        for (const line of lines) {
          if (line.startsWith('event: ')) {
            currentEvent = line.slice(7).trim()
          } else if (line.startsWith('data: ')) {
            const data = line.slice(6)
            try {
              const parsed = JSON.parse(data)

              if (currentEvent === 'delta' && parsed.content !== undefined) {
                streamingContent.value += parsed.content
              } else if (currentEvent === 'done' && parsed.message_id) {
                finalMessageId = parsed.message_id
                finalTokenUsage = parsed.token_usage || finalTokenUsage
              } else if (currentEvent === 'error') {
                error.value = {
                  code: parsed.code || 'stream_error',
                  message: parsed.message || 'An error occurred',
                  retryable: parsed.retryable ?? false,
                }
                lastMessageContent = content
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
        error.value = { code: 'connection_error', message: e.message || 'Failed to send message', retryable: true }
        lastMessageContent = content
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
      error.value = { code: 'delete_error', message: e instanceof Error ? e.message : 'Failed to delete conversation', retryable: false }
    }
  }

  function retryLastMessage() {
    if (lastMessageContent && error.value?.retryable) {
      // Remove the failed user message before retrying
      const lastUserMsgIndex = messages.value.findLastIndex(m => m.role === 'user')
      if (lastUserMsgIndex >= 0) {
        messages.value.splice(lastUserMsgIndex, 1)
      }
      error.value = null
      sendMessage(lastMessageContent)
    }
  }

  function dismissError() {
    error.value = null
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
    searchQuery,
    searchResults,
    isSearching,
    loadConversations,
    createConversation,
    loadMessages,
    sendMessage,
    deleteConversation,
    retryLastMessage,
    dismissError,
    setSearchQuery,
    clearSearch,
    togglePanel,
    openPanel,
    closePanel,
  }
})
