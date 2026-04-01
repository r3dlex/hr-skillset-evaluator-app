import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

vi.mock('../client', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiDelete: vi.fn(),
}))

import { apiGet, apiPost, apiDelete } from '../client'
import { chatApi } from '../chat'

const mockConversation = {
  id: 1,
  title: 'Test Chat',
  inserted_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
}

const mockMessage = {
  id: 1,
  role: 'user' as const,
  content: 'Hello',
  token_usage: { input: 5, output: 0 },
  provider: '',
  model: '',
  inserted_at: '2024-01-01T00:00:00Z',
}

describe('chatApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('createConversation calls apiPost and returns conversation', async () => {
    vi.mocked(apiPost).mockResolvedValue({ data: mockConversation })
    const result = await chatApi.createConversation()
    expect(apiPost).toHaveBeenCalledWith('/chat/conversations', { locale: undefined })
    expect(result).toEqual(mockConversation)
  })

  it('createConversation passes locale', async () => {
    vi.mocked(apiPost).mockResolvedValue({ data: mockConversation })
    await chatApi.createConversation('en')
    expect(apiPost).toHaveBeenCalledWith('/chat/conversations', { locale: 'en' })
  })

  it('listConversations calls apiGet', async () => {
    vi.mocked(apiGet).mockResolvedValue({ data: [mockConversation] })
    const result = await chatApi.listConversations()
    expect(apiGet).toHaveBeenCalledWith('/chat/conversations')
    expect(result).toEqual([mockConversation])
  })

  it('searchConversations calls apiGet with encoded query', async () => {
    vi.mocked(apiGet).mockResolvedValue({ data: [] })
    await chatApi.searchConversations('hello world')
    expect(apiGet).toHaveBeenCalledWith('/chat/conversations?q=hello%20world')
  })

  it('getConversation calls apiGet and returns conversation and messages', async () => {
    vi.mocked(apiGet).mockResolvedValue({
      data: { ...mockConversation, messages: [mockMessage] },
    })
    const result = await chatApi.getConversation(1)
    expect(apiGet).toHaveBeenCalledWith('/chat/conversations/1')
    expect(result.messages).toEqual([mockMessage])
  })

  it('getConversation returns empty messages when none in response', async () => {
    vi.mocked(apiGet).mockResolvedValue({
      data: { ...mockConversation },
    })
    const result = await chatApi.getConversation(1)
    expect(result.messages).toEqual([])
  })

  it('deleteConversation calls apiDelete', async () => {
    vi.mocked(apiDelete).mockResolvedValue(undefined)
    await chatApi.deleteConversation(1)
    expect(apiDelete).toHaveBeenCalledWith('/chat/conversations/1')
  })

  it('sendMessage returns stream and abort function', () => {
    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      body: {},
    })
    const originalFetch = globalThis.fetch
    globalThis.fetch = mockFetch

    const result = chatApi.sendMessage(1, 'Hello', { screen: 'dashboard' })
    expect(result).toHaveProperty('stream')
    expect(result).toHaveProperty('abort')
    expect(typeof result.abort).toBe('function')
    expect(result.stream).toBeInstanceOf(Promise)

    globalThis.fetch = originalFetch
  })

  it('sendMessage calls fetch with correct params', async () => {
    const mockBody = {}
    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      body: mockBody,
    })
    const originalFetch = globalThis.fetch
    globalThis.fetch = mockFetch

    const screenContext = { screen: 'skillset', skillset_id: 1 }
    chatApi.sendMessage(1, 'Hello', screenContext)

    expect(mockFetch).toHaveBeenCalledWith(
      '/api/chat/conversations/1/messages',
      expect.objectContaining({
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: 'Hello', screen_context: screenContext }),
        credentials: 'same-origin',
      })
    )

    globalThis.fetch = originalFetch
  })

  it('sendMessage stream rejects on non-ok response', async () => {
    const mockFetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 500,
    })
    const originalFetch = globalThis.fetch
    globalThis.fetch = mockFetch

    const { stream } = chatApi.sendMessage(1, 'Hello')
    await expect(stream).rejects.toThrow('HTTP 500')

    globalThis.fetch = originalFetch
  })

  it('abort cancels the request', () => {
    const mockAbort = vi.fn()
    vi.spyOn(globalThis, 'AbortController').mockImplementation(() => ({
      abort: mockAbort,
      signal: {} as AbortSignal,
    }))

    const mockFetch = vi.fn().mockResolvedValue({ ok: true, body: {} })
    const originalFetch = globalThis.fetch
    globalThis.fetch = mockFetch

    const { abort } = chatApi.sendMessage(1, 'Hello')
    abort()
    expect(mockAbort).toHaveBeenCalled()

    globalThis.fetch = originalFetch
    vi.restoreAllMocks()
  })
})
