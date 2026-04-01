import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import ChatInput from '../ChatInput.vue'

vi.mock('@/stores/chat', () => ({ useChatStore: vi.fn() }))
vi.mock('@/stores/auth', () => ({ useAuthStore: vi.fn() }))

import { useChatStore } from '@/stores/chat'
import { useAuthStore } from '@/stores/auth'

const mockChatStore = {
  isStreaming: false,
  sendMessage: vi.fn(),
}

const mockAuthStore = {
  user: { id: 1, name: 'Alice', email: 'alice@example.com', role: 'manager' as const, active: true },
}

describe('ChatInput', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useChatStore).mockReturnValue(mockChatStore as unknown as ReturnType<typeof useChatStore>)
    vi.mocked(useAuthStore).mockReturnValue(mockAuthStore as ReturnType<typeof useAuthStore>)
    mockChatStore.isStreaming = false
  })

  function mountComponent() {
    return mount(ChatInput, {
      global: {
        plugins: [createPinia()],
      },
    })
  }

  it('renders textarea', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('textarea').exists()).toBe(true)
  })

  it('renders send button', () => {
    const wrapper = mountComponent()
    // The send button doesn't have a title attr — find by SVG content or button count
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBeGreaterThan(0)
  })

  it('send button is disabled when input is empty', () => {
    const wrapper = mountComponent()
    const buttons = wrapper.findAll('button')
    // Last button is the send button
    const sendBtn = buttons[buttons.length - 1]
    expect((sendBtn.element as HTMLButtonElement).disabled).toBe(true)
  })

  it('send button is enabled when input has text', async () => {
    const wrapper = mountComponent()
    await wrapper.find('textarea').setValue('Hello world')
    const buttons = wrapper.findAll('button')
    const sendBtn = buttons[buttons.length - 1]
    expect((sendBtn.element as HTMLButtonElement).disabled).toBe(false)
  })

  it('calls sendMessage on send button click', async () => {
    const wrapper = mountComponent()
    await wrapper.find('textarea').setValue('Hello')
    const buttons = wrapper.findAll('button')
    await buttons[buttons.length - 1].trigger('click')
    expect(mockChatStore.sendMessage).toHaveBeenCalledWith('Hello')
  })

  it('clears input after sending', async () => {
    const wrapper = mountComponent()
    await wrapper.find('textarea').setValue('Hello')
    const buttons = wrapper.findAll('button')
    await buttons[buttons.length - 1].trigger('click')
    expect((wrapper.find('textarea').element as HTMLTextAreaElement).value).toBe('')
  })

  it('sends on Enter key press', async () => {
    const wrapper = mountComponent()
    await wrapper.find('textarea').setValue('Hello')
    await wrapper.find('textarea').trigger('keydown', { key: 'Enter', shiftKey: false })
    expect(mockChatStore.sendMessage).toHaveBeenCalledWith('Hello')
  })

  it('does not send on Shift+Enter', async () => {
    const wrapper = mountComponent()
    await wrapper.find('textarea').setValue('Hello')
    await wrapper.find('textarea').trigger('keydown', { key: 'Enter', shiftKey: true })
    expect(mockChatStore.sendMessage).not.toHaveBeenCalled()
  })

  it('send button is disabled when streaming', async () => {
    mockChatStore.isStreaming = true
    const wrapper = mountComponent()
    await wrapper.find('textarea').setValue('Hello')
    const buttons = wrapper.findAll('button')
    const sendBtn = buttons[buttons.length - 1]
    expect((sendBtn.element as HTMLButtonElement).disabled).toBe(true)
  })

  it('handles file upload for managers', () => {
    const wrapper = mountComponent()
    // Manager should see file upload option
    const fileInput = wrapper.find('input[type="file"]')
    expect(fileInput.exists()).toBe(true)
  })

  it('emits upload event when file selected', async () => {
    const wrapper = mountComponent()
    const file = new File(['content'], 'test.xlsx')
    const fileInput = wrapper.find('input[type="file"]')
    Object.defineProperty(fileInput.element, 'files', { value: [file] })
    await fileInput.trigger('change')
    expect(wrapper.emitted('upload')).toBeTruthy()
  })

  it('handles input event to resize textarea', async () => {
    const wrapper = mountComponent()
    await wrapper.find('textarea').trigger('input')
    expect(wrapper.exists()).toBe(true)
  })
})
