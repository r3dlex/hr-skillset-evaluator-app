<script setup lang="ts">
import ribLogoUrl from '@/assets/rib-logo.png'

withDefaults(defineProps<{
  color?: string
  size?: number
  showText?: boolean
}>(), {
  color: '#0166B1',
  size: 32,
  showText: true,
})
</script>

<template>
  <div class="flex items-center gap-2">
    <img
      :width="size"
      :height="size"
      :src="ribLogoUrl"
      alt="RIB"
      class="shrink-0 rounded-full"
    />

    <!-- "RIB" text -->
    <span
      v-if="showText"
      class="font-bold tracking-tight"
      :style="{ color, fontSize: `${size * 0.6}px`, lineHeight: 1 }"
    >
      RIB
    </span>
  </div>
</template>
