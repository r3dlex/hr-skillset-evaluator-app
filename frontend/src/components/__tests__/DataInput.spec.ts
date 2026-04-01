import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DataInput from '../DataInput.vue'
import type { Skill, GapAnalysisItem } from '@/types'

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

    const sliders = wrapper.findAll('input[type="range"]')
    expect(sliders.length).toBe(3)

    await sliders[0].setValue('5')
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

  it('shows team_avg and role_avg columns when gapItems provided', () => {
    const gapItems: GapAnalysisItem[] = [
      { skill_id: 1, name: 'JavaScript', manager_score: 4, self_score: 3, gap: 1, team_avg: 3.5, role_avg: 4.0, priority: 'critical' },
      { skill_id: 2, name: 'Python', manager_score: 3, self_score: 2, gap: 1, team_avg: null, role_avg: null, priority: 'high' },
    ]
    const wrapper = mount(DataInput, {
      props: { skills: sampleSkills, scores: sampleScores, readonly: false, gapItems },
    })
    // Should show team_avg value for skill 1
    expect(wrapper.text()).toContain('3.5')
    // Should show role_avg value for skill 1
    expect(wrapper.text()).toContain('4.0')
    // Should show dash for skill 2 (null team_avg)
    expect(wrapper.text()).toContain('—')
  })

  it('shows saved scores with non-null values in Current Score column', () => {
    const savedScores: Record<number, number | null> = { 1: 3, 2: null }
    const wrapper = mount(DataInput, {
      props: { skills: sampleSkills.slice(0, 2), scores: sampleScores, readonly: false, savedScores },
    })
    // formatScore for non-null returns the string of the number
    expect(wrapper.text()).toContain('3')
    // formatScore for null returns '?'
    expect(wrapper.text()).toContain('?')
  })
})
