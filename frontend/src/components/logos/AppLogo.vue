<script setup lang="ts">
import { computed } from 'vue'
import { useThemeStore } from '@/stores/theme'
import SkillForgeLogo from './SkillForgeLogo.vue'

withDefaults(defineProps<{
  size?: number
  collapsed?: boolean
}>(), {
  size: 32,
  collapsed: false,
})

const themeStore = useThemeStore()

const isRib = computed(() => themeStore.themeName === 'rib')
</script>

<template>
  <div class="flex items-center gap-2 min-w-0">
    <!-- SkillForge is always the app logo -->
    <SkillForgeLogo
      :size="size"
      :show-text="!collapsed"
      text-color-var="--color-sidebar-active"
    />

    <!-- When RIB theme is active, show small company badge -->
    <span
      v-if="isRib && !collapsed"
      class="text-xs font-medium px-1.5 py-0.5 rounded opacity-60 shrink-0"
      :style="{
        color: 'var(--color-sidebar-active)',
        border: '1px solid currentColor',
      }"
    >
      by RIB
    </span>
  </div>
</template>
