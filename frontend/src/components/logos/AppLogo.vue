<script setup lang="ts">
import { computed } from 'vue'
import { useThemeStore } from '@/stores/theme'
import RibLogo from './RibLogo.vue'

withDefaults(defineProps<{
  size?: number
  collapsed?: boolean
}>(), {
  size: 32,
  collapsed: false,
})

const themeStore = useThemeStore()

const isRib = computed(() => themeStore.themeName === 'rib')

const logoColor = computed(() => {
  if (isRib.value) {
    return '#ffffff'
  }
  return 'var(--color-primary)'
})
</script>

<template>
  <div class="flex items-center gap-2 min-w-0">
    <template v-if="isRib">
      <RibLogo
        :color="logoColor"
        :size="size"
        :show-text="!collapsed"
      />
    </template>
    <template v-else>
      <!-- Default theme: "SE" text mark -->
      <div
        class="flex items-center justify-center rounded-lg font-bold text-white shrink-0"
        :style="{
          width: `${size}px`,
          height: `${size}px`,
          fontSize: `${size * 0.4}px`,
          backgroundColor: 'var(--color-primary)',
        }"
      >
        SF
      </div>
      <span
        v-if="!collapsed"
        class="font-semibold truncate"
        :style="{ color: 'var(--color-sidebar-active)', fontSize: `${size * 0.45}px` }"
      >
        SkillForge
      </span>
    </template>
  </div>
</template>
