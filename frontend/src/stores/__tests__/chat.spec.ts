import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useChatStore } from '../chat'

vi.mock('@/api/chat', () => ({
  chatApi: {
    listConversations: vi.fn(),
    createConversation: vi.fn(),
    getConversation: vi.fn(),
    deleteConversation: vi.fn(),
    searchConversations: vi.fn(),
    sendMessage: vi.fn(),
  },
}))

vi.mock('@/composables/useScreenContext', () => ({
  getScreenContext: vi.fn().mockReturnValue({ screen: 'test' }),
}))

import { chatApi } from '@/api/chat'

const mockConversation = {
  id: 1,
  title: 'Test Conversation',
  inserted_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
}

const mockMessages = [
  { id: 1, role: 'user' as const, content: 'Hello', token_usage: { input: 5, output: 0 }, provider: '', model: '', inserted_at: '2024-01-01T00:00:00Z' },
  { id: 2, role: 'assistant' as const, content: 'Hi there', token_usage: { input: 0, output: 10 }, provider: 'anthropic', model: 'claude', inserted_at: '2024-01-01T00:00:01Z' },
]

describe('useChatStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('has correct initial state', () => {
    const store = useChatStore()
    expect(store.conversations).toEqual([])
    expect(store.activeConversationId).toBeNull()
    expect(store.messages).toEqual([])
    expect(store.isStreaming).toBe(false)
    expect(store.streamingContent).toBe('')
    expect(store.error).toBeNull()
    expect(store.isPanelOpen).toBe(false)
    expect(store.panelWidth).toBe(400)
    expect(store.activeConversation).toBeNull()
  })

  it('loadConversations loads conversations from API', async () => {
    vi.mocked(chatApi.listConversations).mockResolvedValue([mockConversation])
    const store = useChatStore()
    await store.loadConversations()
    expect(store.conversations).toEqual([mockConversation])
  })

  it('loadConversations sets error on failure', async () => {
    vi.mocked(chatApi.listConversations).mockRejectedValue(new Error('Network error'))
    const store = useChatStore()
    await store.loadConversations()
    expect(store.error).not.toBeNull()
    expect(store.error?.code).toBe('load_error')
  })

  it('createConversation creates a new conversation', async () => {
    vi.mocked(chatApi.createConversation).mockResolvedValue(mockConversation)
    const store = useChatStore()
    const conv = await store.createConversation()
    expect(conv).toEqual(mockConversation)
    expect(store.conversations).toContainEqual(mockConversation)
    expect(store.activeConversationId).toBe(1)
    expect(store.messages).toEqual([])
  })

  it('createConversation sets error on failure', async () => {
    vi.mocked(chatApi.createConversation).mockRejectedValue(new Error('Create failed'))
    const store = useChatStore()
    const conv = await store.createConversation()
    expect(conv).toBeNull()
    expect(store.error?.code).toBe('create_error')
  })

  it('loadMessages sets active conversation and messages', async () => {
    vi.mocked(chatApi.getConversation).mockResolvedValue({ conversation: mockConversation, messages: mockMessages })
    const store = useChatStore()
    await store.loadMessages(1)
    expect(store.activeConversationId).toBe(1)
    expect(store.messages).toEqual(mockMessages)
  })

  it('loadMessages sets error on failure', async () => {
    vi.mocked(chatApi.getConversation).mockRejectedValue(new Error('Not found'))
    const store = useChatStore()
    await store.loadMessages(999)
    expect(store.error?.code).toBe('load_error')
  })

  it('deleteConversation removes conversation from list', async () => {
    vi.mocked(chatApi.deleteConversation).mockResolvedValue(undefined)
    vi.mocked(chatApi.listConversations).mockResolvedValue([mockConversation])
    const store = useChatStore()
    await store.loadConversations()
    await store.deleteConversation(1)
    expect(store.conversations).toEqual([])
  })

  it('deleteConversation clears active if it was deleted', async () => {
    vi.mocked(chatApi.deleteConversation).mockResolvedValue(undefined)
    vi.mocked(chatApi.createConversation).mockResolvedValue(mockConversation)
    const store = useChatStore()
    await store.createConversation()
    expect(store.activeConversationId).toBe(1)
    await store.deleteConversation(1)
    expect(store.activeConversationId).toBeNull()
    expect(store.messages).toEqual([])
  })

  it('deleteConversation sets error on failure', async () => {
    vi.mocked(chatApi.deleteConversation).mockRejectedValue(new Error('Delete failed'))
    const store = useChatStore()
    await store.deleteConversation(1)
    expect(store.error?.code).toBe('delete_error')
  })

  it('activeConversation computed returns the active conversation', async () => {
    vi.mocked(chatApi.createConversation).mockResolvedValue(mockConversation)
    const store = useChatStore()
    await store.createConversation()
    expect(store.activeConversation).toEqual(mockConversation)
  })

  it('togglePanel toggles isPanelOpen', () => {
    const store = useChatStore()
    expect(store.isPanelOpen).toBe(false)
    store.togglePanel()
    expect(store.isPanelOpen).toBe(true)
    store.togglePanel()
    expect(store.isPanelOpen).toBe(false)
  })

  it('openPanel sets isPanelOpen to true', () => {
    const store = useChatStore()
    store.openPanel()
    expect(store.isPanelOpen).toBe(true)
  })

  it('closePanel sets isPanelOpen to false', () => {
    const store = useChatStore()
    store.openPanel()
    store.closePanel()
    expect(store.isPanelOpen).toBe(false)
  })

  it('setPanelWidth clamps to min/max', () => {
    const store = useChatStore()
    store.setPanelWidth(100) // below min
    expect(store.panelWidth).toBe(store.MIN_PANEL_WIDTH)
    store.setPanelWidth(9999) // above max
    expect(store.panelWidth).toBe(store.MAX_PANEL_WIDTH)
    store.setPanelWidth(500)
    expect(store.panelWidth).toBe(500)
  })

  it('togglePanelExpand toggles between max and default', () => {
    const store = useChatStore()
    store.setPanelWidth(400)
    store.togglePanelExpand()
    expect(store.panelWidth).toBe(store.MAX_PANEL_WIDTH)
    store.togglePanelExpand()
    expect(store.panelWidth).toBe(400)
  })

  it('dismissError clears error', async () => {
    vi.mocked(chatApi.listConversations).mockRejectedValue(new Error('error'))
    const store = useChatStore()
    await store.loadConversations()
    expect(store.error).not.toBeNull()
    store.dismissError()
    expect(store.error).toBeNull()
  })

  it('setSearchQuery clears results if empty', async () => {
    const store = useChatStore()
    store.setSearchQuery('')
    expect(store.searchResults).toEqual([])
    expect(store.isSearching).toBe(false)
  })

  it('setSearchQuery sets isSearching for non-empty query', () => {
    vi.mocked(chatApi.searchConversations).mockResolvedValue([])
    const store = useChatStore()
    store.setSearchQuery('test')
    expect(store.isSearching).toBe(true)
  })

  it('clearSearch resets search state', () => {
    const store = useChatStore()
    store.clearSearch()
    expect(store.searchQuery).toBe('')
    expect(store.searchResults).toEqual([])
    expect(store.isSearching).toBe(false)
  })

  it('retryLastMessage does nothing if no error', () => {
    const store = useChatStore()
    store.retryLastMessage() // should not throw
    expect(store.isStreaming).toBe(false)
  })

  it('sendMessage skips if already streaming', async () => {
    const store = useChatStore()
    store.isStreaming = true
    await store.sendMessage('hello')
    expect(chatApi.createConversation).not.toHaveBeenCalled()
  })

  it('sendMessage auto-creates conversation if none active', async () => {
    vi.mocked(chatApi.createConversation).mockResolvedValue(mockConversation)
    // Create a readable stream mock
    const encoder = new TextEncoder()
    const streamData = encoder.encode('event: delta\ndata: {"content":"Hello"}\n\nevent: done\ndata: {"message_id":10,"token_usage":{"input":5,"output":5}}\n\n')
    const readableStream = new ReadableStream({
      start(controller) {
        controller.enqueue(streamData)
        controller.close()
      }
    })
    vi.mocked(chatApi.sendMessage).mockReturnValue({
      stream: Promise.resolve(readableStream),
      abort: vi.fn(),
    })
    const store = useChatStore()
    await store.sendMessage('hello')
    expect(chatApi.createConversation).toHaveBeenCalled()
    expect(store.messages.length).toBeGreaterThan(0)
  })

  it('sendMessage handles stream error', async () => {
    vi.mocked(chatApi.createConversation).mockResolvedValue(mockConversation)
    vi.mocked(chatApi.sendMessage).mockReturnValue({
      stream: Promise.reject(new Error('Connection failed')),
      abort: vi.fn(),
    })
    const store = useChatStore()
    await store.sendMessage('hello')
    expect(store.error?.code).toBe('connection_error')
  })

  it('sendMessage does not create conversation if one is active', async () => {
    vi.mocked(chatApi.createConversation).mockResolvedValue(mockConversation)
    const encoder = new TextEncoder()
    const streamData = encoder.encode('event: done\ndata: {"message_id":11,"token_usage":{"input":1,"output":1}}\n\n')
    const readableStream = new ReadableStream({
      start(controller) {
        controller.enqueue(streamData)
        controller.close()
      }
    })
    vi.mocked(chatApi.sendMessage).mockReturnValue({
      stream: Promise.resolve(readableStream),
      abort: vi.fn(),
    })
    const store = useChatStore()
    // First create conversation
    await store.createConversation()
    vi.clearAllMocks()
    vi.mocked(chatApi.sendMessage).mockReturnValue({
      stream: Promise.resolve(readableStream),
      abort: vi.fn(),
    })
    await store.sendMessage('second message')
    expect(chatApi.createConversation).not.toHaveBeenCalled()
  })

  it('sendMessage sets conversation title from first message', async () => {
    const convNoTitle = { ...mockConversation, title: '' }
    vi.mocked(chatApi.createConversation).mockResolvedValue(convNoTitle)
    const encoder = new TextEncoder()
    const streamData = encoder.encode('')
    const readableStream = new ReadableStream({
      start(controller) {
        controller.enqueue(streamData)
        controller.close()
      }
    })
    vi.mocked(chatApi.sendMessage).mockReturnValue({
      stream: Promise.resolve(readableStream),
      abort: vi.fn(),
    })
    const store = useChatStore()
    await store.sendMessage('This is my first message that is longer')
    const conv = store.conversations.find(c => c.id === 1)
    expect(conv?.title).toContain('This is my first message')
  })
})
