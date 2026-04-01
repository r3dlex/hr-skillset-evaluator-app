import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { apiGet, apiPost, apiPut, apiDelete, apiUpload } from '../client'

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

  it('handles non-2xx with body.message field', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 403,
      json: () => Promise.resolve({ message: 'Access denied' }),
    } as Response)

    await expect(apiGet('/restricted')).rejects.toThrow('Access denied')
  })

  it('handles non-2xx with body.errors field', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 422,
      json: () => Promise.resolve({ errors: { name: ['is required'] } }),
    } as Response)

    await expect(apiPost('/skillsets', {})).rejects.toThrow('{"name":["is required"]}')
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

  // --- apiPut ---

  it('apiPut sends JSON body with PUT method', async () => {
    const responseData = { skillset: { id: 1, name: 'Updated' } }
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve(responseData),
    } as Response)

    const body = { skillset: { name: 'Updated' } }
    const result = await apiPut('/skillsets/1', body)

    expect(result).toEqual(responseData)
    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/api/skillsets/1',
      expect.objectContaining({
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        credentials: 'same-origin',
        body: JSON.stringify(body),
      }),
    )
  })

  it('apiPut sends request without body when body is undefined', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({}),
    } as Response)

    await apiPut('/some/endpoint')

    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/api/some/endpoint',
      expect.objectContaining({
        method: 'PUT',
        body: undefined,
      }),
    )
  })

  it('apiPut handles errors like other methods', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 422,
      json: () => Promise.resolve({ error: 'Invalid data' }),
    } as Response)

    await expect(apiPut('/skillsets/1', { name: '' })).rejects.toThrow('Invalid data')
  })

  // --- apiDelete ---

  it('apiDelete sends DELETE request', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 204,
      json: () => Promise.reject(new Error('no body')),
    } as Response)

    await apiDelete('/skillsets/1')

    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/api/skillsets/1',
      expect.objectContaining({
        method: 'DELETE',
        headers: { Accept: 'application/json' },
        credentials: 'same-origin',
      }),
    )
  })

  it('apiDelete handles 401 by redirecting', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 401,
      json: () => Promise.resolve({}),
    } as Response)

    await expect(apiDelete('/auth/logout')).rejects.toThrow('Unauthorized')
    expect(window.location.href).toBe('/login')
  })

  it('apiDelete handles error responses', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 404,
      json: () => Promise.resolve({ error: 'Not found' }),
    } as Response)

    await expect(apiDelete('/skillsets/999')).rejects.toThrow('Not found')
  })

  // --- apiUpload ---

  it('apiUpload sends FormData with file', async () => {
    const responseData = { data: { imported: 5, errors: [] } }
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve(responseData),
    } as Response)

    const file = new File(['content'], 'test.xlsx', { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
    const result = await apiUpload('/import', file, { period: '2024-Q1' })

    expect(result).toEqual(responseData)
    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/api/import',
      expect.objectContaining({
        method: 'POST',
        credentials: 'same-origin',
        headers: { Accept: 'application/json' },
      }),
    )

    // Verify FormData was sent as body
    const callArgs = vi.mocked(globalThis.fetch).mock.calls[0]
    const sentBody = callArgs[1]?.body as FormData
    expect(sentBody).toBeInstanceOf(FormData)
    expect(sentBody.get('file')).toBeInstanceOf(File)
    expect(sentBody.get('period')).toBe('2024-Q1')
  })

  it('apiUpload sends FormData without extra fields when not provided', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ data: {} }),
    } as Response)

    const file = new File(['content'], 'test.xlsx')
    await apiUpload('/import', file)

    const callArgs = vi.mocked(globalThis.fetch).mock.calls[0]
    const sentBody = callArgs[1]?.body as FormData
    expect(sentBody.get('file')).toBeInstanceOf(File)
    // No extra fields, only file
    const keys = Array.from(sentBody.keys())
    expect(keys).toEqual(['file'])
  })

  it('apiUpload handles error responses', async () => {
    vi.mocked(globalThis.fetch).mockResolvedValue({
      ok: false,
      status: 400,
      json: () => Promise.resolve({ error: 'Invalid file format' }),
    } as Response)

    const file = new File(['bad'], 'test.txt')
    await expect(apiUpload('/import', file)).rejects.toThrow('Invalid file format')
  })
})
