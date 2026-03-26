<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useOnboardingStore } from '@/stores/onboarding'

const emit = defineEmits<{
  (e: 'start-tour'): void
}>()

const router = useRouter()
const onboardingStore = useOnboardingStore()
const collapsed = ref(false)

function toggleCollapse() {
  collapsed.value = !collapsed.value
}

function navigateToStep(route?: string) {
  if (route) {
    router.push(route)
  }
}
</script>

<template>
  <div class="mx-3 my-2 rounded-lg bg-[#16163a] border border-white/5 overflow-hidden">
    <!-- Header -->
    <button
      class="w-full flex items-center justify-between px-4 py-3 hover:bg-white/5 transition-colors"
      @click="toggleCollapse"
    >
      <div class="flex items-center gap-2">
        <span class="text-sm font-semibold text-white">Getting Started</span>
        <span class="text-xs font-medium text-primary bg-primary/20 px-1.5 py-0.5 rounded">
          {{ onboardingStore.progress.completed }}/{{ onboardingStore.progress.total }}
        </span>
      </div>
      <svg
        class="w-4 h-4 text-white/40 transition-transform duration-200"
        :class="{ 'rotate-180': !collapsed }"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Progress bar -->
    <div class="px-4 pb-1">
      <div class="h-1 bg-white/10 rounded-full overflow-hidden">
        <div
          class="h-full bg-primary rounded-full transition-all duration-500 ease-out"
          :style="{ width: `${onboardingStore.progress.percentage}%` }"
        />
      </div>
    </div>

    <!-- Steps list -->
    <div
      class="overflow-hidden transition-all duration-300 ease-in-out"
      :style="{ maxHeight: collapsed ? '0px' : '400px' }"
    >
      <div class="px-3 py-2 space-y-0.5">
        <div
          v-for="step in onboardingStore.steps"
          :key="step.id"
          class="flex items-center gap-2.5 px-2 py-1.5 rounded-md transition-colors duration-200"
          :class="[
            onboardingStore.completedSteps.includes(step.id)
              ? 'opacity-60'
              : 'hover:bg-white/5 cursor-pointer'
          ]"
          @click="navigateToStep(step.route)"
        >
          <!-- Checkbox circle -->
          <div
            class="w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-all duration-300"
            :class="
              onboardingStore.completedSteps.includes(step.id)
                ? 'border-green-500 bg-green-500'
                : 'border-white/30'
            "
          >
            <svg
              v-if="onboardingStore.completedSteps.includes(step.id)"
              class="w-3 h-3 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
            </svg>
          </div>

          <!-- Label -->
          <span
            class="text-xs leading-tight transition-all duration-200"
            :class="
              onboardingStore.completedSteps.includes(step.id)
                ? 'text-white/40 line-through'
                : 'text-white/80'
            "
          >
            {{ step.label }}
          </span>

          <!-- Route arrow -->
          <svg
            v-if="step.route && !onboardingStore.completedSteps.includes(step.id)"
            class="w-3 h-3 text-white/20 ml-auto shrink-0"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </div>
      </div>

      <!-- Actions -->
      <div class="px-4 py-2.5 flex items-center justify-between border-t border-white/5">
        <button
          class="text-xs font-medium text-primary border border-primary/30 hover:bg-primary/10 px-3 py-1 rounded-md transition-colors"
          @click="emit('start-tour')"
        >
          Take a tour
        </button>
        <button
          class="text-xs text-white/30 hover:text-white/50 transition-colors"
          @click="onboardingStore.dismiss()"
        >
          Dismiss
        </button>
      </div>
    </div>
  </div>
</template>
