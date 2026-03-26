<script setup lang="ts">
import type { Skill } from '@/types'
import ScoreSlider from './ScoreSlider.vue'

defineProps<{
  skills: Skill[]
  scores: Record<number, number | null>
  readonly: boolean
}>()

const emit = defineEmits<{
  'update:score': [skillId: number, value: number]
}>()

function priorityColor(priority: string): string {
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
    <h3 class="text-lg font-semibold text-gray-900 mb-4">
      Score Data
    </h3>

    <!-- Table header -->
    <div class="grid grid-cols-12 gap-4 px-4 py-2 text-xs font-medium text-gray-500 uppercase tracking-wider">
      <div class="col-span-5">Skill</div>
      <div class="col-span-2">Priority</div>
      <div class="col-span-5">Score (0-5)</div>
    </div>

    <!-- Skill rows -->
    <div class="divide-y divide-gray-100">
      <div
        v-for="skill in skills"
        :key="skill.id"
        class="grid grid-cols-12 gap-4 items-center px-4 py-3"
      >
        <div class="col-span-5 text-sm font-medium text-gray-900">
          {{ skill.name }}
        </div>
        <div class="col-span-2">
          <span
            class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
            :class="priorityColor(skill.priority)"
          >
            {{ skill.priority }}
          </span>
        </div>
        <div class="col-span-5">
          <ScoreSlider
            :model-value="scores[skill.id] ?? 0"
            :disabled="readonly"
            @update:model-value="emit('update:score', skill.id, $event)"
          />
        </div>
      </div>
    </div>

    <p v-if="skills.length === 0" class="text-center py-8 text-gray-400">
      No skills to display
    </p>
  </div>
</template>
