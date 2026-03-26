<script setup lang="ts">
import { provide } from 'vue'
import Sidebar from '@/components/Sidebar.vue'
import TourTooltip from '@/components/TourTooltip.vue'
import { useTour } from '@/composables/useTour'
import type { TourStep } from '@/types'

const tour = useTour()

function startTour(steps: TourStep[]) {
  tour.start(steps)
}

provide('startTour', startTour)
</script>

<template>
  <div class="flex min-h-screen">
    <Sidebar />
    <main class="flex-1 ml-[260px] bg-[#f8f9fa] min-h-screen">
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
