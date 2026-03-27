<script setup lang="ts">
import { computed } from 'vue'
import type { GapAnalysisItem } from '@/types'

const props = defineProps<{
  items: GapAnalysisItem[]
}>()

const sortedItems = computed(() =>
  [...props.items].sort((a, b) => Math.abs(b.gap) - Math.abs(a.gap)),
)

const maxScore = 5

function barWidth(score: number): string {
  return `${(score / maxScore) * 100}%`
}

function gapColor(gap: number): string {
  const absGap = Math.abs(gap)
  if (absGap >= 2) return 'text-red-600'
  if (absGap >= 1) return 'text-orange-500'
  return 'text-green-600'
}

function gapBg(gap: number): string {
  const absGap = Math.abs(gap)
  if (absGap >= 2) return 'bg-red-100'
  if (absGap >= 1) return 'bg-orange-100'
  return 'bg-green-100'
}
</script>

<template>
  <div>
    <h3 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
      Gap Analysis
    </h3>
    <p class="text-sm mb-6" :style="{ color: 'var(--color-text-secondary)' }">
      Comparing manager scores vs self-assessment scores. Sorted by largest gap.
    </p>

    <div class="space-y-4">
      <div
        v-for="item in sortedItems"
        :key="item.name"
        class="rounded-lg p-4"
        :style="{ border: '1px solid var(--color-border)' }"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-medium" :style="{ color: 'var(--color-text-primary)' }">{{ item.name }}</span>
          <span
            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold"
            :class="[gapColor(item.gap), gapBg(item.gap)]"
          >
            Gap: {{ item.gap > 0 ? '+' : '' }}{{ item.gap.toFixed(1) }}
          </span>
        </div>

        <!-- Manager score bar -->
        <div class="flex items-center gap-3 mb-2">
          <span class="text-xs w-16 shrink-0" :style="{ color: 'var(--color-text-secondary)' }">Manager</span>
          <div class="flex-1 h-5 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
            <div
              class="h-full rounded-full transition-all duration-300"
              :style="{ width: barWidth(item.manager_score), backgroundColor: 'var(--color-primary)' }"
            />
          </div>
          <span class="text-xs font-medium w-8 text-right" :style="{ color: 'var(--color-text-secondary)' }">
            {{ item.manager_score.toFixed(1) }}
          </span>
        </div>

        <!-- Self score bar -->
        <div class="flex items-center gap-3">
          <span class="text-xs w-16 shrink-0" :style="{ color: 'var(--color-text-secondary)' }">Self</span>
          <div class="flex-1 h-5 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
            <div
              class="h-full bg-emerald-500 rounded-full transition-all duration-300"
              :style="{ width: barWidth(item.self_score) }"
            />
          </div>
          <span class="text-xs font-medium w-8 text-right" :style="{ color: 'var(--color-text-secondary)' }">
            {{ item.self_score.toFixed(1) }}
          </span>
        </div>
      </div>
    </div>

    <div v-if="items.length === 0" class="text-center py-12" :style="{ color: 'var(--color-text-muted)' }">
      <p>No gap analysis data available</p>
    </div>
  </div>
</template>
