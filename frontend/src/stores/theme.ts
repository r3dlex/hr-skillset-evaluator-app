import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'

export type ThemeName = 'default' | 'rib'
export type ColorMode = 'light' | 'dark' | 'system'

export const useThemeStore = defineStore('theme', () => {
  const themeName = ref<ThemeName>(
    (localStorage.getItem('app-theme') as ThemeName) || 'default',
  )
  const colorMode = ref<ColorMode>(
    (localStorage.getItem('app-color-mode') as ColorMode) || 'system',
  )
  const sidebarCollapsed = ref<boolean>(
    localStorage.getItem('sidebar-collapsed') === 'true',
  )

  const resolvedMode = computed<'light' | 'dark'>(() => {
    if (colorMode.value !== 'system') return colorMode.value
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  })

  const isDark = computed(() => resolvedMode.value === 'dark')

  function applyTheme() {
    const html = document.documentElement
    html.classList.remove('theme-default', 'theme-rib', 'dark', 'light')
    html.classList.add(`theme-${themeName.value}`)
    html.classList.add(resolvedMode.value)
    if (isDark.value) {
      html.classList.add('dark')
    }
  }

  watch(themeName, (v) => {
    localStorage.setItem('app-theme', v)
    applyTheme()
  })
  watch(colorMode, (v) => {
    localStorage.setItem('app-color-mode', v)
    applyTheme()
  })
  watch(sidebarCollapsed, (v) => {
    localStorage.setItem('sidebar-collapsed', String(v))
  })

  function initSystemListener() {
    const mq = window.matchMedia('(prefers-color-scheme: dark)')
    mq.addEventListener('change', () => {
      if (colorMode.value === 'system') applyTheme()
    })
    applyTheme()
  }

  function setTheme(name: ThemeName) {
    themeName.value = name
  }
  function setColorMode(mode: ColorMode) {
    colorMode.value = mode
  }
  function toggleSidebar() {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }

  return {
    themeName,
    colorMode,
    sidebarCollapsed,
    resolvedMode,
    isDark,
    setTheme,
    setColorMode,
    toggleSidebar,
    initSystemListener,
    applyTheme,
  }
})
