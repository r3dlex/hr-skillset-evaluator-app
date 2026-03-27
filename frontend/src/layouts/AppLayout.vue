<script setup lang="ts">
import { provide } from 'vue'
import Sidebar from '@/components/Sidebar.vue'
import TourTooltip from '@/components/TourTooltip.vue'
import { useTour } from '@/composables/useTour'
import { useThemeStore } from '@/stores/theme'
import type { TourStep } from '@/types'

const tour = useTour()
const themeStore = useThemeStore()

function startTour(steps: TourStep[]) {
  tour.start(steps)
}

provide('startTour', startTour)
</script>

<template>
  <div class="flex min-h-screen" :style="{ backgroundColor: 'var(--color-bg)' }">
    <Sidebar />
    <main
      class="flex-1 min-h-screen transition-all duration-200"
      :style="{
        marginLeft: themeStore.sidebarCollapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)',
        backgroundColor: 'var(--color-bg)',
      }"
    >
      <div class="p-8">
        <slot />
      </div>
    </main>

    <!-- Tour Tooltip -->
    <TourTooltip
      :is-active="tour.isActive.value"
      :current-step="tour.currentStep.value"
      :target-rect="tour.targetRect.value"
      :step-label="tour.stepLabel.value"
      :is-first="tour.isFirst.value"
      :is-last="tour.isLast.value"
      @next="tour.next()"
      @prev="tour.prev()"
      @stop="tour.stop()"
    />
  </div>
</template>
