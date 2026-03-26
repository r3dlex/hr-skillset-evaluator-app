<script setup lang="ts">
import type { Skillset } from '@/types'

defineProps<{
  skillsets: Skillset[]
  activeId: number | null
}>()

const emit = defineEmits<{
  select: [id: number]
}>()
</script>

<template>
  <div class="flex gap-1 overflow-x-auto pb-1">
    <button
      v-for="skillset in skillsets"
      :key="skillset.id"
      class="px-4 py-2 text-sm font-medium rounded-lg whitespace-nowrap transition-colors shrink-0"
      :class="
        activeId === skillset.id
          ? 'bg-primary text-white shadow-sm'
          : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
      "
      @click="emit('select', skillset.id)"
    >
      {{ skillset.name }}
      <span
        v-if="skillset.skill_count"
        class="ml-1.5 text-xs opacity-70"
      >
        ({{ skillset.skill_count }})
      </span>
    </button>
    <p
      v-if="skillsets.length === 0"
      class="text-sm text-gray-400 py-2"
    >
      No skillsets available
    </p>
  </div>
</template>
