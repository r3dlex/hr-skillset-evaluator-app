<script setup lang="ts">
import { computed, watch, ref } from 'vue'
import type { TourStep } from '@/types'

const props = defineProps<{
  isActive: boolean
  currentStep: TourStep | null
  targetRect: DOMRect | null
  stepLabel: string
  isFirst: boolean
  isLast: boolean
}>()

const emit = defineEmits<{
  (e: 'next'): void
  (e: 'prev'): void
  (e: 'stop'): void
}>()

const visible = ref(false)

watch(() => props.isActive, (active) => {
  if (active) {
    // Small delay for entrance animation
    requestAnimationFrame(() => { visible.value = true })
  } else {
    visible.value = false
  }
}, { immediate: true })

const TOOLTIP_WIDTH = 350
const TOOLTIP_HEIGHT = 180
const ARROW_SIZE = 8
const GAP = 12

const tooltipStyle = computed(() => {
  if (!props.targetRect || !props.currentStep) {
    return { top: '50%', left: '50%', transform: 'translate(-50%, -50%)' }
  }

  const rect = props.targetRect
  const pos = props.currentStep.position

  let top = 0
  let left = 0

  switch (pos) {
    case 'bottom':
      top = rect.bottom + GAP + ARROW_SIZE
      left = rect.left + rect.width / 2 - TOOLTIP_WIDTH / 2
      break
    case 'top':
      top = rect.top - GAP - ARROW_SIZE - TOOLTIP_HEIGHT
      left = rect.left + rect.width / 2 - TOOLTIP_WIDTH / 2
      break
    case 'right':
      top = rect.top + rect.height / 2 - TOOLTIP_HEIGHT / 2
      left = rect.right + GAP + ARROW_SIZE
      break
    case 'left':
      top = rect.top + rect.height / 2 - TOOLTIP_HEIGHT / 2
      left = rect.left - GAP - ARROW_SIZE - TOOLTIP_WIDTH
      break
  }

  // Clamp to viewport
  left = Math.max(16, Math.min(left, window.innerWidth - TOOLTIP_WIDTH - 16))
  top = Math.max(16, Math.min(top, window.innerHeight - TOOLTIP_HEIGHT - 16))

  return { top: `${top}px`, left: `${left}px` }
})

const cutoutStyle = computed(() => {
  if (!props.targetRect) return {}
  const r = props.targetRect
  const pad = 6
  return {
    position: 'fixed' as const,
    top: `${r.top - pad}px`,
    left: `${r.left - pad}px`,
    width: `${r.width + pad * 2}px`,
    height: `${r.height + pad * 2}px`,
    borderRadius: '8px',
    boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.5)',
    zIndex: 9998,
    pointerEvents: 'none' as const,
  }
})

const arrowClass = computed(() => {
  if (!props.currentStep) return ''
  switch (props.currentStep.position) {
    case 'bottom': return 'tour-arrow-top'
    case 'top': return 'tour-arrow-bottom'
    case 'right': return 'tour-arrow-left'
    case 'left': return 'tour-arrow-right'
    default: return ''
  }
})
</script>

<template>
  <Teleport to="body">
    <div v-if="isActive && currentStep" class="tour-overlay">
      <!-- Cutout highlight -->
      <div v-if="targetRect" :style="cutoutStyle" />

      <!-- Tooltip card -->
      <div
        class="fixed z-[9999] transition-all duration-300 ease-out"
        :class="[visible ? 'opacity-100 scale-100' : 'opacity-0 scale-95']"
        :style="tooltipStyle"
      >
        <div
          class="bg-white rounded-xl shadow-xl p-5 relative"
          :class="arrowClass"
          :style="{ width: `${TOOLTIP_WIDTH}px` }"
        >
          <!-- Step counter -->
          <div class="text-xs text-gray-400 mb-2">
            {{ stepLabel }}
          </div>

          <!-- Title -->
          <h3 class="text-base font-bold text-gray-900 mb-1.5">
            {{ currentStep.title }}
          </h3>

          <!-- Content -->
          <p class="text-sm text-gray-600 leading-relaxed mb-4">
            {{ currentStep.content }}
          </p>

          <!-- Actions -->
          <div class="flex items-center justify-between">
            <button
              class="text-xs text-gray-400 hover:text-gray-600 transition-colors"
              @click="emit('stop')"
            >
              Skip tour
            </button>
            <div class="flex items-center gap-2">
              <button
                v-if="!isFirst"
                class="px-3 py-1.5 text-xs font-medium text-gray-600 hover:text-gray-800 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
                @click="emit('prev')"
              >
                Previous
              </button>
              <button
                class="px-4 py-1.5 text-xs font-medium text-white bg-primary hover:bg-primary-dark rounded-lg transition-colors"
                @click="emit('next')"
              >
                {{ isLast ? 'Finish' : 'Next' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.tour-overlay {
  position: fixed;
  inset: 0;
  z-index: 9997;
  pointer-events: none;
}

.tour-overlay > * {
  pointer-events: auto;
}

/* Arrow styles */
.tour-arrow-top::before {
  content: '';
  position: absolute;
  top: -8px;
  left: 50%;
  transform: translateX(-50%);
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-bottom: 8px solid white;
}

.tour-arrow-bottom::after {
  content: '';
  position: absolute;
  bottom: -8px;
  left: 50%;
  transform: translateX(-50%);
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-top: 8px solid white;
}

.tour-arrow-left::before {
  content: '';
  position: absolute;
  left: -8px;
  top: 50%;
  transform: translateY(-50%);
  border-top: 8px solid transparent;
  border-bottom: 8px solid transparent;
  border-right: 8px solid white;
}

.tour-arrow-right::after {
  content: '';
  position: absolute;
  right: -8px;
  top: 50%;
  transform: translateY(-50%);
  border-top: 8px solid transparent;
  border-bottom: 8px solid transparent;
  border-left: 8px solid white;
}
</style>
