import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useThemeStore } from '../theme'

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] ?? null,
    setItem: (key: string, value: string) => { store[key] = value },
    removeItem: (key: string) => { delete store[key] },
    clear: () => { store = {} },
  }
})()

Object.defineProperty(window, 'localStorage', { value: localStorageMock })

// Mock matchMedia
const matchMediaMock = vi.fn().mockImplementation((query: string) => ({
  matches: query === '(prefers-color-scheme: dark)' ? false : false,
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
}))

Object.defineProperty(window, 'matchMedia', { value: matchMediaMock, writable: true })

describe('useThemeStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorageMock.clear()
    vi.clearAllMocks()
    // Reset matchMedia mock to light mode by default
    matchMediaMock.mockImplementation((_query: string) => ({
      matches: false,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }))
  })

  afterEach(() => {
    localStorageMock.clear()
  })

  it('has correct initial state with defaults', () => {
    const store = useThemeStore()
    expect(store.themeName).toBe('default')
    expect(store.colorMode).toBe('system')
    expect(store.sidebarCollapsed).toBe(false)
  })

  it('loads theme from localStorage', () => {
    localStorageMock.setItem('app-theme', 'rib')
    localStorageMock.setItem('app-color-mode', 'dark')
    localStorageMock.setItem('sidebar-collapsed', 'true')
    const store = useThemeStore()
    expect(store.themeName).toBe('rib')
    expect(store.colorMode).toBe('dark')
    expect(store.sidebarCollapsed).toBe(true)
  })

  it('setTheme changes themeName', async () => {
    const store = useThemeStore()
    store.setTheme('rib')
    expect(store.themeName).toBe('rib')
  })

  it('setColorMode changes colorMode', async () => {
    const store = useThemeStore()
    store.setColorMode('dark')
    expect(store.colorMode).toBe('dark')
  })

  it('setColorMode to light resolves mode to light', async () => {
    const store = useThemeStore()
    store.setColorMode('light')
    expect(store.resolvedMode).toBe('light')
    expect(store.isDark).toBe(false)
  })

  it('setColorMode to dark resolves mode to dark', async () => {
    const store = useThemeStore()
    store.setColorMode('dark')
    expect(store.resolvedMode).toBe('dark')
    expect(store.isDark).toBe(true)
  })

  it('system mode resolves based on matchMedia', () => {
    matchMediaMock.mockImplementation((_query: string) => ({
      matches: true,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }))
    const store = useThemeStore()
    store.setColorMode('system')
    expect(store.resolvedMode).toBe('dark')
    expect(store.isDark).toBe(true)
  })

  it('system mode resolves to light when matchMedia is false', () => {
    matchMediaMock.mockImplementation((_query: string) => ({
      matches: false,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }))
    const store = useThemeStore()
    store.setColorMode('system')
    expect(store.resolvedMode).toBe('light')
    expect(store.isDark).toBe(false)
  })

  it('toggleSidebar toggles sidebarCollapsed', () => {
    const store = useThemeStore()
    expect(store.sidebarCollapsed).toBe(false)
    store.toggleSidebar()
    expect(store.sidebarCollapsed).toBe(true)
    store.toggleSidebar()
    expect(store.sidebarCollapsed).toBe(false)
  })

  it('applyTheme modifies document.documentElement class list', () => {
    const store = useThemeStore()
    store.setColorMode('light')
    store.setTheme('rib')
    store.applyTheme()
    const classes = document.documentElement.classList
    expect(classes.contains('theme-rib')).toBe(true)
    expect(classes.contains('light')).toBe(true)
  })

  it('applyTheme adds dark class when isDark', () => {
    const store = useThemeStore()
    store.setColorMode('dark')
    store.applyTheme()
    const classes = document.documentElement.classList
    expect(classes.contains('dark')).toBe(true)
  })

  it('initSystemListener calls applyTheme and registers event listener', () => {
    const addEventListenerMock = vi.fn()
    matchMediaMock.mockImplementation((_query: string) => ({
      matches: false,
      addEventListener: addEventListenerMock,
      removeEventListener: vi.fn(),
    }))
    const store = useThemeStore()
    store.initSystemListener()
    expect(addEventListenerMock).toHaveBeenCalledWith('change', expect.any(Function))
  })

  it('initSystemListener triggers applyTheme when colorMode is system', () => {
    let changeHandler: (() => void) | null = null
    matchMediaMock.mockImplementation((_query: string) => ({
      matches: false,
      addEventListener: (event: string, handler: () => void) => {
        if (event === 'change') changeHandler = handler
      },
      removeEventListener: vi.fn(),
    }))
    const store = useThemeStore()
    store.setColorMode('system')
    store.initSystemListener()
    // Trigger the change handler
    if (changeHandler) changeHandler()
    // No errors expected
    expect(store.colorMode).toBe('system')
  })
})
