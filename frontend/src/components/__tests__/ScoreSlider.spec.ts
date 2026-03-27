import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ScoreSlider from '../ScoreSlider.vue'

describe('ScoreSlider', () => {
  it('renders range input with correct min and max', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3 },
    })
    const input = wrapper.find('input[type="range"]')
    expect(input.exists()).toBe(true)
    expect(input.attributes('min')).toBe('0')
    expect(input.attributes('max')).toBe('5')
  })

  it('displays current value', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 4 },
    })
    expect(wrapper.text()).toContain('4')
  })

  it('emits update:modelValue on input change', async () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 2 },
    })
    const input = wrapper.find('input[type="range"]')
    await input.setValue('4')
    expect(wrapper.emitted('update:modelValue')).toBeTruthy()
    expect(wrapper.emitted('update:modelValue')![0]).toEqual([4])
  })

  it('is disabled when disabled prop is true', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3, disabled: true },
    })
    const input = wrapper.find('input[type="range"]')
    expect(input.attributes('disabled')).toBeDefined()
  })

  it('is enabled by default', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3 },
    })
    const input = wrapper.find('input[type="range"]')
    expect(input.attributes('disabled')).toBeUndefined()
  })

  it('shows value badge with border styling when value is 0', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 0 },
    })
    const badge = wrapper.find('.rounded-lg')
    expect(badge.exists()).toBe(true)
    const style = badge.attributes('style') || ''
    expect(style).toContain('var(--color-border)')
  })

  it('shows value badge with primary styling when value > 0', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3 },
    })
    const badge = wrapper.find('.rounded-lg')
    expect(badge.exists()).toBe(true)
    const style = badge.attributes('style') || ''
    expect(style).toContain('var(--color-primary)')
  })
})
