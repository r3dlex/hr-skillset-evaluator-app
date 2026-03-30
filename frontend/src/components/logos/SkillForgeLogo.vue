<script setup lang="ts">
import { computed } from 'vue'
import { useThemeStore } from '@/stores/theme'

const props = withDefaults(defineProps<{
  size?: number
  showText?: boolean
  variant?: 'auto' | 'light' | 'dark'
  /** Use a CSS variable for the text color (e.g. in the sidebar) */
  textColorVar?: string
}>(), {
  size: 32,
  showText: true,
  variant: 'auto',
  textColorVar: '',
})

const themeStore = useThemeStore()

const isDark = computed(() => {
  if (props.variant === 'light') return false
  if (props.variant === 'dark') return true
  return themeStore.isDark
})

const textColor = computed(() => {
  if (props.textColorVar) return `var(${props.textColorVar})`
  return isDark.value ? '#f1f5f9' : '#0f172a'
})
</script>

<template>
  <div class="flex items-center gap-2 min-w-0">
    <!-- Hexagon radar icon -->
    <svg
      :width="size"
      :height="size"
      viewBox="0 0 72 72"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class="shrink-0"
    >
      <defs>
        <linearGradient id="sf-grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#0ea5e9" />
          <stop offset="100%" stop-color="#6366f1" />
        </linearGradient>
      </defs>
      <!-- Rounded square bg -->
      <rect width="72" height="72" rx="14" fill="url(#sf-grad)" />
      <!-- Outer hexagon -->
      <polygon
        points="36,12 57,24 57,48 36,60 15,48 15,24"
        fill="none"
        stroke="white"
        stroke-width="2"
        opacity="0.4"
      />
      <!-- Inner hexagon -->
      <polygon
        points="36,20 50,28 50,44 36,52 22,44 22,28"
        fill="none"
        stroke="white"
        stroke-width="1.5"
        opacity="0.6"
      />
      <!-- Radar fill (asymmetric to show a "skill profile") -->
      <polygon
        points="36,22 46,32 44,46 32,48 24,38 30,26"
        fill="white"
        opacity="0.3"
      />
      <!-- Axis lines -->
      <line x1="36" y1="36" x2="36" y2="12" stroke="white" stroke-width="0.8" opacity="0.3" />
      <line x1="36" y1="36" x2="57" y2="24" stroke="white" stroke-width="0.8" opacity="0.3" />
      <line x1="36" y1="36" x2="57" y2="48" stroke="white" stroke-width="0.8" opacity="0.3" />
      <line x1="36" y1="36" x2="36" y2="60" stroke="white" stroke-width="0.8" opacity="0.3" />
      <line x1="36" y1="36" x2="15" y2="48" stroke="white" stroke-width="0.8" opacity="0.3" />
      <line x1="36" y1="36" x2="15" y2="24" stroke="white" stroke-width="0.8" opacity="0.3" />
      <!-- Center dot -->
      <circle cx="36" cy="36" r="2.5" fill="white" />
    </svg>

    <!-- Text label -->
    <span
      v-if="showText"
      class="font-semibold truncate"
      :style="{ color: textColor, fontSize: `${size * 0.45}px` }"
    >
      SkillForge
    </span>
  </div>
</template>
