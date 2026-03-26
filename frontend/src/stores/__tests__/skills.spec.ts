import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useSkillsStore } from '../skills'

vi.mock('@/api', () => ({
  skillsets: {
    listSkillsets: vi.fn(),
    getSkillset: vi.fn(),
    createSkillset: vi.fn(),
    updateSkillset: vi.fn(),
    deleteSkillset: vi.fn(),
  },
}))

import { skillsets as skillsetsApi } from '@/api'

const mockSkillsets = [
  { id: 1, name: 'Frontend', description: 'Frontend dev', position: 1, skill_count: 10 },
  { id: 2, name: 'Backend', description: 'Backend dev', position: 2, skill_count: 8 },
]

const mockSkillsetDetail = {
  id: 1,
  name: 'Frontend',
  description: 'Frontend dev',
  position: 1,
  skill_groups: [
    {
      id: 1,
      name: 'Languages',
      position: 1,
      skills: [
        { id: 1, name: 'JavaScript', priority: 'critical' as const, position: 1 },
        { id: 2, name: 'TypeScript', priority: 'high' as const, position: 2 },
      ],
    },
  ],
}

describe('useSkillsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('has correct initial empty state', () => {
    const store = useSkillsStore()
    expect(store.skillsets).toEqual([])
    expect(store.currentSkillset).toBeNull()
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('fetchSkillsets populates skillsets array', async () => {
    vi.mocked(skillsetsApi.listSkillsets).mockResolvedValue({ skillsets: mockSkillsets })

    const store = useSkillsStore()
    await store.fetchSkillsets()

    expect(store.skillsets).toEqual(mockSkillsets)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('fetchSkillset sets currentSkillset', async () => {
    vi.mocked(skillsetsApi.getSkillset).mockResolvedValue({ skillset: mockSkillsetDetail })

    const store = useSkillsStore()
    await store.fetchSkillset(1)

    expect(store.currentSkillset).toEqual(mockSkillsetDetail)
    expect(store.loading).toBe(false)
  })

  it('fetchSkillsets sets error on failure', async () => {
    vi.mocked(skillsetsApi.listSkillsets).mockRejectedValue(new Error('Network error'))

    const store = useSkillsStore()
    await store.fetchSkillsets()

    expect(store.error).toBe('Network error')
    expect(store.skillsets).toEqual([])
    expect(store.loading).toBe(false)
  })

  it('fetchSkillset sets error on failure', async () => {
    vi.mocked(skillsetsApi.getSkillset).mockRejectedValue(new Error('Not found'))

    const store = useSkillsStore()
    await store.fetchSkillset(999)

    expect(store.error).toBe('Not found')
    expect(store.currentSkillset).toBeNull()
    expect(store.loading).toBe(false)
  })
})
