import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '../auth'

vi.mock('@/api', () => ({
  auth: {
    login: vi.fn(),
    logout: vi.fn(),
    fetchMe: vi.fn(),
  },
}))

import { auth as authApi } from '@/api'

const mockUser = {
  id: 1,
  email: 'alice@example.com',
  name: 'Alice',
  role: 'manager' as const,
  team: { id: 1, name: 'Engineering' },
  location: 'Berlin',
  active: true,
}

const mockRegularUser = {
  ...mockUser,
  id: 2,
  email: 'bob@example.com',
  name: 'Bob',
  role: 'user' as const,
}

describe('useAuthStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('has correct initial state (no user, not authenticated)', () => {
    const store = useAuthStore()
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
    expect(store.isManager).toBe(false)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('after login, user is set and isAuthenticated is true', async () => {
    vi.mocked(authApi.login).mockResolvedValue({ user: mockUser })

    const store = useAuthStore()
    await store.login('alice@example.com', 'password')

    expect(store.user).toEqual(mockUser)
    expect(store.isAuthenticated).toBe(true)
    expect(store.loading).toBe(false)
  })

  it('after logout, user is null', async () => {
    vi.mocked(authApi.login).mockResolvedValue({ user: mockUser })
    vi.mocked(authApi.logout).mockResolvedValue(undefined as unknown as void)

    const store = useAuthStore()
    await store.login('alice@example.com', 'password')
    expect(store.isAuthenticated).toBe(true)

    await store.logout()
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })

  it('isManager computed is true when role is manager', async () => {
    vi.mocked(authApi.login).mockResolvedValue({ user: mockUser })
    const store = useAuthStore()
    await store.login('alice@example.com', 'password')
    expect(store.isManager).toBe(true)
  })

  it('isManager computed is false when role is user', async () => {
    vi.mocked(authApi.login).mockResolvedValue({ user: mockRegularUser })
    const store = useAuthStore()
    await store.login('bob@example.com', 'password')
    expect(store.isManager).toBe(false)
  })

  it('fetchMe sets user from API response', async () => {
    vi.mocked(authApi.fetchMe).mockResolvedValue({ user: mockUser })

    const store = useAuthStore()
    await store.fetchMe()

    expect(store.user).toEqual(mockUser)
    expect(store.isAuthenticated).toBe(true)
    expect(store.loading).toBe(false)
  })

  it('fetchMe sets user to null on error', async () => {
    vi.mocked(authApi.fetchMe).mockRejectedValue(new Error('Unauthorized'))

    const store = useAuthStore()
    await store.fetchMe()

    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })

  it('login sets error on failure', async () => {
    vi.mocked(authApi.login).mockRejectedValue(new Error('Invalid credentials'))

    const store = useAuthStore()
    await expect(store.login('bad@example.com', 'wrong')).rejects.toThrow('Invalid credentials')

    expect(store.error).toBe('Invalid credentials')
    expect(store.user).toBeNull()
    expect(store.loading).toBe(false)
  })
})
