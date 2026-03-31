import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useEvaluationsStore } from '../evaluations'

vi.mock('@/api', () => ({
  evaluations: {
    getEvaluations: vi.fn(),
    updateManagerScores: vi.fn(),
    updateSelfScores: vi.fn(),
  },
  radar: {
    getRadarData: vi.fn(),
  },
  gapAnalysis: {
    getGapAnalysis: vi.fn(),
  },
  teams: {
    listTeams: vi.fn().mockResolvedValue({ teams: [] }),
    getTeamMembers: vi.fn().mockResolvedValue({ team: {}, members: [] }),
  },
}))

import { evaluations as evalApi, radar as radarApi, gapAnalysis as gapApi } from '@/api'

const mockEvaluations = [
  { skill_id: 1, skill_name: 'JavaScript', manager_score: 4, self_score: 3 },
  { skill_id: 2, skill_name: 'Python', manager_score: 3, self_score: 4 },
]

const mockRadarData = {
  axes: ['JavaScript', 'Python', 'Go'],
  series: [
    { user_id: 1, name: 'Alice', color: '#3b82f6', values: [4, 3, 5] },
  ],
}

const mockGapItems = [
  { name: 'JavaScript', manager_score: 4, self_score: 3, gap: 1 },
  { name: 'Python', manager_score: 3, self_score: 4, gap: -1 },
]

describe('useEvaluationsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('has correct initial state', () => {
    const store = useEvaluationsStore()
    expect(store.evaluations).toEqual([])
    expect(store.radarData).toBeNull()
    expect(store.gapAnalysis).toEqual([])
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('fetchEvaluations populates evaluations', async () => {
    vi.mocked(evalApi.getEvaluations).mockResolvedValue({ evaluations: mockEvaluations })

    const store = useEvaluationsStore()
    await store.fetchEvaluations(1, 1, '2024-Q1')

    expect(store.evaluations).toEqual(mockEvaluations)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(evalApi.getEvaluations).toHaveBeenCalledWith(1, 1, '2024-Q1', undefined)
  })

  it('fetchRadarData populates radarData', async () => {
    vi.mocked(radarApi.getRadarData).mockResolvedValue(mockRadarData)

    const store = useEvaluationsStore()
    await store.fetchRadarData([1], 1, '2024-Q1')

    expect(store.radarData).toEqual(mockRadarData)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(radarApi.getRadarData).toHaveBeenCalledWith([1], 1, '2024-Q1', undefined)
  })

  it('fetchGapAnalysis populates gapAnalysis', async () => {
    vi.mocked(gapApi.getGapAnalysis).mockResolvedValue({ items: mockGapItems })

    const store = useEvaluationsStore()
    await store.fetchGapAnalysis(1, 1, '2024-Q1')

    expect(store.gapAnalysis).toEqual(mockGapItems)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(gapApi.getGapAnalysis).toHaveBeenCalledWith(1, 1, '2024-Q1', { skillGroupId: undefined })
  })

  it('fetchEvaluations sets error on failure', async () => {
    vi.mocked(evalApi.getEvaluations).mockRejectedValue(new Error('Server error'))

    const store = useEvaluationsStore()
    await store.fetchEvaluations(1, 1, '2024-Q1')

    expect(store.error).toBe('Server error')
    expect(store.evaluations).toEqual([])
    expect(store.loading).toBe(false)
  })

  it('fetchRadarData sets error on failure', async () => {
    vi.mocked(radarApi.getRadarData).mockRejectedValue(new Error('Radar failed'))

    const store = useEvaluationsStore()
    await store.fetchRadarData([1], 1, '2024-Q1')

    expect(store.error).toBe('Radar failed')
    expect(store.radarData).toBeNull()
    expect(store.loading).toBe(false)
  })
})
