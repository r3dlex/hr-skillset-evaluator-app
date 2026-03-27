<script setup lang="ts">
import { provide } from 'vue'
import Sidebar from '@/components/Sidebar.vue'
import TourTooltip from '@/components/TourTooltip.vue'
import ChatPanel from '@/components/chat/ChatPanel.vue'
import { useTour } from '@/composables/useTour'
import { useThemeStore } from '@/stores/theme'
import { useChatStore } from '@/stores/chat'
import type { TourStep } from '@/types'

const tour = useTour()
const themeStore = useThemeStore()
const chatStore = useChatStore()

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

    <!-- Chat FAB (bottom-right) -->
    <button
      v-if="!chatStore.isPanelOpen"
      class="fixed bottom-6 right-6 w-14 h-14 rounded-full shadow-lg flex items-center justify-center transition-all hover:scale-105 z-40"
      :style="{ backgroundColor: 'var(--color-primary)', color: '#ffffff' }"
      title="AI Assistant"
      @click="chatStore.togglePanel()"
    >
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
      <span
        v-if="chatStore.isStreaming"
        class="absolute -top-1 -right-1 w-4 h-4 rounded-full animate-pulse"
        :style="{ backgroundColor: 'var(--color-success, #22c55e)' }"
      />
    </button>

    <!-- Chat Panel -->
    <ChatPanel />

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
