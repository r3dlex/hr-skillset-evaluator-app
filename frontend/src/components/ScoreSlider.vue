<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  modelValue: number
  disabled?: boolean
}>(), {
  disabled: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()

const percentage = computed(() => (props.modelValue / 5) * 100)

function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', Number(target.value))
}
</script>

<template>
  <div class="flex items-center gap-3">
    <input
      type="range"
      min="0"
      max="5"
      step="1"
      :value="modelValue"
      :disabled="disabled"
      class="flex-1 h-2 rounded-full appearance-none cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed accent-primary"
      :style="{
        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${percentage}%, #e5e7eb ${percentage}%, #e5e7eb 100%)`,
      }"
      @input="handleInput"
    />
    <span
      class="w-8 h-8 rounded-lg flex items-center justify-center text-sm font-semibold shrink-0"
      :class="modelValue > 0 ? 'bg-primary/10 text-primary' : 'bg-gray-100 text-gray-400'"
    >
      {{ modelValue }}
    </span>
  </div>
</template>
