import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Overview from '../Overview.vue'

describe('Overview', () => {
  it('renders stat cards', () => {
    const wrapper = mount(Overview, {
      props: {
        totalSkills: 25,
        totalSkillsets: 3,
        teamSize: 8,
        averageScore: 3.7,
        skillsRated: 20,
        completionPercentage: 80,
      },
    })
    const cards = wrapper.findAll('.card')
    expect(cards.length).toBe(4)
  })

  it('displays correct summary values from props', () => {
    const wrapper = mount(Overview, {
      props: {
        totalSkills: 25,
        totalSkillsets: 3,
        teamSize: 8,
        averageScore: 3.7,
        skillsRated: 20,
        completionPercentage: 80,
      },
    })
    const text = wrapper.text()
    expect(text).toContain('25')
    expect(text).toContain('3.7')
    expect(text).toContain('20')
    expect(text).toContain('80%')
  })

  it('shows -- for average score when it is 0', () => {
    const wrapper = mount(Overview, {
      props: {
        totalSkills: 0,
        averageScore: 0,
        skillsRated: 0,
        completionPercentage: 0,
      },
    })
    expect(wrapper.text()).toContain('--')
  })

  it('uses default prop values when not provided', () => {
    const wrapper = mount(Overview)
    const text = wrapper.text()
    // Defaults are all 0 except averageScore shows '--'
    expect(text).toContain('--')
    expect(text).toContain('0%')
  })
})
