import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import AuthLayout from '../AuthLayout.vue'

describe('AuthLayout', () => {
  it('renders slot content', () => {
    const wrapper = mount(AuthLayout, {
      slots: {
        default: '<div class="test-slot">Hello</div>',
      },
    })
    expect(wrapper.find('.test-slot').exists()).toBe(true)
    expect(wrapper.text()).toContain('Hello')
  })

  it('renders with min-h-screen class', () => {
    const wrapper = mount(AuthLayout)
    expect(wrapper.find('.min-h-screen').exists()).toBe(true)
  })
})
