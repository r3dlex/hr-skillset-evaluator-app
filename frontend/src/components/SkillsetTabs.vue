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
      :style="
        activeId === skillset.id
          ? { backgroundColor: 'var(--color-primary)', color: '#ffffff', boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)' }
          : { backgroundColor: 'var(--color-surface)', color: 'var(--color-text-secondary)', border: '1px solid var(--color-border)' }
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
      class="text-sm py-2"
      :style="{ color: 'var(--color-text-muted)' }"
    >
      No skillsets available
    </p>
  </div>
</template>
