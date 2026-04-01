import { ref, computed, onUnmounted, nextTick } from 'vue'
import type { TourStep } from '@/types'

export function useTour() {
  const isActive = ref(false)
  const currentIndex = ref(0)
  const steps = ref<TourStep[]>([])
  const targetRect = ref<DOMRect | null>(null)

  const currentStep = computed(() => steps.value[currentIndex.value] || null)
  const isFirst = computed(() => currentIndex.value === 0)
  const isLast = computed(() => steps.value.length === 0 || currentIndex.value === steps.value.length - 1)
  const stepLabel = computed(() => `${currentIndex.value + 1} / ${steps.value.length}`)

  function start(tourSteps: TourStep[]) {
    steps.value = tourSteps
    currentIndex.value = 0
    isActive.value = true
    nextTick(() => updateTargetRect())
  }

  function next() {
    if (!isLast.value) {
      currentIndex.value++
      nextTick(() => updateTargetRect())
    } else {
      stop()
    }
  }

  function prev() {
    if (!isFirst.value) {
      currentIndex.value--
      nextTick(() => updateTargetRect())
    }
  }

  function stop() {
    isActive.value = false
    currentIndex.value = 0
    steps.value = []
    targetRect.value = null
  }

  function updateTargetRect() {
    const step = currentStep.value
    if (!step) return
    const el = document.querySelector(step.target)
    if (el) {
      targetRect.value = el.getBoundingClientRect()
      el.scrollIntoView({ behavior: 'smooth', block: 'center' })
    } else {
      targetRect.value = null
    }
  }

  // Keyboard handler
  function handleKeydown(e: KeyboardEvent) {
    if (!isActive.value) return
    if (e.key === 'Escape') stop()
    if (e.key === 'ArrowRight') next()
    if (e.key === 'ArrowLeft') prev()
  }

  if (typeof window !== 'undefined') {
    window.addEventListener('keydown', handleKeydown)
    onUnmounted(() => window.removeEventListener('keydown', handleKeydown))
  }

  return { isActive, currentStep, currentIndex, targetRect, stepLabel, isFirst, isLast, start, next, prev, stop }
}
