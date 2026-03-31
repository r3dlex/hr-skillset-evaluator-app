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

  // --- createSkillset ---

  it('createSkillset adds to skillsets and returns new skillset', async () => {
    const newSkillset = { id: 3, name: 'DevOps', description: 'DevOps skills', position: 3, skill_count: 0 }
    vi.mocked(skillsetsApi.createSkillset).mockResolvedValue({ skillset: newSkillset })

    const store = useSkillsStore()
    store.skillsets = [...mockSkillsets]

    const result = await store.createSkillset({ name: 'DevOps', description: 'DevOps skills' })

    expect(result).toEqual(newSkillset)
    expect(store.skillsets).toHaveLength(3)
    expect(store.skillsets[2]).toEqual(newSkillset)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(skillsetsApi.createSkillset).toHaveBeenCalledWith({ name: 'DevOps', description: 'DevOps skills' })
  })

  it('createSkillset sets error and rethrows on failure', async () => {
    vi.mocked(skillsetsApi.createSkillset).mockRejectedValue(new Error('Validation failed'))

    const store = useSkillsStore()

    await expect(store.createSkillset({ name: '', description: '' })).rejects.toThrow('Validation failed')
    expect(store.error).toBe('Validation failed')
    expect(store.loading).toBe(false)
  })

  // --- deleteSkillset ---

  it('deleteSkillset removes from skillsets list', async () => {
    vi.mocked(skillsetsApi.deleteSkillset).mockResolvedValue(undefined as unknown as void)

    const store = useSkillsStore()
    store.skillsets = [...mockSkillsets]

    await store.deleteSkillset(1)

    expect(store.skillsets).toHaveLength(1)
    expect(store.skillsets[0].id).toBe(2)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(skillsetsApi.deleteSkillset).toHaveBeenCalledWith(1)
  })

  it('deleteSkillset clears currentSkillset if it matches deleted id', async () => {
    vi.mocked(skillsetsApi.deleteSkillset).mockResolvedValue(undefined as unknown as void)

    const store = useSkillsStore()
    store.skillsets = [...mockSkillsets]
    store.currentSkillset = mockSkillsetDetail as any

    await store.deleteSkillset(1)

    expect(store.currentSkillset).toBeNull()
  })

  it('deleteSkillset keeps currentSkillset if it does not match deleted id', async () => {
    vi.mocked(skillsetsApi.deleteSkillset).mockResolvedValue(undefined as unknown as void)

    const store = useSkillsStore()
    store.skillsets = [...mockSkillsets]
    store.currentSkillset = mockSkillsetDetail as any

    await store.deleteSkillset(2)

    expect(store.currentSkillset).toEqual(mockSkillsetDetail)
  })

  it('deleteSkillset sets error and rethrows on failure', async () => {
    vi.mocked(skillsetsApi.deleteSkillset).mockRejectedValue(new Error('Forbidden'))

    const store = useSkillsStore()

    await expect(store.deleteSkillset(1)).rejects.toThrow('Forbidden')
    expect(store.error).toBe('Forbidden')
    expect(store.loading).toBe(false)
  })
})
