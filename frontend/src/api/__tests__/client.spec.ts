import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { apiGet, apiPost } from '../client'

const originalFetch = globalThis.fetch

describe('API client', () => {
  beforeEach(() => {
    globalThis.fetch = vi.fn()
    // Mock window.location to be writable
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { href: '/' },
    })
  })

  afterEach(() => {
    globalThis.fetch = originalFetch
  })

  it('apiGet returns parsed JSON', async () => {
    const mockData = { skillsets: [{ id: 1, name: 'Frontend' }] }
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve(mockData),
    } as Response)

    const result = await apiGet('/skillsets')

    expect(result).toEqual(mockData)
    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/api/skillsets',
      expect.objectContaining({
        method: 'GET',
        headers: { Accept: 'application/json' },
        credentials: 'same-origin',
      }),
    )
  })

  it('apiPost sends JSON body', async () => {
    const responseData = { user: { id: 1, name: 'Alice' } }
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve(responseData),
    } as Response)

    const body = { email: 'alice@example.com', password: 'secret' }
    const result = await apiPost('/auth/login', body)

    expect(result).toEqual(responseData)
    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/api/auth/login',
      expect.objectContaining({
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        credentials: 'same-origin',
        body: JSON.stringify(body),
      }),
    )
  })

  it('handles 401 by redirecting to /login', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 401,
      json: () => Promise.resolve({}),
    } as Response)

    await expect(apiGet('/auth/me')).rejects.toThrow('Unauthorized')
    expect(window.location.href).toBe('/login')
  })

  it('handles non-2xx by throwing with error message', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 422,
      json: () => Promise.resolve({ error: 'Validation failed' }),
    } as Response)

    await expect(apiPost('/skillsets', { name: '' })).rejects.toThrow('Validation failed')
  })

  it('handles non-2xx with generic message when body has no error field', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 500,
      json: () => Promise.reject(new Error('not json')),
    } as Response)

    await expect(apiGet('/broken')).rejects.toThrow('Request failed with status 500')
  })

  it('handles 204 No Content response', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 204,
      json: () => Promise.reject(new Error('no body')),
    } as Response)

    const result = await apiPost('/auth/logout')
    expect(result).toBeUndefined()
  })
})
