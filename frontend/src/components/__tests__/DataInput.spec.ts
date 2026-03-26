import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DataInput from '../DataInput.vue'
import ScoreSlider from '../ScoreSlider.vue'
import type { Skill } from '@/types'

const sampleSkills: Skill[] = [
  { id: 1, name: 'JavaScript', priority: 'critical', position: 1 },
  { id: 2, name: 'Python', priority: 'high', position: 2 },
  { id: 3, name: 'Go', priority: 'medium', position: 3 },
]

const sampleScores: Record<number, number | null> = {
  1: 4,
  2: 3,
  3: null,
}

describe('DataInput', () => {
  it('renders correct number of skill rows', () => {
    const wrapper = mount(DataInput, {
      props: { skills: sampleSkills, scores: sampleScores, readonly: false },
    })
    // Each skill row is a grid div inside .divide-y
    const rows = wrapper.findAll('.divide-y > div')
    expect(rows.length).toBe(3)
  })

  it('shows priority badges', () => {
    const wrapper = mount(DataInput, {
      props: { skills: sampleSkills, scores: sampleScores, readonly: false },
    })
    const text = wrapper.text()
    expect(text).toContain('critical')
    expect(text).toContain('high')
    expect(text).toContain('medium')
  })

  it('emits update:score event on slider change', async () => {
    const wrapper = mount(DataInput, {
      props: { skills: sampleSkills, scores: sampleScores, readonly: false },
    })

    // Find the first ScoreSlider and emit update:modelValue
    const sliders = wrapper.findAllComponents(ScoreSlider)
    expect(sliders.length).toBe(3)

    await sliders[0].vm.$emit('update:modelValue', 5)
    await wrapper.vm.$nextTick()

    const emitted = wrapper.emitted('update:score')
    expect(emitted).toBeTruthy()
    expect(emitted![0]).toEqual([1, 5])
  })

  it('respects readonly prop (sliders are disabled when readonly)', () => {
    const wrapper = mount(DataInput, {
      props: { skills: sampleSkills, scores: sampleScores, readonly: true },
    })
    const inputs = wrapper.findAll('input[type="range"]')
    expect(inputs.length).toBe(3)
    for (const input of inputs) {
      expect((input.element as HTMLInputElement).disabled).toBe(true)
    }
  })

  it('shows empty message when no skills provided', () => {
    const wrapper = mount(DataInput, {
      props: { skills: [], scores: {}, readonly: false },
    })
    expect(wrapper.text()).toContain('No skills to display')
  })
})
