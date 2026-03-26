import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ScoreSlider from '../ScoreSlider.vue'

describe('ScoreSlider', () => {
  it('renders range input with correct min/max (0-5)', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3 },
    })
    const input = wrapper.find('input[type="range"]')
    expect(input.exists()).toBe(true)
    expect(input.attributes('min')).toBe('0')
    expect(input.attributes('max')).toBe('5')
    expect(input.attributes('step')).toBe('1')
  })

  it('displays current value', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 4 },
    })
    // The value is shown in a span element
    const valueDisplay = wrapper.find('span')
    expect(valueDisplay.text()).toBe('4')
  })

  it('emits update:modelValue on change', async () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 2 },
    })
    const input = wrapper.find('input[type="range"]')
    await input.setValue('4')

    const emitted = wrapper.emitted('update:modelValue')
    expect(emitted).toBeTruthy()
    expect(emitted![0]).toEqual([4])
  })

  it('is disabled when disabled prop is true', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3, disabled: true },
    })
    const input = wrapper.find('input[type="range"]')
    expect((input.element as HTMLInputElement).disabled).toBe(true)
  })

  it('is not disabled by default', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3 },
    })
    const input = wrapper.find('input[type="range"]')
    expect((input.element as HTMLInputElement).disabled).toBe(false)
  })

  it('shows value with correct styling when value is 0', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 0 },
    })
    const valueDisplay = wrapper.find('span')
    expect(valueDisplay.text()).toBe('0')
    expect(valueDisplay.classes()).toContain('bg-gray-100')
    expect(valueDisplay.classes()).toContain('text-gray-400')
  })

  it('shows value with primary styling when value > 0', () => {
    const wrapper = mount(ScoreSlider, {
      props: { modelValue: 3 },
    })
    const valueDisplay = wrapper.find('span')
    expect(valueDisplay.classes()).toContain('text-primary')
  })
})
