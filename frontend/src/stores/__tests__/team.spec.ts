import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'

// Mock localStorage for test environment
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: vi.fn((key: string) => store[key] ?? null),
    setItem: vi.fn((key: string, value: string) => { store[key] = value }),
    removeItem: vi.fn((key: string) => { delete store[key] }),
    clear: vi.fn(() => { store = {} }),
    get length() { return Object.keys(store).length },
    key: vi.fn((i: number) => Object.keys(store)[i] ?? null),
  }
})()
Object.defineProperty(globalThis, 'localStorage', { value: localStorageMock })

vi.mock('@/api', () => ({
  teams: {
    listTeams: vi.fn(),
    getTeamMembers: vi.fn(),
  },
}))

import { teams as teamsApi } from '@/api'
import { useTeamStore } from '../team'

const mockTeams = [
  { id: 1, name: 'Engineering' },
  { id: 2, name: 'Design' },
]

const mockMembers = [
  { id: 10, name: 'Alice', email: 'alice@example.com', role: 'manager' as const, team: { id: 1, name: 'Engineering' }, location: 'Berlin', active: true },
  { id: 11, name: 'Bob', email: 'bob@example.com', role: 'user' as const, team: { id: 1, name: 'Engineering' }, location: 'Berlin', active: true },
]

describe('useTeamStore', () => {
  beforeEach(() => {
    localStorageMock.clear()
    vi.clearAllMocks()
    setActivePinia(createPinia())
  })

  it('has correct initial state', () => {
    const store = useTeamStore()
    expect(store.teams).toEqual([])
    expect(store.members).toEqual([])
    expect(store.selectedMemberIds).toEqual(new Set())
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  // --- fetchTeams ---

  it('fetchTeams populates teams array', async () => {
    vi.mocked(teamsApi.listTeams).mockResolvedValue({ teams: mockTeams })

    const store = useTeamStore()
    await store.fetchTeams()

    expect(store.teams).toEqual(mockTeams)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(teamsApi.listTeams).toHaveBeenCalledOnce()
  })

  it('fetchTeams sets error on failure', async () => {
    vi.mocked(teamsApi.listTeams).mockRejectedValue(new Error('Network error'))

    const store = useTeamStore()
    await store.fetchTeams()

    expect(store.error).toBe('Network error')
    expect(store.teams).toEqual([])
    expect(store.loading).toBe(false)
  })

  // --- fetchMembers ---

  it('fetchMembers populates members and selectedMemberIds', async () => {
    vi.mocked(teamsApi.getTeamMembers).mockResolvedValue({
      team: { id: 1, name: 'Engineering' },
      members: mockMembers,
    })

    const store = useTeamStore()
    await store.fetchMembers(1)

    expect(store.members).toEqual(mockMembers)
    expect(store.selectedMemberIds).toEqual(new Set([10, 11]))
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(teamsApi.getTeamMembers).toHaveBeenCalledWith(1)
  })

  it('fetchMembers sets error on failure', async () => {
    vi.mocked(teamsApi.getTeamMembers).mockRejectedValue(new Error('Not found'))

    const store = useTeamStore()
    await store.fetchMembers(999)

    expect(store.error).toBe('Not found')
    expect(store.members).toEqual([])
    expect(store.loading).toBe(false)
  })

  // --- setSelectedTeamId ---

  it('setSelectedTeamId sets value and persists to localStorage', () => {
    const store = useTeamStore()
    store.setSelectedTeamId(5)

    expect(store.selectedTeamId).toBe(5)
    expect(localStorageMock.setItem).toHaveBeenCalledWith('selected-team-id', '5')
  })

  it('setSelectedTeamId(null) clears localStorage', () => {
    const store = useTeamStore()
    store.setSelectedTeamId(5)
    store.setSelectedTeamId(null)

    expect(store.selectedTeamId).toBeNull()
    expect(localStorageMock.removeItem).toHaveBeenCalledWith('selected-team-id')
  })

  // --- setSelectedUserId ---

  it('setSelectedUserId sets value and persists to localStorage', () => {
    const store = useTeamStore()
    store.setSelectedUserId(42)

    expect(store.selectedUserId).toBe(42)
    expect(localStorageMock.setItem).toHaveBeenCalledWith('selected-user-id', '42')
  })

  it('setSelectedUserId(null) clears localStorage', () => {
    const store = useTeamStore()
    store.setSelectedUserId(42)
    store.setSelectedUserId(null)

    expect(store.selectedUserId).toBeNull()
    expect(localStorageMock.removeItem).toHaveBeenCalledWith('selected-user-id')
  })

  // --- setSelectedAssessment ---

  it('setSelectedAssessment sets value and persists to localStorage', () => {
    const store = useTeamStore()
    store.setSelectedAssessment('2024-Q1')

    expect(store.selectedAssessmentName).toBe('2024-Q1')
    expect(localStorageMock.setItem).toHaveBeenCalledWith('selected-assessment', '2024-Q1')
  })

  it('setSelectedAssessment with empty string resets to all', () => {
    const store = useTeamStore()
    store.setSelectedAssessment('2024-Q1')
    store.setSelectedAssessment('')

    expect(store.selectedAssessmentName).toBe('')
    expect(localStorageMock.setItem).toHaveBeenCalledWith('selected-assessment', '')
  })

  // --- toggleMember ---

  it('toggleMember removes member when already selected', async () => {
    vi.mocked(teamsApi.getTeamMembers).mockResolvedValue({
      team: { id: 1, name: 'Engineering' },
      members: mockMembers,
    })

    const store = useTeamStore()
    await store.fetchMembers(1)
    expect(store.selectedMemberIds.has(10)).toBe(true)

    store.toggleMember(10)
    expect(store.selectedMemberIds.has(10)).toBe(false)
    expect(store.selectedMemberIds.has(11)).toBe(true)
  })

  it('toggleMember adds member when not selected', async () => {
    vi.mocked(teamsApi.getTeamMembers).mockResolvedValue({
      team: { id: 1, name: 'Engineering' },
      members: mockMembers,
    })

    const store = useTeamStore()
    await store.fetchMembers(1)

    store.toggleMember(10) // remove
    expect(store.selectedMemberIds.has(10)).toBe(false)

    store.toggleMember(10) // add back
    expect(store.selectedMemberIds.has(10)).toBe(true)
  })

  it('toggleMember triggers reactivity (creates new Set)', async () => {
    vi.mocked(teamsApi.getTeamMembers).mockResolvedValue({
      team: { id: 1, name: 'Engineering' },
      members: mockMembers,
    })

    const store = useTeamStore()
    await store.fetchMembers(1)
    const originalSet = store.selectedMemberIds

    store.toggleMember(10)
    // Should be a new Set instance for reactivity
    expect(store.selectedMemberIds).not.toBe(originalSet)
  })
})
