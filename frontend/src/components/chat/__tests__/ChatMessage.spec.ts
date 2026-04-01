import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ChatMessage from '../ChatMessage.vue'

const mockUserMessage = {
  id: 1,
  role: 'user' as const,
  content: 'Hello **world**',
  token_usage: { input: 5, output: 0 },
  provider: '',
  model: '',
  inserted_at: '2024-01-01T00:00:00Z',
}

const mockAssistantMessage = {
  id: 2,
  role: 'assistant' as const,
  content: 'Hi there! How can I help?',
  token_usage: { input: 0, output: 15 },
  provider: 'anthropic',
  model: 'claude',
  inserted_at: '2024-01-01T00:00:01Z',
}

const mockSystemMessage = {
  id: 3,
  role: 'system' as const,
  content: 'System message',
  token_usage: { input: 0, output: 0 },
  provider: '',
  model: '',
  inserted_at: '2024-01-01T00:00:02Z',
}

describe('ChatMessage', () => {
  it('renders user message', () => {
    const wrapper = mount(ChatMessage, { props: { message: mockUserMessage } })
    expect(wrapper.text()).toContain('Hello')
    expect(wrapper.text()).toContain('world')
  })

  it('renders assistant message', () => {
    const wrapper = mount(ChatMessage, { props: { message: mockAssistantMessage } })
    expect(wrapper.text()).toContain('Hi there!')
  })

  it('aligns user message to the right', () => {
    const wrapper = mount(ChatMessage, { props: { message: mockUserMessage } })
    const container = wrapper.find('.flex')
    expect(container.classes()).toContain('justify-end')
  })

  it('aligns assistant message to the left', () => {
    const wrapper = mount(ChatMessage, { props: { message: mockAssistantMessage } })
    const container = wrapper.find('.flex')
    expect(container.classes()).toContain('justify-start')
  })

  it('centers system message', () => {
    const wrapper = mount(ChatMessage, { props: { message: mockSystemMessage } })
    const container = wrapper.find('.flex')
    expect(container.classes()).toContain('justify-center')
  })

  it('renders markdown in content', () => {
    const wrapper = mount(ChatMessage, { props: { message: mockUserMessage } })
    // marked should process **world** into <strong>world</strong>
    expect(wrapper.html()).toContain('<strong>')
  })

  it('shows streaming cursor when isStreaming is true', () => {
    const wrapper = mount(ChatMessage, {
      props: { message: mockAssistantMessage, isStreaming: true },
    })
    // There should be a cursor indicator
    expect(wrapper.find('span.animate-pulse').exists() || wrapper.html().includes('animate')).toBe(true)
  })

  it('does not show streaming cursor when isStreaming is false', () => {
    const wrapper = mount(ChatMessage, {
      props: { message: mockAssistantMessage, isStreaming: false },
    })
    expect(wrapper.find('span[v-if]').exists() || !wrapper.html().includes('animate-pulse')).toBe(true)
  })

  it('handles empty content gracefully', () => {
    const emptyMsg = { ...mockAssistantMessage, content: '' }
    const wrapper = mount(ChatMessage, { props: { message: emptyMsg } })
    expect(wrapper.exists()).toBe(true)
  })
})
