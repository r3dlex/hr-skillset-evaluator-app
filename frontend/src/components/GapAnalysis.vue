<script setup lang="ts">
import { computed } from 'vue'
import type { GapAnalysisItem } from '@/types'

const props = defineProps<{
  items: GapAnalysisItem[]
}>()

const sortedItems = computed(() =>
  [...props.items]
    .sort((a, b) => {
      // Sort by priority first (critical > high > medium > low)
      const prio = priorityWeight(b.priority) - priorityWeight(a.priority)
      if (prio !== 0) return prio
      // Then by absolute gap
      return Math.abs(b.gap ?? 0) - Math.abs(a.gap ?? 0)
    }),
)

const maxScore = 5

function priorityWeight(p?: string): number {
  switch (p) {
    case 'critical': return 4
    case 'high': return 3
    case 'medium': return 2
    case 'low': return 1
    default: return 0
  }
}

function barWidth(score: number | null): string {
  return `${((score ?? 0) / maxScore) * 100}%`
}

function gapColor(gap: number | null): string {
  if (gap == null) return 'text-gray-500'
  const absGap = Math.abs(gap)
  if (absGap >= 2) return 'text-red-600'
  if (absGap >= 1) return 'text-orange-500'
  return 'text-green-600'
}

function gapBg(gap: number | null): string {
  if (gap == null) return 'bg-gray-100'
  const absGap = Math.abs(gap)
  if (absGap >= 2) return 'bg-red-100'
  if (absGap >= 1) return 'bg-orange-100'
  return 'bg-green-100'
}

function priorityColor(priority?: string): string {
  switch (priority) {
    case 'critical': return 'bg-red-100 text-red-800'
    case 'high': return 'bg-orange-100 text-orange-800'
    case 'medium': return 'bg-blue-100 text-blue-800'
    default: return 'bg-gray-100 text-gray-600'
  }
}
</script>

<template>
  <div>
    <h3 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
      Gap Analysis
    </h3>
    <p class="text-sm mb-6" :style="{ color: 'var(--color-text-secondary)' }">
      Comparing individual assessment against self, team average, and role average. Sorted by priority then gap size.
    </p>

    <div class="space-y-4">
      <div
        v-for="item in sortedItems"
        :key="item.name"
        class="rounded-lg p-4"
        :style="{ border: '1px solid var(--color-border)' }"
      >
        <!-- Header: name + priority + gap -->
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-2">
            <span class="text-sm font-medium" :style="{ color: 'var(--color-text-primary)' }">{{ item.name }}</span>
            <span
              v-if="item.priority"
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
              :class="priorityColor(item.priority)"
            >
              {{ item.priority }}
            </span>
          </div>
          <span
            v-if="item.gap != null"
            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold"
            :class="[gapColor(item.gap), gapBg(item.gap)]"
          >
            Gap: {{ item.gap > 0 ? '+' : '' }}{{ item.gap.toFixed(1) }}
          </span>
          <span
            v-else
            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-gray-100 text-gray-500"
          >
            No gap data
          </span>
        </div>

        <!-- Score bars -->
        <div class="space-y-2">
          <!-- Manager score bar -->
          <div v-if="item.manager_score != null" class="flex items-center gap-3">
            <span class="text-xs w-20 shrink-0" :style="{ color: 'var(--color-text-secondary)' }">Manager</span>
            <div class="flex-1 h-4 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
              <div
                class="h-full rounded-full transition-all duration-300"
                :style="{ width: barWidth(item.manager_score), backgroundColor: 'var(--color-primary)' }"
              />
            </div>
            <span class="text-xs font-medium w-8 text-right" :style="{ color: 'var(--color-text-secondary)' }">
              {{ (item.manager_score ?? 0).toFixed(1) }}
            </span>
          </div>

          <!-- Self score bar -->
          <div v-if="item.self_score != null" class="flex items-center gap-3">
            <span class="text-xs w-20 shrink-0" :style="{ color: 'var(--color-text-secondary)' }">Self</span>
            <div class="flex-1 h-4 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
              <div
                class="h-full bg-emerald-500 rounded-full transition-all duration-300"
                :style="{ width: barWidth(item.self_score) }"
              />
            </div>
            <span class="text-xs font-medium w-8 text-right" :style="{ color: 'var(--color-text-secondary)' }">
              {{ (item.self_score ?? 0).toFixed(1) }}
            </span>
          </div>

          <!-- Team average bar -->
          <div v-if="item.team_avg != null" class="flex items-center gap-3">
            <span class="text-xs w-20 shrink-0" :style="{ color: 'var(--color-text-secondary)' }">Team Avg</span>
            <div class="flex-1 h-4 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
              <div
                class="h-full bg-sky-400 rounded-full transition-all duration-300"
                :style="{ width: barWidth(item.team_avg) }"
              />
            </div>
            <span class="text-xs font-medium w-8 text-right" :style="{ color: 'var(--color-text-secondary)' }">
              {{ (item.team_avg ?? 0).toFixed(1) }}
            </span>
          </div>

          <!-- Role average bar -->
          <div v-if="item.role_avg != null" class="flex items-center gap-3">
            <span class="text-xs w-20 shrink-0" :style="{ color: 'var(--color-text-secondary)' }">Role Avg</span>
            <div class="flex-1 h-4 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
              <div
                class="h-full bg-violet-400 rounded-full transition-all duration-300"
                :style="{ width: barWidth(item.role_avg) }"
              />
            </div>
            <span class="text-xs font-medium w-8 text-right" :style="{ color: 'var(--color-text-secondary)' }">
              {{ (item.role_avg ?? 0).toFixed(1) }}
            </span>
          </div>

          <!-- No data state -->
          <p
            v-if="item.manager_score == null && item.self_score == null && item.team_avg == null && item.role_avg == null"
            class="text-xs italic"
            :style="{ color: 'var(--color-text-muted)' }"
          >
            No assessment data available
          </p>
        </div>
      </div>
    </div>

    <div v-if="items.length === 0" class="text-center py-12" :style="{ color: 'var(--color-text-muted)' }">
      <p>No gap analysis data available</p>
    </div>
  </div>
</template>
