<script setup lang="ts">
import { ref } from 'vue'
import type { RadarSeries } from '@/types'

defineProps<{
  series: RadarSeries[]
}>()

const hiddenIds = ref<Set<number>>(new Set())

function toggleVisibility(userId: number) {
  if (hiddenIds.value.has(userId)) {
    hiddenIds.value.delete(userId)
  } else {
    hiddenIds.value.add(userId)
  }
  hiddenIds.value = new Set(hiddenIds.value)
}

function averageScore(values: number[]): string {
  if (values.length === 0) return '0.0'
  const avg = values.reduce((a, b) => a + b, 0) / values.length
  return avg.toFixed(1)
}
</script>

<template>
  <div class="card p-4">
    <h3 class="text-sm font-semibold mb-3" :style="{ color: 'var(--color-text-primary)' }">
      Team Members
    </h3>
    <div class="space-y-2">
      <button
        v-for="s in series"
        :key="s.user_id"
        class="flex items-center gap-3 w-full px-3 py-2 rounded-lg transition-colors text-left"
        :class="{ 'opacity-40': hiddenIds.has(s.user_id) }"
        :style="{ color: 'var(--color-text-secondary)' }"
        @click="toggleVisibility(s.user_id)"
      >
        <span
          class="w-3 h-3 rounded-full shrink-0"
          :style="{ backgroundColor: s.color }"
        />
        <span class="flex-1 text-sm truncate">{{ s.name }}</span>
        <span class="text-xs font-medium" :style="{ color: 'var(--color-text-muted)' }">
          {{ averageScore(s.values) }}
        </span>
      </button>
    </div>
    <p v-if="series.length === 0" class="text-sm" :style="{ color: 'var(--color-text-muted)' }">
      No members selected
    </p>
  </div>
</template>
